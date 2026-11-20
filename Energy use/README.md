# Household Energy Account Dashboard

**Open the dashboard:** [index.html](index.html)  
**Original history image:** [Schermafbeelding 2026-11-20 150101.png](Schermafbeelding%202026-11-20%20150101.png)

A standalone dashboard for tracking household electricity and gas consumption, supplier advance payments, and the projected energy-year settlement. It uses the historical monthly values transcribed from the PNG and manual monthly consumption entries. **It does not import or depend on the CSV files.**

## Your energy year

- Energy year starts on **1 July** and ends on **30 June**.
- Comparison baseline: **July 2025 – June 2026**.
- Data before July 2025 is excluded because it relates to a different house.
- Baseline consumption: **3,301 kWh electricity** and **722 m³ gas**.
- Current tracking year: **July 2026 – June 2027**.

## Unit prices and payments already entered

| Setting | Value |
|---|---:|
| Electricity | **€0.26697 / kWh** |
| Gas | **€1.43817 / m³** |
| Current monthly advance | **€180** |
| Payments already logged | **2 × €228 + 2 × €180 = €816** |
| Separate fixed costs | **None included** |

The four initial payments are stored without dates because dates were not supplied. You can remove and re-enter a payment with a date if you want a dated ledger. Record each future payment using the payment form; the monthly advance setting is only used for the annual payment plan and does not automatically invent payments.

## How the cost and account calculations work

- Monthly energy cost = electricity kWh × electricity rate + gas m³ × gas rate.
- A month's cost is counted only when both electricity and gas values are entered.
- Payments logged = sum of actual payment records.
- Paid less recorded consumption cost = payments logged minus costs for months with both readings. This is shown at the bottom of the Payments made to supplier card. It is a running comparison, **not a confirmed supplier credit**, because missing readings and payment dates may affect the true balance.
- Projected full-year energy cost uses complete current-year months entered consecutively from July, then uses the matching 2025/26 monthly consumption for the remaining months. As you enter actual consumption, the estimate is replaced month by month.
- Projected annual credit / shortfall = 12 × current monthly advance − projected full-year energy cost.
- No additional fixed charges are added.

At the current rates, the previous-year baseline costs approximately **€1,919.63 per year**, or **€159.97 per month**. At €180 per month, the projected annual advance is €2,160, giving an indicative buffer of **€240.37** if consumption and rates remain comparable.

## Monthly update routine

1. Open `index.html` in a modern browser.
2. Select the month in the July–June energy year.
3. Enter monthly electricity in kWh and gas in m³.
4. Mark actual readings as “Actual monthly reading”, or mark estimates/partial readings accordingly.
5. Save the month. The dashboard refreshes consumption comparisons, monthly costs, payment balance and annual forecast.
6. Add each supplier advance payment when it is actually paid. You can include the payment date.
7. Use **Export backup** regularly. **Import backup** restores consumption entries, rates and payment history.

## Files

- `index.html` — dashboard page.
- `styles.css` — dashboard styling.
- `app.js` — calculations, manual entries, payment ledger and backup/restore.
- `history-baseline.json` — structured copy of the PNG historical data.
- `Schermafbeelding 2026-11-20 150101.png` — original image source.

## Saving and publishing

GitHub stores the dashboard source and historical baseline. Your monthly readings, payment ledger and setting changes are saved in the browser's local storage, not automatically committed to GitHub or shared between devices. Use Export backup to retain or transfer the data.

For GitHub Pages, select the `main` branch and the `/ (root)` folder in repository Settings → Pages. The page should then be available at:

`https://dan1982mc.github.io/Expenses/Energy%20use/`

The three application files must stay together in the same folder if you download and run the dashboard locally.
