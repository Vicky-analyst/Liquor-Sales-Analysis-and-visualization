USE liquor_sales;


# EXPLORING THE DATA SET
DESCRIBE iowa_liquor_sales;

-- checking for null values
SELECT *
FROM iowa_liquor_sales  
WHERE county IS NULL
 OR store_name IS NULL
 OR category_name is null;

# DATA CLEANING
ALTER TABLE iowa_liquor_sales -- changing column name
CHANGE COLUMN `ï»¿invoice_and_item_number`  invoice_and_item_number varchar(255);

ALTER TABLE iowa_liquor_sales
RENAME COLUMN sale_dollars TO sales;

UPDATE iowa_liquor_sales
SET date = str_to_date(date, '%m/%d/%Y');-- changing data type
ALTER TABLE iowa_liquor_sales
MODIFY COLUMN date DATE;

-- cleaning store_name irregularities
SELECT 
    store_name, 
    SUBSTRING_INDEX(store_name, '/', 1) AS store_name_clean
FROM iowa_liquor_sales;

ALTER Table iowa_liquor_sales
ADD store_name_clean varchar(100);

UPDATE iowa_liquor_sales
SET store_name_clean = SUBSTRING_INDEX(store_name, '/', 1);

Alter Table iowa_liquor_sales
ADD store_name_clean_2 varchar(100);

UPDATE iowa_liquor_sales
SET store_name_clean_2 = TRIM(REGEXP_REPLACE(store_name_clean, '(# ?[0-9]+)', ''));

Alter TABLE iowa_liquor_sales
ADD store_name_clean_3 varchar(100);

UPDATE iowa_liquor_sales
SET store_name_clean_3 = TRIM(
    REGEXP_REPLACE(store_name_clean_2, '[ ]?[A-Za-z-]*[0-9]+|[0-9]+[A-Za-z]*|[0-9]+', ''));

SELECT store_name_clean_2,
TRIM(
    REGEXP_REPLACE(store_name_clean_2, '[ ]?[A-Za-z-]*[0-9]+|[0-9]+[A-Za-z]*|[0-9]+', '')
)AS store_name_clean_3
from iowa_liquor_sales;

SELECT store_name_clean_3,
SUBSTRING_INDEX(store_name_clean_3, " -", 1) AS Store_name_clean_4
FROM iowa_liquor_sales;

Alter TABLE iowa_liquor_sales
ADD store_name_clean_4 varchar(100);

UPDATE iowa_liquor_sales
SET store_name_clean_4 = SUBSTRING_INDEX(store_name_clean_3, " -", 1);

SELECT *
FROM iowa_liquor_sales
WHERE store_name_clean_4 = '';

UPDATE iowa_liquor_sales
SET store_name_clean_4 = "Leo1"
WHERE store_name_clean_4 = '';

UPDATE iowa_liquor_sales
SET store_name_clean_4 = REPLACE(store_name_clean_4, 'and', '&')
WHERE store_name_clean_4 like '%and%';

ALTER TABLE iowa_liquor_sales
DROP COLUMN store_name;

ALTER TABLE iowa_liquor_sales
DROP COLUMN store_name_clean;

ALTER TABLE iowa_liquor_sales
DROP COLUMN store_name_clean_2;

ALTER TABLE iowa_liquor_sales
DROP COLUMN store_name_clean_3;

ALTER TABLE iowa_liquor_sales -- droping column
DROP COLUMN invalid_county_number;

ALTER TABLE iowa_liquor_sales
DROP COLUMN store_location;

ALTER TABLE iowa_liquor_sales
RENAME COLUMN store_name_clean_4 TO store_name

# DATA ANALYSIS
-- what is the total sales/profit/bottle sold/customer/orders/ made over time
SELECT Total_Sales,
	   COGS,
	   Total_Profit,
       Total_Bottle_Sold,
       Total_Orders
FROM (SELECT concat(round(sum(state_bottle_retail * bottles_sold)/1000000,2), 'M') AS Total_Sales,
			 concat(round(sum(state_bottle_cost * bottles_sold)/1000000,2), 'M') AS COGS,
			 concat(round((sum(sales) - (sum(state_bottle_cost * bottles_sold)))/1000000,2),'M') AS Total_Profit,
             concat(sum(bottles_sold)/1000000,'M') AS Total_Bottle_Sold,
             concat(round(count(invoice_and_item_number)/1000000,2), 'M') AS Total_Orders
	  FROM iowa_liquor_sales) AS summary;
      
-- what is the total sales/profit/bottle sold/customer/orders per month #(month Feb,2021)
SELECT total_sales,
	   cogs,
       total_profit,
       total_bottle_sold,
       total_orders
FROM (SELECT concat(round(sum(state_bottle_retail * bottles_sold)/1000000,2), 'M') AS Total_Sales,
			 concat(round(sum(state_bottle_cost * bottles_sold)/1000000,2), 'M') AS COGS,
			 concat(round((sum(state_bottle_retail * bottles_sold) - (sum(state_bottle_cost * bottles_sold)))/1000000,2),'M') AS Total_Profit,
             concat(sum(bottles_sold)/1000000,'M') AS Total_Bottle_Sold,
             concat(round(count(invoice_and_item_number)/1000000,2), 'M') AS Total_Orders
	  FROM iowa_liquor_sales 
	  WHERE MONTH(date)= 2 AND YEAR(date) = 2021) AS summary; -- Feb month

-- what is the MOM increase in sales
SELECT MONTH(date) as month, 
	concat(round(sum(state_bottle_retail * bottles_sold)/1000000,2), 'M') as total_sales,
    round((sum(state_bottle_retail * bottles_sold) - lag(sum(state_bottle_retail * bottles_sold),1,0) 
    over(order by month(date))) / lag(sum(state_bottle_retail * bottles_sold),1,0) 
    over(order by month(date)) * 100,2) AS MOM_increase_percent
FROM iowa_liquor_sales
WHERE MONTH(date) in (6,7) AND YEAR(date) = 2021 -- Jun and Jul 2021
GROUP BY MONTH(date)
ORDER BY MONTH(date);

-- what is the MOM increase and decrease in profit
SELECT MONTH(date) as month, 
	concat(
		   round(
				  (sum(state_bottle_retail * bottles_sold) - (sum(state_bottle_cost * bottles_sold)))/1000000,2),'M') as total_profit,
    round(

		   ((sum(state_bottle_retail * bottles_sold) - (sum(state_bottle_cost * bottles_sold))) - lag(sum(state_bottle_retail * bottles_sold) - (sum(state_bottle_cost * bottles_sold)),1,0) 
			over(order by month(date))) / lag(sum(state_bottle_retail * bottles_sold) - (sum(state_bottle_cost * bottles_sold)),1,0) 
			over(order by month(date)) * 100,2) AS MOM_increase_percent
FROM iowa_liquor_sales
WHERE MONTH(date) in (6,7) AND YEAR(date) = 2021
GROUP BY MONTH(date)
ORDER BY MONTH(date);

-- what is the month to month increase in bottle sold
SELECT MONTH(date) as month, 
	concat(round(sum(bottles_sold)/1000000,2), 'M') as total_bottle_sold,
    round((sum(bottles_sold) - lag(sum(bottles_sold),1,0) 
    over(order by month(date))) / lag(sum(bottles_sold),1,0) 
    over(order by month(date)) * 100,2) AS MOM_increase_percent
FROM iowa_liquor_sales
WHERE MONTH(date) in (4,5) AND YEAR(date) = 2021
GROUP BY MONTH(date)
ORDER BY MONTH(date);

-- what is the month to month increase in orders
SELECT MONTH(date) as month, 
	concat(round(count(invoice_and_item_number)/1000000,2), 'M') as total_orders,
    round((count(invoice_and_item_number) - lag(count(invoice_and_item_number),1,0) 
    over(order by month(date))) / lag(count(invoice_and_item_number),1,0) 
    over(order by month(date)) * 100,2) AS MOM_increase_percent
FROM iowa_liquor_sales
WHERE MONTH(date) in (4,5) AND YEAR(date) = 2021
GROUP BY MONTH(date)
ORDER BY MONTH(date);

-- What is the top 10 stores and which store generate the highest sales per month
SELECT store_name,
		CASE
           WHEN Total_sales > 1000000 THEN concat(round(Total_sales / 1000000, 2), 'M') 
           ELSE concat(round(Total_sales / 1000, 2), 'k')
       END AS sales_div
FROM (SELECT store_name, 
		sum(state_bottle_retail * bottles_sold) AS Total_sales
	  FROM iowa_liquor_sales
	  WHERE MONTH(date)= 9 AND YEAR(date) = 2021 -- june 2021 
	  GROUP BY store_name) as sales_in_store
ORDER BY  Total_sales DESC 
LIMIT 10;

-- What is the Bottom 10 stores and which store generate the lowest sales per month
SELECT store_name,
		CASE
           WHEN Total_sales > 1000000 THEN concat(round(Total_sales / 1000000, 2), 'M') 
           ELSE concat(round(Total_sales / 1000, 2), 'k')
       END AS sales_div
FROM (SELECT store_name, 
		sum(state_bottle_retail * bottles_sold) AS Total_sales
	  FROM iowa_liquor_sales
	  WHERE MONTH(date)= 9 AND YEAR(date) = 2021 -- june 2021 
	  GROUP BY store_name) as sales_in_store
ORDER BY  Total_sales 
LIMIT 10;

-- what is the top 10 county by sales
SELECT county,
	  CASE
           WHEN total_sales > 1000000 THEN concat(round(total_sales / 1000000, 1), 'M') 
           ELSE concat(round(total_sales / 1000, 1), 'k')
       END AS sales_div
FROM (SELECT county,
			   sum(state_bottle_retail * bottles_sold) AS total_sales
		FROM iowa_liquor_sales
	    WHERE MONTH(date) = 4 AND YEAR(date) = 2021
	    GROUP BY county) AS summary
ORDER BY total_sales DESC
limit 10;

-- what is the bottom 10 county by sales
SELECT county,
	  CASE
           WHEN total_sales > 1000000 THEN concat(round(total_sales / 1000000, 1), 'M') 
           ELSE concat(round(total_sales / 1000, 1), 'k')
       END AS sales_div
FROM (SELECT county,
			   sum(state_bottle_retail * bottles_sold) AS total_sales
		FROM iowa_liquor_sales
	    WHERE MONTH(date) = 4 AND YEAR(date) = 2021
	    GROUP BY county) AS summary
ORDER BY total_sales
limit 10;

-- what is the impact or contribution of top 10 county to total sales
SELECT concat(round(sum(total_sales)/ 1000000, 1), 'M') AS Top_10_total_sales
FROM (SELECT county,
			   sum(state_bottle_retail * bottles_sold) AS total_sales
		FROM iowa_liquor_sales
	    WHERE MONTH(date) = 4 AND YEAR(date) = 2021 -- April 2021
	    GROUP BY county
		ORDER BY total_sales DESC
		limit 10) AS summary;

-- top 10 selling product category
SELECT category_name,
		CASE
			WHEN total_sales > 1000000 THEN concat(round(total_sales/1000000,1),'M')
            ELSE concat(round(total_sales/1000,1),'K')
		END AS parameter_for_sales
FROM (SELECT category_name,
	   round(sum(state_bottle_retail * bottles_sold),1) AS total_sales
	FROM iowa_liquor_sales
	WHERE MONTH(date) = 6 AND YEAR(date) = 2021
	GROUP BY category_name) AS category_sales
ORDER BY total_sales DESC
LIMIT 10;

-- what is the impact or conrtibution of top 10 product to total sales
SELECT concat(round(sum(total_sales)/1000000,1),'M')
FROM (SELECT category_name,
	   round(sum(state_bottle_retail * bottles_sold),1) AS total_sales
	FROM iowa_liquor_sales
	WHERE MONTH(date) = 6 AND YEAR(date) = 2021
	GROUP BY category_name
	ORDER BY total_sales DESC
	LIMIT 10) AS category_sales;

-- Bottom 10 selling product category
SELECT category_name,
		CASE
			WHEN total_sales > 1000000 THEN concat(round(total_sales/1000000,1),'M')
            ELSE concat(round(total_sales/1000,1),'K')
		END AS parameter_for_sales
FROM (SELECT category_name,
	   round(sum(state_bottle_retail * bottles_sold),1) AS total_sales
	FROM iowa_liquor_sales
	WHERE MONTH(date) = 6 AND YEAR(date) = 2021
	GROUP BY category_name) AS category_sales
ORDER BY total_sales
LIMIT 10;

-- what is the avg  bottle volume sold per product base on top 10 product
SELECT category_name,
        round(avg_vol,1) AS avg_vol_sold
FROM (SELECT category_name,
	   round(sum(state_bottle_retail * bottles_sold),1) AS total_sales,
       avg(bottle_volume_ml) AS avg_vol
	FROM iowa_liquor_sales
	WHERE MONTH(date) = 6 AND YEAR(date) = 2021 -- june 2021
	GROUP BY category_name) AS category_sales
ORDER BY total_sales DESC
LIMIT 10;

-- what is the avg  bottle volume sold per product base on bottom 10 product
SELECT category_name,
        round(avg_vol,1) AS avg_vol_sold
FROM (SELECT category_name,
	   round(sum(state_bottle_retail * bottles_sold),1) AS total_sales,
       avg(bottle_volume_ml) AS avg_vol
	FROM iowa_liquor_sales
	WHERE MONTH(date) = 6 AND YEAR(date) = 2021 -- june 2021
	GROUP BY category_name) AS category_sales
ORDER BY total_sales
LIMIT 10;

-- total bottle sold, total sales, total orders per each top 10 product
SELECT category_name,
       total_bottle_sold,
       total_sales,
       total_orders
FROM (SELECT category_name,
			 concat(round(sum(state_bottle_retail * bottles_sold)/1000000,1), "M") AS total_sales,
             sum(bottles_sold) AS total_bottle_sold,
             count(*) AS total_orders
	  FROM iowa_liquor_sales
      WHERE MONTH(date) = 5 AND YEAR(date) = 2021
      GROUP BY category_name) AS category_sales
ORDER BY total_sales DESC
LIMIT 10;

-- total bottle sold, total sales, total orders per each bottom 10 product
SELECT category_name,
       total_bottle_sold,
       total_sales,
       total_orders
FROM (SELECT category_name,
			 round(sum(state_bottle_retail * bottles_sold),1) AS total_sales,
             sum(bottles_sold) AS total_bottle_sold,
             count(*) AS total_orders
	  FROM iowa_liquor_sales
      WHERE MONTH(date) = 5 AND YEAR(date) = 2021
      GROUP BY category_name) AS category_sales
ORDER BY total_sales
LIMIT 10;

-- what is the major top 5 Vendor per each top 10 product 
SELECT
	vendor_name,
    total_bottle_sold,
    total_sales
FROM (SELECT vendor_name,
			sum(bottles_sold) as total_bottle_sold,
            round(sum(sales),2) AS total_sales
	  FROM iowa_liquor_sales
	  WHERE MONTH(date) = 5 AND YEAR(date) = 2021 AND category_name = 'American Vodkas'
	  GROUP BY vendor_name) AS supply_under_american_vodkas
ORDER BY total_bottle_sold DESC
Limit 5;

-- What is the sales| bottle sold |orders chart flow by weekdays
SELECT Week_day,
	   total_sales,
       total_bottle_sold,
       total_orders
FROM(SELECT CASE
				WHEN DAYOFWEEK(date) = 2 THEN 'Monday'
				WHEN DAYOFWEEK(date) = 3 THEN 'Tuesday'
				WHEN DAYOFWEEK(date) = 4 THEN 'Wednesday'
				WHEN DAYOFWEEK(date) = 5 THEN 'Thursday'
				WHEN DAYOFWEEK(date) = 6 THEN 'Friday'
				WHEN DAYOFWEEK(date) = 7 THEN 'Saturday'
				ELSE 'Sunday'
			END AS Week_day,
			round(sum(state_bottle_retail * bottles_sold),2) AS total_sales,
            sum(bottles_sold) AS total_bottle_sold,
            count(invoice_and_item_number) AS total_orders
	FROM iowa_liquor_sales
	WHERE MONTH(date) = 3 AND YEAR(date) = 2021
	GROUP BY CASE
				WHEN DAYOFWEEK(date) = 2 THEN 'Monday'
				WHEN DAYOFWEEK(date) = 3 THEN 'Tuesday'
				WHEN DAYOFWEEK(date) = 4 THEN 'Wednesday'
				WHEN DAYOFWEEK(date) = 5 THEN 'Thursday'
				WHEN DAYOFWEEK(date) = 6 THEN 'Friday'
				WHEN DAYOFWEEK(date) = 7 THEN 'Saturday'
				ELSE 'Sunday'
			END ) AS week_flow;

-- What is the sales| bottle sold |orders chart flow by day
SELECT DAYOFMONTH(date) AS day,
	   round(sum(state_bottle_retail * bottles_sold),2) AS total_sales,
	   sum(bottles_sold) AS total_bottle_sold,
	   count(invoice_and_item_number) AS total_orders
FROM iowa_liquor_sales
WHERE MONTH(date) = 3 AND YEAR(date) = 2021
GROUP BY DAYOFMONTH(date) 
ORDER BY DAYOFMONTH(date); 


