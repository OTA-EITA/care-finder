# bin/ci で GitHub Actions とほぼ同じ検査を手元で流す（MySQL は docker compose up -d で起動しておく）

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Style: Ruby", "bin/rubocop"
  step "Style: TypeScript", "npm run lint"
  step "Types: TypeScript", "npm run typecheck"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: npm audit", "npm audit --audit-level=high"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  step "Build: JS and CSS", "npm run build && npm run build:css"
  step "Tests: RSpec", "bundle exec rspec"
  step "Tests: Jest", "npm test"
  step "Tests: Playwright", "npx playwright test --project smoke"
end
