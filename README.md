# Retail Analytics Dashboard

An end-to-end retail analytics portfolio project built using PostgreSQL, SQL, and Power BI.

The project analyses sales performance, customer behaviour, product performance, and regional trends using the Online Retail II dataset covering 2009–2011.

The goal was to transform raw transactional data into business-ready insights and an interactive Power BI dashboard that supports executive, customer, product, and regional analysis.

## Business Objectives

This project was designed to answer key retail business questions, including:

- How is revenue performing over time?
- Which customer segments generate the most value?
- Which products generate the highest revenue and sales volume?
- Which countries contribute the most revenue and customers?
- How dependent is the business on the domestic UK market?
- What customer and product patterns could support better commercial decision-making?

## Tools & Technologies

- PostgreSQL
- SQL
- DBeaver
- Power BI Desktop
- Power Query
- DAX
- GitHub


## Project Workflow

1. Imported the Online Retail II transactional dataset into PostgreSQL.
2. Cleaned and validated the raw data using SQL.
3. Created reusable SQL views for completed sales and identified customer transactions.
4. Performed customer, product, revenue, and regional analysis.
5. Built dashboard-ready SQL views for Power BI.
6. Imported the prepared datasets into Power BI.
7. Designed a four-page interactive dashboard:
   - Executive Overview
   - Customer Analytics
   - Product Performance
   - Regional Performance
8. Added KPI cards, filters, tables, and business-focused visualisations.
9. Tested interactions and formatted the report for portfolio presentation.

## SQL Data Preparation

The raw transactional data was cleaned and transformed in PostgreSQL before being used in Power BI.

Key preparation steps included:

- Excluding cancelled invoices
- Removing rows with non-positive quantity or price values
- Creating a calculated revenue field
- Separating identified-customer transactions from anonymous sales
- Creating reusable analytical views
- Building dashboard-ready datasets for executive, customer, product, and regional analysis

CREATE OR REPLACE VIEW public.completed_sales AS
SELECT
    invoice,
    stockcode,
    description,
    quantity,
    invoicedate,
    price,
    customer_id,
    country,
    quantity * price AS line_revenue
FROM public.online_retail_ii
WHERE invoice NOT LIKE 'C%'
  AND quantity > 0
  AND price > 0;

## Dashboard Pages

### 1. Executive Overview
Provides a high-level view of overall retail performance, including:
- Total Revenue
- Total Orders
- Total Customers
- Products Sold
- Average Order Value
- Items Sold
- Monthly revenue trends
- Country performance
- Customer segment performance
- Domestic vs international revenue share

### 2. Customer Analytics
Focuses on customer value and segmentation, including:
- Total Customers
- Platinum Customers
- Average Lifetime Revenue
- Average Orders per Customer
- Revenue by Customer Segment
- Orders by Customer Segment
- Revenue Share by Customer Segment
- Customer Segment Summary

### 3. Product Performance
Analyses product-level sales performance, including:
- Total Products
- Units Sold
- Product Revenue
- Average Selling Price
- Top 10 Products by Revenue
- Top 10 Products by Units Sold
- Product Performance Summary
- Product Type filtering

### 4. Regional Performance
Explores geographic performance, including:
- Total Countries
- Total Revenue
- Total Orders
- Total Customers
- Top 10 Countries by Revenue
- Top 10 Countries by Customers
- Country Performance Summary
- Domestic vs international market share

## Key Business Insights

- The business generated approximately £20.97M in revenue from completed sales.
- The United Kingdom was the dominant market, contributing around 85% of total revenue.
- International markets contributed roughly 15% of revenue.
- Customer value was highly concentrated in the Platinum segment, which generated the majority of identified-customer revenue.
- Product performance varied significantly, with a small number of products contributing disproportionately to total revenue and units sold.
- Regional analysis showed that both revenue and customer activity were strongly concentrated in the UK, highlighting geographic dependence on the domestic market.

## Dashboard Screenshots

### Executive Overview

![Executive Overview](Dashboard%20Screenshots/executive_overview.png)


### Customer Analytics

![Customer Analytics](Dashboard%20Screenshots/customer_analytics.png)

### Product Performance

![Product Performance](Dashboard%20Screenshots/product_performance.png)

### Regional Performance

![Regional Performance](Dashboard%20Screenshots/regional_performance.png)

## Repository Structure

```text
retail-analytics-dashboard/
├── README.md
├── SQL/
│   └── retail_analytics.sql
├── Power BI/
│   └── Retail Analytics Dashboard.pbix
└── Dashboard Screenshots/
    ├── executive_overview.png
    ├── customer_analytics.png
    ├── product_performance.png
    └── regional_performance.png

## Conclusion

This project demonstrates an end-to-end retail analytics workflow, from raw transactional data preparation in PostgreSQL to interactive business reporting in Power BI.

The analysis combines SQL-based data cleaning, customer segmentation, product analysis, and regional performance reporting to produce insights that could support commercial decision-making.

The project also demonstrates practical skills in:

- SQL data cleaning and transformation
- Analytical view creation
- Customer and product performance analysis
- Power BI dashboard design
- KPI development
- Business-focused data storytelling
