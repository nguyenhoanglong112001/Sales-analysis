-- showing sale data
select top 1000* from FactInternetSales

-- showing product detail
select *
from FactInternetSales sales
join DimProduct product
on sales.ProductKey = product.ProductKey

-- showing only distinct EnglishProductNam
select distinct EnglishProductName
from FactInternetSales sales
join DimProduct product
on sales.ProductKey = product.ProductKey

-- Showing sales of each year by product
select
    Year(OrderDate) as [year],
	EnglishProductName,
	Count(*) as total_product_sales,
	Sum(SalesAmount) as sales,
	AVG(SalesAmount) as avg_sales,
	min(SalesAmount) as min_sales,
	MAX(SalesAmount) as max_sales
from FactInternetSales as sales
join DimProduct product
on sales.ProductKey = product.ProductKey
Group by EnglishProductName, YEAR(OrderDate)
Order by EnglishProductName


-- Showing avgrate sale by product for Group,Country,Region
select
    EnglishProductName,
    SalesTerritoryGroup,
	SalesTerritoryCountry,
	SalesTerritoryRegion,
	avg(SalesAmount) over (partition by SalesTerritoryGroup,EnglishproductName) as group_avg,
	avg(SalesAmount) over (partition by SalesTerritoryCountry,EnglishproductName) as country_avg,
	avg(SalesAmount) over (partition by SalesTerritoryRegion,EnglishproductName) as country_avg
from FactInternetSales as sales
join DimProduct as product
on sales.ProductKey = product.ProductKey
join DimSalesTerritory as territory
on territory.SalesTerritoryKey = sales.SalesTerritoryKey
order by SalesTerritoryGroup,
	     SalesTerritoryCountry,
	     SalesTerritoryRegion

-- Showing what product is the most sales in each country
-- See in each country , which product is boutgh most by customer
with sales_product as (
select
	EnglishProductName,
	SalesTerritoryCountry,
	Sum(SalesAmount) as sales
from FactInternetSales as sales
join DimProduct as product
on sales.ProductKey = product.ProductKey
join DimSalesTerritory as territory
on territory.SalesTerritoryKey = sales.SalesTerritoryKey
Group by EnglishProductName,SalesTerritoryCountry),
rank_table as(
select *,
    ROW_NUMBER() over(partition by SalesTerritoryCountry order by sales desc) as rank_column
from sales_product)
select * from rank_table
where rank_column =1

-- Showing the percentage between sales of each product and totoal sales
-- This will show that which product has the highest percentage of sales and amount
select
     EnglishProductName,
	 Sum(SalesAmount) as total_sales,
	 Count(*) as total_amount,
	 Format(sum(SalesAmount)/(select Sum(SalesAmount) from FactInternetSales),'P') as pct_sales,
	 Format(count(*)/(select count(*) from FactInternetSales),'P') as pct_amount
from FactInternetSales sales
join DimProduct product
on product.ProductKey = sales.ProductKey
group by EnglishProductName
order by pct_sales desc,pct_amount desc

-- Showing the percentage between sales of each product and totoal sales in each country
with amount_product as (
select SalesTerritoryCountry,
     DP.ProductKey,
     EnglishProductName,
     SUM(SalesAmount) AS total_sales,
     count(distinct SalesOrderNumber) AS number_of_order
from FactInternetSales as FS
         LEFT JOIN DimProduct as DP
                   on DP.ProductKey = FS.ProductKey
         LEFT JOIN DimSalesTerritory DST
                   on DST.SalesTerritoryKey = FS.SalesTerritoryKey
group by SalesTerritoryCountry
       , DP.ProductKey -- mã sản phẩm 
       , EnglishProductName -- tên sản phẩm 
)
select *
    , sum(total_sales) over (partition by SalesTerritoryCountry) as InternetTotalSalesCountry
    , format(total_sales/sum(total_sales) over (partition by  SalesTerritoryCountry), 'P') as PercentofTotaInCountry
from amount_product


-- Showing sales by category and subcategory 
Select
    sub.EnglishProductSubcategoryName,
	category.EnglishProductCategoryName,
	Count(*) as total_product_sales,
	Sum(SalesAmount) as sales,
	AVG(SalesAmount) as avg_sales,
	min(SalesAmount) as min_sales,
	MAX(SalesAmount) as max_sales
from FactInternetSales sales
join DimProduct product
on sales.ProductKey = product.ProductKey
join DimProductSubcategory as sub
on sub.ProductCategoryKey = ProductCategoryKey
join DimProductCategory category
on category.ProductCategoryKey = sub.ProductCategoryKey
group by sub.EnglishProductSubcategoryName, category.EnglishProductCategoryName
order by sub.EnglishProductSubcategoryName, category.EnglishProductCategoryName

--showing sales by category and subcategory each years
Select
    Year(OrderDate) as Year,
    sub.EnglishProductSubcategoryName,
	category.EnglishProductCategoryName,
	Count(*) as total_product_sales,
	Sum(SalesAmount) as sales,
	AVG(SalesAmount) as avg_sales,
	min(SalesAmount) as min_sales,
	MAX(SalesAmount) as max_sales
from FactInternetSales sales
join DimProduct product
on sales.ProductKey = product.ProductKey
join DimProductSubcategory as sub
on sub.ProductCategoryKey = ProductCategoryKey
join DimProductCategory category
on category.ProductCategoryKey = sub.ProductCategoryKey
group by sub.EnglishProductSubcategoryName, category.EnglishProductCategoryName,Year(OrderDate)
order by sub.EnglishProductSubcategoryName, category.EnglishProductCategoryName,Year(OrderDate)

-- Showing the highest category and subcategory in each country
-- See what kind of product that customer buy the most
with sales_by_category as(
select
	 SalesTerritoryCountry,
	 EnglishProductCategoryName,
	 EnglishProductSubcategoryName,
	 Sum(SalesAmount) as sales
from FactInternetSales sales
join DimProduct product
on sales.ProductKey = product.ProductKey
join DimProductSubcategory as sub
on sub.ProductCategoryKey = ProductCategoryKey
join DimProductCategory category
on category.ProductCategoryKey = sub.ProductCategoryKey
join DimSalesTerritory as territory
on territory.SalesTerritoryKey = sales.SalesTerritoryKey
group by SalesTerritoryCountry,
	     EnglishProductCategoryName,EnglishProductSubcategoryName)
, rank_table as (
select *,
     ROW_NUMBER() over (partition by SalesTerritoryCountry order by sales) as rank_column
from sales_by_category)
select * from rank_table where rank_column =1

-- Showing the percentage between total sales of category,subcategory and total sales, total amount of category,subcategory and total amount
Select
    sub.EnglishProductSubcategoryName,
	category.EnglishProductCategoryName,
	Count(category.EnglishProductCategoryName) as total_product_sales,
	Sum(SalesAmount) as total_sales,
	Format(Count(category.EnglishProductCategoryName)/(select Count(*) from FactInternetSales),'P') as pct_amount,
	Format(Sum(SalesAmount)/(select Sum(SalesAmount) from FactInternetSales),'P') as pct_sales
from FactInternetSales sales
join DimProduct product
on sales.ProductKey = product.ProductKey
join DimProductSubcategory as sub
on sub.ProductCategoryKey = ProductCategoryKey
join DimProductCategory category
on category.ProductCategoryKey = sub.ProductCategoryKey
group by sub.EnglishProductSubcategoryName, category.EnglishProductCategoryName
order by sub.EnglishProductSubcategoryName, category.EnglishProductCategoryName



-- I will analyze on the customer 
-- show the customer detail
select 
     CONCAT_WS(' ',Title,FirstName,MiddleName,LastName) as full_name,
	 BirthDate,
	 Gender,
	 EmailAddress,
	 YearlyIncome
from FactInternetSales sales
join DimCustomer cus
on cus.CustomerKey = sales.CustomerKey

-- clasify the customer based on the number order
-- if the customer have more than 1 order,classified as returning user
-- if the customer have less then 1 order,classified as non-returning user
select
    cus.CustomerKey,
	Count(SalesOrderNumber) as total_customer_order,
    CONCAT_WS(' ',Title,FirstName,MiddleName,LastName) as full_name,
	case
	    when Count(SalesOrderNumber) > 1 then 'returning user'
		else 'non return user'
	end as customer_classify
from FactInternetSales sales
join DimCustomer cus
on cus.CustomerKey = sales.CustomerKey
group by cus.CustomerKey,
    CONCAT_WS(' ',Title,FirstName,MiddleName,LastName)
order by total_customer_order

-- caculate retention rate of the customer
-- retention rate = total returning user/ total/user
with count_cust as (
select distinct
        CustomerKey,
        count(SalesOrderNumber) as customer_order,
        count(Customerkey) over() as total_users, 
        case
		    when count(distinct SalesOrderNumber) > 1 then 'returning user'
			else 'non return user'
		end as group_user
     from FactInternetSales
group by CustomerKey
) 
select group_user,
    count(CustomerKey) as nb_user,
    sum(count(CustomerKey)) over() as total_users,
    count(CustomerKey)/ sum(count(CustomerKey)) over() as pct
from count_cust


-- showing the the highest customer month amount in each month
with customer_by_month as (
    select YEAR(OrderDate) as order_year,
          MONTH(OrderDate) as order_month,
          customer.CustomerKey,
          CONCAT_WS(' ', FirstName, MiddleName, LastName) as full_name,
          sum(SalesAmount) AS customer_month_amount,
          ROW_NUMBER() over (partition by YEAR(OrderDate), MONTH(OrderDate) order by sum(SalesAmount) desc) as Customer_rank
    from FactInternetSales as sales
    join DimCustomer customer
    on sales.CustomerKey = customer.CustomerKey
    group by customer.CustomerKey,
           CONCAT_WS(' ', FirstName, MiddleName, LastName),
           YEAR(OrderDate),
           MONTH(OrderDate)
)
select order_year,
      order_month,
      CustomerKey,
      full_name,
      customer_month_amount,
      Customer_rank
from customer_by_month
wherE Customer_rank = 1
order by order_year, order_month, CustomerKey

-- showing total sales and total order
select
    Count(distinct SalesOrderNumber) as total_order,
    Sum(SalesAmount) as total_sale
from FactInternetSales

-- showing total sales and total order in each country
select
    SalesTerritoryCountry,
    Count(distinct SalesOrderNumber) as total_order,
    Sum(SalesAmount) as total_sale
from FactInternetSales sales
join DimSalesTerritory territory
on sales.SalesTerritoryKey = territory.SalesTerritoryKey
group by SalesTerritoryCountry

--Calculation of revenue growth percentage over the same period last year
with table1 as(
select 
    Year(OrderDate) as [year],
	Month(OrderDate) as [month],
	Sum(SalesAmount) as sales_per_month,
	Lag(Sum(SalesAmount),12) over(order by Year(OrderDate),Month(OrderDate)) as last_year_sales
From FactInternetSales
group by Year(OrderDate),Month(OrderDate)
)
select
    *,
	(sales_per_month - last_year_sales) / last_year_sales as pct_sales_growth
from table1








