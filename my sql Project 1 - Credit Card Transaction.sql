-- SQL porfolio project.
use sample_db;
-- write 4-6 queries to explore the dataset and put your findings 
select* from credit_card_transcations as cct;
-- 1. Basic Overview
SELECT * FROM credit_card_transcations LIMIT 10;

-- 2. Descriptive Statistics
SELECT 
  AVG(amount) AS average_amount,
  MEDIAN(amount) AS median_amount,
  STDDEV(amount) AS amount_std_dev
FROM credit_card_transcations;

-- 3. Time-based Analysis
SELECT 
  DATE_FORMAT(transaction_date, '%Y-%m') AS month,
  SUM(amount) AS total_amount
FROM credit_card_transcations
GROUP BY month;

-- 4. Fraud Detection
SELECT * 
FROM credit_card_transcations
WHERE amount > 1000;

-- 5. Customer Spending Behavior
SELECT 
  card_type,
  COUNT(*) AS transaction_count,
  SUM(amount) AS total_amount
FROM credit_card_transcations
GROUP BY card_type
ORDER BY total_amount DESC
LIMIT 10;

-- 6. City Analysis
SELECT 
  city,
  SUM(amount) AS total_amount
FROM credit_card_transcations
GROUP BY city
ORDER BY total_amount DESC
LIMIT 5;


-- solve below questions
-- 1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

SELECT 
  city,
  SUM(amount) AS total_spends,
  (SUM(amount) / (SELECT SUM(amount) FROM credit_card_transcations)) * 100 AS percentage_contribution
FROM credit_card_transcations
GROUP BY city
ORDER BY total_spends DESC
LIMIT 5;

-- 2- write a query to print highest spend month and amount spent in that month for each card type

SELECT 
  card_type,
  DATE_FORMAT(transaction_date, '%Y-%m') AS spending_month,
  SUM(amount) AS total_spends
FROM credit_card_transcations
GROUP BY card_type, spending_month
ORDER BY spending_month;

SELECT 
  card_type,
  DATE_FORMAT(transaction_date, '%Y-%m') AS spending_month,
  SUM(amount) AS total_spends
FROM credit_card_transcations
GROUP BY card_type, spending_month
HAVING total_spends = (
  SELECT MAX(total_spends)
  FROM (
    SELECT 
      card_type,
      DATE_FORMAT(transaction_date, '%Y-%m') AS spending_month,
      SUM(amount) AS total_spends
    FROM credit_card_transcations
    GROUP BY card_type, spending_month
  ) AS monthly_totals
  WHERE monthly_totals.card_type = credit_card_transcations.card_type
);

-- 3- write a query to print the transaction details(all columns from the table) for each card type when
	-- it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

WITH CumulativeSpending AS (
  SELECT 
    *,
    SUM(amount) OVER (PARTITION BY card_type ORDER BY transaction_date) AS cumulative_spending
  FROM credit_card_transcations
)

SELECT *
FROM CumulativeSpending
WHERE cumulative_spending >= 1000000;

-- 4- write a query to find city which had lowest percentage spend for gold card type
SELECT 
     city,
  card_type,
  SUM(amount) AS total_spends,
  (SUM(CASE WHEN card_type = 'gold' THEN amount ELSE 0 END) / (SELECT SUM(amount)  FROM credit_card_transcations )) * 100 AS percentage_contribution
FROM credit_card_transcations
GROUP BY card_type,city
HAVING card_type= "gold"
ORDER BY percentage_contribution ASC
LIMIT 1;

WITH CardTypeSpending AS (
  SELECT 
    city,
    SUM(CASE WHEN card_type = 'gold' THEN amount ELSE 0 END) AS gold_spending,
    SUM(amount) AS total_spending
  FROM credit_card_transcations
  GROUP BY city
)

SELECT 
  city,
  gold_spending,
  total_spending,
  (gold_spending / total_spending) * 100 AS percentage_gold_spend
FROM CardTypeSpending
ORDER BY percentage_gold_spend
LIMIT 1;


-- 5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
SELECT  city, MAX(exp_type) AS highest_expense_type, MIN(exp_type) AS lowest_expense_type
FROM credit_card_transcations
GROUP BY city, exp_type;

WITH ExpenseTypes AS (
  SELECT 
    city,
    card_type,
    SUM(amount) AS total_spending
  FROM credit_card_transcations
  GROUP BY city, card_type
)

SELECT 
  city,
  MAX(CASE WHEN total_spending = max_spending THEN card_type END) AS highest_expense_type,
  MAX(CASE WHEN total_spending = min_spending THEN card_type END) AS lowest_expense_type
FROM (
  SELECT 
    city,
    card_type,
    total_spending,
    MAX(total_spending) OVER (PARTITION BY city) AS max_spending,
    MIN(total_spending) OVER (PARTITION BY city) AS min_spending
  FROM ExpenseTypes
) AS with_extremes
GROUP BY city;



-- 6- write a query to find percentage contribution of spends by females for each expense type

SELECT 
  exp_type,
  SUM(CASE WHEN gender = "F" THEN amount ELSE 0 END) AS female_spending,
  SUM(amount) AS total_spending,
  (SUM(CASE WHEN gender = "F" THEN amount ELSE 0 END) / SUM(amount)) * 100 AS percentage_contribution
FROM credit_card_transcations
GROUP BY exp_type;


  
  
-- 7- which card and expense type combination saw highest month over month growth in Jan-2014

WITH MonthlySpending AS (
  SELECT 
    card_type,
    exp_type,
    SUM(amount) AS total_spending
  FROM credit_card_transcations
  WHERE DATE_FORMAT(transaction_date, '%Y-%m') = '2014-01'
  GROUP BY card_type, exp_type
)

SELECT 
  card_type,
  exp_type,
  total_spending
FROM MonthlySpending
ORDER BY total_spending DESC
LIMIT 1;


-- 8- during weekends which city has highest total spend to total no of transcations ratio 

WITH WeekendSpending AS (
  SELECT 
    city,
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_spend
  FROM credit_card_transcations
  WHERE DAYOFWEEK(transaction_date) IN (1, 7) -- Assuming 1 is Sunday and 7 is Saturday
  GROUP BY city
)

SELECT 
  city,
  total_transactions,
  total_spend,
  total_spend / total_transactions AS spend_per_transaction_ratio
FROM WeekendSpending
ORDER BY spend_per_transaction_ratio DESC
LIMIT 1;

-- 9- which city took least number of days to reach its 500th transaction after the first transaction in that city

WITH CityTransactionDays AS (
  SELECT 
    city,
    MIN(transaction_date) AS first_transaction_date,
    COUNT(*) AS total_transactions,
    DATEDIFF(MIN(transaction_date), MAX(transaction_date)) AS days_to_500th_transaction
  FROM credit_card_transcations
  GROUP BY city
  HAVING COUNT(*) >= 500
)

SELECT 
  city,
  days_to_500th_transaction
FROM CityTransactionDays
ORDER BY days_to_500th_transaction
LIMIT 1;
