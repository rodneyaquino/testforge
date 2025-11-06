// TestForge - Playwright config
// WHY: Centralize browser and test settings for clarity.
// WHAT: Set baseURL to Sauce Demo, use Chromium desktop, enable HTML report,
//       and collect trace on first retry to debug flakiness.
// HOW: Playwright auto-loads this config via CLI.
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './',
  timeout: 60_000,
  expect: { timeout: 5_000 },
  reporter: [
    ['list'],
    ['html', { outputFolder: 'playwright-report', open: 'never' }]
  ],
  use: {
    baseURL: 'https://www.saucedemo.com',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'off'
  },
  // Each test runs in a fresh browser context and page. No manual teardown required.
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } }
  ]
});