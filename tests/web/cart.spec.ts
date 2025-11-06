// Each test runs in a fresh browser context. No manual teardown required.

// WEB-003 and WEB-004 - Cart and Sort
// WHY: Core ecommerce flow and UI sorting behavior.
// WHAT: Add first product; assert cart badge; proceed to checkout step one.
//       Sort A to Z then Z to A changes first visible item.
// HOW: Prefer generic locators to avoid coupling to specific item names.
import { test, expect } from '@playwright/test';

test('WEB-003: add to cart and proceed to checkout step one', async ({ page }) => {
  await page.goto('/');
  await page.getByPlaceholder('Username').fill('standard_user');
  await page.getByPlaceholder('Password').fill('secret_sauce');
  await page.getByRole('button', { name: 'Login' }).click();
  await expect(page).toHaveURL(/inventory/);
  await page.getByRole('button', { name: /add to cart/i }).first().click();
  const cartBadge = page.locator('.shopping_cart_badge');
  await expect(cartBadge).toHaveText('1');
  await page.locator('.shopping_cart_link').click();
  await expect(page).toHaveURL(/cart/);
  await page.getByRole('button', { name: 'Checkout' }).click();
  await expect(page).toHaveURL(/checkout-step-one/);
});

test('WEB-004: sorting A to Z then Z to A changes the first visible item', async ({ page }) => {
  await page.goto('/');
  await page.getByPlaceholder('Username').fill('standard_user');
  await page.getByPlaceholder('Password').fill('secret_sauce');
  await page.getByRole('button', { name: 'Login' }).click();

  // Read the first item before sorting
  const firstBefore = await page.locator('.inventory_item_name').first().textContent();

  // Correct attribute is data-test="product-sort-container"
  const sorter = page.locator('[data-test="product-sort-container"]');
  await sorter.waitFor({ state: 'visible', timeout: 10_000 });
  await sorter.selectOption('za');

  // Wait until the first item actually changes
  await expect(page.locator('.inventory_item_name').first()).not.toHaveText(firstBefore ?? '', { timeout: 10_000 });

  const firstAfter = await page.locator('.inventory_item_name').first().textContent();
  expect(firstAfter).not.toEqual(firstBefore);
});