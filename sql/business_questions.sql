CREATE DATABASE Retail_Sales_Project

ALTER TABLE Sales_Cleaned
ADD CONSTRAINT fk_customer
FOREIGN KEY (customer_id)
REFERENCES Customers_Cleaned(customer_id)

ALTER TABLE Sales_Cleaned
ADD CONSTRAINT fk_product
FOREIGN KEY (product_id)
REFERENCES Products_Cleaned(product_id)


ALTER TABLE Returns_Cleaned
ADD CONSTRAINT fk_order
FOREIGN KEY (order_id)
REFERENCES Sales_Cleaned(order_id)

INSERT INTO Stores_Cleaned VALUES ('-','Online Store','Online','-','-',0)

ALTER TABLE Sales_Cleaned
ADD CONSTRAINT fk_store
FOREIGN KEY (store_id)
REFERENCES Stores_Cleaned(store_id)


CREATE INDEX index_customer
ON Sales_Cleaned (customer_id)

CREATE INDEX index_product
ON Sales_Cleaned(product_id)

CREATE INDEX index_store
ON Sales_Cleaned(store_id)

CREATE INDEX index_order_date
ON Sales_Cleaned(order_date)


/*TOTAL PROFIT */
SELECT ROUND(SUM(profit),2) AS TOTAL_PROFIT FROM sales_cleaned 


/*RETURN PERCENTAGE */
SELECT ROUND(CAST(COUNT(r.return_id)*100.0 /COUNT(s.order_id) AS FLOAT),2) AS 'Total Return %' FROM sales_cleaned s
LEFT JOIN returns_cleaned r
ON s.order_id = r.order_id


/*DISCOUNT PERCENTAGE*/
SELECT ROUND(SUM(discount_pct * total_amount)/ NULLIF(SUM(total_amount), 0)* 100,2) AS "Total Discount %"
FROM sales_cleaned;


/* 1. What is the total revenue generated in the last 12 months? */
SELECT ROUND(SUM(total_amount),2) AS 'TOTAL REVENUE GENERATED IN LAST 12 MONTHS' FROM sales_cleaned
WHERE order_date >= DATEADD(MONTH,-12,(SELECT MAX(order_date) from sales_cleaned))



/* 2. Which are the top 5 best-selling products by quantity?  */
SELECT TOP 5 p.product_name as ProductName,sum(s.quantity) as Quantity from products_cleaned p
JOIN sales_cleaned s 
ON p.product_id = s.product_id
GROUP BY p.product_name 
ORDER BY SUM(s.quantity) DESC



/* 3. How many customers are from each region? */
SELECT COUNT(customer_id) as 'Total No Of Customers',region as 'Region' from customers_cleaned 
group by region



/* 4. Which store has the highest profit in the past year?  */
SELECT TOP 1 st.store_name AS Store_Name ,ROUND(SUM(s.profit),2) AS Profit FROM Sales_Cleaned s
JOIN Stores_Cleaned st
ON st.store_id=s.store_id
WHERE YEAR(s.order_date) = (SELECT YEAR(MAX(order_date)) - 1 FROM sales_cleaned) AND st.store_id<>'-'
GROUP BY st.store_name  
ORDER BY Profit DESC	



/*5. What is the return rate by product category? */
SELECT p.category AS 'Category',FORMAT(COUNT(r.return_id) * 100.0/ NULLIF(COUNT(s.order_id), 0),'N2')+ ' %' AS 'Return_Rate'
FROM products_cleaned p
JOIN sales_cleaned s
ON p.product_id = s.product_id
LEFT JOIN returns_cleaned r
ON s.order_id = r.order_id
GROUP BY p.category



/* 6. What is the average revenue per customer by age group? */
SELECT ROUND(AVG(s.total_amount),2) AS 'AVERAGE REVENUE',c.Age_Group AS 'AGE_GROUP' FROM sales_cleaned s
JOIN customers_cleaned c
ON c.customer_id = s.customer_id
GROUP BY Age_Group



/* 7. Which sales channel (Online vs In-Store) is more profitable on average? */
SELECT TOP 1 s.sales_channel AS 'SALES CHANNEL',ROUND(AVG(profit),2) AS 'PROFITABLE' FROM sales_cleaned s
JOIN products_cleaned p
ON p.product_id = s.product_id
GROUP BY sales_channel
ORDER BY PROFITABLE DESC


/* 8.How has monthly profit changed over the last 2 years by region? */
SELECT st.region AS Region,YEAR(s.order_date) AS Sales_Year,MONTH(s.order_date) AS Sales_Month,ROUND(SUM(s.profit),2) AS Monthly_Profit
FROM sales_cleaned s
JOIN stores_cleaned st
ON st.store_id = s.store_id
WHERE s.order_date >= DATEADD(YEAR,-2,(SELECT MAX(order_date) FROM sales_cleaned)) AND st.region<>'-'
GROUP BY st.region,YEAR(s.order_date),MONTH(s.order_date)
ORDER BY Region,Sales_Year,Sales_Month;



/* 9.Identify the top 3 products with the highest return rate in each category. */
SELECT Category,Product_Name,FORMAT(Return_Rate, '0.#') + '%' AS Return_Rate
FROM (
    SELECT
        p.category AS Category,
        p.product_name AS Product_Name,
        COUNT(r.order_id) * 100.0 / NULLIF(COUNT(s.order_id), 0) AS Return_Rate,
        ROW_NUMBER() OVER 
        (
            PARTITION BY p.category
            ORDER BY COUNT(r.order_id) * 100.0 / NULLIF(COUNT(s.order_id), 0) DESC
        ) AS rn
FROM products_cleaned p
JOIN sales_cleaned s
ON s.product_id = p.product_id
LEFT JOIN returns_cleaned r
ON r.order_id = s.order_id
GROUP BY p.category, p.product_name
) t
WHERE rn <= 3;


/*10. Which 5 customers have contributed the most to total profit, and what is their tenure with the company? */
SELECT TOP 5 CONCAT(c.first_name,' ',C.last_name) AS Customer_Name, ROUND(SUM(s.profit),2) AS Profit ,
CAST(DATEDIFF(MONTH , c.signup_date , GETDATE()) AS VARCHAR(255))+' Months' AS "Tenure (in months)" FROM customers_cleaned c
JOIN sales_cleaned s
ON s.customer_id= c.customer_id
GROUP BY CONCAT(c.first_name,' ',C.last_name), c.customer_id, CAST(DATEDIFF(MONTH , c.signup_date , GETDATE()) AS VARCHAR(255))
ORDER BY Profit DESC

