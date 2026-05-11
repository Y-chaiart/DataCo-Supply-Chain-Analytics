select top 10 * from dbo.Final_DataCo
select count(*) from dbo.Final_DataCo;

--Null Checks --
select
sum(case when Order_Id is null then 1 else 0 end),
sum(case when Order_Date is null then 1 else 0 end),
sum(case when Sales is null then 1 else 0 end),
sum(case when Delivery_Status is null then 1 else 0 end),
sum(case when Days_for_Shipping_Real is null then 1 else 0 end)
from dbo.Final_DataCo

-- Duplicate check --
select 
Order_Id,
count(*) Multiple
from dbo.Final_DataCo
group by Order_Id
having count(*) > 1

-- Duplicate check with full details --
select * from (
select *,
count(*) over(partition by Order_Id) cnt
from dbo.Final_DataCo
)t
where cnt > 1

-- Distinct Values --
select distinct Delivery_Status from dbo.Final_DataCo
select distinct Shipping_Mode from dbo.Final_DataCo
select distinct Customer_Segment from dbo.Final_DataCo

--Negative values --
select * from dbo.Final_DataCo
where Sales < 0
