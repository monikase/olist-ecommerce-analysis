# Analysis Findings

## Business Question

> What distinguishes one-time customers from customers who return?

---

## 1. Customer Type Distribution

### SQL

See:

`sql/03_customer_behavior_analysis.sql`

### Result

| Customer type | Customers | Customer share |
|---|---:|---:|
| One-time | 92,507 | 96.95% |
| Returning | 2,913 | 3.05% |

### Insight

The customer base is highly concentrated among one-time purchasers.
Only 3.05% of customers made more than one purchase in the analyzed
purchase dataset.

This makes repeat purchasing an important area for further analysis.

---

## 2. Customer Behavior by Segment

### Result

| Metric | One-time | Returning |
|---|---:|---:|
| Average orders | 1.00 | 2.11 |
| Average customer value | €161.49 | €310.49 |
| Average order value | €161.49 | €146.85 |
| Average items purchased | 1.14 | 2.57 |
| Average review score | 4.10 | 4.15 |

### Insight

Returning customers have higher average accumulated customer value than
one-time customers.

However, their average individual order value is lower. The higher
customer value therefore comes primarily from making multiple purchases,
rather than from placing larger individual orders.

Returning customers also purchase more items overall.

Average review scores are similar between the two groups.

---

## 3. Revenue Contribution

### Result

| Customer type | Revenue | Revenue share |
|---|---:|---:|
| One-time | €14,939,106.99 | 94.29% |
| Returning | €904,446.25 | 5.71% |

### Insight

Returning customers have higher average customer value, but one-time
customers account for the majority of observed revenue because they
represent 96.95% of the customer base.

This distinction is important when interpreting customer value and
revenue contribution.

---

## 4. Time to Second Purchase

### Result

| Metric | Result |
|---|---:|
| Returning customers | 2,913 |
| Minimum days to second purchase | 0 |
| Average days | 80.79 |
| Median days | 28 |
| Maximum days | 609 |

### Return Timing Distribution

| Return period | Customers | Customer share |
|---|---:|---:|
| 0–30 days | 1,478 | 50.74% |
| 31–60 days | 313 | 10.74% |
| 61–90 days | 201 | 6.90% |
| 91–180 days | 424 | 14.56% |
| 181+ days | 497 | 17.06% |

### Insight

The median time to a second purchase was 28 days, while the average
was 80.79 days. The difference indicates a long tail of customers
whose second purchase occurred substantially later.

Half of returning customers made their second purchase within 30 days.
However, repeat purchasing also occurred over much longer periods, with
17.06% of returning customers taking more than 180 days to make their
second purchase.

This suggests that repeat purchasing occurs across different time
horizons rather than following a single typical return pattern.

## 5. First-Order Behavior: One-Time vs Returning Customers

### Result

| Metric | One-time | Returning |
|---|---:|---:|
| Customers | 92,507 | 2,913 |
| Average first-order value | €161.49 | €146.32 |
| Average first-order items | 1.14 | 1.22 |
| Average first-order freight | €22.82 | €22.73 |
| Average first-order review | 4.10 | 4.14 |

### Insight

The first orders of one-time and returning customers were relatively
similar across the measured metrics.

Returning customers had a lower average first-order value (€146.32)
than one-time customers (€161.49), while the average number of items,
freight value, and review score differed only slightly.

This suggests that simple first-order characteristics alone do not show
a large separation between customers who later returned and those who
did not.

Further analysis is therefore needed to examine whether factors such as
delivery performance or product category are associated with repeat
purchasing.