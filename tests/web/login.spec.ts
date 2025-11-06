// Each test runs in a fresh browser context. No manual teardown required.

// WEB-001 and WEB-002 - Login flows
// WHY: Login is a primary quality gate. Validates routing and error UX.
// WHAT: Valid login -> inventory; invalid login -> error banner.
// HOW: Use stable locators (role and placeholder), assert URL and visible text.
import { test, expect } from '@playwright/test';

test('WEB-001: login with valid credentials shows inventory page', async ({ page }) => {
  await page.goto('/');
  await page.getByPlaceholder('Username').fill('standard_user');
  await page.getByPlaceholder('Password').fill('secret_sauce');
  await page.getByRole('button', { name: 'Login' }).click();
  await expect(page).toHaveURL(/inventory/);
  await expect(page.getByText('Products')).toBeVisible();
});

test('WEB-002: invalid login shows an error banner', async ({ page }) => {
  await page.goto('/');
  await page.getByPlaceholder('Username').fill('locked_out_user');
  await page.getByPlaceholder('Password').fill('wrong_password');
  await page.getByRole('button', { name: 'Login' }).click();
  await expect(page.locator('[data-test="error"]')).toContainText('Epic sadface');
});