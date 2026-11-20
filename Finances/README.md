# Household finances dashboard

A local-first household finance analysis app for Revolut CSV exports. It is separate from the existing Energy use dashboard.

## Start

1. Download or clone this repository to your computer.
2. Open Finances/index.html in a modern browser (Chrome, Edge or Firefox).
3. Select all available CSV exports under Dan's account and Anca's account.
4. Import the files. You can import later statements at any time; exact re-imported rows are skipped.
5. Use the Overview, Comparisons, Projects, Rules, Transactions and Savings forecast sections.

No bank login, API key, server, external JavaScript library or internet connection is required after the files are on your computer.

## Local data and privacy

- Transactions are stored in the browser's IndexedDB database on that device.
- Classification rules and forecast settings are stored in local browser storage.
- The app makes no network requests and does not fetch CSVs from GitHub.
- Use Backup to export a JSON file containing transactions, rules, overrides and forecast settings. Keep that backup private.
- Use Restore backup to restore or merge a backup.
- Clearing browser site data can remove the local database; export a backup regularly.

The repository may contain bank exports in other folders. Keep the repository private. This app does not copy or publish those exports, but it cannot make files already committed to a public repository private.

## Import format

The importer expects the standard Revolut statement columns:
Type, Product, Started Date, Completed Date, Description, Amount, Fee, Currency, State, Balance.

Completed Date is used when present; Started Date is used when Completed Date is blank. Non-completed rows remain visible but are excluded from totals. The application calculates cash effect as Amount minus Fee.

## Classification model

- Card payments are treated as expenses and get a conservative merchant-category suggestion.
- Card refunds reduce expenses in the merchant's category.
- Known employer payments, SVB benefits and Belastingdienst refunds are recognised as income.
- Known Dan↔Anca and named Revolut pocket movements are treated as internal transfers.
- Recognised investment destinations are tracked separately from household consumption.
- Unrecognised transfers and incoming top-ups are sent to Needs review, not guessed as income or expenses.
- Custom rules can match account, description text, transaction type, date range and amount range. They can set a category, project, treatment or expense nature.
- Individual transaction overrides take precedence over custom and built-in rules.

Review the initial classifications before relying on totals. In particular, confirm ambiguous transfer descriptions and any new merchants.

## Version 1 scope and limitations

Included:
- Multi-file Dan and Anca CSV import and exact duplicate detection.
- Local IndexedDB storage, JSON backup/restore and filtered CSV export.
- Monthly income, expenses, investments and net cash-flow overview.
- Same-month previous-year and available previous-years average comparisons by category.
- Same-day cutoff for the latest incomplete imported month.
- Custom merchant / date / account / type / amount rules and project labels.
- Manual transaction classification overrides.
- One-time / limited-expense candidates based on merchant frequency and configurable thresholds.
- Pre-salary savings estimate using balances entered by the user, days to salary, recent 90-day spending, known payments and a minimum reserve.

Not yet included:
- Automatic bank balance retrieval or Revolut API integration.
- Automatic pairing of every possible internal transfer; unknown transfers remain in review.
- Fully automatic recurring-payment calendar with due-date prediction.
- Multi-condition rule groups such as nested AND/OR logic, rule testing and bulk undo.
- A natural-language question box or an embedded AI assistant. Use the comparison filters and exports, then ask ChatGPT to investigate more complex questions.
- Budget targets, category caps, multi-scenario savings plans and asset / net-worth tracking.
- Automatic transaction matching between refunds and original purchases.
- Cloud sync between browsers or devices.

## Important

This is a decision-support tool, not accounting or tax software. Imported data can be incomplete, bank descriptions can be ambiguous, and automatic classifications are suggestions. Confirm review items and check the date coverage before acting on a result.
