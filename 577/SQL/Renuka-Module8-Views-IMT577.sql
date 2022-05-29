/*****************************************
 Course: IMT 577B
 Instructor: Sean Pettersen
 Assignment: Module 8
 *****************************************/

--==================================================
--Pass-through Views--
--==================================================

CREATE OR REPLACE SECURE VIEW VIEW_DIM_CHANNEL AS
SELECT DimChannelID,
    ChannelID,
    ChannelCategoryID,
    ChannelName,
    ChannelCategory
FROM DIM_CHANNEL;
CREATE OR REPLACE SECURE VIEW VIEW_DIM_CUSTOMER AS
SELECT DimCustomerID,
    DimLocationID,
    CustomerID,
    FullName,
    FirstName,
    LastName,
    Gender,
    EmailAddress,
    PhoneNumber
FROM DIM_CUSTOMER;

CREATE OR REPLACE SECURE VIEW VIEW_DIM_LOCATION AS
SELECT DimLocationID,
    PostalCode,
    Address,
    City,
    Region,
    Country
FROM DIM_LOCATION;

CREATE OR REPLACE SECURE VIEW VIEW_DIM_PRODUCT AS
SELECT DimProductID,
    ProductID,
    ProductTypeID,
    ProductCategoryID,
    ProductName,
    ProductType,
    ProductCategory,
    ProductRetailPrice,
    ProductWholesalePrice,
    ProductCost,
    ProductRetailProfit,
    ProductWholesaleUnitProfit,
    ProductProfitMarginUnitPercent
FROM DIM_PRODUCT;

CREATE OR REPLACE SECURE VIEW VIEW_DIM_RESELLER AS
SELECT DimResellerID,
    DimLocationID,
    ResellerID,
    ResellerName,
    ContactName,
    PhoneNumber,
    EmailAddress
FROM DIM_RESELLER;

CREATE OR REPLACE SECURE VIEW VIEW_DIM_STORE AS
SELECT DimStoreID,
    DimLocationID,
    StoreID,
    StoreNumber,
    StoreManager,
    PhoneNumber
FROM DIM_STORE;

CREATE OR REPLACE SECURE VIEW VIEW_DIM_DATE AS
SELECT DATE_PKEY,
    DATE,
    FULL_DATE_DESC,
    DAY_NUM_IN_WEEK,
    DAY_NUM_IN_MONTH,
    DAY_NUM_IN_YEAR,
    DAY_NAME,
    DAY_ABBREV,
    WEEKDAY_IND,
    US_HOLIDAY_IND,
    _HOLIDAY_IND,
    MONTH_END_IND,
    WEEK_BEGIN_DATE_NKEY,
    WEEK_BEGIN_DATE,
    WEEK_END_DATE_NKEY,
    WEEK_END_DATE,
    WEEK_NUM_IN_YEAR,
    MONTH_NAME,
    MONTH_ABBREV,
    MONTH_NUM_IN_YEAR,
    YEARMONTH,
    QUARTER,
    YEARQUARTER,
    YEAR,
    FISCAL_WEEK_NUM,
    FISCAL_MONTH_NUM,
    FISCAL_YEARMONTH,
    FISCAL_QUARTER,
    FISCAL_YEARQUARTER,
    FISCAL_HALFYEAR,
    FISCAL_YEAR,
    SQL_TIMESTAMP,
    CURRENT_ROW_IND,
    EFFECTIVE_DATE,
    EXPIRATION_DATE
FROM DIM_DATE;

CREATE OR REPLACE SECURE VIEW VIEW_FACT_PRODUCTSALESTARGET AS
SELECT DimProductID,
    DimTargetDateID,
    ProductTargetSalesQuantity
FROM FACT_PRODUCTSALESTARGET;

CREATE OR REPLACE SECURE VIEW VIEW_FACT_SRCSALESTARGET AS
SELECT DimStoreID,
    DimResellerID,
    DimChannelID,
    DimTargetDateID,
    SalesTargetAmount
FROM FACT_SRCSALESTARGET;

CREATE OR REPLACE SECURE VIEW VIEW_FACT_SALESACTUAL AS
SELECT DimProductID,
    DimStoreID,
    DimResellerID,
    DimCustomerID,
    DimChannelID,
    DimSaleDateID,
    DimLocationID,
    SalesHeaderID,
    SalesDetailID,
    SalesAmount,
    SalesQuantity,
    SaleUnitPrice,
    SaleExtendedCost,
    SaleTotalProfit
FROM FACT_SALESACTUAL;

--==================================================
--Assessment Of Store 10 And 21’s Sales--
--==================================================

--View #1
Create or Replace Secure View View_Sales_Actual_Target As
Select Year,
    Storenumber,
    Sum(Actualsales) Over (Partition By Storenumber) As Totalsales,
    Sum(Actualtarget) Over (Partition By Storenumber) As Totaltarget
From (
        Select Year,
            Storenumber,
            Sum(Actualtarget) As Actualtarget,
            Sum(Actualsales) As Actualsales
        From (
                Select D.Year,
                    S.Storenumber,
                    Sum(Ft.Salestargetamount) As Actualtarget,
                    0 As Actualsales
                From Fact_Srcsalestarget Ft
                    Inner Join Dim_Store S On Ft.Dimstoreid = S.Dimstoreid
                    Inner Join Dim_Date D On Ft.Dimtargetdateid = D.Date_Pkey
                Where Year = 2013
                    And S.Dimstoreid > -1
                Group By D.Year,
                    S.Storenumber
                Union
                Select D.Year,
                    S.Storenumber,
                    0 As Actualtarget,
                    Sum(Fs.Salesamount) As Actualsales
                From Fact_Salesactual Fs
                    Inner Join Dim_Store S On Fs.Dimstoreid = S.Dimstoreid
                    Inner Join Dim_Date D On Fs.Dimsaledateid = D.Date_Pkey
                Where Year = 2013
                    And S.Dimstoreid > -1
                Group By D.Year,
                    S.Storenumber
            )
        Group By Year,
            Storenumber
    );

-- View #2
Create or Replace Secure View View_Sum_Sales_Actual_Target As
Select Year,
    Sum(TotalSales) As Sum_Actual_Sales_All_Stores,
    Sum(TotalTarget) As Sum_Target_Sales_All_Stores
From View_Sales_Actual_Target
Group By Year 

-- View #3
Create or Replace Secure View View_Bonus_Allocation As
Select a.Year,
    a.Storenumber,
    a.Totalsales,
    a.Totaltarget,
    (
        a.Totalsales * 100 / b.Sum_Actual_Sales_All_Stores
    ) As Percent_of_total_sales_per_store,
    (a.Totalsales * 100 / a.Totaltarget) As Percent_of_target_achieved,
    (
        2000000 * (a.Totalsales / b.Sum_Actual_Sales_All_Stores) * (a.Totalsales / a.Totaltarget)
    ) As Bonus_Allocation
From View_Sales_Actual_Target a
    Left Join View_Sum_Sales_Actual_Target b on a.Year = b.Year
Group by a.Year,
    a.Storenumber,
    a.Totalsales,
    a.Totaltarget,
    (
        a.Totalsales * 100 / b.Sum_Actual_Sales_All_Stores
    ),
    (a.Totalsales * 100 / a.Totaltarget),
    (
        2000000 * (a.Totalsales / b.Sum_Actual_Sales_All_Stores) * (a.Totalsales / a.Totaltarget)
    ) 

-- View #4
Create Or Replace Secure View View_Sales_Actual_Vs_Target As
Select Year,
    Month_name,
    Month_num_in_year,
    Storenumber,
    Sum(Actualsales) Over (
        Partition By Storenumber,
        Month_num_in_year,
        Year
        Order By Year
    ) As Totalsales,
    Sum(Actualtarget) Over (
        Partition By Storenumber,
        Month_num_in_year,
        Year
        Order By Year
    ) As Totaltarget
From (
        Select Year,
            Month_name,
            Month_num_in_year,
            Storenumber,
            Sum(Actualtarget) As Actualtarget,
            Sum(Actualsales) As Actualsales
        From (
                Select D.Year,
                    D.Month_name,
                    D.Month_num_in_year,
                    S.Storenumber,
                    Sum(Ft.Salestargetamount) As Actualtarget,
                    0 As Actualsales
                From Fact_srcsalestarget Ft
                    Inner Join Dim_store S On Ft.Dimstoreid = S.Dimstoreid
                    Inner Join Dim_date D On Ft.Dimtargetdateid = D.Date_pkey
                Where Storenumber != -1
                Group By D.Year,
                    D.Month_name,
                    D.Month_num_in_year,
                    S.Storenumber
                Union
                Select D.Year,
                    D.Month_name,
                    D.Month_num_in_year,
                    S.Storenumber,
                    0 As Actualtarget,
                    Sum(Fs.Salesamount) As Actualsales
                From Fact_salesactual Fs
                    Inner Join Dim_store S On Fs.Dimstoreid = S.Dimstoreid
                    Inner Join Dim_date D On Fs.Dimsaledateid = D.Date_pkey
                Where Storenumber != -1
                Group By D.Year,
                    D.Month_name,
                    D.Month_num_in_year,
                    S.Storenumber
            )
        Group By Year,
            Month_name,
            Month_num_in_year,
            Storenumber
    );

-- View #5
Create Or Replace Secure View View_Product_Profit As
Select D.Year,
    D.Month_Name,
    D.Month_Num_In_Year,
    S.Storenumber,
    C.Channelname,
    P.Productid,
    P.Productname,
    P.Productcost,
    P.Productretailprice,
    P.Productretailprofit,
    P.Productwholesaleprice,
    P.Productwholesaleunitprofit,
    P.Productprofitmarginunitpercent,
    Sa.Salesquantity,
    Sa.Salesamount,
    Sa.Saleunitprice,
    Sa.Saletotalprofit
From Fact_SalesActual sa
    Left Join Dim_Product P On P.Dimproductid = Sa.Dimproductid
    Left Join Dim_Store S On S.Dimstoreid = Sa.Dimstoreid
    Left Join Dim_Channel C On Sa.Dimchannelid = C.Dimchannelid
    Left Join Dim_Date D On Sa.Dimsaledateid = D.Date_Pkey
Where Storenumber In (10, 21)
Group By Storenumber,
    D.Year,
    D.Month_Name,
    D.Month_Num_In_Year,
    C.Channelname,
    P.Productid,
    P.Productname,
    Sa.Salesquantity,
    Sa.Salesamount,
    Sa.Saleunitprice,
    P.Productcost,
    P.Productretailprice,
    P.Productretailprofit,
    P.Productwholesaleprice,
    P.Productwholesaleunitprofit,
    P.Productprofitmarginunitpercent,
    Sa.Saletotalprofit;

-- View #6
Create Or Replace Secure View View_Product_Sales As
Select Date,
    Year,
    Month_name,
    Month_num_in_year,
    Day_name,
    Day_num_in_week,
    Day_num_in_month,
    Storenumber,
    Channelname,
    Productcategory,
    Productname,
    Producttype,
    Productcost,
    Productretailprice,
    Productretailprofit,
    Productwholesaleprice,
    Productwholesaleunitprofit,
    Productprofitmarginunitpercent,
    Sum(Fs.Salesquantity) As Productsalesquantity,
    Sum(Fs.Salesamount) As Productsalesamount
From Fact_salesactual Fs
    Inner Join Dim_store S On Fs.Dimstoreid = S.Dimstoreid
    Inner Join Dim_channel C On Fs.Dimchannelid = C.Dimchannelid
    Inner Join Dim_product P On Fs.Dimproductid = P.Dimproductid
    Inner Join Dim_date D On Fs.Dimsaledateid = D.Date_pkey
Where Storenumber In (10, 21)
Group By Date,
    Year,
    Month_name,
    Month_num_in_year,
    Day_name,
    Day_num_in_week,
    Day_num_in_month,
    Storenumber,
    Channelname,
    Productcategory,
    Productname,
    Producttype,
    Productcost,
    Productretailprice,
    Productretailprofit,
    Productwholesaleprice,
    Productwholesaleunitprofit,
    Productprofitmarginunitpercent;

-- View #7
Create Or Replace Secure View View_New_Stores As
Select Year,
    Storenumber,
    Postalcode,
    Address,
    City,
    Region,
    Country,
    Sum(Actualsales) Over (
        Partition By Storenumber,
        Year
        Order By Year
    ) As Totalsales,
    Sum(Actualtarget) Over (
        Partition By Storenumber,
        Year
        Order By Year
    ) As Totaltarget,
    Sum(TotalProfit) Over (
        Partition By Storenumber,
        Year
        Order By Year
    ) As TotalProfit,
    Round(100 -(((Totaltarget - Totalsales) / Totaltarget) * 100)) As Percentage
From (
        Select Year,
            Storenumber,
            Postalcode,
            Address,
            City,
            Region,
            Country,
            Sum(Actualtarget) As Actualtarget,
            Sum(Actualsales) As Actualsales,
            Sum(TotalProfit) As TotalProfit
        From (
                Select D.Year,
                    S.Storenumber,
                    L.Postalcode,
                    L.Address,
                    L.City,
                    L.Region,
                    L.Country,
                    Sum(Ft.Salestargetamount) As Actualtarget,
                    0 As Actualsales,
                    0 As TotalProfit
                From Fact_srcsalestarget Ft
                    Inner Join Dim_store S On Ft.Dimstoreid = S.Dimstoreid
                    Inner Join Dim_location L On S.Dimlocationid = L.Dimlocationid
                    Inner Join Dim_date D On Ft.Dimtargetdateid = D.Date_pkey
                Where S.Dimstoreid > -1
                Group By D.Year,
                    S.Storenumber,
                    L.Postalcode,
                    L.Address,
                    L.City,
                    L.Region,
                    L.Country
                Union
                Select D.Year,
                    S.Storenumber,
                    L.Postalcode,
                    L.Address,
                    L.City,
                    L.Region,
                    L.Country,
                    0 As Actualtarget,
                    Sum(Fs.Salesamount) As Actualsales,
                    Sum(Fs.Saletotalprofit) As TotalProfit
                From Fact_salesactual Fs
                    Inner Join Dim_store S On Fs.Dimstoreid = S.Dimstoreid
                    Inner Join Dim_location L On Fs.Dimlocationid = L.Dimlocationid
                    Inner Join Dim_date D On Fs.Dimsaledateid = D.Date_pkey
                Where S.Dimstoreid > -1
                Group By D.Year,
                    S.Storenumber,
                    L.Postalcode,
                    L.Address,
                    L.City,
                    L.Region,
                    L.Country
            )
        Group By Year,
            Storenumber,
            Postalcode,
            Address,
            City,
            Region,
            Country
    );
