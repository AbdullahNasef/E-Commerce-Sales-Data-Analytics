--استكشاف البيانات01
--01
use nasef
select
top(100) *
from [dataEcommerce_Cl];
--02
select count(*) as totalrows
from dataEcommerce_Cl;
--02
SELECT COUNT(*) AS TotalRows
FROM [dbo].[dataEcommerce_Cl];
--03 استكشاف نوع البيانات
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dataEcommerce_Cl';
--04 null استكشاف الصفوف التي تحتوى على 
SELECT COUNT(*) AS Totalnulls
FROM [dataEcommerce_Cl]
WHERE [StockCode] IS NULL;

-- finish------------------------------------------------------------
--تنظيف عمود Quantity ##############################################1
--05 عرض القيم الغير رقمية
SELECT Quantity
FROM [dataEcommerce_Cl]
WHERE ISNUMERIC(Quantity) = 0;
--06 تعديل الجدول و اضافة عمود جديد للقيم الرقمية للكمية
alter table [dataEcommerce_Cl] add quantity_numerical int;
--07 تحديث الجدول وتحويل _كل مايمكن تحويله لرقم_ الى رقم 
-- و null لكل ما لا يمكن تحويله
update [dataEcommerce_Cl]
set quantity_numerical = TRY_CAST([Quantity] as int);
--08 اختبار التحديث 
SELECT [quantity_numerical]
FROM [dataEcommerce_Cl]
--09 معرفة عدد ال null
SELECT COUNT(*) AS Totalnulls
FROM [dataEcommerce_Cl]
WHERE [quantity_numerical] IS NULL;
--10 مقارنة البيانات الاصلية بالنظيفة
select top 100
	Quantity as [original_text],
	quantity_numerical as[Cleaned_Number]
from [dataEcommerce_Cl]
where quantity_numerical is not NULL;

select top 100
	Quantity as [original_text],
	quantity_numerical as[Cleaned_Number]
from [dataEcommerce_Cl]
where quantity_numerical is NULL;
--11 تجربة العمليات 
SELECT SUM(quantity_numerical) AS [TOTAL_QUANT]
FROM [dataEcommerce_Cl]
--الغلط يا استاذ مسعد 
SELECT SUM(Quantity) AS [TOTVAL_QUANT]
FROM [dataEcommerce_Cl]
-- finish------------------------------------------------------------
--تنظيف عمود ال101 UNIT_PRICE ##############################################2
SELECT UnitPrice
FROM [dataEcommerce_Cl]
WHERE ISNUMERIC(UnitPrice) = 0;
--معرفة عدد الاخطاء فالعمود102
select count(*) as count_notNUMERIC_UnitPrice
FROM [dataEcommerce_Cl]
WHERE ISNUMERIC(UnitPrice) = 0;
--103 تعديل الجدول و اضافة عمود جديد للقيم الرقمية لل UnitPrice
ALTER TABLE [dataEcommerce_Cl] ADD UnitPrice_numerical float;
--104تحديث الجدول وتحويل _كل مايمكن تحويله لرقم_ الى رقم 
-- و null لكل ما لا يمكن تحويله
update [dataEcommerce_Cl]
set UnitPrice_numerical = TRY_CAST([UnitPrice] as float);
--105 اختبار التحديث 
select  UnitPrice_numerical
from [dataEcommerce_Cl]
-- مقارنة البيانات الاصلية بالنظيفة106
select top(20)
	UnitPrice as [original_text],
	UnitPrice_numerical as[Cleaned_Number]
from [dataEcommerce_Cl]
where UnitPrice_numerical is not NULL;
select top(20)
	UnitPrice as [original_text],
	UnitPrice_numerical as[Cleaned_Number]
from [dataEcommerce_Cl]
where UnitPrice_numerical is  NULL;
--107 تجربة العمليات
select
	sum(quantity_numerical * UnitPrice_numerical) as [totaal_revenue]
from [dataEcommerce_Cl]
where
quantity_numerical is not null and UnitPrice_numerical is not null;
--Optimization
select
	round(sum(quantity_numerical * UnitPrice_numerical),2) as [totaal_revenue_format]
from [dataEcommerce_Cl]
where
quantity_numerical is not null and UnitPrice_numerical is not null;
-- finish------------------------------------------------------------
--201 تنظيف عمود ال InvoiceDate ############################################## 3 
alter table [dataEcommerce_Cl] add InvoiceDate_cleann datetime;
update [dataEcommerce_Cl]
set InvoiceDate_cleann = TRY_CAST([InvoiceDate] as datetime);

select top 20
	InvoiceDate as [original_text],
	InvoiceDate_cleann as [cleand_text]
from [dataEcommerce_Cl]
where InvoiceDate_cleann is not null;

select count(*) as InvoiceDate_cleann_null
FROM [dataEcommerce_Cl]
WHERE  InvoiceDate_cleann is null;
-- finish------------------------------------------------------------
--301 تنظيف عمود ال country ############################################## 4 
--1 عرض العمود الاصلي
select country 
from [dataEcommerce_Cl]

--2 استكشاف اماكن ال"."و "," في العمود
SELECT 
    Country, 
    CHARINDEX(',', Country) AS Comma_Pos,
    CHARINDEX('.', Country) AS Dot_Pos
FROM [dataEcommerce_Cl]
WHERE Country LIKE '%.%' OR Country LIKE '%,%';

--3 حذف ال"."و "," من العمود 
alter table [dataEcommerce_Cl] add countrycleand_new varchar(260);
update [dataEcommerce_Cl]
set countrycleand_new =
	TRIM(
	replace( REPLACE(country, ',', '') , '.' ,'')
	)
where country like '%,%' or country like '%.%';
--تجربة
select countrycleand_new
from  [dataEcommerce_Cl];
-- مقارنة القديم بالجديد  
select
	country as [original_text],
	countrycleand_new as[Cleaned_text]
from [dataEcommerce_Cl]
where countrycleand_new is NULL ;
-- معرفة عدد الفراغات
select count(*) as countrycleand_new_null
FROM [dataEcommerce_Cl]
where countrycleand_new is NULL ;

--4 استبدال الفراغات ب قيمها
update [dataEcommerce_Cl]
set countrycleand_new = TRIM(Country)
where countrycleand_new is null;
--تجربة
select countrycleand_new
from  [dataEcommerce_Cl];
--5 ازالة الارقام 
update [dataEcommerce_Cl]
set countrycleand_new =
	SUBSTRING(
	countrycleand_new ,
	PATINDEX('%[A-Za-z]%' , countrycleand_new),
	LEN(countrycleand_new)
			)
where patindex('%[0-9]%', countrycleand_new) >0;
--تجربة
select countrycleand_new
from  [dataEcommerce_Cl];

-- مقارنة القديم بالجديد  
select
	country as [original_text],
	countrycleand_new as[Cleaned_text]
from [dataEcommerce_Cl]
-- معرفة القيم الفريدة 
select distinct countrycleand_new
from [dataEcommerce_Cl]
order by countrycleand_new;
-- finish------------------------------------------------------------
select InvoiceNo, StockCode, Description,CustomerID
from [dataEcommerce_Cl];
-- 401 clean CustomerID ##############################################5
--1 استكشاف العمود
select count (*) as ggg 
from [dataEcommerce_Cl]
where CustomerID like '%.%'
	or TRY_CAST(CustomerID as int) is null;
--2 انشاء عمود جديد للبيانات النظيفة
alter table [dataEcommerce_Cl] add CustomerID_cleand int;
--3 نقل القيم النظيفة ل عمود الجديد 
update [dataEcommerce_Cl] 
set CustomerID_cleand = TRY_CAST(CustomerID as int)
where CustomerID not like '%.%'
and TRY_CAST(CustomerID as int ) >= 12000 ;

         
--4 استكشاف البيانات لمعرفة الاخطاء و الفراغات و الخ
select 
	CustomerID_cleand as [new_CustomerID],
	CustomerID as [orginal_id]
from [dataEcommerce_Cl]
ORDER BY CustomerID ASC;

select count(*)
from [dataEcommerce_Cl]
where CustomerID like '%.%'
and TRY_CAST(CustomerID as float ) <= 12000 ;

-- عدد ال null
select count(*) as null_id
from [dataEcommerce_Cl]
where CustomerID_cleand is null;
-- تحقق من اكبر و اصغر قيمة
SELECT
    MIN(TRY_CAST(CustomerID AS INT)) AS Smallest_ID,
    MAX(TRY_CAST(CustomerID AS INT)) AS Biggest_ID
FROM [dataEcommerce_Cl]
WHERE CustomerID NOT LIKE '%.%'        -- ابنعد عن الكسور والتواريخ
  AND CustomerID NOT LIKE '%,%'        -- ابتعد عن اللي فيهم كومات لسه
  AND TRY_CAST(CustomerID AS INT) > 0; -- هات الأرقام الحقيقية بس

-- اول 100 صف
SELECT DISTINCT TOP 100 
    TRY_CAST(CustomerID AS INT) AS Potential_ID
FROM [dataEcommerce_Cl]
WHERE TRY_CAST(CustomerID AS INT) IS NOT NULL -- هات بس اللي نفع يتحول لرقم
  AND CustomerID NOT LIKE '%.%'                -- استتبعد عن الكسور والتواريخ
ORDER BY Potential_ID ASC;  

-- معرفة اجمالي عدد الصفوف و عدد القيم الغير فارغة في العمود النظيف الجديد و عدد القيم الجاربج
SELECT 
    (SELECT COUNT(*) FROM [dataEcommerce_Cl]) AS Total_Rows,
    (SELECT COUNT(*) FROM [dataEcommerce_Cl] WHERE CustomerID_cleand IS NOT NULL) AS Valid_Customers,
    (SELECT COUNT(*) FROM [dataEcommerce_Cl] WHERE CustomerID_cleand IS NULL) AS Empty_Or_Trash;
-- تحديد اماكن ال138,187 صف الجاربج 
SELECT 
    CASE 
        WHEN CustomerID is null or CustomerID = '' then 'Empty or Null'
        WHEN CustomerID like '%.%' then 'Decimals or Dates or Dots'
        WHEN TRY_CAST(CustomerID AS INT) < 12000 then 'Small IDs (Under 12000)'
        ELSE 'Other Dirty Data'
    END AS Garbage_Data_Type,
    COUNT(*) AS Rows_Count
FROM [dataEcommerce_Cl]
WHERE CustomerID_cleand is null
GROUP BY 
    CASE 
        WHEN CustomerID is null or CustomerID = '' then 'Empty or Null'
        WHEN CustomerID like '%.%' then 'Decimals or Dates or Dots'
        WHEN TRY_CAST(CustomerID AS INT) < 12000 then 'Small IDs (Under 12000)'
        ELSE 'Other Dirty Data'
    END
order by Rows_Count desc;

 -- finish------------------------------------------------------------
-- 501 clean Description ##############################################6
select   distinct  
	[Description], count(*)

from [dataEcommerce_Cl]
group by [Description]
order by [Description];
--1 انشاء عمود جديد للبيانات النظيفة 
alter table [dataEcommerce_Cl] add Description_cleand VARCHAR(MAX) ;
--UPDATE1
update [dataEcommerce_Cl]
set Description_cleand = 
UPPER(LTRIM(RTRIM(REPLACE([Description],'"',''))));
--UPDATE2
update [dataEcommerce_Cl]
set Description_cleand = NULL
WHERE Description_cleand LIKE '%?%'
	OR Description_cleand IN (
	'CHECK' , 'DAMAGED', 'SAMPLES','WRONG CODE',
	'ADJUSTMENT', 'MOULDY', 'BROKEN', 'LOST', 
     'UNSALEABLE', 'AMAZON', 'ADJUST', 'BAD DEBT'
	); -- لسه فيه  بعض الكلمات سنقوم بإضافتها لتستثنى 
-- عرض العمودين جوار بعض تنازليا --> تم اضافتهم خلاص 
--update
UPDATE [dataEcommerce_Cl]
SET Description_cleand = NULL
WHERE  LTRIM(RTRIM(Description_cleand)) = ''
	or Description_cleand IN (
    'POSTAGE', 
    'DOTCOM POSTAGE', 
    'MANUAL', 
    'BANK CHARGES', 
    'AMAZON FEE', 
    'CRUK COMMISSION',
	'FOUND'
);
--
select  
	[Description_cleand] as new ,
	[Description] as old,
	count(*) as total

from [dataEcommerce_Cl]
group by [Description_cleand],[Description]
order by total desc
;
--عرض العمود النظيف
select [Description_cleand]
from [dataEcommerce_Cl]


 -- finish------------------------------------------------------------

 -- 601 clean InvoiceNo ##############################################7
 --استكشاف
select InvoiceNo
from [dataEcommerce_Cl]
order by InvoiceNo desc;
--
select * from [dataEcommerce_Cl]
where InvoiceNo like '%A%';
--
select * from [dataEcommerce_Cl]
where InvoiceNo like '%C%';

--1 انشاء عمود نظيف 
alter table [dataEcommerce_Cl] add InvoiceNo_cleand varchar(255);
--
UPDATE [dataEcommerce_Cl]
SET InvoiceNo_cleand = LTRIM(RTRIM(InvoiceNo))
WHERE InvoiceNo NOT LIKE '%A%';
 -- finish------------------------------------------------------------
 -- 701 clean StockCode ##############################################8
-- استكشاف
select DISTINCT StockCode , COUNT (*) AS TOTALCOUNT 
from [dataEcommerce_Cl]
GROUP BY StockCode
order by StockCode  desc;
--
select DISTINCT StockCode , COUNT (*) AS TOTALCOUNT 
from [dataEcommerce_Cl]
GROUP BY StockCode
order by COUNT (*)  desc;
-- تصنيف محتوى العمود

SELECT 
    CASE 
        WHEN StockCode LIKE '[0-9][0-9][0-9][0-9][0-9]' THEN 'Pure Numeric (only number)'
        WHEN StockCode LIKE '[0-9][0-9][0-9][0-9][0-9][A-Z]%' THEN 'Numeric + Letter'
        ELSE 'Non-Product / Administrative'
    END AS Stock_Type,
    COUNT(DISTINCT StockCode) AS Unique_Codes_Count,
    COUNT(*) AS Total_Transactions
FROM [dataEcommerce_Cl]
GROUP BY 
    CASE 
        WHEN StockCode LIKE '[0-9][0-9][0-9][0-9][0-9]' THEN 'Pure Numeric (only number)'
        WHEN StockCode LIKE '[0-9][0-9][0-9][0-9][0-9][A-Z]%' THEN 'Numeric + Letter'
        ELSE 'Non-Product / Administrative'
    END
order by COUNT(*) desc ;

-- انشاء عمود جديد
alter table [dataEcommerce_Cl] add StockCode_cleand varchar(255);

-- نقل البيانات النظيفة
update [dataEcommerce_Cl]
set StockCode_cleand =LTRIM(RTRIM(StockCode))
where StockCode like '[0-9][0-9][0-9][0-9][0-9]%';
--
select count (*)
FROM [dataEcommerce_Cl]
where StockCode_cleand is not null;
--
select count (*)
FROM [dataEcommerce_Cl]
where StockCode_cleand is  null;
 -- finish------------------------------------------------------------
