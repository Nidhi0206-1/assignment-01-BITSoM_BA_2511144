# RDBMS vs NoSQL — Comparative Analysis

## Overview

| Dimension | RDBMS (e.g., MySQL) | NoSQL (e.g., MongoDB) |
|---|---|---|
| Data model | Structured, tabular, fixed schema | Flexible, document/key-value/graph |
| Consistency model | ACID | BASE (eventually consistent) |
| CAP alignment | CA (Consistency + Availability) | CP or AP depending on config |
| Scaling strategy | Vertical (scale-up) | Horizontal (scale-out) |
| Joins | Native, performant | Application-side or `$lookup` |
| Schema changes | ALTER TABLE (costly) | Schema-less, easy iteration |
| Best for | Transactional, relational data | Hierarchical, high-volume, varied data |

---

## Database Recommendation

**Scenario: Healthcare patient management system, with a potential fraud detection module.**

For the core **patient management system**, I would recommend **MySQL** (or another ACID-compliant RDBMS such as PostgreSQL).

Healthcare data — patient demographics, diagnoses, prescriptions, billing records, and clinical histories — is inherently relational. A patient links to multiple appointments, each appointment links to a physician and a set of diagnoses, and billing ties back to insurance records. These relationships are well-served by foreign keys, normalized tables, and JOIN queries.

More critically, healthcare systems demand **ACID guarantees**. When a prescription is written or a lab result is recorded, the database must ensure Atomicity (the full transaction completes or nothing does), Consistency (data always satisfies integrity constraints), Isolation (concurrent transactions do not corrupt each other), and Durability (a committed record survives crashes). A BASE system, which sacrifices strict consistency for availability and partition tolerance, is unacceptable here — reading stale medication dosage data could endanger a patient. Under the **CAP theorem**, the system should prioritize **Consistency + Availability (CA)**, accepting that in a rare network partition, writes may be temporarily blocked rather than serving potentially incorrect data.

Regulatory compliance frameworks such as **HIPAA** also align better with RDBMS: auditable schemas, row-level security, and mature access-control tooling are battle-tested in relational databases.

**Would the answer change for a fraud detection module?**  
Yes, partially. Fraud detection requires analyzing large volumes of behavioural events — login attempts, billing claim patterns, anomaly signals — in near real-time. This workload is a poor fit for a transactional RDBMS. Here, a **NoSQL or hybrid approach** becomes appropriate: a document store like MongoDB (or a graph database like Neo4j for relationship-based fraud patterns) can ingest high-throughput event streams and tolerate a more flexible schema as fraud signals evolve. The fraud module can operate under an **AP** (Availability + Partition Tolerance) model because a slight delay in flagging a suspicious claim is far less harmful than blocking legitimate healthcare transactions. The recommended architecture would therefore be **MySQL for the core patient management system** and a **separate NoSQL store for the fraud detection pipeline**, integrated via an event-streaming layer such as Kafka.

---

## References

- Brewer, E. (2000). *Towards Robust Distributed Systems* (CAP Theorem origin).
- MongoDB Documentation — ACID Transactions.
- MySQL 8.0 Reference Manual — InnoDB and ACID Model.
