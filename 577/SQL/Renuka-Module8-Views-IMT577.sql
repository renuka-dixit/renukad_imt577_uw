/*****************************************
 Course: IMT 577B
 Instructor: Sean Pettersen
 Assignment: Module 8
 Date: 05/22/2022
 *****************************************/

--==================================================
--Pass-through Views--
--==================================================

CREATE OR REPLACE VIEW VIEW_DIM_CHANNEL AS
SELECT DimChannelID,
    ChannelID,
    ChannelCategoryID,
    ChannelName,
    ChannelCategory
FROM DIM_CHANNEL;

CREATE OR REPLACE VIEW VIEW_DIM_CUSTOMER AS
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

CREATE OR REPLACE VIEW VIEW_DIM_LOCATION AS
SELECT DimLocationID,
    PostalCode,
    Address,
    City,
    Region,
    Country
FROM DIM_LOCATION;

CREATE OR REPLACE VIEW VIEW_DIM_PRODUCT AS
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

CREATE OR REPLACE VIEW VIEW_DIM_RESELLER AS
SELECT DimResellerID,
    DimLocationID,
    ResellerID,
    ResellerName,
    ContactName,
    PhoneNumber,
    EmailAddress
FROM DIM_RESELLER;

CREATE OR REPLACE VIEW VIEW_DIM_STORE AS
SELECT DimStoreID,
    DimLocationID,
    StoreID,
    StoreNumber,
    StoreManager,
    PhoneNumber
FROM DIM_STORE;

CREATE OR REPLACE VIEW VIEW_DIM_DATE AS
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

CREATE OR REPLACE VIEW VIEW_FACT_PRODUCTSALESTARGET AS
SELECT DimProductID,
    DimTargetDateID,
    ProductTargetSalesQuantity
FROM FACT_PRODUCTSALESTARGET;

CREATE OR REPLACE VIEW VIEW_FACT_SRCSALESTARGET AS
SELECT DimStoreID,
    DimResellerID,
    DimChannelID,
    DimTargetDateID,
    SalesTargetAmount
FROM FACT_SRCSALESTARGET;

CREATE OR REPLACE VIEW VIEW_FACT_SALESACTUAL AS
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

-- Q1a - How Are They Performing Compared To Target? Will They Meet Their 2014 Target?
Create or Replace View View_Store_Performance AS
Select Year,
    Month_Name,
    Month_Num_In_Year,
    Storenumber,
    Channelname,
    Sum(Actualsales) Over (
        Partition By Storenumber
        Order By Month_Num_In_Year Asc
    ) As Totalsales,
    Sum(Actualtarget) Over (
        Partition By Storenumber
        Order By Month_Num_In_Year Asc
    ) As Totaltarget
From (
        Select Year,
            Month_Name,
            Month_Num_In_Year,
            Storenumber,
            Channelname,
            Sum(Actualtarget) As Actualtarget,
            Sum(Actualsales) As Actualsales
        From (
                Select D.Year,
                    D.Month_Name,
                    D.Month_Num_In_Year,
                    S.Storenumber,
                    C.Channelname,
                    Sum(Ft.Salestargetamount) As Actualtarget,
                    0 As Actualsales
                From Fact_Srcsalestarget Ft
                    Inner Join Dim_Store S On Ft.Dimstoreid = S.Dimstoreid
                    Inner Join Dim_Channel C On Ft.Dimchannelid = C.Dimchannelid
                    Inner Join Dim_Date D On Ft.Dimtargetdateid = D.Date_Pkey
                Where D.Date_Pkey <= 20141031
                    And Storenumber In (10, 21)
                Group By D.Year,
                    D.Month_Name,
                    D.Month_Num_In_Year,
                    S.Storenumber,
                    C.Channelname
                Union
                Select D.Year,
                    D.Month_Name,
                    D.Month_Num_In_Year,
                    S.Storenumber,
                    C.Channelname,
                    0 As Actualtarget,
                    Sum(Fs.Salesamount) As Actualsales
                From Fact_Salesactual Fs
                    Inner Join Dim_Store S On Fs.Dimstoreid = S.Dimstoreid
                    Inner Join Dim_Channel C On Fs.Dimchannelid = C.Dimchannelid
                    Inner Join Dim_Date D On Fs.Dimsaledateid = D.Date_Pkey
                Where D.Date_Pkey <= 20141031
                    And Storenumber In (10, 21)
                Group By D.Year,
                    D.Month_Name,
                    D.Month_Num_In_Year,
                    S.Storenumber,
                    C.Channelname
            )
        Group By Year,
            Month_Name,
            Month_Num_In_Year,
            Storenumber,
            Channelname
    );

-- Q1b - Should either store be closed? Why or why not?
Create Or Replace View View_Store_Profit AS
Select Year,
    Month_Name,
    Month_Num_In_Year,
    Storenumber,
    Sum(Actualsales) Over (
        Partition By Storenumber
        Order By Month_Num_In_Year Asc
    ) As Totalsales,
    Sum(Actualtarget) Over (
        Partition By Storenumber
        Order By Month_Num_In_Year Asc
    ) As Totaltarget,
    ((Totalsales - Totaltarget) / Totaltarget) * 100 As Percentage
From (
        Select Year,
            Month_Name,
            Month_Num_In_Year,
            Storenumber,
            Sum(Actualtarget) As Actualtarget,
            Sum(Actualsales) As Actualsales
        From (
                Select D.Year,
                    D.Month_Name,
                    D.Month_Num_In_Year,
                    S.Storenumber,
                    Sum(Ft.Salestargetamount) As Actualtarget,
                    0 As Actualsales
                From Fact_Srcsalestarget Ft
                    Inner Join Dim_Store S On Ft.Dimstoreid = S.Dimstoreid
                    Inner Join Dim_Date D On Ft.Dimtargetdateid = D.Date_Pkey
                Where D.Date_Pkey <= 20141031
                    And Storenumber In (10, 21)
                Group By D.Year,
                    D.Month_Name,
                    D.Month_Num_In_Year,
                    S.Storenumber
                Union
                Select D.Year,
                    D.Month_Name,
                    D.Month_Num_In_Year,
                    S.Storenumber,
                    0 As Actualtarget,
                    Sum(Fs.Salesamount) As Actualsales
                From Fact_Salesactual Fs
                    Inner Join Dim_Store S On Fs.Dimstoreid = S.Dimstoreid
                    Inner Join Dim_Date D On Fs.Dimsaledateid = D.Date_Pkey
                Where D.Date_Pkey <= 20141031
                    And Storenumber In (10, 21)
                Group By D.Year,
                    D.Month_Name,
                    D.Month_Num_In_Year,
                    S.Storenumber
            )
        Group By Year,
            Month_Name,
            Month_Num_In_Year,
            Storenumber
    );

--Q1c - What Should Be Done In The Next Year To Maximize Store Profits?
CREATE OR REPLACE VIEW VIEW_MAXIMIZE_STORE_PROFIT AS
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
From Dim_Product P
    Left Join Fact_Salesactual Sa On P.Dimproductid = Sa.Dimproductid
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

--Q2 - Recommend 2013 bonus amounts for each store if the total bonus pool is $2,000,000 using a comparison of 2013 actual sales vs. 2013 sales targets as the basis for the recommendation.
CREATE OR REPLACE VIEW VIEW_BONUS AS
Select Year,
    Month_Name,
    Month_Num_In_Year,
    Storenumber,
    Sum(Actualsales) Over (
        Partition By Storenumber
        Order By Month_Num_In_Year Asc
    ) As Totalsales,
    Sum(Actualtarget) Over (
        Partition By Storenumber
        Order By Month_Num_In_Year Asc
    ) As Totaltarget,
    ((Totalsales - Totaltarget) / Totaltarget) * 100 As Percentage
From (
        Select Year,
            Month_Name,
            Month_Num_In_Year,
            Storenumber,
            Sum(Actualtarget) As Actualtarget,
            Sum(Actualsales) As Actualsales
        From (
                Select D.Year,
                    D.Month_Name,
                    D.Month_Num_In_Year,
                    S.Storenumber,
                    Sum(Ft.Salestargetamount) As Actualtarget,
                    0 As Actualsales
                From Fact_Srcsalestarget Ft
                    Inner Join Dim_Store S On Ft.Dimstoreid = S.Dimstoreid
                    Inner Join Dim_Date D On Ft.Dimtargetdateid = D.Date_Pkey
                Where Year = 2013
                    And S.Dimstoreid > -1
                Group By D.Year,
                    D.Month_Name,
                    D.Month_Num_In_Year,
                    S.Storenumber
                Union
                Select D.Year,
                    D.Month_Name,
                    D.Month_Num_In_Year,
                    S.Storenumber,
                    0 As Actualtarget,
                    Sum(Fs.Salesamount) As Actualsales
                From Fact_Salesactual Fs
                    Inner Join Dim_Store S On Fs.Dimstoreid = S.Dimstoreid
                    Inner Join Dim_Date D On Fs.Dimsaledateid = D.Date_Pkey
                Where Year = 2013
                    And S.Dimstoreid > -1
                Group By D.Year,
                    D.Month_Name,
                    D.Month_Num_In_Year,
                    S.Storenumber
            )
        Group By Year,
            Month_Name,
            Month_Num_In_Year,
            Storenumber
    );

--Q3 - Assess product sales by day of the week at stores 10 and 21. What can we learn about sales trends?
CREATE OR REPLACE VIEW VIEW_SALES_TRENDS AS
Select Date,
    Year,
    Month_Name,
    Month_Num_In_Year,
    Day_Name,
    Day_Num_In_Week,
    Day_Num_In_Month,
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
    Salesquantity As Productsalesquantity,
    Salesamount As Productsalesamount
From Fact_Salesactual Fs
    Inner Join Dim_Store S On Fs.Dimstoreid = S.Dimstoreid
    Inner Join Dim_Channel C On Fs.Dimchannelid = C.Dimchannelid
    Inner Join Dim_Product P On Fs.Dimproductid = P.Dimproductid
    Inner Join Dim_Date D On Fs.Dimsaledateid = D.Date_Pkey
Where D.Date_Pkey <= 20141031
    And Storenumber In (10, 21)
Group By Date,
    Year,
    Month_Name,
    Month_Num_In_Year,
    Day_Name,
    Day_Num_In_Week,
    Day_Num_In_Month,
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
    Salesquantity,
    Salesamount; 
    
--Q4 - Should any new stores be opened? Include all stores in your analysis if necessary. If so, where? Why or why not?
CREATE OR REPLACE VIEW VIEW_NEW_STORES AS
Select Year,
    Month_Name,
    Month_Num_In_Year,
    Storenumber,
    Postalcode,
    Address,
    City,
    Region,
    Country,
    Sum(Actualsales) Over (
        Partition By Storenumber
        Order By Month_Num_In_Year Asc
    ) As Totalsales,
    Sum(Actualtarget) Over (
        Partition By Storenumber
        Order By Month_Num_In_Year Asc
    ) As Totaltarget,
    ((Totalsales - Totaltarget) / Totaltarget) * 100 As Percentage
From (
        Select Year,
            Month_Name,
            Month_Num_In_Year,
            Storenumber,
            Postalcode,
            Address,
            City,
            Region,
            Country,
            Sum(Actualtarget) As Actualtarget,
            Sum(Actualsales) As Actualsales
        From (
                Select D.Year,
                    D.Month_Name,
                    D.Month_Num_In_Year,
                    S.Storenumber,
                    L.Postalcode,
                    L.Address,
                    L.City,
                    L.Region,
                    L.Country,
                    Sum(Ft.Salestargetamount) As Actualtarget,
                    0 As Actualsales
                From Fact_Srcsalestarget Ft
                    Inner Join Dim_Store S On Ft.Dimstoreid = S.Dimstoreid
                    Inner Join Dim_Location L On S.Dimlocationid = L.Dimlocationid
                    Inner Join Dim_Date D On Ft.Dimtargetdateid = D.Date_Pkey
                Where D.Date_Pkey <= 20141031
                    And S.Dimstoreid > -1
                Group By D.Year,
                    D.Month_Name,
                    D.Month_Num_In_Year,
                    S.Storenumber,
                    L.Postalcode,
                    L.Address,
                    L.City,
                    L.Region,
                    L.Country
                Union
                Select D.Year,
                    D.Month_Name,
                    D.Month_Num_In_Year,
                    S.Storenumber,
                    L.Postalcode,
                    L.Address,
                    L.City,
                    L.Region,
                    L.Country,
                    0 As Actualtarget,
                    Sum(Fs.Salesamount) As Actualsales
                From Fact_Salesactual Fs
                    Inner Join Dim_Store S On Fs.Dimstoreid = S.Dimstoreid
                    Inner Join Dim_Location L On Fs.Dimlocationid = L.Dimlocationid
                    Inner Join Dim_Date D On Fs.Dimsaledateid = D.Date_Pkey
                Where D.Date_Pkey <= 20141031
                    And S.Dimstoreid > -1
                Group By D.Year,
                    D.Month_Name,
                    D.Month_Num_In_Year,
                    S.Storenumber,
                    L.Postalcode,
                    L.Address,
                    L.City,
                    L.Region,
                    L.Country
            )
        Group By Year,
            Month_Name,
            Month_Num_In_Year,
            Storenumber,
            Postalcode,
            Address,
            City,
            Region,
            Country
    );