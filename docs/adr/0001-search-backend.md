# ADR 0001: 検索は MySQL FULLTEXT（ngram）を既定にし、Elasticsearch は差し替え可能にする

- 状態: 採用
- 日付: 2026-10-25

## 背景

事業所の検索では、次のことが必要になる。

- 日本語のキーワード検索（事業所名・法人名・住所・紹介文・支援内容）。分かち書きがないため、単語単位の索引は使えない
- 表記ゆれの吸収（全角/半角、ひらがな/カタカナ、住所のダッシュ）
- 地域・サービス種別・曜日・送迎・支援内容での絞り込みと、条件ごとの件数（ファセット）
- 駅や住所からの距離順

データ量は北海道と大阪府で約 7,300 件、全国でも放デイ 2.5 万件・児発 1.7 万件程度で、更新は半年ごとのオープンデータと職員の編集だけ。

## 選択肢

| | MySQL FULLTEXT（ngram） | Elasticsearch / OpenSearch |
|---|---|---|
| 追加の運用 | なし（Aurora をそのまま使う） | クラスター、索引の同期、バージョンアップ |
| 日本語 | ngram パーサーで 2-gram。形態素解析はない | kuromoji なども選べる。ここでは同じ 1〜2-gram にした |
| 反映の速さ | コミット時に索引が更新される | 非同期ジョブで反映（数秒の遅れ） |
| ファセット | 条件ごとに COUNT と GROUP BY（1 回の検索で 10 クエリ前後） | aggregations で 1 リクエスト |
| 距離 | `ST_Distance_Sphere`（空間索引なし） | `geo_point` と `_geo_distance` |
| スコアの調整 | ほぼできない | boost、function_score など |

## 決定

- 検索処理を `Search::Backends::*` の共通インターフェース（`search` / `index` / `remove` / `reindex_all` / `indexes_documents?`）の裏に置き、`SEARCH_BACKEND` で切り替える
- 既定は **MySQL FULLTEXT（`WITH PARSER ngram`、`ngram_token_size=2`）**。今のデータ量なら追加の運用を持たずに要件を満たせる
- Elasticsearch 実装も用意し、同じ契約テスト（`spec/support/shared_examples/search_backend.rb`）を両方に流して結果がそろうことを確かめる
- 正規化（NFKC、ひらがな→カタカナ、ダッシュ統一、小文字化）は Ruby の `Search::TextNormalizer` に寄せ、索引と検索語の両方に同じ処理をかける。どちらのバックエンドでも同じ規則になる
- Elasticsearch が落ちたら `Search::FacilitySearch` が MySQL で検索を続け、画面に「簡易検索」と出す

## 結果

- FULLTEXT の定義（`WITH PARSER ngram`）は `schema.rb` に残らないため、スキーマは `db/structure.sql` で管理する
- InnoDB の FULLTEXT はコミット時に更新されるので、全文検索を通すテストはトランザクションを使わない（`:committed_data`）
- ngram の 2-gram に載らない 1 文字の語は `LIKE` で補う。Elasticsearch 側も 1 文字用と 2 文字用の検索アナライザーを分けて同じ挙動にした
- Elasticsearch の索引はエイリアス + 日時付きの実体で持ち、`bin/rails search:reindex` は新しい実体を作ってからエイリアスを付け替える（無停止で作り直せる）
- Elasticsearch のクライアントは公式 gem を使わず、使う API だけを呼ぶ薄いクライアントにした。製品チェックやメジャーバージョンへの追従を持たずに済み、OpenSearch にもそのまま向けられる

## Elasticsearch に切り替える目安

- 全国のデータを入れて、ファセット付き検索の p95 が SLO（[docs/slo.md](../slo.md)）を超える
- 検索語の分析（ゼロ件の語、クリック率）から、同義語やスコア調整が必要になる
- 「おすすめ」を検索結果の並び順にも混ぜたくなる（function_score）
