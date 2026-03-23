[architecture_choice.md](https://github.com/user-attachments/files/26185078/architecture_choice.md)
# Architecture Choice — Part 5

## Architecture Recommendation

**Recommended Architecture: Data Lakehouse**

For a fast-growing food delivery startup ingesting GPS location logs, customer text reviews, payment transactions, and restaurant menu images, a **Data Lakehouse** is the most appropriate architecture. Here are three specific reasons:

### 1. Heterogeneous Data Formats in One Unified Store
The startup generates at least four fundamentally different data types: structured (payment transactions), semi-structured (GPS logs, JSON event streams), unstructured text (customer reviews), and binary blobs (restaurant menu images). A traditional Data Warehouse handles only structured, schema-on-write data — images and raw GPS streams cannot live there without costly ETL transformation. A pure Data Lake can store all of it cheaply but lacks query reliability and ACID guarantees. A Data Lakehouse — built on open table formats such as Delta Lake or Apache Iceberg on top of object storage — stores every format natively while still exposing SQL-queryable, transactionally consistent tables for analytics, giving the best of both worlds.

### 2. Real-Time and Batch Workloads on the Same Platform
Food delivery is time-critical: GPS tracking, surge pricing, and fraud detection on payments require low-latency, streaming ingestion and near-real-time queries. Meanwhile, trend analysis on reviews and menu performance demands batch processing. A Data Warehouse is optimised exclusively for batch analytical workloads. A Data Lake, without a serving layer, cannot efficiently serve low-latency queries. The Lakehouse pattern — pairing open table formats with engines like Apache Spark Structured Streaming and Trino/Presto — supports both streaming writes and interactive queries on the same dataset, eliminating the need to maintain separate Lambda-architecture pipelines.

### 3. Cost-Efficient Scalability with Governance
GPS logs and images grow exponentially as the platform expands to new cities. Object storage (S3/GCS) costs a fraction of columnar warehouse storage per GB. A Lakehouse inherits this cost advantage while adding schema evolution, time-travel, column-level access controls, and data lineage — governance features that a raw Data Lake lacks. This matters for PCI-DSS compliance around payment data and for GDPR-style deletion requirements on customer reviews, both of which require fine-grained table-level operations that only ACID-compliant Lakehouse table formats provide.

In summary, the Data Lakehouse is the only architecture that can ingest diverse data at startup speed, query it in real time, govern it at enterprise standards, and scale cost-effectively — making it the clear choice for this use case.
