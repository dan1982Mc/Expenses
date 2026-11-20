# Household Energy Dashboard

**Dashboard:** [Open the dashboard files](index.html)  
**Original historical screenshot:** [Schermafbeelding 2026-11-20 150101.png](Schermafbeelding%202026-11-20%20150101.png)

A simple, standalone monthly energy tracker for this household. It uses the historical monthly values transcribed from the PNG and manual monthly entries for the months that follow. **It does not use either CSV export.**

## Tracking period

- Energy year: **1 July to 30 June**.
- Historical comparison year: **July 2025 – June 2026**.
- Previous house data before July 2025 is intentionally excluded.
- Baseline total: **3,301 kWh electricity** and **722 m³ gas**.
- The manual-entry year in the current app is **July 2026 – June 2027**.

The source PNG is retained in this folder. Its transcribed values are also stored in [history-baseline.json](history-baseline.json).

## Starting rates and payment

| Setting | Value |
|---|---:|
| Electricity unit price | **€0.26697 / kWh** |
| Gas unit price | **€1.43817 / m³** |
| Monthly advance payment | **€180** |
| Annual advance plan | **€2,160** |
| Fixed charges | **€0** until entered |

The unit prices were supplied by the household owner and can be changed in the dashboard. Fixed charges are kept separate because the supplied rates may not include every fixed component of the supplier bill.

## How to use it

1. Open `index.html` in a modern browser.
2. Select the relevant month in the July–June energy year.
3. Enter electricity in kWh and gas in m³, then choose whether the figures are complete or estimates.
4. Save the month. The dashboard updates annual-to-date totals, same-period year-on-year comparison, month-on-month changes and estimated variable energy costs.
5. Update unit prices, fixed charges and advance-payment settings when they change.
6. Use **Export backup** periodically. **Import backup** restores the entries and settings.

## Files

- `index.html` — dashboard page.
- `styles.css` — dashboard layout and styling.
- `app.js` — monthly-entry, comparison and cost calculations.
- `history-baseline.json` — structured copy of the July 2025–June 2026 PNG data.
- `Schermafbeelding 2026-11-20 150101.png` — original image source.

## Saving and sharing your entries

The website files and historical baseline are stored in this GitHub repository. **Monthly entries and setting changes are stored in the browser's local storage; they are not automatically written back to GitHub or shared across devices.** Export a JSON backup to retain your entries or move them to another browser/device.

To publish it as a web page, enable GitHub Pages in repository Settings → Pages and select the `main` branch. The page will then be available at:

`https://dan1982mc.github.io/Expenses/Energy%20use/`

If GitHub Pages is not enabled, download the three app files together and open `index.html` locally. Keep `styles.css` and `app.js` in the same folder as `index.html`.
