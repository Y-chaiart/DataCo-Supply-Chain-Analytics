-- View line fill rate -- 
create view vw_line_fill_rate as 
with line_fill_cte as (
select Order_region,
count(*) Total_lines,
sum(case when delivery_status in ('Shipping on time' , 'Advance Shipping')
then 1 else 0
end) Fulfilled_lines
from vw_Orders
group by Order_region
)
select * ,
concat(cast(round(100.0 * Fulfilled_lines / nullif(Total_lines,0),2) as decimal(5,2)),'%') Line_fill_rate_pct
from line_fill_cte ;

-- View volume fill rate -- 
create view vw_volume_fill_rate as 
with fill_rate_cte as (
select Order_region,
sum(Order_Item_Quantity) Total_Qty,
sum(case when delivery_status in ('Shipping on time' , 'Advance Shipping')
then Order_Item_Quantity else 0
end) Fulfilled_Qty
from vw_Orders
group by Order_region
)
select *,
concat((100 * Fulfilled_Qty / Total_Qty),'%')  Vol_fill_rate_pct
from fill_rate_cte ;

-- View On_Time_delivery_pct -- 
create view vw_On_Time_delivery_pct as 
with OTD_cte as (
select Order_Region,
count(distinct Order_Id) Total_Orders,
count(distinct case when delivery_status in ('Shipping on time' , 'Advance Shipping')
then Order_Id else 0 end) On_Time_Orders
from vw_Orders
group by Order_Region
)
select *,
concat(cast(round(100.0 * On_Time_Orders / Total_Orders ,2) as decimal(5,2)),'%') On_Time_delivery_pct
from OTD_cte

-- View Infull_Delivery_Pct -- 
create view vw_Infull_Delivery_Pct as 
with order_status_cte as(
select
Order_Id,
max(case when delivery_status = 'Shipping canceled' then 1 else 0 end) Has_cancel
from vw_Orders
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

-- View On time in full percentage (OTIF %) --
create view vw_OTIF_Pct as    
with Order_Level as(
select
Order_Id,
max(case when delivery_status in ('Shipping on time', 'Advance shipping')
then 1 else 0 end) Is_On_Time,
max(case when delivery_status = 'Shipping canceled'
then 1 else 0 end) Has_Cancel
from vw_Orders
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

-- View lead time --
create view vw_Lead_time as 
With Lead_time_Cte as (
select Order_Id, Order_Region,Shipping_Mode,
Category_Name, 
Days_for_Shipping_Real - Days_for_Shipment_Scheduled Delay
from vw_Orders
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

-- View abc analysis --
create view vw_abc_analysis as 
with Sales_cte as (
select Product_Name,
round(sum(sales),2) Total_Sales
from vw_Orders
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
