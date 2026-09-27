# Project Notes

## 1. Project Overview

### Project
From First Purchase to Loyal Customer

### Objective

This project analyzes customer behavior in an e-commerce
marketplace to understand what distinguishes one-time
customers from repeat customers.

The project is designed to demonstrate:

- SQL
- relational data modeling
- dbt
- DuckDB
- customer/product analytics
- statistical analysis
- machine learning

---

## 2. Dataset Selection

### Dataset

Brazilian E-Commerce Public Dataset by Olist

### Why this dataset?

The dataset was selected because it contains multiple
related tables rather than a single flat dataset.

The main entities include:

- customers
- orders
- order items
- products
- sellers
- payments
- reviews
- geolocation

This allows the project to demonstrate relational data
modeling and SQL joins.

---

## 3. Initial Research Questions

The initial questions are:

1. What distinguishes one-time customers from repeat customers?
2. How quickly do customers return after their first purchase?
3. Which product categories are associated with repeat purchasing?
4. Does delivery performance affect customer satisfaction?
5. How does seller performance relate to customer reviews?
6. Can customer behavior and purchase experience be used
   to predict repeat purchasing?

These questions may be refined after exploring the data.

---

## 4. Initial Data Modeling Observations

The dataset contains both:

- `customer_id`
- `customer_unique_id`

These identifiers will be investigated before defining
the customer-level analytical model.

Because the project focuses on repeat purchasing, the
definition of a "customer" must be carefully established.

---

## 5. Decisions Log

This section will be updated throughout the project.

### Decision 1
**Date:** 2026-09-27

**Decision:**
Use a relational data model rather than analyzing a
single denormalized dataset.

**Reason:**
The dataset contains multiple entities and relationships.
Keeping these relationships allows the project to
demonstrate SQL joins, aggregation, data modeling and
data-quality checks.

---

## 6. Raw Data Ingestion

The raw CSV files are loaded into DuckDB using a Python
ingestion script rather than manually importing each file.

This makes the database creation reproducible and allows
the same process to be repeated if the raw data changes.

The raw tables are intentionally kept close to their
original structure. Transformations will be handled later
through dbt.

---

## 7. Analysis Diary

### 2026-09-27

- Selected the Olist Brazilian e-commerce dataset.
- Created the initial VS Code project structure.
- Added the raw CSV files to `data/raw/`.
- Created this project documentation file.
- Next step: set up DuckDB and inspect the raw tables.