import { expect, test } from "@playwright/test";

// 家族が事業所をさがし、詳細を見て、ログインしてお気に入りに入れるまでの一連の流れ
test("検索 → 詳細 → ログイン → お気に入り", async ({ page }) => {
  await page.goto("/");

  // React の絞り込みパネルが載っている（件数付きのチェックボックス）
  const panel = page.getByRole("search", { name: "事業所の絞り込み" });
  await expect(panel.getByRole("checkbox", { name: /放課後等デイサービス/ })).toBeVisible();

  await panel.getByLabel("キーワード").fill("ひまわり教室");
  await panel.getByRole("button", { name: "この条件で探す" }).click();
  await expect(page).toHaveURL(/keyword=/);

  await panel.getByRole("checkbox", { name: /土曜に利用できる/ }).check();
  await expect(page).toHaveURL(/open_saturday=1/);

  const card = page.getByTestId("facility-card").filter({ hasText: "サンプル ひまわり教室（架空）" });
  await expect(card).toBeVisible();
  await card.getByRole("link", { name: "サンプル ひまわり教室（架空）" }).click();

  await expect(page.getByRole("heading", { level: 1, name: "サンプル ひまわり教室（架空）" })).toBeVisible();
  await expect(page.getByText("サンプルデータ（架空）").first()).toBeVisible();
  const recommendation = page.getByTestId("recommendation").first();
  await expect(recommendation.getByRole("list", { name: "おすすめの理由" })).toBeVisible();

  // 未ログインでお気に入り → ログイン画面 → ログイン後に事業所ページへ戻る
  await page.getByRole("button", { name: /お気に入りに追加/ }).click();
  await expect(page).toHaveURL(/\/session\/new/);
  await page.getByLabel("メールアドレス").fill("family@example.com");
  await page.getByLabel("パスワード").fill("demo-password-2026");
  await page.getByRole("button", { name: "ログイン" }).click();
  await expect(page.getByRole("heading", { level: 1, name: "サンプル ひまわり教室（架空）" })).toBeVisible();

  // Turbo Stream でボタンだけが切り替わる
  await page.getByRole("button", { name: /お気に入りに追加/ }).click();
  await expect(page.getByRole("button", { name: /お気に入りから外す/ })).toBeVisible();

  await page.getByRole("link", { name: "お気に入り", exact: true }).click();
  await expect(page.getByTestId("facility-card").filter({ hasText: "サンプル ひまわり教室（架空）" })).toBeVisible();

  // 後片付け（何度流しても同じ状態から始められるように）
  await page.goto(await page.getByRole("link", { name: "サンプル ひまわり教室（架空）" }).getAttribute("href") ?? "/");
  await page.getByRole("button", { name: /お気に入りから外す/ }).click();
  await expect(page.getByRole("button", { name: /お気に入りに追加/ })).toBeVisible();
});
