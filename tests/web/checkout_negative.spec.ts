// Each test runs in a fresh browser context. No manual teardown required.

// WEB-005 - Checkout validation negative
// WHY: The brief requires at least two negative web tests.
// WHAT: Attempt to continue checkout with missing required fields. Expect error banner.
// HOW: Run within a single isolated test. State resets automatically.
import { test, expect } from '@playwright/test';

test('WEB-005: checkout shows validation errors for missing info', async ({ page }) => {
  await page.goto('/');
  await page.getByPlaceholder('Username').fill('standard_user');
  await page.getByPlaceholder('Password').fill('secret_sauce');
  await page.getByRole('button', { name: 'Login' }).click();
  await expect(page).toHaveURL(/inventory/);
  await page.getByRole('button', { name: /add to cart/i }).first().click();
  await page.locator('.shopping_cart_link').click();
  await expect(page).toHaveURL(/cart/);
  await page.getByRole('button', { name: 'Checkout' }).click();
  await expect(page).toHaveURL(/checkout-step-one/);
  await page.getByRole('button', { name: 'Continue' }).click();
  await expect(page.locator('[data-test="error"]')).toBeVisible();
  await expect(page.locator('[data-test="error"]')).toContainText(/Error/);
});