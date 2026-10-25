# ADR 0004: 画面は Hotwire で作り、絞り込みパネルだけを React の島にする

- 状態: 採用
- 日付: 2026-10-25

## 背景

ほとんどの画面はフォームと一覧で、サーバーで描けば足りる。一方、検索の絞り込みパネルは、件数付きのチェックボックス・都道府県に連動する市区町村・入力の確定タイミングなど、状態の組み合わせが多い。

## 決定

- 画面遷移は Turbo Drive、お気に入りボタンは Turbo Frame / Turbo Stream、小さな動き（文字数カウンター、スマートフォンでの開閉）は Stimulus
- 絞り込みパネルだけを React + TypeScript にし、サーバーが描いた HTML の中に「島」として載せる
  - `<div data-react-island="SearchFilterPanel" data-props="JSON">` の中には JS なしで動く同じ内容のフォームを描いておき、React が読み込めたら置き換える
  - Turbo がページをキャッシュする前（`turbo:before-cache`）に React を外し、元の HTML に戻す
  - 検索条件の型は Rails の `Search::Criteria` と TypeScript の `SearchState` でそろえ、クエリ文字列の組み立ては純粋関数にして Jest で確かめる
- ビルドは jsbundling-rails + esbuild。React 本体は島があるページでだけ読み込む（code splitting）
- ESLint・Jest（Testing Library）・Storybook はこの島のために入れる

## 結果

- React を使わないページの JS は Turbo と Stimulus だけ（minify 後 約 140KB）で、React（約 210KB）は検索画面でだけ読む
- JS が無効でも検索できる（サーバー側のフォーム）
- 島を増やすときは `app/javascript/islands/index.ts` の registry に足す
