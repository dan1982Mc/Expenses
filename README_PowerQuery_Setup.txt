PERSONAL FINANCES — HOUSEHOLD POWER QUERY SETUP

What this package is
--------------------
An Excel-based household cashflow and expense analysis system for the two Revolut accounts (Dan + Anca). The source data has been checked: 8 CSV files, 5,324 transaction rows, EUR only, covering 2023-01-01 to 2026-11-17. Dan and Anca are combined as one household; account identity remains available for filtering.

1. Prepare the source folder
----------------------------
Download the GitHub repository as a ZIP:
https://github.com/dan1982Mc/Expenses/archive/refs/heads/main.zip

Extract the two account folders into a local folder with this exact structure:
C:\Personal_Finances\Bank_Exports\
    Revolut Dan\   (the four Dan CSV files)
    Revolut Anca\ (the four Anca CSV files)

The query scans subfolders recursively. Preserve the two folder names. New monthly or annual CSV statements can be dropped into the relevant account folder; no need to rename existing files.

2. Set the folder path
----------------------
Open Personal_Finances_Household.xlsx > Settings.
In the ImportFolder setting, replace the example path with the parent folder, e.g. C:\Personal_Finances\Bank_Exports
Do not point to either account subfolder; point to the folder containing both account folders.

3. Create the Power Query queries (one-time setup)
--------------------------------------------------
In Excel desktop for Windows:
Data > Get Data > From Other Sources > Blank Query > Advanced Editor.
Copy the matching section from PowerQuery_Queries.m and create these queries with the exact names:

- qTransactionsRaw               (connection only)
- qTransactionsCategorized       (load to Transactions!A3)
- qMonthlySummary                (load to Monthly_Summary!A3)
- qCategoryMonthly               (load to Category_Monthly!A3)
- qRecurringCandidates           (load to Recurring_Candidates!A3)
- qTransferReview                (load to Transfer_Review!A3)
- qInsights                      (load to Insights!A3)

Create qTransactionsRaw first, then create qTransactionsCategorized, then the remaining dependent queries. For each query, use the section with the same QUERY name in PowerQuery_Queries.m. Set qTransactionsRaw to Connection Only. For the others use Close & Load To > Table > Existing worksheet and the destinations above (start at cell A3 to preserve worksheet titles). Load each query to an empty output sheet starting at A1; let Power Query create its result table.

When first prompted for the folder connector credentials, select Windows or Anonymous as appropriate for a local Folder source. No bank login or Revolut API credentials are used.

4. Refresh every month
----------------------
Export the new Revolut statement CSV for each account and put it in the matching subfolder. Then open the workbook and select Data > Refresh All. The system re-reads all files, so historical exports must remain in the folder. If an annual export overlaps a previous export, the query marks repeated fingerprints for review rather than silently deleting rows.

5. Rules and classifications
----------------------------
The Merchant_Rules sheet is editable. Add a new rule when an unclassified merchant or transfer appears. Lower Priority numbers run first. MatchText is a case-insensitive text-contains rule. FlowTreatment must be one of:
Expense | Income | Refund | Internal transfer | Investment | Mortgage review | Transfer review | Income review | Currency Exchange | Excluded

The model deliberately does not treat every outgoing Transfer as a purchase. Ambiguous transfers, unknown top-ups and mortgage-related payments are sent to Transfer_Review until classified. Known Dan↔Anca transfers and pocket/savings movements are excluded from household spending using starter rules. Check these rules before relying on totals.

6. Analysis notes and limitations
---------------------------------
- Date basis: Completed Date; Started Date is used only when Completed Date is blank.
- Cash effect: Amount minus Fee, matching the effect on the Revolut balance for fee-bearing transactions.
- Only COMPLETED entries enter income/expense analysis. PENDING and REVERTED remain visible in the transaction output but are excluded from totals.
- Repeated fingerprints are flagged, not automatically removed: Revolut exports do not provide a dependable unique transaction ID in these files, and identical same-merchant/same-amount payments can be legitimate.
- Year-on-year comparisons use the same calendar month. The current month is marked partial; compare complete months for fair conclusions.
- Recurring payment detection is a suggestion based on repeated merchant descriptions and date gaps. Confirm annual and one-off flags before using the monthly equivalents as a budget commitment.
- Mortgage transfers are not treated as fully understood mortgage expenses: the principal/interest split must be added from lender statements when mortgage data is introduced.
- Investments are tracked as contributions, not consumption. Future portfolio valuations belong in the Asset_Snapshots sheet.

7. First review checklist
-------------------------
- Check all rows in Transfer_Review and classify frequent bill transfers.
- Confirm the Dan↔Anca and savings-pocket rules.
- Review Recurring_Candidates, especially Annual and Single occurrence.
- Add realistic budgets for the four broad expense groups.
- Check the Data_Audit sheet for the imported file inventory.

IMPORTANT: This workbook is a cashflow and planning aid, not accounting or tax software. It does not infer the purpose of unknown transactions with certainty.
