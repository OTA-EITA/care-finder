# ADR 0003: キャッシュは ElastiCache Redis、ジョブは Solid Queue（Aurora）にする

- 状態: 採用
- 日付: 2026-10-25

## 背景

Rails 8 の既定は Solid Cache / Solid Queue / Solid Cable で、どれも DB に載る。このアプリで必要なのは次の 2 つ。

- **キャッシュ**: ログインと新規登録の `rate_limit` の回数、国土地理院 API のジオコーディング結果。複数の Fargate タスクで共有する必要がある
- **ジョブ**: Elasticsearch バックエンドのときの索引更新（`SearchIndexJob`）、パスワード再設定メール

## 決定

- `Rails.cache` は本番で **ElastiCache（Redis）** を使う
  - `rate_limit` はリクエストごとに読み書きするので、DB ではなくメモリのストアに置き、Aurora の負荷とレイテンシに影響させない
  - 消えても困らないデータだけを置く。Redis 障害時は `error_handler` でログを出し、キャッシュなしで動き続ける（その間は回数制限が効かないので、WAF のレート制限を二重の備えにしている）
- ジョブは **Solid Queue** を **primary DB に同居** させる（別 DB にしない）
  - Redis を落としてもジョブが消えない。Aurora のバックアップにも含まれる
  - 量が少なく、DB を分けるほどの負荷がない。DB が 1 つなら接続設定とマイグレーションも 1 つで済む
  - ワーカーは Web とは別の ECS サービス（`bin/jobs`）で動かす
- Action Cable は使わない（Turbo Stream はフォーム送信の応答だけで使う）ので、Solid Cable は入れない

## 結果

- `solid_queue:install` が作る `db/queue_schema.rb` はマイグレーションに移した
- テストでは `rate_limit` を確かめるために `memory_store` を使い、Redis 自体の動作は `REDIS_URL` があるときだけ統合テストで確かめる
- ジョブの滞留は ECS のタスク数と Solid Queue のテーブルで見る。量が増えたら Mission Control などの導入を検討する
