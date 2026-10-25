import { expect, test } from "@playwright/test";

// README 用のスクリーンショットを撮る。開発環境（オープンデータ取り込み済み + シード）に向けて手動で流す:
//   E2E_BASE_URL=http://127.0.0.1:3000 npx playwright test --project screenshots
test.skip(!process.env.E2E_BASE_URL, "開発サーバーに向けたときだけ撮る");

const out = (name: string) => `docs/images/${name}.webp`;

test("検索画面", async ({ page }) => {
  await page.goto("/facilities?prefecture=北海道&municipality=帯広市&near=帯広駅&sort=distance");
  await expect(page.getByRole("search", { name: "事業所の絞り込み" })).toBeVisible();
  await page.screenshot({ path: out("search"), type: "webp", quality: 80 });
});

test("詳細画面（オープンデータの事業所）", async ({ page }) => {
  await page.goto("/facilities?prefecture=北海道&municipality=帯広市&near=帯広駅&sort=distance&service_types[]=houkago_day&open_saturday=1");
  const card = page.getByTestId("facility-card").filter({ hasNotText: "サンプルデータ" }).first();
  await card.getByRole("link").first().click();
  await expect(page.getByRole("heading", { name: "似ている事業所" })).toBeVisible();
  await page.screenshot({ path: out("detail"), type: "webp", quality: 80, fullPage: true });
});

test("管理画面（サンプル事業所の編集）", async ({ page }) => {
  await page.goto("/session/new");
  await page.getByLabel("メールアドレス").fill("staff@example.com");
  await page.getByLabel("パスワード").fill("demo-password-2026");
  await page.getByRole("button", { name: "ログイン" }).click();
  await expect(page.getByRole("link", { name: "掲載情報の管理" })).toBeVisible();
  await page.goto("/admin/facilities");
  await page.getByRole("link", { name: "編集" }).first().click();
  await expect(page.getByText(/あと \d+ 文字/)).toBeVisible();
  await page.screenshot({ path: out("admin"), type: "webp", quality: 80, fullPage: true });
});

test("スマートフォン幅の検索画面", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/facilities?prefecture=大阪府&municipality=大阪市天王寺区&near=天王寺駅&sort=distance");
  await expect(page.getByTestId("facility-card").first()).toBeVisible();
  await page.screenshot({ path: out("mobile"), type: "webp", quality: 80 });
});
