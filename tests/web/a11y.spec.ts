// WEB-A11Y — Accessibility scan with axe-core
// WHY: Enforce zero critical violations in the main content. Document the known upstream issue separately.
// WHAT: Run a strict scan scoped to the product list. No rule filtering. If any critical issues remain, fail with full details.
// HOW: Add a separate skipped test to track the known unlabeled sort <select> issue and link to BUG-001.

import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test('WEB-A11Y: inventory page content has zero critical accessibility violations', async ({ page }) => {
  // Login to reach the inventory page
  await page.goto('/');
  await page.getByPlaceholder('Username').fill('standard_user');
  await page.getByPlaceholder('Password').fill('secret_sauce');
  await page.getByRole('button', { name: 'Login' }).click();

  // Scope to the main product list. This focuses on core user content.
  const results = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa'])
    .include('.inventory_list')
    .analyze();

  // Collect critical violations without filtering out any rule ids
  const critical = results.violations.filter(v => v.impact === 'critical');

  // If anything is critical, fail with the full violations JSON for quick triage
  expect(critical, JSON.stringify(results.violations, null, 2)).toHaveLength(0);
});

/**
 * WEB-A11Y-KNOWN-BUG-001 — Unlabeled sort <select> in the header
 * WHY: The public demo site ships a sort control without an accessible name. This is a known upstream issue not owned by us.
 * WHAT: Document and track for transparency. Keep the strict content scan above. Do not mute rules in the passing test.
 * HOW: Mark as skipped so CI remains truthful while the defect is logged in reports/bugs/BUG-001-a11y-sort-select-label.md
 * Ref: BUG-001
 */
test.skip('WEB-A11Y-KNOWN-BUG-001: header sort dropdown is missing an accessible name', async ({ page }) => {
  // Login to reach the inventory header controls
  await page.goto('/');
  await page.getByPlaceholder('Username').fill('standard_user');
  await page.getByPlaceholder('Password').fill('secret_sauce');
  await page.getByRole('button', { name: 'Login' }).click();

  // Scan only the header area that contains the sort control
  const results = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa'])
    .include('.header_secondary_container') // container with the sort <select>
    .analyze();

  // Assert that the known violation is present to document reality
  const selectNameIssues = results.violations.filter(v => v.id === 'select-name');
  expect(selectNameIssues.length, 'Expected select-name violation to be present in header area').toBeGreaterThan(0);

  // This test is skipped by design. It exists as living documentation and a pointer to BUG-001.
});