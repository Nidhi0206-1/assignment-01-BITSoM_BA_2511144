
[normalization.md](https://github.com/user-attachments/files/26184258/normalization.md)
# Normalization Report — `orders_flat.csv`

---

## Anomaly Analysis

### Insert Anomaly

**Definition:** An insert anomaly occurs when certain data cannot be inserted into the database without the existence of other, unrelated data.

**Example from the dataset:**

In `orders_flat.csv`, it is impossible to record a new **sales representative** (e.g., a newly hired rep SR04) in the system without them first having at least one order. All sales rep attributes (`sales_rep_id`, `sales_rep_name`, `sales_rep_email`, `office_address`) are stored as columns within the Orders table. Since every row requires an `order_id`, a new sales rep who has not yet handled any order simply cannot be stored.

Similarly, a new **product** that has not yet been ordered cannot be recorded. Product details (`product_id`, `product_name`, `category`, `unit_price`) exist only as attributes of order rows — there is no way to add product P009 to the catalogue without a corresponding order.

**Specific citation:** There is no row in the CSV for a sales rep or product that does not appear in at least one order. The schema itself prevents this — confirming the anomaly structurally.

---

### Update Anomaly

**Definition:** An update anomaly occurs when the same piece of information is stored in multiple rows, so updating it in one place without updating all others leads to inconsistent data.

**Example from the dataset:**

Sales rep **SR01 (Deepak Joshi)** has their `office_address` stored in every single order row they are associated with (80+ rows). Due to this redundancy, the address is recorded inconsistently across rows:

- **Correct value (majority of rows):** `Mumbai HQ, Nariman Point, Mumbai - 400021`
  - Seen in rows with `order_id`: ORD1114, ORD1153, ORD1083, ORD1091, ORD1022, etc.
- **Inconsistent/truncated value (15 rows):** `Mumbai HQ, Nariman Pt, Mumbai - 400021`
  - Seen in rows with `order_id`: **ORD1180** (CSV row 37), **ORD1173** (row 56), **ORD1170** (row 89), **ORD1183** (row 92), **ORD1181** (row 96), **ORD1184** (row 98), **ORD1172** (row 110), **ORD1182** (row 122), and others.

This is a direct consequence of the update anomaly: when SR01's address was entered or edited, not all rows were updated consistently, resulting in `"Nariman Point"` being abbreviated as `"Nariman Pt"` in 15 out of ~80 rows.

**Specific columns:** `sales_rep_id = 'SR01'`, `office_address` column, across the rows listed above.

---

### Delete Anomaly

**Definition:** A delete anomaly occurs when deleting a row to remove one piece of information unintentionally destroys other, unrelated information.

**Example from the dataset:**

Customer **C007 (Arjun Nair, arjun@gmail.com, Bangalore)** appears in very few orders. If all orders placed by Arjun Nair were deleted from the table (e.g., orders were cancelled or the records were purged for business reasons), every piece of information about Arjun Nair as a customer — their ID, name, email, and city — would be permanently lost from the database. There is no separate customer record to preserve it.

**Specific citation:**
- `customer_id = 'C007'`, `customer_name = 'Arjun Nair'`, `customer_email = 'arjun@gmail.com'`
- Appears in rows including `order_id = ORD1098` (CSV row 15) and a small number of other rows.
- Deleting these order rows would erase all knowledge of this customer from the system.

The same logic applies to any product — deleting all orders containing `P008 (Webcam)` would erase all product metadata for that item.

---

## Normalization Justification

### "Normalization is Over-Engineering" — A Refutation

The argument that keeping everything in one flat table is "simpler" is appealing on the surface but falls apart quickly when examined against the actual data in `orders_flat.csv`.

Consider what happened in this very dataset due to the flat structure: Sales rep Deepak Joshi's office address is stored in over 80 rows. Because it had to be entered or updated across dozens of records, it ended up inconsistent — 15 rows say `"Nariman Pt"` while the rest say `"Nariman Point"`. In a normalized schema, the address would live in exactly one row of a `SalesReps` table. One update, one place, zero inconsistency. The "simplicity" of the flat table directly caused a data quality problem that would silently corrupt any reports or address lookups.

The insert anomaly makes the flat table even less useful operationally. Suppose the company hires a new sales rep or adds a product to their catalogue before any orders arrive. In the flat table, there is nowhere to record this — you cannot insert a rep or product without fabricating an order. This forces workarounds like dummy placeholder orders, which pollute the data further. A proper `Products` and `SalesReps` table eliminates this entirely.

The delete anomaly is perhaps the most dangerous in practice. If a customer like Arjun Nair (C007) cancels all their orders and those records are purged, the business loses all record that this customer ever existed — their name, email, and city are gone. In a normalized schema, the `Customers` table is unaffected by order deletions.

The flat table does appear simpler for a single `SELECT *` query. But that convenience is illusory — it trades short-term ease of reading for long-term corruption, loss of data integrity, and operational inflexibility. Normalization to 3NF is not over-engineering; it is the minimum responsible structure for production data.

---
