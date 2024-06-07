/* Creating a new table that provides information about each individual table in the dataset.
Results will return the table name, columns count, and rows count for each table. */

SELECT 'Customers' AS table_name,
       (SELECT COUNT(*) FROM pragma_table_info('customers')) AS number_of_attributes,
       COUNT(*) AS number_of_rows
  FROM customers

UNION ALL

SELECT 'Products' AS table_name,
       (SELECT COUNT(*) FROM pragma_table_info('products')) AS number_of_attributes,
       COUNT(*) AS number_of_rows
  FROM products

UNION ALL

SELECT 'ProductLines' AS table_name,
       (SELECT COUNT(*) FROM pragma_table_info('ProductLines')) AS number_of_attributes,
       COUNT(*) AS number_of_rows
  FROM ProductLines

UNION ALL

SELECT 'Orders' AS table_name,
       (SELECT COUNT(*) FROM pragma_table_info('orders')) AS number_of_attributes,
       COUNT(*) AS number_of_rows
  FROM orders

UNION ALL

SELECT 'OrderDetails' AS table_name,
       (SELECT COUNT(*) FROM pragma_table_info('OrderDetails')) AS number_of_attributes,
       COUNT(*) AS number_of_rows
  FROM OrderDetails

UNION ALL

SELECT 'Payments' AS table_name,
       (SELECT COUNT(*) FROM pragma_table_info('payments')) AS number_of_attributes,
       COUNT(*) AS number_of_rows
  FROM payments

UNION ALL

SELECT 'Employees' AS table_name,
       (SELECT COUNT(*) FROM pragma_table_info('employees')) AS number_of_attributes,
       COUNT(*) AS number_of_rows
  FROM Employees

UNION ALL

SELECT 'Offices' AS table_name,
       (SELECT COUNT(*) FROM pragma_table_info('offices')) AS number_of_attributes,
       COUNT(*) AS number_of_rows
  FROM offices;
  
/* Setting up a CTE to call a list of 10 items that are currently low in stock.
This CTE provides the product code, name, and the stock represented as a percentage of the amount ordered.
This CTE joins the product information from the Order Details table with the products table to retrieve the current stock and quantity originally ordered. */

WITH low_stock_items AS
     (SELECT p.productCode,
             p.productName,
             ROUND(SUM(od.quantityOrdered)*1.0/p.quantityInStock,2) AS low_stock
        FROM orderdetails AS od
        JOIN products AS p
          ON od.productCode = p.productCode
    GROUP BY p.productCode
    ORDER BY low_stock DESC
       LIMIT 10
),

/* Setting up a CTE to call a list of 10 items that are top performers, meaning they pring in the most revenue.
This CTE provides the product code, name, and the performance calculated as quantity sold multiplied by selling price.
This CTE joins the product information from the Order Details table with the products table to retrieve the number of orders and selling price for each. */

      top_performers AS
      (SELECT p.productCode,
              p.productName,
              SUM(od.quantityOrdered*od.priceEach) AS product_performance
         FROM orderdetails AS od
         JOIN products AS p
           ON od.productCode = p.productCode
     GROUP BY p.productCode
     ORDER BY product_performance DESC
        LIMIT 10
)

/* Creating a query that pulls the product code, name, product line, and sales performance for high performing items that also need to be restocked soon.
This pulls the relevant measures from the order details and product tables, and uses the low_stock_items CTE to qualify which items need to be replenished.
Results are limited to the top 10 items. 
 */

SELECT p.productCode,
       p.productName,
       p.productLine,
       SUM(od.quantityOrdered*od.priceEach) AS product_performance
  FROM orderdetails AS od
  JOIN products AS p
    ON od.productCode = p.productCode
 WHERE p.productCode IN (SELECT productCode FROM low_stock_items)
 GROUP BY p.productCode
 ORDER BY product_performance DESC
 LIMIT 10
 
/* We need to identify the customers that bring in the most profit, and customers that bring in the least profit.
For both customer sets, we will create a CTE that joins customer information with their purchasing history and limit each to the top/bottom five spenders. */

WITH customer_profit_table AS (
SELECT o.customerNumber,
       SUM(od.quantityOrdered*(od.priceEach-p.buyPrice)) AS customer_profit
  FROM orders o
 INNER JOIN orderdetails od
    ON o.orderNumber = od.orderNumber
 INNER JOIN products p
    ON od.productCode = p.productCode
 GROUP BY o.customerNumber
 ORDER BY customer_profit DESC
)

/* Running a query to provide us customer information, and joining it on our customer_profit CTE to see how much each customer has purchased.
From there, the query orders the profit in descending order and limits the table to the TOP five customers */
 
SELECT c.contactLastName,
       c.contactFirstName,
       c.city,
       c.country,
       cpt.customer_profit
  FROM customers AS c
  JOIN customer_profit_table AS cpt
    ON c.customerNumber = cpt.customerNumber
 ORDER BY cpt.customer_profit DESC
 LIMIT 5

/* We need to identify the customers that bring in the most profit, and customers that bring in the least profit.
For both customer sets, we will create a CTE that joins customer information with their purchasing history and limit each to the top/bottom five spenders. */

WITH customer_profit_table AS (
SELECT o.customerNumber,
       SUM(od.quantityOrdered*(od.priceEach-p.buyPrice)) AS customer_profit
  FROM orders o
 INNER JOIN orderdetails od
    ON o.orderNumber = od.orderNumber
 INNER JOIN products p
    ON od.productCode = p.productCode
 GROUP BY o.customerNumber
 ORDER BY customer_profit DESC
)

/* Running a query to provide us customer information, and joining it on our customer_profit CTE to see how much each customer has purchased.
From there, the query orders the profit in descending order and limits the table to the BOTOM five customers */

SELECT c.contactLastName,
       c.contactFirstName,
       c.city,
       c.country,
       cpt.customer_profit
  FROM customers AS c
  JOIN customer_profit_table AS cpt
    ON c.customerNumber = cpt.customerNumber
 ORDER BY cpt.customer_profit
 LIMIT 5

/* We would also like to find the total and average lifetime value of our customers.
For this, we will use the same customer_profit CTE and set up the accompanying query to return the sum and average profit across all of the customers represented in the dataset. */

WITH customer_profit_table AS (
SELECT o.customerNumber,
       SUM(od.quantityOrdered*(od.priceEach-p.buyPrice)) AS customer_profit
  FROM orders o
 INNER JOIN orderdetails od
    ON o.orderNumber = od.orderNumber
 INNER JOIN products p
    ON od.productCode = p.productCode
 GROUP BY o.customerNumber
 ORDER BY customer_profit DESC
)

SELECT 
       SUM(cpt.customer_profit),
       AVG(cpt.customer_profit)
  FROM customer_profit_table AS cpt
 ORDER BY cpt.customer_profit