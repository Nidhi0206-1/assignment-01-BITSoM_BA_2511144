[etl_notes.md](https://github.com/user-attachments/files/26184867/etl_notes.md)
# ETL Notes — Retail Transactions Data Warehouse

## ETL Decisions

### Decision 1 — Date Format Normalisation
**Problem:** The `date` column in the source CSV uses three different formats
interchangeably across rows: `DD/MM/YYYY` (e.g. `29/08/2023`),
`DD-MM-YYYY` (e.g. `12-12-2023`), and ISO `YYYY-MM-DD` (e.g. `2023-02-05`).
Attempting to load these directly into a `DATE` column would fail or silently
produce wrong dates depending on the database parser's default format
assumption.

**Resolution:** During the staging step, all date strings were parsed
programmatically using format detection (check for a leading four-digit year to
identify ISO format; otherwise parse as `DD/MM/YYYY` or `DD-MM-YYYY` by
detecting the separator). Every date was re-emitted in canonical ISO
`YYYY-MM-DD` form before being converted to the `date_key` integer surrogate
(`YYYYMMDD`). This guarantees unambiguous, consistent date representation
throughout the warehouse.

---

### Decision 2 — Category Value Standardisation
**Problem:** The `category` field contains the same logical category under
multiple spellings and casings: `electronics`, `Electronics` (two distinct
values for the same category); `Grocery` vs `Groceries` (used
interchangeably for grocery items such as Biscuits, Milk, and Atta).
Leaving these as-is would cause category-level aggregations to split a single
category into two or three rows, significantly understating revenue figures.

**Resolution:** A lookup-based normalisation map was applied during the
transformation stage:

| Raw value   | Standardised value |
|-------------|-------------------|
| electronics | Electronics        |
| Groceries   | Grocery            |

All other values (`Clothing`, `Grocery`, `Electronics`) were already correct.
The normalised value was stored in `dim_product.category` and all fact rows
reference products with the corrected category, so no further patching of the
fact table is needed.

---

### Decision 3 — NULL Store City Imputation
**Problem:** Fourteen rows in the source data have a blank (NULL) `store_city`
value while `store_name` is populated. Because `dim_store` requires a
non-null `store_city`, these rows cannot be loaded directly. Discarding them
would silently lose revenue data; asking the business for corrections would
delay the load.

**Resolution:** A deterministic imputation rule was applied: since each
`store_name` in the dataset maps to exactly one city (e.g. `Mumbai Central`
always appears in Mumbai, `Delhi South` in Delhi), the city was inferred from
the store name using a static lookup table. This mapping was verified against
all rows where `store_city` was present and found to be 100 % consistent.
Imputed cities were flagged with a boolean `city_imputed = TRUE` in the staging
table for audit purposes, while `dim_store` was populated with the resolved
city values.
