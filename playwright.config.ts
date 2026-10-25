import { defineConfig, devices } from "@playwright/test";

// E2E は test 環境の Rails をシード済みのサンプルデータ（架空）で起動して流す。
// 既に起動しているサーバーに当てるときは E2E_BASE_URL を指定する。
const port = Number(process.env.E2E_PORT ?? 3200);
const baseURL = process.env.E2E_BASE_URL ?? `http://127.0.0.1:${port}`;

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: false,
  workers: 1,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? [["list"], ["html", { open: "never" }]] : "list",
  use: {
    baseURL,
    locale: "ja-JP",
    trace: "retain-on-failure",
    // ローカルではインストール済みの Google Chrome を使える（PLAYWRIGHT_CHANNEL=chrome）
    channel: process.env.PLAYWRIGHT_CHANNEL,
  },
  projects: [
    { name: "smoke", testIgnore: /screenshots\.spec\.ts/, use: { ...devices["Desktop Chrome"], channel: process.env.PLAYWRIGHT_CHANNEL } },
    { name: "screenshots", testMatch: /screenshots\.spec\.ts/, use: { viewport: { width: 1280, height: 860 }, channel: process.env.PLAYWRIGHT_CHANNEL } },
  ],
  webServer: process.env.E2E_BASE_URL
    ? undefined
    : {
        command: `bin/rails db:prepare db:seed && bin/rails server -p ${port} -b 127.0.0.1`,
        url: `${baseURL}/up`,
        env: { RAILS_ENV: "test", COVERAGE: "0" },
        reuseExistingServer: !process.env.CI,
        timeout: 120_000,
      },
});
