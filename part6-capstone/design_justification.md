# Part 6 — Design Justification

## Storage Systems

The architecture assigns a purpose-built storage system to each of the four goals, avoiding the trap of a one-size-fits-all database.

**Goal 1 — Readmission Prediction (ML):** Historical treatment and admission records are sourced from an OLTP **PostgreSQL** database (structured, relational patient data) and then moved into **Snowflake** (OLAP data warehouse) via an Airflow ETL pipeline. Snowflake is ideal here because ML feature engineering requires large-scale historical aggregations — joining years of treatment episodes, lab results, and readmission events across millions of rows — which columnar storage handles far more efficiently than row-oriented databases. Raw data is also archived in **S3 (Data Lake)** so data science teams can version training datasets and retrain models without impacting production.

**Goal 2 — Natural Language Patient Queries (NLP):** Patient history records are indexed in **Elasticsearch**, which provides full-text inverted indexes optimised for semantic and keyword search. When a doctor asks "Has this patient had a cardiac event before?", a LangChain-based RAG (Retrieval-Augmented Generation) pipeline queries Elasticsearch to retrieve relevant clinical fragments and passes them to an LLM. A **Redis** cache layer reduces latency for repeated queries on the same patient. PostgreSQL remains the authoritative source of record; Elasticsearch is a read-optimised projection of it.

**Goal 3 — Monthly Management Reports:** **Snowflake** is the central OLAP store for this goal as well. Bed occupancy, department-wise cost, and throughput metrics are modelled using **dbt** (data build tool), which transforms raw warehouse data into clean, aggregated reporting tables. **Metabase** (or an equivalent BI tool) connects to Snowflake to render the final dashboards and PDFs for hospital management. Using a dedicated warehouse prevents analytical workloads from degrading transactional performance.

**Goal 4 — Real-Time ICU Vitals Streaming:** ICU monitor data is ingested via **Apache Kafka** (publish-subscribe streaming) and persisted in **InfluxDB**, a time-series database explicitly designed for high-frequency, timestamped sensor data. InfluxDB's native downsampling and retention policies make it straightforward to store fine-grained readings (e.g., every second) while automatically rolling them up to minute-level averages. An Apache Flink or AWS Lambda alerting service consumes the Kafka topic in real time to trigger threshold-breach notifications without waiting for data to reach the warehouse.

---

## OLTP vs OLAP Boundary

The OLTP boundary ends at **PostgreSQL**. All transactional operations — patient registration, appointment creation, order entry, medication dispensing — write directly to PostgreSQL, which enforces ACID guarantees and handles concurrent reads by clinical staff. This keeps the system of record consistent and safe for real-time clinical use.

The OLAP boundary begins when data crosses into **Snowflake**. This transition is mediated by Airflow batch ETL jobs (for structured data) and Debezium CDC connectors (for near-real-time change streams). Once in Snowflake, data is immutable from an operational perspective — it is never written back to PostgreSQL from the warehouse. This clean separation means that a heavy management report query scanning two years of billing data will never lock rows that a nurse needs to update a patient record.

The **InfluxDB** time-series store sits in its own lane: it receives ICU streaming data from Kafka and never feeds back into the OLTP layer. Aggregated vitals summaries can be pushed to Snowflake on a scheduled basis for longer-term analytics, but the hot path (alerting and live dashboards) bypasses the warehouse entirely for speed.

---

## Trade-offs

**Trade-off: Data Duplication and Synchronisation Lag**

The most significant trade-off in this architecture is that the same patient data lives in multiple stores simultaneously — PostgreSQL, Elasticsearch, Snowflake, and the S3 data lake. This redundancy improves query performance and decouples concerns, but it introduces **synchronisation lag** and **consistency risk**. A record updated in PostgreSQL (e.g., a corrected diagnosis code) may take minutes to propagate to Elasticsearch via CDC and hours to appear in Snowflake via the next ETL batch run. During that window, a doctor's NLP query could return stale results, and management reports could reflect outdated figures.

**Mitigation strategies:**
1. **Debezium CDC with sub-minute latency** is used for the Elasticsearch sync path, because NLP patient queries are clinically sensitive and need to be as fresh as possible.
2. **Versioned records with `updated_at` timestamps** are propagated through all pipelines, so downstream consumers can display the data's freshness to the user (e.g., "Patient record as of 14:32 today").
3. **Snowflake ETL jobs are scheduled every 4 hours** for operational metrics and nightly for full historical reconciliation, which is acceptable given that monthly reports are not time-critical at the minute level.
4. In a future iteration, the Airflow batch pipeline for Goal 1 could be replaced with a **streaming Flink job** writing directly to Snowflake, reducing the OLAP lag from hours to minutes at the cost of increased infrastructure complexity.
