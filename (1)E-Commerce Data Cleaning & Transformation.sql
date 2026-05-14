--===============================================================================
--PROJECT: E-Commerce Data Cleaning & Transformation
--AUTHOR: Abdullah Nasef

--DESCRIPTION: 
--    This script make comprehensive Data Cleaning on raw e-commerce data. 
--    It focuses on handling nulls, correcting data types, filtering invalid 
--    transactions, and standardizing categorical columns for final analysis.
--===============================================================================
-------------------------------------------------------------------------------
-- STEP 1:  DATA EXPLORATION
-------------------------------------------------------------------------------
--01--
	select
	top(100) *
	from [dataEcommerce_Cl];
--02--
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

-- finish STEP 1 ------------------------------------------------------------
-------------------------------------------------------------------------------
-- STEP 2: Cleaning numerc columns (quantity and unit price)
-----------------------------------------------------------------------------
--1-- Cleaning quantity  ##############################################  
	--1 Displaying non-numeric values
	SELECT Quantity
	FROM [dataEcommerce_Cl]
	WHERE ISNUMERIC(Quantity) = 0;
	-- Edit the table and add a new column for the numerical values ​​of the quantity
	alter table [dataEcommerce_Cl] add quantity_numerical int;
--2 Update the table and convert everything that can be converted to a number to a number, and everything that cannot be converted to null	
	update [dataEcommerce_Cl]
	set quantity_numerical = TRY_CAST([Quantity] as int);
-- Update test
	SELECT [quantity_numerical]
	FROM [dataEcommerce_Cl]
	--Knowing the number of null
	SELECT COUNT(*) AS Totalnulls
	FROM [dataEcommerce_Cl]
	WHERE [quantity_numerical] IS NULL;
-- Comparing the original data with the clean data
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
-- Operations test
SELECT SUM(quantity_numerical) AS [TOTAL_QUANT]
	FROM [dataEcommerce_Cl]
	--الغلط يا استاذ عبدالله  
	SELECT SUM(Quantity) AS [TOTVAL_QUANT]
	FROM [dataEcommerce_Cl]
-- finish column ------------------------------------------------------------


--2-- Cleaning unit price  ##############################################  
	SELECT UnitPrice
	FROM [dataEcommerce_Cl]
	WHERE ISNUMERIC(UnitPrice) = 0;
-- Knowing the number of errors in the column
	select count(*) as count_notNUMERIC_UnitPrice
	FROM [dataEcommerce_Cl]
	WHERE ISNUMERIC(UnitPrice) = 0;
-- Edit the table and add a new column for the numerical values ​​of UnitPrice
	ALTER TABLE [dataEcommerce_Cl] ADD UnitPrice_numerical float;
	----Update the table and convert everything that can be converted to a number to a number, and everything that cannot be converted to null.
	update [dataEcommerce_Cl]
	set UnitPrice_numerical = TRY_CAST([UnitPrice] as float);
--test Update
	select  UnitPrice_numerical
	from [dataEcommerce_Cl]
--Comparing the original data with the clean data
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
-- Operations test
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
-- finish column ------------------------------------------------------------
-- finish numerc columns ------------------------------------------------------------

-------------------------------------------------------------------------------
-- STEP 3: Cleaning categorl columns (Country & Description)
-------------------------------------------------------------------------------
--3-- Cleaning country ##############################################  
-- Original column display
	select country 
	from [dataEcommerce_Cl]
	
-- Exploring the locations of the "." and "," in the column
	SELECT 
	    Country, 
	    CHARINDEX(',', Country) AS Comma_Pos,
	    CHARINDEX('.', Country) AS Dot_Pos
	FROM [dataEcommerce_Cl]
	WHERE Country LIKE '%.%' OR Country LIKE '%,%';
-- Create a new table for clean data
	alter table [dataEcommerce_Cl] add countrycleand_new varchar(260);
-- Delete the "." and ","
	update [dataEcommerce_Cl]
	set countrycleand_new =
		TRIM(
		replace( REPLACE(country, ',', '') , '.' ,'')
		)
	where country like '%,%' or country like '%.%';
--test
	select countrycleand_new
	from  [dataEcommerce_Cl];
-- Comparing the original data with the clean data  is NULL
	select
		country as [original_text],
		countrycleand_new as[Cleaned_text]
	from [dataEcommerce_Cl]
	where countrycleand_new is NULL ;
-- Knowing the number null
	select count(*) as countrycleand_new_null
	FROM [dataEcommerce_Cl]
	where countrycleand_new is NULL ;
	
--  Replace the null with their values
	update [dataEcommerce_Cl]
	set countrycleand_new = TRIM(Country)
	where countrycleand_new is null;
--test
	select countrycleand_new
	from  [dataEcommerce_Cl];
-- Remove numbers
	update [dataEcommerce_Cl]
	set countrycleand_new =
		SUBSTRING(
		countrycleand_new ,
		PATINDEX('%[A-Za-z]%' , countrycleand_new),
		LEN(countrycleand_new)
				)
	where patindex('%[0-9]%', countrycleand_new) >0;
-- test
	select countrycleand_new
	from  [dataEcommerce_Cl];
	
-- Comparing 
	select
		country as [original_text],
		countrycleand_new as[Cleaned_text]
	from [dataEcommerce_Cl]
	-- unique values 
	select distinct countrycleand_new
	from [dataEcommerce_Cl]
	order by countrycleand_new;
-- finish column ------------------------------------------------------------

--4-- clean Description ##############################################
-- display
	select   distinct  
		[Description], count(*)
	
	from [dataEcommerce_Cl]
	group by [Description]
	order by [Description];
--Create a new table for clean data
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
		);  
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
-- Comparing
	select  
		[Description_cleand] as new ,
		[Description] as old,
		count(*) as total
	
	from [dataEcommerce_Cl]
	group by [Description_cleand],[Description]
	order by total desc
	;
--Clean Column Display
	select [Description_cleand]
	from [dataEcommerce_Cl]
	

-- finish column ------------------------------------------------------------
-- finish categorl columns ------------------------------------------------------------

-------------------------------------------------------------------------------
-- STEP 4: Cleaning identifiers (customer ID and StockCode )
-------------------------------------------------------------------------------
--5-- Cleaning CustomerID ##############################################
-- display the coulmnn
	select count (*) as ggg 
	from [dataEcommerce_Cl]
	where CustomerID like '%.%'
		or TRY_CAST(CustomerID as int) is null;
-- Create a new table for clean data
	alter table [dataEcommerce_Cl] add CustomerID_cleand int;
-- Transferring clean values ​​to the new column
	update [dataEcommerce_Cl] 
	set CustomerID_cleand = TRY_CAST(CustomerID as int)
	where CustomerID not like '%.%'
	and TRY_CAST(CustomerID as int ) >= 12000 ; --Because numbers smaller than that are incorrect.
	
	         
-- Exploring the data to identify errors, gap, etc.
select 
		CustomerID_cleand as [new_CustomerID],
		CustomerID as [orginal_id]
	from [dataEcommerce_Cl]
	ORDER BY CustomerID ASC;
	
	select count(*)
	from [dataEcommerce_Cl]
	where CustomerID like '%.%'
	and TRY_CAST(CustomerID as float ) <= 12000 ;
	
-- count Number of null
	select count(*) as null_id
	from [dataEcommerce_Cl]
	where CustomerID_cleand is null;
	-- Check the largest and smallest values
	SELECT
	    MIN(TRY_CAST(CustomerID AS INT)) AS Smallest_ID,
	    MAX(TRY_CAST(CustomerID AS INT)) AS Biggest_ID
	FROM [dataEcommerce_Cl]
	WHERE CustomerID NOT LIKE '%.%'        -- ابنعد عن الكسور والتواريخ
	  AND CustomerID NOT LIKE '%,%'        -- ابتعد عن اللي فيهم كومات لسه
	  AND TRY_CAST(CustomerID AS INT) > 0; -- هات الأرقام الحقيقية بس
	
	-- 
	SELECT DISTINCT TOP 100 
	    TRY_CAST(CustomerID AS INT) AS Potential_ID
	FROM [dataEcommerce_Cl]
	WHERE TRY_CAST(CustomerID AS INT) IS NOT NULL -- هات بس اللي نفع يتحول لرقم
	  AND CustomerID NOT LIKE '%.%'                -- استتبعد عن الكسور والتواريخ
	ORDER BY Potential_ID ASC;  
	
	-- Determining the total number of rows, the number of non-empty values ​​in the new clean column, and the number of junk values.
	SELECT 
	    (SELECT COUNT(*) FROM [dataEcommerce_Cl]) AS Total_Rows,
	    (SELECT COUNT(*) FROM [dataEcommerce_Cl] WHERE CustomerID_cleand IS NOT NULL) AS Valid_Customers,
	    (SELECT COUNT(*) FROM [dataEcommerce_Cl] WHERE CustomerID_cleand IS NULL) AS Empty_Or_Trash;
	--Locating the 138,187 rows of the Empty_Or_Trash
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
	
-- finish column ------------------------------------------------------------

--6-- clean StockCode ##############################################
	-- display the coulmnn
	select DISTINCT StockCode , COUNT (*) AS TOTALCOUNT 
	from [dataEcommerce_Cl]
	GROUP BY StockCode
	order by StockCode  desc;
	--
	select DISTINCT StockCode , COUNT (*) AS TOTALCOUNT 
	from [dataEcommerce_Cl]
	GROUP BY StockCode
	order by COUNT (*)  desc;
	-- Column Content 
	
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
	
	-- Create a new table for clean data
	alter table [dataEcommerce_Cl] add StockCode_cleand varchar(255);
	
	-- Transferring clean values ​​to the new column
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
-- finish column ------------------------------------------------------------
-- finish identifier columns ------------------------------------------------------------


--7-- clean InvoiceNo ##############################################7
	 --display the coulmnn
	select InvoiceNo
	from [dataEcommerce_Cl]
	order by InvoiceNo desc;
	--
	select * from [dataEcommerce_Cl]
	where InvoiceNo like '%A%';
	--
	select * from [dataEcommerce_Cl]
	where InvoiceNo like '%C%';
	
	-- Create a new table for clean data
	alter table [dataEcommerce_Cl] add InvoiceNo_cleand varchar(255);
	-- Transferring clean values ​​to the new column
	UPDATE [dataEcommerce_Cl]
	SET InvoiceNo_cleand = LTRIM(RTRIM(InvoiceNo))
	WHERE InvoiceNo NOT LIKE '%A%';
-- finish column ------------------------------------------------------------

--8-- Cleaning InvoiceDate ##############################################
--Create a new table for clean data
	alter table [dataEcommerce_Cl] add InvoiceDate_cleann datetime;
--Transferring clean values ​​to the new column
	update [dataEcommerce_Cl]
	set InvoiceDate_cleann = TRY_CAST([InvoiceDate] as datetime);
-- Comparing
	select top 20
		InvoiceDate as [original_text],
		InvoiceDate_cleann as [cleand_text]
	from [dataEcommerce_Cl]
	where InvoiceDate_cleann is not null;
-- Knowing the number null
	select count(*) as InvoiceDate_cleann_null
	FROM [dataEcommerce_Cl]
	WHERE  InvoiceDate_cleann is null;
-- finish column ------------------------------------------------------------



--=================end=================end=================end
