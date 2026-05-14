
--نسخ البيانات النظيفة إلى جدول جديد 
select 
	InvoiceNo_cleand as InvoiceNo_F,
	StockCode_cleand as StockCode_DP_F,
	Description_cleand as Description_DP,
	quantity_numerical as quantity_F,
	InvoiceDate_cleann as InvoiceDate_F,
	UnitPrice_numerical as UnitPrice_F,
	CustomerID_cleand as Customerid_DC_F,
	countrycleand_new as country_DC
into Ecoomerce_cleaned
from [dataEcommerce_Cl]
where 
--مش عوزين اي سطر مبيعات مش مرتبط بمنتج حقيقي
	StockCode_cleand is not null
--	استبعاد أي عملية بيع مالهاش وصف واضح للمنتج
	and Description_cleand is not null;
	
--  لنتمكن من عمل داتا مودلينج(DP, DC, F) تقسيم الجداول الى 
--1 DP (Dimension Product)انشاء جدول ال
select distinct
	StockCode_DP_F,
	Description_DP
into Dim_Products
from Ecoomerce_cleaned;
--2 DC (Dimension Customer)انشاء جدول ال
select distinct
	Customerid_DC_F,
	country_DC
into Dim_Customers
from Ecoomerce_cleaned;
--3 F (Fact Sales)انشاء جدول ال
select 
	InvoiceNo_F,
	StockCode_DP_F,
	Customerid_DC_F,
	quantity_F,
	UnitPrice_F,
	InvoiceDate_F
into Fact_salse
from Ecoomerce_cleaned;

SELECT 
    F.InvoiceNo_F, 
    P.Description_DP,      -- اسم المنتج من جدول المنتجات
    C.country_DC,          -- دولة العميل من جدول العملاء
    F.quantity_F, 
    F.UnitPrice_F,
    (F.quantity_F * F.UnitPrice_F) AS TotalPrice -- حساب إجمالي السطر
FROM Fact_salse AS F
INNER JOIN Dim_Products AS P ON F.StockCode_DP_F = P.StockCode_DP_F
INNER JOIN Dim_Customers AS C ON F.Customerid_DC_F = C.Customerid_DC_F
ORDER BY TotalPrice DESC;
-- تحديد ال السعر الاجمالي لكل فاتورة في الجدول 
--استخدمت INNER JOIN  عشان تحدد فقط العمليات اللي فيها بيانات كاملة
select 
	f.InvoiceNo_f,
	p.Description_DP,
	c.country_DC,
	f.quantity_F,
	f.UnitPrice_F,
	(f.quantity_F * f.UnitPrice_F) as totalprice
from Fact_salse as f
inner join Dim_Products as p
		on f.StockCode_DP_F= p.StockCode_DP_F
inner join Dim_Customers as c
		on f.Customerid_DC_F= c.Customerid_DC_F
where f.quantity_F > 0  -- استبعدت المرتجعات
	and f.UnitPrice_F> 0 -- استبعدت الهدايا او العينات المفقودهااو اخطاء ادخال

order by totalprice desc;

--(1)Total Price تحليل عمود ال 
--1 تحديد أفضل 10 منتجات 
select top 15
	p.Description_DP,
	sum(f.quantity_F * f.UnitPrice_F) as Total_sales,
	sum(f.quantity_F) as Units_sold
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
group by p.Description_DP
order by Total_sales desc;
--2 تحددد أقل 10 منتجات 
select top 15
	p.Description_DP,
	sum(f.quantity_F * f.UnitPrice_F) as Total_sales,
	sum(f.quantity_F) as Units_sold
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
group by p.Description_DP
order by Total_sales asc;
--3 تحديد المبيعات حسب الدول
select 
	c.country_DC as country ,
	sum(f.quantity_F * f.UnitPrice_F) as Total_sales,
	count(distinct f.InvoiceNo_F) as total_orders
from Fact_salse as f
inner join Dim_Customers as c
		on f.Customerid_DC_F = c.Customerid_DC_F
inner join Dim_Products as p
		on f.StockCode_DP_F = p.StockCode_DP_F
where f.quantity_F > 0 
and f.UnitPrice_F> 0
-- الشروط التالية مستبعدة حتى لا تزود مبيعات الدول المحفوظة باسهما بارقام  وهمية 
and P.Description_DP not in (
    'DAMAGES', 'FAULTY', 'WRONGLY MARKED CARTON 22804', 
    'MAILOUT', 'POSTAGE', 'DOTCOM POSTAGE', 'CRUK Commission',
    'WEBSITE FIXED', 'FOR ONLINE RETAIL ORDERS',
	'ALLOCATE STOCK FOR DOTCOM ORDERS TA'
  )
  and P.Description_DP not like '%ADJUST%'
  and P.Description_DP not like '%STOCK%'

group by c.country_DC
order by Total_sales desc;
--4 (ع.20عميل)vip تحديد العملاء ال
select top 30
	f.Customerid_DC_F,
	c.country_DC,
	sum(f.quantity_F * f.UnitPrice_F) as custemer_spend
from Fact_salse as f
inner join Dim_Customers as c
		on f.Customerid_DC_F=c.Customerid_DC_F
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
group by f.Customerid_DC_F ,c.country_DC
order by custemer_spend desc;
--5 تحديد المبيعات حسب الشهر لتحديد فترات الصعود و الهبوط
select 
	year(f.InvoiceDate_F) as sales_year,
	month(f.InvoiceDate_F) as sales_month,
	-- اضفت عدد الايام عشان اعرف سبب نقصان مبيعات شهر 12 /2011
	count(distinct day(f.InvoiceDate_F)) as dayys_count, 
	sum(f.quantity_F * f.UnitPrice_F) as monthly_sales
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
group by year(InvoiceDate_F), month(f.InvoiceDate_F)
order by year(InvoiceDate_F), month(f.InvoiceDate_F);
