-- Task 1: Identifying the Top Branch by Sales Growth Rate --
WITH Monthly_Sales AS (
    SELECT 
        Branch,
        DATE_FORMAT(STR_TO_DATE(Date, '%d-%m-%Y'), '%m') AS `Month`,
        SUM(Total) AS Monthly_Sales
    FROM walmartsales
    GROUP BY Branch, `Month`
),
Growth_Rate AS (
    SELECT 
        Branch,
        `Month`,
        Monthly_Sales,
        LAG(Monthly_Sales) OVER (PARTITION BY Branch ORDER BY `Month`) AS Last_month_sales,
        (Monthly_Sales - LAG(Monthly_Sales) OVER (PARTITION BY Branch ORDER BY `Month`)) / 
        LAG(Monthly_Sales) OVER (PARTITION BY Branch ORDER BY `Month`) * 100 AS GrowthRatePerMonth
    FROM Monthly_Sales
)
SELECT 
    Branch,
    AVG(GrowthRatePerMonth) AS AvgGrowthRate
FROM Growth_Rate
WHERE GrowthRatePerMonth IS NOT NULL
GROUP BY Branch
ORDER BY AvgGrowthRate DESC
LIMIT 1;

-- Task 2: Finding the Most Profitable Product Line for Each Branch --
WITH ProfitPerProductLine AS (
    SELECT 
        Branch,
        Product_line,
        SUM(Total - COGS) AS TotalProfit
    FROM walmartsales
    GROUP BY Branch, Product_line
),
Ranked_ProductLine AS (
    SELECT 
        Branch,
        Product_line,
        TotalProfit,
        ROW_NUMBER() OVER (PARTITION BY Branch ORDER BY TotalProfit DESC) AS Rnk
    FROM ProfitPerProductLine
)
SELECT 
    Branch,
    Product_line,
    ROUND(TotalProfit, 2) AS BestProfit
FROM Ranked_ProductLine
WHERE Rnk = 1;

-- Task 3: Analyzing Customer Segmentation Based on Spending --
WITH Purchase AS (
    SELECT 
        Customer_ID,
        ROUND(SUM(Total)) AS Total_spent 
    FROM walmartsales
    GROUP BY Customer_ID
)
SELECT 
    Customer_ID,
    Total_spent,
    CASE 
        WHEN Total_spent < 20000 THEN 'Low' 
        WHEN Total_spent < 23000 THEN 'Medium'
        ELSE 'High' 
    END AS spenders_type
FROM Purchase
ORDER BY Customer_ID;

-- Task 4: Detecting Anomalies in Sales Transactions  --
WITH AVG_SALES AS (
    SELECT 
        Product_line, 
        ROUND(AVG(Total), 2) AS avg_sales 
    FROM walmartsales 
    GROUP BY Product_line
), 
CTE AS (
    SELECT 
        WMS.Invoice_ID, 
        WMS.Product_line, 
        ROUND(WMS.Total, 2) AS Total, 
        AVG_SALES.avg_sales 
    FROM walmartsales AS WMS 
    INNER JOIN AVG_SALES ON WMS.Product_line = AVG_SALES.Product_line
), 
CTE_deviation AS (
    SELECT 
        Invoice_ID, 
        Product_line, 
        ROUND((Total - avg_sales) / avg_sales, 2) AS Deviation 
    FROM CTE
) 
SELECT * 
FROM CTE_deviation 
WHERE Deviation >= 0.50 OR Deviation <= -0.50 
ORDER BY Product_line;

-- Task 5: Most Popular Payment Method by City --
WITH Payment_method AS (
    SELECT 
        City,
        Payment,
        COUNT(Payment) AS count_payment_method 
    FROM walmartsales 
    GROUP BY City, Payment
), 
Payment_method2 AS (
    SELECT 
        City,
        Payment,
        count_payment_method,
        ROW_NUMBER() OVER (PARTITION BY City ORDER BY count_payment_method DESC) AS r_no 
    FROM Payment_method
) 
SELECT 
    City, 
    Payment, 
    count_payment_method 
FROM Payment_method2 
WHERE r_no = 1
ORDER BY City;

-- Task 6: Monthly Sales Distribution by Gender --
WITH Sales_Distribution AS (
    SELECT 
        Gender, 
        DATE_FORMAT(STR_TO_DATE(Date, '%d-%m-%Y'), '%m') AS Month,
        ROUND(SUM(Total)) AS Sales 
    FROM walmartsales 
    GROUP BY Gender, Month
), 
Female_Monthly_Sales AS (
    SELECT Gender, Month, Sales 
    FROM Sales_Distribution
    WHERE Gender = 'Female'
), 
Male_Monthly_Sales AS (
    SELECT Gender, Month, Sales 
    FROM Sales_Distribution
    WHERE Gender = 'Male'
) 
SELECT 
    F.Month, 
    F.Gender AS Female_Gender, 
    F.Sales AS Female_Sales, 
    M.Gender AS Male_Gender, 
    M.Sales AS Male_Sales
FROM Female_Monthly_Sales AS F 
INNER JOIN Male_Monthly_Sales AS M 
ON F.Month = M.Month
ORDER BY F.Month;

-- Task 7: Best Product Line by Customer Type --
WITH Total_Revenue_Each_Product AS (
    SELECT 
        Customer_type,
        Product_line,
        ROUND(SUM(Total)) AS Total_Revenue 
    FROM walmartsales 
    GROUP BY Customer_type, Product_line
), 
Total_Revenue_Each_Product2 AS (
    SELECT 
        Customer_type,
        Product_line,
        Total_Revenue,
        ROW_NUMBER() OVER (PARTITION BY Customer_type ORDER BY Total_Revenue DESC) AS rowno 
    FROM Total_Revenue_Each_Product
) 
SELECT 
    Customer_type,
    Product_line,
    Total_Revenue 
FROM Total_Revenue_Each_Product2 
WHERE rowno = 1;

-- Task 8: Identifying Repeat Customers --
WITH customer_purchases AS (
    SELECT 
        Customer_ID, 
        Invoice_ID,
        STR_TO_DATE(Date, '%d-%m-%Y') AS purchased_date,
        LEAD(STR_TO_DATE(Date, '%d-%m-%Y'), 1) OVER (PARTITION BY Customer_ID ORDER BY STR_TO_DATE(Date, '%d-%m-%Y')) AS next_purchased
    FROM walmartsales
)
SELECT 
    Customer_ID,
    COUNT(*) AS next_purchased_count
FROM customer_purchases
WHERE next_purchased IS NOT NULL
    AND DATEDIFF(next_purchased, purchased_date) <= 30
GROUP BY Customer_ID;

-- Task 9: Finding Top 5 Customers by Sales Volume  --
SELECT 
    Customer_ID,
    ROUND(SUM(Total), 2) AS SalesRevenue
FROM walmartsales
GROUP BY Customer_ID
ORDER BY SalesRevenue DESC
LIMIT 5;

-- Task 10: Analyzing Sales Trends by Day of the Week  --
SELECT 
    DAYNAME(STR_TO_DATE(Date, '%d-%m-%Y')) AS Weekdays,
    ROUND(SUM(Total), 2) AS TotalSales
FROM walmartsales
GROUP BY DAYNAME(STR_TO_DATE(Date, '%d-%m-%Y'))
ORDER BY TotalSales DESC;
