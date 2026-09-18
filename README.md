# Olist E-Commerce Analytics

## Project Overview
This project analyzes the Olist dataset, a Brazilian e-commerce marketplace dataset containing roughly 99K orders. Through advanced SQL analysis and a comprehensive Power BI dashboard, the core question this analysis answers is: *Is this business's growth healthy, and where are the operational weak points?*

## Tools Used
- **SQL (PostgreSQL syntax):** Data exploration, aggregation, time series analysis, and advanced querying (CTEs, Window Functions).
- **Power BI:** Interactive executive dashboards for visual storytelling and metric monitoring.

## Dashboard
Below are the key pages from the Power BI dashboard, highlighting different aspects of the business:

### Executive Overview
![Executive Overview](assets/executive_overview.png)
*A high-level view of revenue trends, total orders, and average order value, showcasing the explosive growth from 2016 to 2018.*

### Logistics
![Logistics](assets/logistics.png)
*Analyzes delivery lead times, on-time delivery rates, and carrier performance across different states to identify supply chain bottlenecks.*

### Category & Sentiment
![Category & Sentiment](assets/category_and_sentiment.png)
*Explores product performance, revenue vs. review scores, and customer sentiment distribution across major categories.*

### Seller Ecosystem
![Seller Ecosystem](assets/seller_ecosystem.png)
*Highlights seller performance, revenue distribution among top sellers, and geographical clusters of active sellers.*

## Key Findings

1. **Acquisition-Driven Growth (Not Retention-Driven):** Revenue grew ~150x from near-zero (Sep 2016) to 1M+/month by late 2017, but only 3.12% of customers are repeat buyers. This indicates that growth is heavily reliant on new customer acquisition rather than retention.
2. **High Seller Concentration Risk:** The top 20% of sellers generate 81.5% of total revenue (13.05M of 16.01M). Losing a few key sellers could severely impact marketplace revenue.
3. **Geographic Concentration Risk:** São Paulo alone accounts for 6.0M of 16.01M total revenue, which is more than the next four states combined.
4. **Logistics Weak Point in RJ:** Rio de Janeiro (RJ) has the weakest logistics performance at 88.98% on-time route delivery vs 94%+ in other major states, despite being the second-largest revenue state by volume.
5. **Conservative Delivery Estimates:** Average delivery time is 12.09 days but the estimated delivery window is roughly double that. This means delivery estimates are highly conservative and deliveries consistently beat expectations (89.14% on-time rate).
6. **Skewed Review Scores:** Review scores are heavily skewed toward 5-star (~60K of ~99K reviews), making the simple average rating a weak standalone signal without checking the distribution shape.

## SQL Highlights
The analysis utilizes advanced SQL techniques to answer complex business questions:
- **Top Customer per State (Window Functions):** Uses `ROW_NUMBER() OVER(PARTITION BY...)` to rank customers by total spend within each state.
- **Products with 100% Late Delivery Rate (CTEs & Aggregations):** Utilizes Common Table Expressions to calculate delivery stats and filter for products that consistently fail delivery estimates.
- **Seller Performance Ranking (Aggregations & HAVING):** Combines revenue, total orders, and average review scores to rank sellers, demonstrating multi-metric aggregation.
- **Full Category-to-Seller-to-State Chain (Multiple CTEs & JOINs):** Chains multiple CTEs to merge product, review, seller, and geographical data, identifying top performers across categories.

## Repo Structure
```text
.
├── assets/
│   ├── category_and_sentiment.png
│   ├── executive_overview.png
│   ├── logistics.png
│   ├── seller_ecosystem.png
│   └── query_results/      # CSV outputs of the 24 SQL queries
├── dashboards/
│   └── powerbi_executive.pbix
├── data/                   # Raw CSV datasets
├── sql/
│   ├── olist.sql           # Core analysis queries
│   └── olist_Helper.sql
└── README.md
```

## Author
* [Your Name]
* [LinkedIn](https://linkedin.com/in/yourprofile)
* [GitHub](https://github.com/yourusername)
