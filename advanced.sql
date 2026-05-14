--1--CTE
with clean_data as(
	select 
		InvoiceDate_F,
        (quantity_F * UnitPrice_F) AS row_total
from Fact_salse as f
inner join Dim_Products as p
		on f.StockCode_DP_F = p.StockCode_DP_F
where f.quantity_F > 0 
and f.UnitPrice_F> 0
and P.Description_DP not in (
    'DAMAGES', 'FAULTY', 'WRONGLY MARKED CARTON 22804', 
    'MAILOUT', 'POSTAGE', 'DOTCOM POSTAGE', 'CRUK Commission',
    'WEBSITE FIXED', 'FOR ONLINE RETAIL ORDERS',
	'ALLOCATE STOCK FOR DOTCOM ORDERS TA'
  )
  and P.Description_DP not like '%ADJUST%'
  and P.Description_DP not like '%STOCK%'
)
select
	year(InvoiceDate_F) AS sales_year,
	MONTH(InvoiceDate_F) AS sales_month,
    SUM(row_total) AS Total_sales
from clean_data
group by year(InvoiceDate_F),MONTH(InvoiceDate_F)
order by sales_year,sales_month;




--2-- CTE + LAG + Growth Rate
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




-- 4--CTE + Identify top three products in each country
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

--أغلى 10 عمليات بيع منفردة
select top 10 
	Description_DP,rowtotal
from v_cleanData
order by rowtotal desc;


-- في عدد سطور اقل و اسرع  joinو كدا نقدر نكتب الاكواد بتاع 
--view مثلا :اعلى 10 منتجات من حيث المبيعات باستخدام ال  <<<---
select top 10 
	Description_DP,sum(rowtotal) as totalSales
from v_cleanData
group by Description_DP
order by totalSales desc;



--6-- Window Function مع  CTE ب ال  view  ربط ال 
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

---- شوف الفرق بين التالي و السابق و شاهد الفرق
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
-- الفواتير اللي تخطت المتوسط
select 
	InvoiceNo_F,rowtotal
from v_cleanData
where rowtotal > (select avg(rowtotal) from v_cleanData );

--8-- تقسيم الفواتير لفئات 
with avgvalue as(
	select 
	InvoiceNo_F,rowtotal
from v_cleanData
where rowtotal > (select avg(rowtotal) from v_cleanData )
)
select *,ntile(4) over(order by rowtotal desc) as sales_cat
from avgvalue;
--9-- (اجمالي مبيعات (الفئة 1
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



--10-- whereمع  havingاستخدام 
-- الدول التي تجاوزت مبيعاتها 50 ألف دولار مع استبعاد المعاملات الأقل من 100 دولار
select 
	c.country_DC,
	sum(f.quantity_F * f.UnitPrice_F) as totalSales
from Fact_salse f
inner join Dim_Customers c
	on f.Customerid_DC_F = c.Customerid_DC_F
where (f.quantity_F * f.UnitPrice_F) > 100
group by c.country_DC
having sum(f.quantity_F * f.UnitPrice_F) > 50000;


--11--   و اضافة اعمدة اخرىviewتعديل ال 
alter view dbo.v_cleanData as
	select 
	f.InvoiceNo_F,
	f.InvoiceDate_F,
	p.Description_DP,
	f.Customerid_DC_F,
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
