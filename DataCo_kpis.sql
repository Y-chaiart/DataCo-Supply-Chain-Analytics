-- KPIs --
-- 1. Availability --
-- Since Product Status is 0 we cannot find availability. Also dataset doesnot contain inventory stock level data --

-- 2.Total Orders --
select
count(distinct order_id) Total_Orders
from dbo.Final_DataCo

-- 3.Order lines --
with order_lines_cte as (
select Order_Region,
count(*) Total_Lines,
count(distinct order_id) Total_Orders
from dbo.Final_DataCo
group by Order_Region
)
select *,
round(cast(Total_Lines as float) / nullif (Total_Orders,0),2) Avg_lines_per_order
from order_lines_cte ;


-- 4. Line fill rate -- 
with line_fill_cte as (
select Order_region,
count(*) Total_lines,
sum(case when delivery_status in ('Shipping on time' , 'Advance Shipping')
then 1 else 0
end) Fulfilled_lines
from dbo.Final_DataCo
group by Order_region
)
select * ,
concat(cast(round(100.0 * Fulfilled_lines / nullif(Total_lines,0),2) as decimal(5,2)),'%') Line_fill_rate_pct
from line_fill_cte ;


-- 5.Volume fill rate --
with fill_rate_cte as (
select Order_region,
sum(Order_Item_Quantity) Total_Qty,
sum(case when delivery_status in ('Shipping on time' , 'Advance Shipping')
then Order_Item_Quantity else 0
end) Fulfilled_Qty
from dbo.Final_DataCo
group by Order_region
)
select *,
concat((100 * Fulfilled_Qty / Total_Qty),'%')  Vol_fill_rate_pct
from fill_rate_cte ;


-- 6. On time delivery % --
with OTD_cte as (
select Order_Region,
count(distinct Order_Id) Total_Orders,
count(distinct case when delivery_status in ('Shipping on time' , 'Advance Shipping')
then Order_Id else 0 end) On_Time_Orders
from dbo.Final_DataCo
group by Order_Region
)
select *,
concat(cast(round(100.0 * On_Time_Orders / Total_Orders ,2) as decimal(5,2)),'%') On_Time_delivery_pct
from OTD_cte


-- 7. In full delivery % --
with order_status_cte as(
select
Order_Id,
max(case when delivery_status = 'Shipping canceled' then 1 else 0 end) Has_cancel
from dbo.Final_DataCo
group by Order_Id
),
infull_cte as (
select 
count(*) Total_Orders,
sum(case when Has_cancel = 0 then 1 else 0 end) Infull_Orders
from order_status_cte
)
select *,
concat(cast(round(100.0 * Infull_Orders / Total_Orders ,2) as decimal(5,2)),'%') Infull_Delivery_Pct
from infull_cte


-- 8. On time in full percentage (OTIF %) --
with Order_Level as(
select
Order_Id,
max(case when delivery_status in ('Shipping on time', 'Advance shipping')
then 1 else 0 end) Is_On_Time,
max(case when delivery_status = 'Shipping canceled'
then 1 else 0 end) Has_Cancel
from dbo.Final_DataCo
group by Order_Id
),
Otif_cte as (
select *,
case when Is_On_Time = 1 and Has_Cancel = 0 then 1 else 0 end Otif_Flag
from Order_Level
)
select 
count(*) Total_Orders,
sum(Otif_Flag) OTIF_Orders,
concat(cast(round(100.0 * sum(Otif_Flag) / count(*),2) as decimal(5,2)),'%') OTIF_Pct
from Otif_cte


--  9. Inventory turnover ratio --
--  Dataset lacks true inventory holding values --

-- 10. Slow and obsolete inventory (SLOB) proxy --

with Product_Sales_cte as(
select Product_Name, Category_Name,
sum(Order_Item_Quantity) Total_Qty,
round(sum(Sales),2) Total_Sales,
sum(case when delivery_status = 'Shipping canceled' then 1 else 0 end) Cancelled_Orders
from dbo.Final_DataCo
group by Product_Name,Category_Name
),
Ranked as (
select *,
ntile(5) over(order by Total_Qty asc) Qty_Bucket
from Product_Sales_cte
)
select *,
case when Cancelled_Orders > 0 and Total_Sales = 0 then 'Obsolete'
	 when Qty_Bucket =1  then 'Slow Moving'
	 else 'Active'
end Slob_Status
from Ranked
order by Total_Qty asc


-- 10. Inventory Accuracy (Proxy)--
with Inv_Acc_Cte as (
select
sum(Order_Item_Quantity) Total_Qty,
sum(case when Delivery_Status in ('Shipping on time','Advance shipping')
then Order_Item_Quantity
else 0 
end ) Accurate_Qty
from dbo.Final_DataCo
)
select Total_Qty, Accurate_Qty,
concat((100 * Accurate_Qty / Total_Qty),'%')  Inv_Acc_percent
from Inv_Acc_Cte


-- 11. Lead Time --
With Lead_time_Cte as (
select Order_Id, Order_Region,Shipping_Mode,
Category_Name, 
Days_for_Shipping_Real - Days_for_Shipment_Scheduled Delay
from dbo.Final_DataCo
), classified_cte as (
select Order_Region, 
Shipping_Mode, Category_Name, 
case when Delay > 0 then 'Late'
	 when Delay < 0 then 'Early'
	 else 'On Time'
	 end Lead_time_status
from Lead_time_Cte
)
select Order_Region, Shipping_Mode, Category_Name, 
count(*) Total_Orders,
Lead_time_status
from classified_cte
group by Order_Region,Shipping_Mode, Lead_time_status, Category_Name
order by Order_Region


-- 12. Occupancy Rate (Proxy) --
-- Dataset lacks warehouse capacity and utilisation data --

with Occ_Cte as (
select Category_Name,
sum(Order_Item_Quantity) Total_Qty
from dbo.Final_DataCo
group by Category_Name
)
select Category_Name, Total_Qty,
concat(cast(100.0 * Total_Qty / sum(Total_Qty) over() as decimal(10,2)), '%') Occ_Rate
from Occ_Cte
order by Total_Qty desc

-- 13. Forecast Accuracy (Proxy) --
with monthly_sales_cte as (
select format(Order_Date,'yyyy-MM') Month,
Category_Name,
sum(Order_item_quantity) Actual_Sales
from dbo.Final_DataCo
group by format(Order_Date,'yyyy-MM'),Category_Name
),
forecast_cte as (
select *,
LAG(Actual_Sales) over(partition by Category_Name order by Month) Prev_Sales
from monthly_sales_cte
)
select *, 
concat(cast(round(case when Prev_Sales is null then null
	  when Prev_Sales = 0 then 0
	  else (1 - ABS(Actual_Sales - Prev_Sales)*1.0 / Prev_Sales) * 100
	  end, 2) as decimal(10,2)),'%') Forecast_Acc_Pct
from forecast_cte
where Prev_sales is not null
order by Category_Name,Month


-- 14. SCM costs ( Warehousing, Transport, Inventory, Administrative ) Proxy --
with scm_cost_cte as (
select Order_region,
sum(order_item_quantity) Inventory_load,
sum(days_for_shipping_real) Transport_load,
count(order_id) Admin_workload,
round(sum(Sales),2) Value_Impact
from dbo.Final_DataCo
group by Order_region
)
select * from scm_cost_cte
order by Value_Impact desc


-- 15. ABC Analysis --
with Sales_cte as (
select Product_Name,
round(sum(sales),2) Total_Sales
from dbo.Final_DataCo
group by Product_Name
)
, cum_cte as (
select*,
sum(Total_Sales) over(order by Total_Sales desc) Cum_Sales,
round(sum(Total_Sales) over(order by Total_Sales desc) * 100.0 /
sum(Total_Sales) over(),2) Cum_Per
from Sales_cte
)
select *,
case when Cum_Per <= 80 then 'A' 
when Cum_Per <= 95 then 'B' 
else 'C'
end ABC_Class
from cum_cte
order by Total_Sales desc


-- Business Insights --

-- 1. MOM Growth --
with cte as(
select 
format(order_date,'yyyy-MM') Month,
round(sum(sales),2) TotalSales
from vw_Orders
group by format(order_date,'yyyy-MM')
)select Month, TotalSales,
lag(TotalSales) over(order by Month) Prev_month_sales,
isnull(round((TotalSales - lag(TotalSales) over(order by Month))* 100.0 / 
nullif(lag(TotalSales) over(order by Month),0),2),0) MOM_Growth_Pct
from cte;

-- 2. Cumulative Sales --
with cte as(
select 
format(order_date,'yyyy-MM') Month,
round(sum(sales),2) TotalSales
from vw_Orders
group by format(order_date,'yyyy-MM')
),cte1 as (
select Month, TotalSales,
sum(TotalSales) over(order by month rows between unbounded preceding and current row) Cum_Sales
from cte
)
select Month, TotalSales,Cum_Sales,
round(Cum_Sales * 100.0/ max(Cum_Sales) over(),2) Cum_Sales_pct
from cte1

-- 3. YOY growth -- 
WITH cte AS (
 SELECT 
 YEAR(Order_Date) AS Year,
 ROUND(SUM(Sales), 2) AS Total_Sales
 FROM vw_Orders
 GROUP BY YEAR(Order_Date)
),
cte1 AS (
 SELECT 
  Year, Total_Sales,
  LAG(Total_Sales) OVER(ORDER BY Year) AS Prev_Year_Sales,
  isnull(ROUND((Total_Sales - LAG(Total_Sales) OVER(ORDER BY Year)) * 100.0 /
  NULLIF(LAG(Total_Sales) OVER(ORDER BY Year), 0),2),0) AS YOY_Growth_Pct
 FROM cte
)
SELECT * FROM cte1
ORDER BY Year



























