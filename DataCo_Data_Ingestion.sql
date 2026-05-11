CREATE TABLE dbo.Staging_DataCo (

[Type] NVARCHAR(MAX),
[Days for shipping (real)] NVARCHAR(MAX),
[Days for shipment (scheduled)] NVARCHAR(MAX),
[Benefit per order] NVARCHAR(MAX),
[Sales per customer] NVARCHAR(MAX),
[Delivery Status] NVARCHAR(MAX),
[Late_delivery_risk] NVARCHAR(MAX),
[Category Id] NVARCHAR(MAX),
[Category Name] NVARCHAR(MAX),
[Customer City] NVARCHAR(MAX),
[Customer Country] NVARCHAR(MAX),
[Customer Email] NVARCHAR(MAX),
[Customer Fname] NVARCHAR(MAX),
[Customer Id] NVARCHAR(MAX),
[Customer Lname] NVARCHAR(MAX),
[Customer Password] NVARCHAR(MAX),
[Customer Segment] NVARCHAR(MAX),
[Customer State] NVARCHAR(MAX),
[Customer Street] NVARCHAR(MAX),
[Customer Zipcode] NVARCHAR(MAX),
[Department Id] NVARCHAR(MAX),
[Department Name] NVARCHAR(MAX),
[Latitude] NVARCHAR(MAX),
[Longitude] NVARCHAR(MAX),
[Market] NVARCHAR(MAX),
[Order City] NVARCHAR(MAX),
[Order Country] NVARCHAR(MAX),
[Order Customer Id] NVARCHAR(MAX),
[order date (DateOrders)] NVARCHAR(MAX),
[Order Id] NVARCHAR(MAX),
[Order Item Cardprod Id] NVARCHAR(MAX),
[Order Item Discount] NVARCHAR(MAX),
[Order Item Discount Rate] NVARCHAR(MAX),
[Order Item Id] NVARCHAR(MAX),
[Order Item Product Price] NVARCHAR(MAX),
[Order Item Profit Ratio] NVARCHAR(MAX),
[Order Item Quantity] NVARCHAR(MAX),
[Sales] NVARCHAR(MAX),
[Order Item Total] NVARCHAR(MAX),
[Order Profit Per Order] NVARCHAR(MAX),
[Order Region] NVARCHAR(MAX),
[Order State] NVARCHAR(MAX),
[Order Status] NVARCHAR(MAX),
[Order Zipcode] NVARCHAR(MAX),
[Product Card Id] NVARCHAR(MAX),
[Product Category Id] NVARCHAR(MAX),
[Product Description] NVARCHAR(MAX),
[Product Image] NVARCHAR(MAX),
[Product Name] NVARCHAR(MAX),
[Product Price] NVARCHAR(MAX),
[Product Status] NVARCHAR(MAX),
[shipping date (DateOrders)] NVARCHAR(MAX),
[Shipping Mode] NVARCHAR(MAX)

);

-- Bulk Insert --
BULK INSERT dbo.Staging_DataCo
FROM 'C:\Users\Yash\OneDrive\Desktop\Datasets\Dataco SCM\DataCoSupplyChainDataset.csv' 
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',
    TABLOCK
);

-- Clean table --
CREATE TABLE dbo.Final_DataCo (

Order_Id VARCHAR(50),
Order_Date DATETIME,
Shipping_Date DATETIME,
Order_Status VARCHAR(50),
Shipping_Mode VARCHAR(50),

Days_for_Shipping_Real INT,
Days_for_Shipment_Scheduled INT,
Late_Delivery_Risk INT,
Delivery_Status VARCHAR(50),

Market VARCHAR(50),
Order_Region VARCHAR(50),
Order_Country VARCHAR(50),

Category_Name VARCHAR(100),
Department_Name VARCHAR(100),
Product_Name VARCHAR(150),
Product_Price FLOAT,

Order_Item_Quantity INT,
Order_Item_Total FLOAT,
Sales FLOAT,
Order_Profit_Per_Order FLOAT,
Benefit_per_Order FLOAT,

Customer_Segment VARCHAR(50)

);

-- Insert Data --
INSERT INTO dbo.Final_DataCo
SELECT

[Order Id],
TRY_CAST([order date (DateOrders)] AS DATETIME),
TRY_CAST([shipping date (DateOrders)] AS DATETIME),
[Order Status],
[Shipping Mode],

TRY_CAST([Days for shipping (real)] AS INT),
TRY_CAST([Days for shipment (scheduled)] AS INT),
TRY_CAST([Late_delivery_risk] AS INT),
[Delivery Status],

[Market],
[Order Region],
[Order Country],

[Category Name],
[Department Name],
[Product Name],
TRY_CAST([Product Price] AS FLOAT),

TRY_CAST([Order Item Quantity] AS INT),
TRY_CAST([Order Item Total] AS FLOAT),
TRY_CAST([Sales] AS FLOAT),
TRY_CAST([Order Profit Per Order] AS FLOAT),
TRY_CAST([Benefit per order] AS FLOAT),

[Customer Segment]

FROM dbo.Staging_DataCo;

SELECT TOP 10 * FROM dbo.Final_DataCo;