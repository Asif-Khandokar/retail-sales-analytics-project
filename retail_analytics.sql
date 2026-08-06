/*
======================================================================
                            RETAIL ANALYTICS
                     Business Intelligence Case Study
======================================================================

Author      : Asif Khandokar
Database    : PostgreSQL
Tool        : DBeaver
Dataset     : Online Retail II
Version     : 4.0

----------------------------------------------------------------------
PROJECT OVERVIEW
----------------------------------------------------------------------

This project analyzes transactional data from an online retail
business to evaluate:

• Data quality
• Sales performance
• Customer behavior
• Customer value
• Product performance
• Regional performance
• RFM customer segmentation
• Executive business KPIs

The analysis produces reusable SQL datasets that can be connected
directly to Power BI for dashboard development.

----------------------------------------------------------------------
METHODOLOGY
----------------------------------------------------------------------

Two cleaned views are used because company-level analysis and
customer-level analysis require different populations.

1. completed_sales
   Includes every valid completed transaction, even when customer_id
   is missing.

2. identified_customer_sales
   Includes only valid completed transactions linked to a known
   customer.

This distinction prevents customer-level filtering from incorrectly
reducing company revenue, product sales, and regional totals.

----------------------------------------------------------------------
SQL SKILLS DEMONSTRATED
----------------------------------------------------------------------

• Data Quality Assessment
• Reusable SQL Views
• Exploratory Data Analysis
• Aggregate Functions
• Filtered Aggregation
• CASE Expressions
• HAVING
• Common Table Expressions
• Percentile Analysis
• Window Functions
• RFM Segmentation
• KPI Reporting
• Dashboard Dataset Creation

======================================================================
*/


/*======================================================================
SECTION 0: REUSABLE CLEANED SALES VIEWS
======================================================================*/

/*
Business Objective:
Create consistent and reusable analytical datasets for company-level
and customer-level reporting.
*/


-- 0.1 Create all valid completed-sales transactions

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


-- 0.2 Create completed sales linked to identified customers

CREATE OR REPLACE VIEW public.identified_customer_sales AS
SELECT
    invoice,
    stockcode,
    description,
    quantity,
    invoicedate,
    price,
    customer_id,
    country,
    line_revenue
FROM public.completed_sales
WHERE customer_id IS NOT NULL;


/*======================================================================
VIEW VALIDATION
======================================================================*/


-- 0.3 Verify completed-sales row count

SELECT
    COUNT(*) AS completed_sales_rows
FROM public.completed_sales;


-- 0.4 Verify identified-customer sales row count

SELECT
    COUNT(*) AS identified_customer_sales_rows
FROM public.identified_customer_sales;


-- 0.5 Verify both views exist

SELECT
    table_schema,
    table_name
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name IN (
      'completed_sales',
      'identified_customer_sales'
  )
ORDER BY table_name;


/*
Methodology Note:
Use public.completed_sales for:

• Overall revenue
• Monthly sales
• Product analysis
• Regional analysis
• Executive KPIs

Use public.identified_customer_sales for:

• Customer rankings
• One-time versus repeat customers
• Revenue segmentation
• RFM analysis
• Customer dashboards
*/

/*======================================================================
SECTION 1: DATA QUALITY ASSESSMENT
======================================================================*/

/*
Business Objective:
Assess the structure, completeness, and reliability of the raw
transaction data before using it for business analysis and
dashboard reporting.
*/

/*
Business Questions:
1. How many rows and columns are in the dataset?
2. How many customer IDs are missing?
3. How many cancelled transactions are present?
4. How many records contain negative quantities or prices?
5. What period does the dataset cover?
6. How much data remains after applying the completed-sales rules?
*/


-- 1.1 Count total records

SELECT
    COUNT(*) AS total_records
FROM public.online_retail_ii;


-- 1.2 Count total columns

SELECT
    COUNT(*) AS total_columns
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'online_retail_ii';


-- 1.3 Summarize major data-quality issues

SELECT
    COUNT(*) AS total_records,

    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS missing_customer_ids,

    ROUND(
        100.0
        * COUNT(*) FILTER (WHERE customer_id IS NULL)
        / NULLIF(COUNT(*), 0),
        2
    ) AS pct_missing_customer_ids,

    COUNT(*) FILTER (
        WHERE invoice LIKE 'C%'
    ) AS cancelled_transactions,

    ROUND(
        100.0
        * COUNT(*) FILTER (WHERE invoice LIKE 'C%')
        / NULLIF(COUNT(*), 0),
        2
    ) AS pct_cancelled_transactions,

    COUNT(*) FILTER (
        WHERE quantity < 0
    ) AS negative_quantity_records,

    ROUND(
        100.0
        * COUNT(*) FILTER (WHERE quantity < 0)
        / NULLIF(COUNT(*), 0),
        2
    ) AS pct_negative_quantity_records,

    COUNT(*) FILTER (
        WHERE price < 0
    ) AS negative_price_records,

    ROUND(
        100.0
        * COUNT(*) FILTER (WHERE price < 0)
        / NULLIF(COUNT(*), 0),
        4
    ) AS pct_negative_price_records

FROM public.online_retail_ii;

-- 1.4 Check for duplicate transaction rows

SELECT
    COUNT(*) AS total_rows,

    COUNT(DISTINCT (
        invoice,
        stockcode,
        description,
        quantity,
        invoicedate,
        price,
        customer_id,
        country
    )) AS distinct_rows,

    COUNT(*) -
    COUNT(DISTINCT (
        invoice,
        stockcode,
        description,
        quantity,
        invoicedate,
        price,
        customer_id,
        country
    )) AS duplicate_rows

FROM public.online_retail_ii;

-- 1.5 Identify the dataset date range

SELECT
    MIN(invoicedate) AS first_transaction_date,
    MAX(invoicedate) AS last_transaction_date
FROM public.online_retail_ii;


-- 1.6 Compare raw and cleaned row populations

SELECT
    (SELECT COUNT(*)
     FROM public.online_retail_ii) AS raw_transaction_rows,

    (SELECT COUNT(*)
     FROM public.completed_sales) AS completed_sales_rows,

    (SELECT COUNT(*)
     FROM public.identified_customer_sales)
        AS identified_customer_sales_rows;


-- 1.7 Count valid completed sales without a customer ID

SELECT
    COUNT(*) AS completed_sales_without_customer_id
FROM public.completed_sales
WHERE customer_id IS NULL;


/*
Key Findings:
----------------------------------------------------------------------
• The raw dataset contains missing customer identifiers,
  cancelled invoices, negative quantities, and a small number
  of negative-price records.

• public.completed_sales contains valid completed transactions
  after excluding cancellations, non-positive quantities, and
  non-positive prices.

• public.identified_customer_sales contains the subset of completed
  transactions linked to a known customer.

• The difference between the two cleaned views represents valid
  completed sales that cannot be used for customer-level analysis.
*/


/*
Data-Usage Decision:
----------------------------------------------------------------------
Use public.online_retail_ii only for raw-data quality assessment.

Use public.completed_sales for company-level, product, regional,
monthly, and executive analysis.

Use public.identified_customer_sales for customer-level analysis,
revenue segmentation, loyalty analysis, and RFM segmentation.
*/
/*
Data Quality Conclusion
======================================================================

The dataset is suitable for business analysis after applying the
completed_sales cleaning rules.

Cancelled invoices, returns, and invalid sales values have been
excluded from company-level reporting, while customer-level analyses
are performed only on transactions linked to a known customer.

This cleaning methodology establishes a consistent analytical
foundation for all subsequent sales, customer, product, regional,
and RFM analyses.
*/


/*======================================================================
SECTION 2: EXPLORATORY DATA ANALYSIS
======================================================================*/

/*
Business Objective:
Explore the structure and scale of the cleaned retail dataset to
understand customers, products, orders, and geographic coverage
before performing detailed business analysis.
*/

/*
Business Questions:
1. How many unique customers, products, and countries exist?
2. How many completed orders and items were sold?
3. Which countries generate the highest transaction activity?
4. Which customers place the most completed orders?
5. Which products are sold most frequently?
*/


-- 2.1 Dataset Coverage Summary

SELECT
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT stockcode) AS unique_products,
    COUNT(DISTINCT country) AS unique_countries
FROM public.identified_customer_sales;

-- 2.2 Business Scale Summary

SELECT
    COUNT(DISTINCT invoice) AS completed_orders,
    SUM(quantity) AS total_items_sold,
    ROUND(SUM(line_revenue),2) AS total_revenue
FROM public.completed_sales;

-- 2.3 Top 10 Countries by Completed Transaction Rows

SELECT
    country,
    COUNT(*) AS transaction_rows
FROM public.completed_sales
GROUP BY country
ORDER BY transaction_rows DESC
LIMIT 10;

-- 2.4 Top 10 Customers by Completed Orders

SELECT
    customer_id,
    COUNT(DISTINCT invoice) AS completed_orders
FROM public.identified_customer_sales
GROUP BY customer_id
ORDER BY completed_orders DESC
LIMIT 10;

-- 2.5 Top 10 Products by Quantity Sold

SELECT
    stockcode,
    description,
    SUM(quantity) AS total_quantity_sold
FROM public.completed_sales
GROUP BY
    stockcode,
    description
ORDER BY total_quantity_sold DESC
LIMIT 10;

-- 2.6 Top 10 Products by Revenue

SELECT
    stockcode,
    description,
    ROUND(SUM(line_revenue),2) AS total_revenue
FROM public.completed_sales
GROUP BY
    stockcode,
    description
ORDER BY total_revenue DESC
LIMIT 10;

/*
Key Findings
======================================================================

• The cleaned dataset contains 5,878 identified customers,
  4,630 unique products, and transactions across 41 countries,
  demonstrating a large and internationally distributed retail
  operation.

• The business completed 40,077 customer orders, selling more
  than 11.42 million items and generating approximately
  £20.97 million in completed-sales revenue.

• The United Kingdom accounts for the highest transaction
  activity, confirming it as the retailer's primary market.

• Customer purchasing behaviour varies considerably, with the
  most active customer completing 398 separate orders.

• Product demand is highly concentrated. "WORLD WAR 2 GLIDERS
  ASSTD DESIGNS" recorded the highest sales volume, while
  "REGENCY CAKESTAND 3 TIER" generated the highest revenue.

• These exploratory results establish the business context for
  the detailed sales, customer, product, and regional analyses
  presented in the following sections.
*/

/*
Analytical Note:
Operational stock codes such as M (Manual), DOT (Dotcom Postage),
and POST (Postage) represent operational charges rather than
physical retail products.

These values are retained because they contribute to company
revenue, but product-performance analysis should interpret them
separately from merchandise sales.
*/

/*======================================================================
SECTION 3: SALES PERFORMANCE ANALYSIS
======================================================================*/

/*
Business Objective:
Evaluate the company's overall sales performance by measuring
revenue, order activity, and monthly sales trends.

This section identifies seasonality, growth patterns, and
executive KPIs that support strategic business decisions.
*/

/*
Business Questions:
1. What are the company's overall sales KPIs?
2. How has monthly revenue changed over time?
3. What is the month-over-month revenue growth?
4. Which months generated the highest revenue?
5. What cumulative revenue has the business generated over time?
*/

-- 3.1 Executive KPI Summary

SELECT

    ROUND(SUM(line_revenue),2) AS total_revenue,

    COUNT(DISTINCT invoice) AS total_orders,

    COUNT(DISTINCT customer_id) AS unique_customers,

    COUNT(DISTINCT stockcode) AS products_sold,

    SUM(quantity) AS total_items_sold,

    ROUND(
        SUM(line_revenue)
        / COUNT(DISTINCT invoice),
        2
    ) AS average_order_value

FROM public.completed_sales;

-- 3.2 Monthly Revenue Trend

SELECT

    DATE_TRUNC('month', invoicedate) AS sales_month,

    ROUND(
        SUM(line_revenue),
        2
    ) AS monthly_revenue

FROM public.completed_sales

GROUP BY DATE_TRUNC('month', invoicedate)

ORDER BY sales_month;

-- 3.3 Month-over-Month Revenue Performance

WITH monthly_sales AS
(
    SELECT

        DATE_TRUNC('month', invoicedate) AS sales_month,

        ROUND(
            SUM(line_revenue),
            2
        ) AS monthly_revenue

    FROM public.completed_sales

    GROUP BY DATE_TRUNC('month', invoicedate)
),

monthly_comparison AS
(
    SELECT

        sales_month,

        monthly_revenue,

        LAG(monthly_revenue)
        OVER (
            ORDER BY sales_month
        ) AS previous_month_revenue

    FROM monthly_sales
)

SELECT

    sales_month,

    monthly_revenue,

    previous_month_revenue,

    ROUND(
        monthly_revenue - previous_month_revenue,
        2
    ) AS revenue_difference,

    ROUND(

        100.0 *
        (monthly_revenue - previous_month_revenue)

        /

        NULLIF(previous_month_revenue,0),

        2

    ) AS revenue_growth_pct

FROM monthly_comparison

ORDER BY sales_month;

-- 3.4 Cumulative Revenue Trend

WITH monthly_sales AS
(
    SELECT

        DATE_TRUNC('month', invoicedate) AS sales_month,

        ROUND(
            SUM(line_revenue),
            2
        ) AS monthly_revenue

    FROM public.completed_sales

    GROUP BY DATE_TRUNC('month', invoicedate)
)

SELECT

    sales_month,

    monthly_revenue,

    ROUND(

        SUM(monthly_revenue)

        OVER (

            ORDER BY sales_month

        ),

        2

    ) AS cumulative_revenue

FROM monthly_sales

ORDER BY sales_month;

-- 3.5 Rank Months by Revenue

WITH monthly_sales AS
(
    SELECT

        DATE_TRUNC('month', invoicedate) AS sales_month,

        ROUND(
            SUM(line_revenue),
            2
        ) AS monthly_revenue

    FROM public.completed_sales

    GROUP BY DATE_TRUNC('month', invoicedate)
)

SELECT

    DENSE_RANK()

    OVER (

        ORDER BY monthly_revenue DESC

    ) AS revenue_rank,

    sales_month,

    monthly_revenue

FROM monthly_sales

ORDER BY revenue_rank;

-- 3.6 Highest and Lowest Revenue Months

WITH monthly_sales AS
(
    SELECT
        DATE_TRUNC('month', invoicedate) AS sales_month,
        ROUND(SUM(line_revenue),2) AS monthly_revenue
    FROM public.completed_sales
    GROUP BY DATE_TRUNC('month', invoicedate)
)

SELECT
    sales_month,
    monthly_revenue,
    CASE
        WHEN monthly_revenue = MAX(monthly_revenue) OVER ()
            THEN 'Highest Revenue Month'
        WHEN monthly_revenue = MIN(monthly_revenue) OVER ()
            THEN 'Lowest Revenue Month'
    END AS revenue_category
FROM monthly_sales
WHERE monthly_revenue IN
(
    (SELECT MAX(monthly_revenue) FROM monthly_sales),
    (SELECT MIN(monthly_revenue) FROM monthly_sales)
);

/*
Key Findings
======================================================================

• The business generated approximately £20.97 million in completed
  sales revenue across 40,077 completed customer orders.

• Monthly revenue demonstrates clear seasonality, with sales
  increasing substantially during the final quarter of each year.

• November 2011 recorded the highest monthly revenue
  (£1,509,496.33), followed by November 2010
  (£1,470,272.48), indicating strong year-end demand.

• Revenue growth accelerated significantly during September–
  November in both years, suggesting recurring seasonal purchasing
  patterns.

• The cumulative revenue analysis shows consistent business growth
  throughout the reporting period, reaching approximately
  £20.97 million by the end of the dataset.

• These results indicate that demand is strongly influenced by
  seasonal shopping periods, making inventory planning and
  marketing campaigns particularly important during the fourth
  quarter.
*/

/*
Business Recommendations
======================================================================

• Increase inventory levels and warehouse capacity before the
  fourth quarter to support recurring seasonal demand.

• Launch major promotional campaigns during September and October
  to maximize sales leading into the peak November trading period.

• Investigate the causes of lower sales during January and
  February to identify opportunities for demand stimulation.

• Incorporate seasonal sales forecasts into future budgeting and
  inventory planning to improve operational efficiency.
*/


/*======================================================================
SECTION 4: CUSTOMER ANALYTICS
======================================================================*/

/*
Business Objective:
Analyze identified customers to understand purchasing value,
order frequency, spending patterns, and revenue concentration.

This section identifies the customers who contribute the most
revenue and provides a foundation for later segmentation and
RFM analysis.
*/

/*
Business Questions:
1. Which customers generate the highest revenue?
2. Which customers place the most completed orders?
3. What is each customer's average order value?
4. How concentrated is customer revenue?
5. Which customers should the business prioritize?
*/

-- 4.1 Identify Top 10 Customers by Revenue

SELECT
    customer_id,
    ROUND(SUM(line_revenue), 2) AS total_revenue
FROM public.identified_customer_sales
GROUP BY customer_id
ORDER BY total_revenue DESC
LIMIT 10;

-- 4.2 Identify Top 10 Customers by Completed Orders

SELECT
    customer_id,
    COUNT(DISTINCT invoice) AS total_orders
FROM public.identified_customer_sales
GROUP BY customer_id
ORDER BY total_orders DESC
LIMIT 10;

-- 4.3 Create Customer Performance Dataset

SELECT
    customer_id,

    ROUND(
        SUM(line_revenue),
        2
    ) AS total_revenue,

    COUNT(DISTINCT invoice) AS total_orders,

    SUM(quantity) AS total_items_purchased,

    ROUND(
        SUM(line_revenue)
        / NULLIF(COUNT(DISTINCT invoice), 0),
        2
    ) AS average_order_value

FROM public.identified_customer_sales

GROUP BY customer_id

ORDER BY total_revenue DESC;

-- 4.4 Identify Customers with More Than 10 Completed Orders

SELECT
    customer_id,
    COUNT(DISTINCT invoice) AS total_orders
FROM public.identified_customer_sales
GROUP BY customer_id
HAVING COUNT(DISTINCT invoice) > 10
ORDER BY total_orders DESC;


-- 4.5 Analyze One-Time and Repeat Customers

WITH customer_orders AS
(
    SELECT
        customer_id,
        COUNT(DISTINCT invoice) AS total_orders
    FROM public.identified_customer_sales
    GROUP BY customer_id
)

SELECT
    CASE
        WHEN total_orders = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,

    COUNT(*) AS number_of_customers,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS pct_of_customers

FROM customer_orders

GROUP BY customer_type

ORDER BY number_of_customers DESC;

-- 4.6 Customer Revenue Pareto Analysis (80/20 Rule)

WITH customer_revenue AS
(
    SELECT
        customer_id,
        SUM(line_revenue) AS total_revenue
    FROM public.identified_customer_sales
    GROUP BY customer_id
),

ranked_customers AS
(
    SELECT
        customer_id,
        total_revenue,

        ROW_NUMBER() OVER (
            ORDER BY total_revenue DESC
        ) AS customer_rank,

        COUNT(*) OVER () AS total_customers,

        SUM(total_revenue) OVER () AS overall_revenue

    FROM customer_revenue
)

SELECT

    CASE
        WHEN customer_rank <= CEIL(total_customers * 0.20)
            THEN 'Top 20% Customers'
        ELSE 'Remaining 80% Customers'
    END AS customer_group,

    COUNT(*) AS number_of_customers,

    ROUND(
        SUM(total_revenue),
        2
    ) AS group_revenue,

    ROUND(
        100.0 * SUM(total_revenue)
        / MAX(overall_revenue),
        2
    ) AS pct_of_total_revenue

FROM ranked_customers

GROUP BY
    CASE
        WHEN customer_rank <= CEIL(total_customers * 0.20)
            THEN 'Top 20% Customers'
        ELSE 'Remaining 80% Customers'
    END

ORDER BY group_revenue DESC;

/*
Key Findings
======================================================================

• Customer spending is highly concentrated among a relatively small
  group of high-value customers.

• Customer 18102 generated the highest revenue (£608,821.65),
  followed by Customer 14646 (£528,602.52) and Customer 14156
  (£313,946.37).

• Customer 14911 was the most active customer, completing
  398 separate orders during the analysis period.

• Purchasing behaviour differs substantially across customers.
  While some customers place hundreds of relatively small orders,
  others generate very high revenue through fewer, high-value
  purchases.

• Approximately 72.39% of identified customers are repeat
  customers, demonstrating strong customer retention and repeat
  purchasing behaviour.

• Revenue is highly concentrated. The top 1% of customers
  generated approximately 31.94% of total identified-customer
  revenue, while the top 10% contributed nearly 63.93% of total
  customer revenue.

• These results indicate that a relatively small proportion of
  customers drives a significant share of business revenue.
*/

/*
Business Recommendations
======================================================================

• Develop loyalty and retention programmes for the highest-value
  customers to protect a significant source of company revenue.

• Identify characteristics shared by top-performing customers to
  improve customer acquisition strategies.

• Encourage repeat purchasing among one-time customers through
  personalised promotions and post-purchase engagement.

• Monitor customers with exceptionally high average order values,
  as these may represent wholesale or business accounts requiring
  dedicated account management.

• Prioritise marketing investment toward high-value customer
  segments while maintaining strategies to convert occasional
  buyers into repeat customers.
*/

/*======================================================================
SECTION 5: PRODUCT PERFORMANCE ANALYSIS
======================================================================*/

/*
Business Objective:
Evaluate product performance by analyzing revenue generation,
sales volume, pricing, and product concentration to identify
high-performing merchandise and opportunities for inventory
optimization.

This section helps determine which products contribute most to
business success and supports merchandising decisions.
*/

/*
Business Questions:
1. Which products generate the highest revenue?
2. Which products sell the highest quantity?
3. Which products have the highest average selling price?
4. Is product revenue concentrated among a small number of products?
5. Which products should the business prioritize?
*/



-- 5.1 Top 10 Products by Revenue

SELECT
    stockcode,
    description,

    ROUND(
        SUM(line_revenue),
        2
    ) AS total_revenue,

    SUM(quantity) AS total_quantity_sold,

    COUNT(DISTINCT invoice) AS total_orders

FROM public.completed_sales

GROUP BY
    stockcode,
    description

ORDER BY total_revenue DESC

LIMIT 10;

-- 5.2 Top 10 Products by Quantity Sold

SELECT
    stockcode,
    description,

    SUM(quantity) AS total_quantity_sold,

    ROUND(
        SUM(line_revenue),
        2
    ) AS total_revenue

FROM public.completed_sales

GROUP BY
    stockcode,
    description

ORDER BY total_quantity_sold DESC

LIMIT 10;

-- 5.3 Highest Average Selling Price

SELECT

    stockcode,

    description,

    ROUND(
        AVG(price),
        2
    ) AS average_unit_price,

    COUNT(*) AS transaction_rows

FROM public.completed_sales

GROUP BY
    stockcode,
    description

HAVING COUNT(*) >= 20

ORDER BY average_unit_price DESC

LIMIT 10;

-- 5.4 Product Revenue Pareto Analysis

WITH product_revenue AS
(
    SELECT

        stockcode,

        description,

        SUM(line_revenue) AS total_revenue

    FROM public.completed_sales

    GROUP BY
        stockcode,
        description
),

ranked_products AS
(
    SELECT

        stockcode,

        description,

        total_revenue,

        ROW_NUMBER() OVER (
            ORDER BY total_revenue DESC
        ) AS product_rank,

        COUNT(*) OVER () AS total_products,

        SUM(total_revenue) OVER () AS overall_revenue

    FROM product_revenue
)

SELECT

    CASE
        WHEN product_rank <= CEIL(total_products * 0.20)
            THEN 'Top 20% Products'
        ELSE 'Remaining 80% Products'
    END AS product_group,

    COUNT(*) AS number_of_products,

    ROUND(
        SUM(total_revenue),
        2
    ) AS group_revenue,

    ROUND(
        100.0 * SUM(total_revenue)
        / MAX(overall_revenue),
        2
    ) AS pct_of_total_revenue

FROM ranked_products

GROUP BY
    CASE
        WHEN product_rank <= CEIL(total_products * 0.20)
            THEN 'Top 20% Products'
        ELSE 'Remaining 80% Products'
    END

ORDER BY group_revenue DESC;


-- 5.5 Operational Charges vs Merchandise Revenue

SELECT

    CASE

        WHEN stockcode IN ('POST','DOT','M')
            THEN 'Operational Charges'

        ELSE 'Merchandise'

    END AS revenue_type,

    ROUND(
        SUM(line_revenue),
        2
    ) AS total_revenue,

    ROUND(
        100.0 * SUM(line_revenue)
        / SUM(SUM(line_revenue)) OVER (),
        2
    ) AS pct_of_total_revenue

FROM public.completed_sales

GROUP BY revenue_type;

/*
Key Findings
======================================================================

• Product performance follows a classic Pareto distribution.
  Approximately 20% of products generate nearly 80% of total
  company revenue.

• "WORLD WAR 2 GLIDERS ASSTD DESIGNS" recorded the highest sales
  volume, demonstrating strong customer demand despite relatively
  low unit pricing.

• "REGENCY CAKESTAND 3 TIER" generated the highest product revenue,
  indicating strong commercial value through a combination of price
  and sales volume.

• Average selling price varies considerably across products,
  reflecting a diverse product portfolio that includes both
  low-cost, high-volume items and premium-priced merchandise.

• Merchandise sales account for approximately 96.23% of company
  revenue, while operational charges contribute only 3.77%,
  confirming that retail product sales remain the primary revenue
  driver.
*/
/*
Business Recommendations
======================================================================

• Prioritise inventory availability for the highest-revenue
  products to minimise lost sales during periods of high demand.

• Promote high-volume products through cross-selling and
  complementary product recommendations to increase average
  order value.

• Review premium-priced products to ensure pricing remains
  competitive while protecting profit margins.

• Focus merchandising and marketing investment on the top
  20% of revenue-generating products while periodically
  reviewing the performance of lower-selling items.

• Continue monitoring operational charges separately from
  merchandise revenue to maintain accurate product-performance
  reporting.
*/

/*======================================================================
SECTION 6: REGIONAL SALES ANALYSIS
======================================================================*/

/*
Business Objective:
Evaluate the geographical distribution of sales performance by
analyzing revenue, customer activity, order behavior, and market
contribution across countries.

This analysis identifies the company's strongest international
markets and highlights opportunities for regional expansion.
*/

/*
Business Questions:
1. Which countries generate the highest revenue?
2. Which countries have the most customers?
3. Which countries have the highest average order value?
4. How concentrated is revenue across countries?
5. Which international markets deserve greater investment?
*/

-- 6.1 Revenue by Country

SELECT

    country,

    ROUND(
        SUM(line_revenue),
        2
    ) AS total_revenue,

    COUNT(DISTINCT invoice) AS total_orders,

    COUNT(DISTINCT customer_id) AS unique_customers,

    ROUND(
        SUM(line_revenue)
        /
        COUNT(DISTINCT invoice),
        2
    ) AS average_order_value

FROM public.completed_sales

GROUP BY country

ORDER BY total_revenue DESC;

-- 6.2 Countries with the Largest Customer Base

SELECT

    country,

    COUNT(DISTINCT customer_id) AS unique_customers

FROM public.identified_customer_sales

GROUP BY country

ORDER BY unique_customers DESC;

-- 6.3 Rank Countries by Revenue

WITH country_sales AS
(
    SELECT

        country,

        ROUND(
            SUM(line_revenue),
            2
        ) AS total_revenue

    FROM public.completed_sales

    GROUP BY country
)

SELECT

    RANK()

    OVER(

        ORDER BY total_revenue DESC

    ) AS revenue_rank,

    country,

    total_revenue

FROM country_sales

ORDER BY revenue_rank;

-- 6.4 Country Revenue Contribution

WITH country_sales AS
(
    SELECT

        country,

        SUM(line_revenue) AS total_revenue

    FROM public.completed_sales

    GROUP BY country
)

SELECT

    country,

    ROUND(total_revenue,2) AS total_revenue,

    ROUND(

        100.0 *

        total_revenue

        /

        SUM(total_revenue) OVER(),

        2

    ) AS pct_of_total_revenue

FROM country_sales

ORDER BY total_revenue DESC;

-- 6.5 Regional Revenue Pareto Analysis

WITH country_sales AS
(
    SELECT

        country,

        SUM(line_revenue) AS total_revenue

    FROM public.completed_sales

    GROUP BY country
),

ranked_country AS
(
    SELECT

        country,

        total_revenue,

        ROW_NUMBER()

        OVER(

            ORDER BY total_revenue DESC

        ) AS revenue_rank,

        COUNT(*) OVER() AS total_countries,

        SUM(total_revenue) OVER() AS overall_revenue

    FROM country_sales
)

SELECT

    CASE

        WHEN revenue_rank <= CEIL(total_countries*0.20)

            THEN 'Top 20% Countries'

        ELSE 'Remaining 80% Countries'

    END AS country_group,

    COUNT(*) AS number_of_countries,

    ROUND(
        SUM(total_revenue),
        2
    ) AS group_revenue,

    ROUND(

        100.0 *

        SUM(total_revenue)

        /

        MAX(overall_revenue),

        2

    ) AS pct_of_total_revenue

FROM ranked_country

GROUP BY

CASE

    WHEN revenue_rank <= CEIL(total_countries*0.20)

        THEN 'Top 20% Countries'

    ELSE 'Remaining 80% Countries'

END

ORDER BY group_revenue DESC;

/*
Analytical Note:
The regional Pareto result is more concentrated than a traditional
80/20 pattern: the top 20% of countries generate 97.03% of revenue.
This indicates that geographic performance is heavily dependent on
a small group of markets.
*/

-- 6.6 Domestic vs International Revenue

SELECT

    CASE

        WHEN country='United Kingdom'

            THEN 'Domestic Market'

        ELSE 'International Markets'

    END AS market,

    ROUND(
        SUM(line_revenue),
        2
    ) AS total_revenue,

    ROUND(

        100.0 *

        SUM(line_revenue)

        /

        SUM(SUM(line_revenue)) OVER(),

        2

    ) AS pct_of_total_revenue

FROM public.completed_sales

GROUP BY market;

/*
Key Findings
======================================================================

• The United Kingdom is the company’s dominant market, generating
  approximately £17.87 million and contributing 85.21% of total
  completed-sales revenue.

• International markets collectively generated approximately
  £3.10 million, representing 14.79% of total revenue.

• EIRE and the Netherlands were the strongest international
  markets, generating approximately £664,431.78 and £554,232.34
  respectively.

• The United Kingdom also has the largest identified customer base,
  with 5,350 customers, substantially exceeding every other market.

• Regional revenue is highly concentrated. The top 20% of countries
  generated approximately 97.03% of total revenue, while the
  remaining 80% contributed only 2.97%.

• These results demonstrate a high level of dependence on the
  domestic UK market, while also identifying several valuable
  international markets with expansion potential.
*/

/*
Business Recommendations
======================================================================

• Protect the company’s position in the United Kingdom through
  customer-retention programmes, reliable inventory availability,
  and continued investment in the domestic market.

• Reduce geographic concentration risk by expanding selectively
  within high-performing international markets such as EIRE,
  the Netherlands, Germany, and France.

• Investigate the purchasing behaviour and customer profiles of
  successful international markets to identify repeatable growth
  opportunities.

• Avoid spreading investment evenly across all countries. Prioritise
  markets with proven revenue, customer demand, and order value.

• Monitor domestic and international revenue shares over time to
  evaluate whether geographic diversification strategies are
  successfully reducing reliance on the United Kingdom.
*/

/*======================================================================
SECTION 7: CUSTOMER SEGMENTATION
======================================================================*/

/*
Business Objective:
Segment customers based on their lifetime revenue contribution
to support targeted marketing, customer relationship management,
and resource allocation.

Rather than using fixed revenue thresholds, customer segments
are created using SQL window functions to produce data-driven
revenue percentiles.

Business Questions:
1. How is customer revenue distributed?
2. How many customers belong to each revenue segment?
3. How much revenue does each segment contribute?
4. Which customer segments deserve the highest business priority?
*/


-- 7.1 Customer Lifetime Revenue

SELECT

    customer_id,

    ROUND(
        SUM(line_revenue),
        2
    ) AS lifetime_revenue,

    COUNT(DISTINCT invoice) AS total_orders,

    SUM(quantity) AS total_items_purchased

FROM public.identified_customer_sales

GROUP BY customer_id

ORDER BY lifetime_revenue DESC;

-- 7.2 Revenue Quartile Segmentation

WITH customer_summary AS
(
    SELECT

        customer_id,

        SUM(line_revenue) AS lifetime_revenue

    FROM public.identified_customer_sales

    GROUP BY customer_id
)

SELECT

    customer_id,

    ROUND(lifetime_revenue,2) AS lifetime_revenue,

    CASE NTILE(4)

        OVER(

            ORDER BY lifetime_revenue DESC

        )

        WHEN 1 THEN 'Platinum'

        WHEN 2 THEN 'Gold'

        WHEN 3 THEN 'Silver'

        ELSE 'Bronze'

    END AS customer_segment

FROM customer_summary

ORDER BY lifetime_revenue DESC;

-- 7.3 Segment Performance Summary

WITH customer_summary AS
(
    SELECT

        customer_id,

        SUM(line_revenue) AS lifetime_revenue

    FROM public.identified_customer_sales

    GROUP BY customer_id
),

segmented AS
(
    SELECT

        customer_id,

        lifetime_revenue,

        CASE NTILE(4)

            OVER(

                ORDER BY lifetime_revenue DESC

            )

            WHEN 1 THEN 'Platinum'

            WHEN 2 THEN 'Gold'

            WHEN 3 THEN 'Silver'

            ELSE 'Bronze'

        END AS customer_segment

    FROM customer_summary
)

SELECT

    customer_segment,

    COUNT(*) AS number_of_customers,

    ROUND(
        SUM(lifetime_revenue),
        2
    ) AS total_segment_revenue,

    ROUND(
        AVG(lifetime_revenue),
        2
    ) AS average_customer_revenue,

    ROUND(
        100.0 *
        SUM(lifetime_revenue)
        /
        SUM(SUM(lifetime_revenue)) OVER(),
        2
    ) AS pct_of_total_customer_revenue

FROM segmented

GROUP BY customer_segment

ORDER BY total_segment_revenue DESC;

-- 7.4 Customer Revenue Percentile

WITH customer_summary AS
(
    SELECT
        customer_id,
        SUM(line_revenue) AS lifetime_revenue
    FROM public.identified_customer_sales
    GROUP BY customer_id
)

SELECT
    customer_id,

    ROUND(
        lifetime_revenue,
        2
    ) AS lifetime_revenue,

    ROUND(
        (
            PERCENT_RANK() OVER (
                ORDER BY lifetime_revenue
            )
        )::numeric,
        4
    ) AS revenue_percentile

FROM customer_summary

ORDER BY lifetime_revenue DESC;

-- 7.5 High-Value vs Standard Customers

WITH customer_summary AS
(
    SELECT

        customer_id,

        SUM(line_revenue) AS lifetime_revenue

    FROM public.identified_customer_sales

    GROUP BY customer_id
),

overall_stats AS
(
    SELECT

        AVG(lifetime_revenue) AS average_customer_revenue

    FROM customer_summary
)

SELECT

    CASE

        WHEN lifetime_revenue >= average_customer_revenue

            THEN 'High-Value Customer'

        ELSE 'Standard Customer'

    END AS customer_group,

    COUNT(*) AS number_of_customers,

    ROUND(
        AVG(lifetime_revenue),
        2
    ) AS average_revenue

FROM customer_summary

CROSS JOIN overall_stats

GROUP BY customer_group;

/*
Key Findings
======================================================================

• Revenue is highly concentrated among the highest-performing
  customer segment.

• Customers classified within the Platinum segment generate
  approximately 81.61% of total identified-customer revenue,
  despite representing only one quarter of the customer base.

• Gold customers contribute an additional 11.97% of revenue,
  while Silver and Bronze customers together account for less
  than 7% of total customer revenue.

• Revenue percentile analysis confirms substantial variation
  in customer value, highlighting the importance of targeted
  customer management strategies.

• High-Value Customers (1,151 customers) generate an average
  lifetime revenue of approximately £11,844.99, compared with
  approximately £869.44 for Standard Customers.

• These findings demonstrate that customer value is highly
  concentrated and supports differentiated marketing,
  retention, and loyalty initiatives.
*/

/*
Business Recommendations
======================================================================

• Prioritize retention strategies for Platinum customers through
  VIP programmes, personalised communication, and premium
  customer service.

• Develop targeted campaigns to encourage Gold customers to
  progress into the Platinum segment.

• Design cross-selling and repeat-purchase initiatives for
  Silver customers to increase customer lifetime value.

• Use cost-efficient marketing strategies for Bronze customers
  while monitoring opportunities for future growth.

• Integrate customer segmentation into CRM and marketing
  platforms to enable personalised promotions and
  data-driven customer engagement.
*/

/*======================================================================
SECTION 8: RFM CUSTOMER ANALYSIS
======================================================================*/

/*
Business Objective:
Evaluate customer purchasing behaviour using the RFM
(Recency, Frequency, Monetary) framework.

RFM analysis identifies high-value customers, loyal customers,
inactive customers, and customers at risk of churn, enabling
targeted retention and marketing strategies.

Business Questions:
1. Which customers purchased most recently?
2. Which customers purchase most frequently?
3. Which customers generate the most revenue?
4. Which customers are most valuable overall?
5. Which customers require retention efforts?
*/

-- 8.1 Build Customer RFM Metrics

SELECT

    customer_id,

    MAX(invoicedate) AS last_purchase_date,

    (
        SELECT MAX(invoicedate)
        FROM public.identified_customer_sales
    )::date

    -

    MAX(invoicedate)::date

    AS recency_days,

    COUNT(DISTINCT invoice) AS frequency,

    ROUND(
        SUM(line_revenue),
        2
    ) AS monetary

FROM public.identified_customer_sales

GROUP BY customer_id

ORDER BY monetary DESC;

-- 8.2 Calculate RFM Scores
-- Score range: 1–4, where 4 represents the best performance.

WITH reference_date AS
(
    SELECT
        MAX(invoicedate)::date AS snapshot_date
    FROM public.identified_customer_sales
),

customer_rfm AS
(
    SELECT
        sales.customer_id,

        (
            SELECT snapshot_date
            FROM reference_date
        ) - MAX(sales.invoicedate)::date AS recency_days,

        COUNT(DISTINCT sales.invoice) AS frequency,

        SUM(sales.line_revenue) AS monetary

    FROM public.identified_customer_sales AS sales

    GROUP BY sales.customer_id
)

SELECT
    customer_id,
    recency_days,
    frequency,
    ROUND(monetary, 2) AS monetary,

    NTILE(4) OVER (
        ORDER BY recency_days DESC
    ) AS recency_score,

    NTILE(4) OVER (
        ORDER BY frequency ASC
    ) AS frequency_score,

    NTILE(4) OVER (
        ORDER BY monetary ASC
    ) AS monetary_score

FROM customer_rfm

ORDER BY monetary DESC;

-- 8.3 Create Customer RFM Codes

WITH reference_date AS
(
    SELECT
        MAX(invoicedate)::date AS snapshot_date
    FROM public.identified_customer_sales
),

customer_rfm AS
(
    SELECT
        sales.customer_id,

        (
            SELECT snapshot_date
            FROM reference_date
        ) - MAX(sales.invoicedate)::date AS recency_days,

        COUNT(DISTINCT sales.invoice) AS frequency,

        SUM(sales.line_revenue) AS monetary

    FROM public.identified_customer_sales AS sales

    GROUP BY sales.customer_id
),

rfm_scores AS
(
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,

        NTILE(4) OVER (
            ORDER BY recency_days DESC
        ) AS recency_score,

        NTILE(4) OVER (
            ORDER BY frequency ASC
        ) AS frequency_score,

        NTILE(4) OVER (
            ORDER BY monetary ASC
        ) AS monetary_score

    FROM customer_rfm
)

SELECT
    customer_id,
    recency_days,
    frequency,
    ROUND(monetary, 2) AS monetary,
    recency_score,
    frequency_score,
    monetary_score,

    CONCAT(
        recency_score,
        frequency_score,
        monetary_score
    ) AS rfm_code

FROM rfm_scores

ORDER BY
    recency_score DESC,
    frequency_score DESC,
    monetary_score DESC;

-- 8.3 Create Customer RFM Codes

WITH reference_date AS
(
    SELECT
        MAX(invoicedate)::date AS snapshot_date
    FROM public.identified_customer_sales
),

customer_rfm AS
(
    SELECT
        sales.customer_id,

        (
            SELECT snapshot_date
            FROM reference_date
        ) - MAX(sales.invoicedate)::date AS recency_days,

        COUNT(DISTINCT sales.invoice) AS frequency,

        SUM(sales.line_revenue) AS monetary

    FROM public.identified_customer_sales AS sales

    GROUP BY sales.customer_id
),

rfm_scores AS
(
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,

        NTILE(4) OVER (
            ORDER BY recency_days DESC
        ) AS recency_score,

        NTILE(4) OVER (
            ORDER BY frequency ASC
        ) AS frequency_score,

        NTILE(4) OVER (
            ORDER BY monetary ASC
        ) AS monetary_score

    FROM customer_rfm
)

SELECT
    customer_id,
    recency_days,
    frequency,
    ROUND(monetary, 2) AS monetary,
    recency_score,
    frequency_score,
    monetary_score,

    CONCAT(
        recency_score,
        frequency_score,
        monetary_score
    ) AS rfm_code

FROM rfm_scores

ORDER BY
    recency_score DESC,
    frequency_score DESC,
    monetary_score DESC;

-- 8.4 Create Customer Segments Based on RFM Scores

WITH reference_date AS
(
    SELECT
        MAX(invoicedate)::date AS snapshot_date
    FROM public.identified_customer_sales
),

customer_rfm AS
(
    SELECT
        sales.customer_id,

        (
            SELECT snapshot_date
            FROM reference_date
        ) - MAX(sales.invoicedate)::date AS recency_days,

        COUNT(DISTINCT sales.invoice) AS frequency,

        SUM(sales.line_revenue) AS monetary

    FROM public.identified_customer_sales AS sales

    GROUP BY sales.customer_id
),

rfm_scores AS
(
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,

        NTILE(4) OVER (
            ORDER BY recency_days DESC
        ) AS recency_score,

        NTILE(4) OVER (
            ORDER BY frequency ASC
        ) AS frequency_score,

        NTILE(4) OVER (
            ORDER BY monetary ASC
        ) AS monetary_score

    FROM customer_rfm
),

rfm_segments AS
(
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        recency_score,
        frequency_score,
        monetary_score,

        CASE
            WHEN recency_score = 4
             AND frequency_score = 4
             AND monetary_score = 4
                THEN 'Champions'

            WHEN recency_score >= 3
             AND frequency_score >= 3
                THEN 'Loyal Customers'

            WHEN recency_score >= 3
             AND monetary_score >= 3
                THEN 'High-Value Customers'

            WHEN recency_score = 1
                THEN 'At Risk'

            ELSE 'Regular Customers'
        END AS customer_segment

    FROM rfm_scores
)

SELECT
    customer_segment,
    COUNT(*) AS number_of_customers,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS pct_of_customers

FROM rfm_segments

GROUP BY customer_segment

ORDER BY number_of_customers DESC;

-- 8.5 Average Customer Metrics by RFM Segment

WITH reference_date AS
(
    SELECT
        MAX(invoicedate)::date AS snapshot_date
    FROM public.identified_customer_sales
),

customer_rfm AS
(
    SELECT
        sales.customer_id,

        (
            SELECT snapshot_date
            FROM reference_date
        ) - MAX(sales.invoicedate)::date AS recency_days,

        COUNT(DISTINCT sales.invoice) AS frequency,

        SUM(sales.line_revenue) AS monetary

    FROM public.identified_customer_sales AS sales

    GROUP BY sales.customer_id
),

rfm_scores AS
(
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,

        NTILE(4) OVER (
            ORDER BY recency_days DESC
        ) AS recency_score,

        NTILE(4) OVER (
            ORDER BY frequency ASC
        ) AS frequency_score,

        NTILE(4) OVER (
            ORDER BY monetary ASC
        ) AS monetary_score

    FROM customer_rfm
),

rfm_segments AS
(
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        recency_score,
        frequency_score,
        monetary_score,

        CASE
            WHEN recency_score = 4
             AND frequency_score = 4
             AND monetary_score = 4
                THEN 'Champions'

            WHEN recency_score >= 3
             AND frequency_score >= 3
                THEN 'Loyal Customers'

            WHEN recency_score >= 3
             AND monetary_score >= 3
                THEN 'High-Value Customers'

            WHEN recency_score = 1
                THEN 'At Risk'

            ELSE 'Regular Customers'
        END AS customer_segment

    FROM rfm_scores
)

SELECT
    customer_segment,

    COUNT(*) AS number_of_customers,

    ROUND(
        AVG(recency_days),
        1
    ) AS avg_recency_days,

    ROUND(
        AVG(frequency),
        1
    ) AS avg_frequency,

    ROUND(
        AVG(monetary),
        2
    ) AS avg_monetary,

    ROUND(
        SUM(monetary),
        2
    ) AS total_segment_revenue,

    ROUND(
        100.0 * SUM(monetary)
        / SUM(SUM(monetary)) OVER (),
        2
    ) AS pct_of_customer_revenue

FROM rfm_segments

GROUP BY customer_segment

ORDER BY total_segment_revenue DESC;


/*
================================================================
Key Findings
• The RFM model segmented all 5,878 identified customers into five
  actionable customer groups.

• Champions represent only 11.01% of customers but contribute
  53.73% of total customer revenue, making them the company's most
  valuable customer segment.

• Loyal Customers account for 23.80% of customers and generate
  22.92% of customer revenue, representing strong long-term
  purchasing behavior.

• Regular Customers comprise the largest customer segment
  (36.97%) but contribute only 14.74% of customer revenue,
  indicating opportunities for customer development.

• At Risk Customers account for 25.01% of customers and have an
  average recency of over 513 days, suggesting that targeted
  re-engagement campaigns could help recover lost revenue.

• High-Value Customers have high average spending (£2,507.89)
  despite relatively low purchase frequency, making them suitable
  for premium retention and loyalty initiatives.
  */
/*======================================================================
SECTION 9: POWER BI DASHBOARD DATASETS
======================================================================*/

/*
Business Objective:
Create standardized, reusable analytical views for Power BI.

Each view supports a specific dashboard page and uses the same
cleaned-data definitions established in Section 0.

Dashboard Views:
1. Executive KPI Summary
2. Monthly Sales Trend
3. Customer Performance
4. Product Performance
5. Regional Performance
6. Revenue-Based Customer Segmentation
7. RFM Customer Segmentation
*/

-- 9.1 Create Executive KPI Dashboard View

CREATE OR REPLACE VIEW public.dashboard_executive_kpis AS
SELECT
    ROUND(
        SUM(line_revenue),
        2
    ) AS total_revenue,

    COUNT(DISTINCT invoice) AS total_orders,

    COUNT(DISTINCT customer_id) AS identified_customers,

    COUNT(DISTINCT stockcode) AS products_sold,

    SUM(quantity) AS total_items_sold,

    ROUND(
        SUM(line_revenue)
        / NULLIF(COUNT(DISTINCT invoice), 0),
        2
    ) AS average_order_value

FROM public.completed_sales;

SELECT *
FROM public.dashboard_executive_kpis;

-- 9.2 Create Monthly Sales Dashboard View

CREATE OR REPLACE VIEW public.dashboard_monthly_sales AS

WITH monthly_sales AS
(
    SELECT
        DATE_TRUNC('month', invoicedate)::date AS sales_month,

        ROUND(
            SUM(line_revenue),
            2
        ) AS total_revenue,

        COUNT(DISTINCT invoice) AS total_orders,

        COUNT(DISTINCT customer_id) AS identified_customers,

        SUM(quantity) AS total_items_sold

    FROM public.completed_sales

    GROUP BY DATE_TRUNC('month', invoicedate)::date
),

monthly_comparison AS
(
    SELECT
        sales_month,
        total_revenue,
        total_orders,
        identified_customers,
        total_items_sold,

        LAG(total_revenue) OVER (
            ORDER BY sales_month
        ) AS previous_month_revenue

    FROM monthly_sales
)

SELECT
    sales_month,
    total_revenue,
    total_orders,
    identified_customers,
    total_items_sold,

    ROUND(
        total_revenue
        / NULLIF(total_orders, 0),
        2
    ) AS average_order_value,

    previous_month_revenue,

    ROUND(
        total_revenue - previous_month_revenue,
        2
    ) AS revenue_difference,

    ROUND(
        100.0
        * (total_revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0),
        2
    ) AS revenue_growth_pct,

    ROUND(
        SUM(total_revenue) OVER (
            ORDER BY sales_month
        ),
        2
    ) AS cumulative_revenue

FROM monthly_comparison;

SELECT *
FROM public.dashboard_monthly_sales
ORDER BY sales_month;

-- 9.3 Create Customer Performance Dashboard View

CREATE OR REPLACE VIEW public.dashboard_customer_performance AS
SELECT
    customer_id,

    ROUND(
        SUM(line_revenue),
        2
    ) AS total_revenue,

    COUNT(DISTINCT invoice) AS total_orders,

    SUM(quantity) AS total_items_purchased,

    MIN(invoicedate) AS first_purchase_date,

    MAX(invoicedate) AS last_purchase_date,

    ROUND(
        SUM(line_revenue)
        / NULLIF(COUNT(DISTINCT invoice), 0),
        2
    ) AS average_order_value

FROM public.identified_customer_sales

GROUP BY customer_id;

SELECT *
FROM public.dashboard_customer_performance
ORDER BY total_revenue DESC
LIMIT 10;

-- 9.4 Create Product Performance Dashboard View

CREATE OR REPLACE VIEW public.dashboard_product_performance AS
SELECT
    stockcode,
    description,

    CASE
        WHEN stockcode IN ('M', 'DOT', 'POST')
            THEN 'Operational Charge'
        ELSE 'Merchandise'
    END AS product_type,

    ROUND(
        SUM(line_revenue),
        2
    ) AS total_revenue,

    COUNT(DISTINCT invoice) AS total_orders,

    SUM(quantity) AS total_quantity_sold,

    ROUND(
        SUM(line_revenue)
        / NULLIF(SUM(quantity), 0),
        2
    ) AS weighted_average_selling_price

FROM public.completed_sales

GROUP BY
    stockcode,
    description,
    CASE
        WHEN stockcode IN ('M', 'DOT', 'POST')
            THEN 'Operational Charge'
        ELSE 'Merchandise'
    END;

SELECT *
FROM public.dashboard_product_performance
ORDER BY total_revenue DESC
LIMIT 10;

-- 9.5 Create Regional Performance Dashboard View

CREATE OR REPLACE VIEW public.dashboard_regional_performance AS
SELECT
    country,

    CASE
        WHEN country = 'United Kingdom'
            THEN 'Domestic Market'
        ELSE 'International Market'
    END AS market_type,

    ROUND(
        SUM(line_revenue),
        2
    ) AS total_revenue,

    COUNT(DISTINCT invoice) AS total_orders,

    COUNT(DISTINCT customer_id) AS identified_customers,

    SUM(quantity) AS total_items_sold,

    ROUND(
        SUM(line_revenue)
        / NULLIF(COUNT(DISTINCT invoice), 0),
        2
    ) AS average_order_value,

    ROUND(
        100.0
        * SUM(line_revenue)
        / SUM(SUM(line_revenue)) OVER (),
        2
    ) AS pct_of_total_revenue

FROM public.completed_sales

GROUP BY
    country,
    CASE
        WHEN country = 'United Kingdom'
            THEN 'Domestic Market'
        ELSE 'International Market'
    END;

SELECT *
FROM public.dashboard_regional_performance
ORDER BY total_revenue DESC;

-- 9.6 Create Revenue-Based Customer Segmentation View

CREATE OR REPLACE VIEW public.dashboard_customer_segments AS

WITH customer_summary AS
(
    SELECT
        customer_id,

        SUM(line_revenue) AS lifetime_revenue,

        COUNT(DISTINCT invoice) AS total_orders,

        SUM(quantity) AS total_items_purchased

    FROM public.identified_customer_sales

    GROUP BY customer_id
),

segmented_customers AS
(
    SELECT
        customer_id,
        lifetime_revenue,
        total_orders,
        total_items_purchased,

        NTILE(4) OVER (
            ORDER BY lifetime_revenue DESC
        ) AS revenue_quartile

    FROM customer_summary
)

SELECT
    customer_id,

    ROUND(
        lifetime_revenue,
        2
    ) AS lifetime_revenue,

    total_orders,

    total_items_purchased,

    ROUND(
        lifetime_revenue
        / NULLIF(total_orders, 0),
        2
    ) AS average_order_value,

    CASE
        WHEN revenue_quartile = 1 THEN 'Platinum'
        WHEN revenue_quartile = 2 THEN 'Gold'
        WHEN revenue_quartile = 3 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_segment

FROM segmented_customers;

SELECT
    customer_segment,
    COUNT(*) AS number_of_customers,
    ROUND(SUM(lifetime_revenue), 2) AS segment_revenue
FROM public.dashboard_customer_segments
GROUP BY customer_segment
ORDER BY segment_revenue DESC;

-- 9.7 Create RFM Customer Dashboard View

CREATE OR REPLACE VIEW public.dashboard_customer_rfm AS

WITH reference_date AS
(
    SELECT
        MAX(invoicedate)::date AS snapshot_date
    FROM public.identified_customer_sales
),

customer_rfm AS
(
    SELECT
        sales.customer_id,

        (
            SELECT snapshot_date
            FROM reference_date
        ) - MAX(sales.invoicedate)::date AS recency_days,

        COUNT(DISTINCT sales.invoice) AS frequency,

        SUM(sales.line_revenue) AS monetary

    FROM public.identified_customer_sales AS sales

    GROUP BY sales.customer_id
),

rfm_scores AS
(
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,

        NTILE(4) OVER (
            ORDER BY recency_days DESC
        ) AS recency_score,

        NTILE(4) OVER (
            ORDER BY frequency ASC
        ) AS frequency_score,

        NTILE(4) OVER (
            ORDER BY monetary ASC
        ) AS monetary_score

    FROM customer_rfm
)

SELECT
    customer_id,
    recency_days,
    frequency,

    ROUND(
        monetary,
        2
    ) AS monetary,

    recency_score,
    frequency_score,
    monetary_score,

    CONCAT(
        recency_score,
        frequency_score,
        monetary_score
    ) AS rfm_code,

    CASE
        WHEN recency_score = 4
         AND frequency_score = 4
         AND monetary_score = 4
            THEN 'Champions'

        WHEN recency_score >= 3
         AND frequency_score >= 3
            THEN 'Loyal Customers'

        WHEN recency_score >= 3
         AND monetary_score >= 3
            THEN 'High-Value Customers'

        WHEN recency_score = 1
            THEN 'At Risk'

        ELSE 'Regular Customers'
    END AS rfm_segment

FROM rfm_scores;

SELECT
    rfm_segment,
    COUNT(*) AS number_of_customers,
    ROUND(SUM(monetary), 2) AS segment_revenue
FROM public.dashboard_customer_rfm
GROUP BY rfm_segment
ORDER BY segment_revenue DESC;

-- 9.8 Verify Power BI Dashboard Views

SELECT
    table_schema,
    table_name
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name LIKE 'dashboard_%'
ORDER BY table_name;

/*
Dashboard Methodology:
======================================================================

The dashboard views standardize the business logic used across
Power BI reports.

Company-level views use public.completed_sales, ensuring valid
anonymous sales remain included in financial and operational KPIs.

Customer-level views use public.identified_customer_sales because
customer identification is required for customer analytics,
segmentation, and RFM reporting.

These reusable views eliminate duplicated transformation logic and
ensure that every Power BI dashboard uses consistent KPI definitions.
*/

/*
Key Findings
======================================================================

• Seven standardized dashboard views were created for Power BI.

• Company-level views use public.completed_sales, ensuring valid
  transactions without customer IDs remain included in financial,
  product, regional, and monthly reporting.

• Customer-level views use public.identified_customer_sales,
  ensuring that customer performance, segmentation, and RFM
  analysis are based only on identified customers.

• The views centralize KPI logic and prevent duplicated
  transformation rules across multiple Power BI pages.

• The dashboard layer is now ready to support executive, sales,
  customer, product, regional, segmentation, and RFM reporting.
*/

/*======================================================================
SECTION 10: EXECUTIVE SUMMARY & BUSINESS RECOMMENDATIONS
======================================================================

Business Objective:
Summarize the key analytical findings and translate them into
actionable business recommendations for decision makers.

======================================================================
EXECUTIVE SUMMARY
======================================================================

The analysis examined 1,067,371 retail transactions and identified
1,041,652 valid completed sales records, generating total revenue of
£20.97 million across 40,077 completed customer orders.

The business serves customers across 41 countries, with the United
Kingdom accounting for approximately 85% of total revenue. While the
customer base is geographically diverse, revenue remains highly
concentrated within the domestic market.

Customer purchasing behaviour shows strong repeat engagement, with
72.39% of identified customers making multiple purchases. Revenue is
also highly concentrated among a relatively small group of customers,
where the top 10% contribute approximately 68% of customer revenue
and the top 1% contribute nearly one-third of customer revenue.

Product sales follow a similar concentration pattern. The top 20% of
products generate nearly 80% of total merchandise revenue, while
operational charges such as postage and manual adjustments represent
only a small proportion of overall revenue.

Monthly revenue demonstrates clear seasonality, with the strongest
sales occurring during the final quarter of the year, particularly
November 2011, suggesting substantial opportunities for seasonal
inventory planning and promotional campaigns.

RFM analysis identified five distinct customer segments. Champions
represent only 11.01% of customers but contribute more than half of
all customer revenue, highlighting the importance of customer
retention and loyalty strategies.

======================================================================
BUSINESS RECOMMENDATIONS
======================================================================

1. Prioritize customer retention initiatives for Champions and Loyal
   Customers through loyalty programmes, personalised marketing, and
   exclusive offers.

2. Develop targeted reactivation campaigns for At Risk customers to
   recover dormant customer relationships before permanent churn
   occurs.

3. Increase inventory planning and staffing ahead of Q4 demand,
   particularly during October and November when sales volumes peak.

4. Expand marketing investment in high-performing products while
   reviewing the long-tail product portfolio for optimisation
   opportunities.

5. Explore international market expansion by focusing on the highest
   performing overseas countries, including Ireland, the Netherlands,
   Germany, and France.

6. Continue monitoring customer purchasing behaviour using RFM
   segmentation to improve customer lifetime value and marketing
   effectiveness.

======================================================================
PROJECT CONCLUSION
======================================================================

This project demonstrates an end-to-end SQL analytics workflow,
including data quality assessment, exploratory analysis, reusable SQL
views, business KPI development, customer segmentation, RFM analysis,
and dashboard-ready dataset generation.

The resulting analytical views provide a scalable foundation for
interactive reporting in Power BI while maintaining consistent
business definitions across all reporting layers.
*/

