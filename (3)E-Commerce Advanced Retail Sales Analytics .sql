--===============================================================================
--PROJECT NAME        : Advanced Retail Sales Analytics (E-Commerce)
--AUTHOR              : Abdullah Nasef
--DESCRIPTION:
--    This comprehensive script performs advanced Business Intelligence (BI) 
--    analysis on cleaned e-commerce data. It aims to transform raw transactional 
--    records into actionable insights through:
    
--    1. TIME ANALYSIS      : Monthly Growth Rates (MoM) and Year-over-Year trends.
--    2. MARKET RANKING     : Top Product identification per Country using Dense Ranking.
--    3. DATA SEGMENTATION  : Customer and Transaction quartiles using NTILE functions.
--    4. VIEW OPTIMIZATION  : Encapsulating complex business logic into efficient SQL Views.
--    5. PERFORMANCE AUDIT  : Evaluating high-value transactions and geographic performance.
--===============================================================================
--SECTION 1: Advanced Time Analysis(Growth & Trends) 
--===============================================================================
-- CTE + LAG + Growth Rate
--  Monthly Revenue Growth Rate (Using CTE & Window Functions)
-- Logic: Uses LAG() to compare current month sales vs previous month to calculate MoM % growth.
with monthlySales as(
	select
	year(f.InvoiceDate_F) as sales_year,
	month(f.InvoiceDate_F) as sales_month,
	sum(f.quantity_F * f.UnitPrice_F) as monthly_sales_current
from Fact_salse as f
inner join Dim_Products as p
		on f.StockCode_DP_F = p.StockCode_DP_F
where f.quantity_F > 0 
and f.UnitPrice_F> 0
and P.Description_DP not in (
    'DAMAGES', 'FAULTY', 'WRONGLY MARKED CARTON 22804', 
    'MAILOUT', 'POSTAGE', 'DOTCOM POSTAGE', 'CRUK Commission',
    'WEBSITE FIXED', 'FOR ONLINE RETAIL ORDERS',
	'ALLOCATE STOCK FOR DOTCOM ORDERS TA')
group by year(f.InvoiceDate_F) , month(f.InvoiceDate_F)

)
select 
	sales_year,sales_month,monthly_sales_current,
	lag(monthly_sales_current) over (order by sales_year,sales_month ) as monthly_sales_previous,

	format(((monthly_sales_current - lag(monthly_sales_current) over (order by sales_year,sales_month )) 
	/ lag(monthly_sales_current) over (order by sales_year,sales_month )),'p') as growth_percentage
from monthlySales
order by sales_year,sales_month;




--3-- CTE + LAG + Growth Rate for specific product (EX. TOP 20)
--  Specific Product Growth
-- Target: Analyzing the monthly sales trend for the top-selling product.
with ProductMonthlySales as(
	select
	p.Description_DP,
	year(f.InvoiceDate_F) as sales_year,
	month(f.InvoiceDate_F) as sales_month,
	sum(f.quantity_F * f.UnitPrice_F) as monthly_sales_current
from Fact_salse as f
inner join Dim_Products as p
		on f.StockCode_DP_F = p.StockCode_DP_F
where f.quantity_F > 0 
	and f.UnitPrice_F> 0
	and p.Description_DP = 'REGENCY CAKESTAND 3 TIER'
group by year(f.InvoiceDate_F) , month(f.InvoiceDate_F),p.Description_DP

)
select 
	sales_year,sales_month,Description_DP,monthly_sales_current,
	lag(monthly_sales_current) over (order by sales_year,sales_month ) as monthly_sales_previous,

	format(((monthly_sales_current - lag(monthly_sales_current) over (order by sales_year,sales_month )) 
	/ lag(monthly_sales_current) over (order by sales_year,sales_month )),'p') as growth_percentage
from ProductMonthlySales
order by sales_year,sales_month;


--===============================================================================
--SECTION 2: MARKET SHARE & RANKING (Ranking Products by Geography)
--===============================================================================

-- 4--CTE + Identify top three products in each country
-- Identify Top 3 Products Per Country (Using DENSE_RANK)
-- Target: Discover regional preferences by ranking products based on revenue within each country.
WITH 
ProductSalesByCountry AS (
    SELECT 
        c.country_DC,
        p.Description_DP,
        SUM(f.quantity_F * f.UnitPrice_F) AS Total_Sales
    FROM Fact_salse AS f
    INNER JOIN Dim_Customers AS c ON f.Customerid_DC_F = c.Customerid_DC_F
    INNER JOIN Dim_Products AS p ON f.StockCode_DP_F = p.StockCode_DP_F
    WHERE f.quantity_F > 0 AND f.UnitPrice_F > 0
	and P.Description_DP not in (
    'DAMAGES', 'FAULTY', 'WRONGLY MARKED CARTON 22804', 
    'MAILOUT', 'POSTAGE', 'DOTCOM POSTAGE', 'CRUK Commission',
    'WEBSITE FIXED', 'FOR ONLINE RETAIL ORDERS',
	'ALLOCATE STOCK FOR DOTCOM ORDERS TA')
    GROUP BY c.country_DC, p.Description_DP
),
RankedProducts AS (
    SELECT 
        country_DC,
        Description_DP,
        Total_Sales,

        DENSE_RANK() OVER (PARTITION BY country_DC ORDER BY Total_Sales DESC) AS Product_Rank
    FROM ProductSalesByCountry
)

SELECT * FROM RankedProducts
WHERE Product_Rank <= 3
ORDER BY country_DC, Product_Rank;





--5-- view
--===============================================================================
--SECTION 3:  VIEW & DATA SEGMENTATION (NTILE & Subqueries)
--===============================================================================
create view v_cleanData as 
select 
	f.InvoiceNo_F,
	f.InvoiceDate_F,
	p.Description_DP,
	(f.quantity_F * f.UnitPrice_F) as rowtotal
from Fact_salse f
inner join Dim_Products p
	on f.StockCode_DP_F = p.StockCode_DP_F
WHERE f.quantity_F > 0 AND f.UnitPrice_F > 0
	and P.Description_DP not in (
    'DAMAGES', 'FAULTY', 'WRONGLY MARKED CARTON 22804', 
    'MAILOUT', 'POSTAGE', 'DOTCOM POSTAGE', 'CRUK Commission',
    'WEBSITE FIXED', 'FOR ONLINE RETAIL ORDERS',
	'ALLOCATE STOCK FOR DOTCOM ORDERS TA')
	 and P.Description_DP not like '%ADJUST%'
     and P.Description_DP not like '%STOCK%' ;
--And that way we can write the join code in fewer lines and faster.



-- For example: Top 10 products by sales using view
select top 10 
	Description_DP,sum(rowtotal) as totalSales
from v_cleanData
group by Description_DP
order by totalSales desc;

-- Top 10 Most Expensive Single Sales
select top 10 
	Description_DP,rowtotal
from v_cleanData
order by rowtotal desc;

--6-- Window Function with CTE with view
with monthelyRate as (
	select 
	year(InvoiceDate_F) as salse_year,
	month(InvoiceDate_F) as salse_month,
	sum(rowtotal) as monthelysum
	from v_cleanData
	group by year(InvoiceDate_F) , month(InvoiceDate_F)
)

select salse_year, salse_month,monthelysum,
	lag(monthelysum)over (order by salse_year, salse_month) as previes_month,
	format(((monthelysum - lag(monthelysum)over (order by salse_year, salse_month))/lag(monthelysum)over (order by salse_year, salse_month)), 'p') as growth_percentage
from monthelyRate;

---- without view
with monthlySales as(
	select
	year(f.InvoiceDate_F) as sales_year,
	month(f.InvoiceDate_F) as sales_month,
	sum(f.quantity_F * f.UnitPrice_F) as monthly_sales_current
from Fact_salse as f
inner join Dim_Products as p
		on f.StockCode_DP_F = p.StockCode_DP_F
where f.quantity_F > 0 
and f.UnitPrice_F> 0
and P.Description_DP not in (
    'DAMAGES', 'FAULTY', 'WRONGLY MARKED CARTON 22804', 
    'MAILOUT', 'POSTAGE', 'DOTCOM POSTAGE', 'CRUK Commission',
    'WEBSITE FIXED', 'FOR ONLINE RETAIL ORDERS',
	'ALLOCATE STOCK FOR DOTCOM ORDERS TA')
and P.Description_DP not like '%ADJUST%'
and P.Description_DP not like '%STOCK%' 
group by year(f.InvoiceDate_F) , month(f.InvoiceDate_F)

)
select 
	sales_year,sales_month,monthly_sales_current,
	lag(monthly_sales_current) over (order by sales_year,sales_month ) as monthly_sales_previous,

	format(((monthly_sales_current - lag(monthly_sales_current) over (order by sales_year,sales_month )) 
	/ lag(monthly_sales_current) over (order by sales_year,sales_month )),'p') as growth_percentage
from monthlySales
order by sales_year,sales_month;



--7--Subquery
-- Bills that exceeded the average
select 
	InvoiceNo_F,rowtotal
from v_cleanData
where rowtotal > (select avg(rowtotal) from v_cleanData );

--8-- Customer Segmentation (NTILE)
-- target : Dividing high-value transactions (above average) into 4 quartiles for tiered analysis.
with avgvalue as(
	select 
	InvoiceNo_F,rowtotal
from v_cleanData
where rowtotal > (select avg(rowtotal) from v_cleanData )
)
select *,ntile(4) over(order by rowtotal desc) as sales_cat
from avgvalue;
--9-- Total sales (Category 1)
with 
	avgvalue as(
		select 
		InvoiceNo_F,rowtotal
	from v_cleanData
	where rowtotal > (select avg(rowtotal) from v_cleanData )
	),
	Cat_Sales as(
	select rowtotal,ntile(4) over(order by rowtotal desc) as sales_cat
	from avgvalue
	)

select sum(rowtotal)
from Cat_Sales
where sales_cat = 1;


--===============================================================================
--SECTION 4: AGGREGATE FILTERS (WHERE vs HAVING)
--===============================================================================
--10-- useing where with having 
-- High-Value Markets Analysis
-- Filters raw rows > $100 and then filters aggregated countries > $50,000
select 
	c.country_DC,
	sum(f.quantity_F * f.UnitPrice_F) as totalSales
from Fact_salse f
inner join Dim_Customers c
	on f.Customerid_DC_F = c.Customerid_DC_F
where (f.quantity_F * f.UnitPrice_F) > 100
group by c.country_DC
having sum(f.quantity_F * f.UnitPrice_F) > 50000;


--11--   Edit view and add other columns
alter view dbo.v_cleanData as
	select 
	f.InvoiceNo_F,
	f.InvoiceDate_F,
	p.Description_DP,
	f.Customerid_DC_F,
	f.Quantity_F,      
    f.UnitPrice_F,
	c.country_DC,
	(f.quantity_F * f.UnitPrice_F) as rowtotal
from Fact_salse f
inner join Dim_Products p
	on f.StockCode_DP_F = p.StockCode_DP_F
inner join Dim_Customers c
		on f.Customerid_DC_F = c.Customerid_DC_F
WHERE f.quantity_F > 0 AND f.UnitPrice_F > 0
	and P.Description_DP not in (
    'DAMAGES', 'FAULTY', 'WRONGLY MARKED CARTON 22804', 
    'MAILOUT', 'POSTAGE', 'DOTCOM POSTAGE', 'CRUK Commission',
    'WEBSITE FIXED', 'FOR ONLINE RETAIL ORDERS',
	'ALLOCATE STOCK FOR DOTCOM ORDERS TA')
	 and P.Description_DP not like '%ADJUST%'
     and P.Description_DP not like '%STOCK%' ;
