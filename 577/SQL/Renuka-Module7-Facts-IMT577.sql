/*****************************************
 Course: IMT 577B
 Instructor: Sean Pettersen
 Assignment: Module 7
 Date: 05/15/2022
 *****************************************/

--==================================================
-------------Fact_SRCSalesTarget
--==================================================
-- Creating the Fact_SRCSalesTarget table
CREATE OR REPLACE TABLE Fact_SRCSalesTarget (
        DimStoreId INT CONSTRAINT FK_DimStoreID FOREIGN KEY REFERENCES Dim_Store(DimStoreId) NOT NULL, -- Foreign Key
        DimResellerID INT CONSTRAINT FK_DimResellerID FOREIGN KEY REFERENCES Dim_Reseller(DimResellerId) NOT NULL, -- Foreign Key
        DimChannelID INT CONSTRAINT FK_DimChannelID FOREIGN KEY REFERENCES Dim_Channel(DimChannelId) NOT NULL, -- Foreign Key
        DimTargetDateID NUMBER(9, 0) CONSTRAINT FK_DimTargetDateID FOREIGN KEY REFERENCES Dim_Date(DATE_PKEY) NOT NULL, -- Foreign Key
        SalesTargetAmount FLOAT
    );
-- Inserting data into the Fact_SRCSalesTarget table
INSERT INTO Fact_SRCSalesTarget (
        DimStoreId,
        DimResellerID,
        DimChannelID,
        DimTargetDateID,
        SalesTargetAmount
    )
SELECT DISTINCT NVL(DimStoreId, -1) AS DimStoreId,
    NVL(DimResellerID, -1) AS DimResellerID,
    NVL(DimChannelID, -1) AS DimChannelID,
    DATE_PKEY as DimTargetDateID,
    (TargetSalesAmount / 365) AS SalesTargetAmount
FROM STAGE_TARGETDATACHANNELRESELLERANDSTORE tdcrs
    INNER JOIN Dim_Channel c ON c.ChannelName = CASE
        WHEN tdcrs.ChannelName = 'Online' THEN 'On-line'
        ELSE tdcrs.ChannelName
    END
    LEFT JOIN Dim_Reseller r ON tdcrs.TargetName = CASE
        WHEN r.ResellerName = 'Mississipi Distributors' THEN 'Mississippi Distributors' -- Correcting a typo
        ELSE r.ResellerName
    END 
    LEFT JOIN Dim_Date d ON d.YEAR = tdcrs.YEAR
    LEFT JOIN Dim_Store s ON s.StoreNumber = CASE
        WHEN tdcrs.TargetName = 'Store Number 5' then 5
        WHEN tdcrs.TargetName = 'Store Number 8' then 8
        WHEN tdcrs.TargetName = 'Store Number 10' then 10
        WHEN tdcrs.TargetName = 'Store Number 21' then 21
        WHEN TargetName = 'Store Number 39' then 39
        WHEN TargetName = 'Store Number 34' then 34
        ELSE -1
    END = -1;
-- 8030 rows inserted

--==================================================
-------------Fact_SalesActual
--==================================================
-- Creating the Fact_SalesActual table
CREATE OR REPLACE TABLE FACT_SalesActual (
        DimProductID INT CONSTRAINT FK_DimProductID FOREIGN KEY REFERENCES Dim_Product(DimProductID) NOT NULL, -- Foreign Key
        DimStoreId INT CONSTRAINT FK_DimStoreID FOREIGN KEY REFERENCES Dim_Store(DimStoreID) NOT NULL, -- Foreign Key
        DimResellerID INT CONSTRAINT FK_DimResellerID FOREIGN KEY REFERENCES Dim_Reseller(DimResellerID) NOT NULL, -- Foreign Key
        DimCustomerID INT CONSTRAINT FK_DimCustomerID FOREIGN KEY REFERENCES Dim_Customer(DimCustomerID) NOT NULL, -- Foreign Key
        DimChannelID INT CONSTRAINT FK_DimChannelID FOREIGN KEY REFERENCES Dim_Channel(DimChannelId) NOT NULL, -- Foreign Key
        DimSaleDateID NUMBER(9, 0) CONSTRAINT FK_DATE_PKEY FOREIGN KEY REFERENCES Dim_Date(Date_PKey) NOT NULL, -- Foreign Key
        DimLocationID INT CONSTRAINT FK_DimLocationID FOREIGN KEY REFERENCES Dim_Location(DimLocationID) NOT NULL, -- Foreign Key
        SalesHeaderID INT,
        SalesDetailID INT,
        SalesAmount FLOAT,
        SalesQuantity INT,
        SaleUnitPrice FLOAT,
        SaleExtendedCost FLOAT,
        SaleTotalProfit FLOAT
    );
-- Inserting data into the Fact_SalesActual table
INSERT INTO Fact_SalesActual (
        DimProductID,
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
    )
SELECT DISTINCT NVL(DimProductID, -1) AS DimProductID,
    NVL(DimStoreID, -1) AS DimStoreID,
    NVL(DimResellerID, -1) AS DimResellerID,
    NVL(DimCustomerID, -1) AS DimCustomerID,
    NVL(DimChannelID, -1) AS DimChannelID,
    DATE_PKEY AS DimSaleDateID,
    NVL(l.DimLocationID, -1) AS DimLocationID,
    NVL(sh.SalesHeaderID, -1) AS SalesHeaderID,
    NVL(SalesDetailID, -1) AS SalesDetailID,
    SalesAmount,
    SalesQuantity,
    (SalesAmount / SalesQuantity) AS SaleUnitPrice,
    (ProductCost * SalesQuantity) AS SaleExtendedCost,
    ((SaleUnitPrice - ProductCost) * SalesQuantity) AS SaleTotalProfit
FROM Stage_SalesHeader sh
    JOIN Stage_SalesDetail sd ON sh.SalesHeaderID = sd.SalesHeaderID
    LEFT JOIN Dim_Product p ON sd.ProductID = p.ProductID
    LEFT JOIN Dim_Store s ON sh.StoreID = s.StoreID
    LEFT JOIN Dim_Reseller r ON sh.ResellerID = r.ResellerID
    LEFT JOIN Dim_Customer cu ON sh.CustomerID = cu.CustomerID
    LEFT JOIN Dim_Channel ch ON sh.ChannelID = ch.ChannelID
    LEFT JOIN Dim_Date d ON d.Date = to_date(sh.date, 'MM/DD/YY')
    LEFT JOIN Dim_Location l ON l.DimLocationID = s.DimLocationID
    OR l.DimLocationID = r.DimLocationID
    OR l.DimLocationID = cu.DimLocationID;
-- 187,320 rows inserted

--==================================================
-------------Fact_ProductSalesTarget
--==================================================
-- Creating the Fact_ProductSalesTarget table
CREATE OR REPLACE TABLE Fact_ProductSalesTarget (
        DimProductID INT CONSTRAINT FK_DimProductID FOREIGN KEY REFERENCES Dim_Product(DimProductID), --Foreign Key
        DimTargetDateID NUMBER(9, 0) CONSTRAINT FK_DimTargetDateID FOREIGN KEY REFERENCES Dim_Date(DATE_PKEY), --Foreign Key
        ProductTargetSalesQuantity INT
    );
-- Inserting data into the Fact_ProductSalesTarget table
INSERT INTO Fact_ProductSalesTarget (
        DimProductID,
        DimTargetDateID,
        ProductTargetSalesQuantity
    )
SELECT DISTINCT NVL(DimProductID, -1) AS DimProductID,
    DATE_PKEY AS DimTargetDateID,
    (SalesQuantityTarget / 365) AS ProductTargetSalesQuantity
FROM Stage_TargetDataProduct tdp
    LEFT JOIN Dim_Product ON tdp.ProductID = Dim_Product.ProductID
    LEFT JOIN Dim_Date d ON d.Year = tdp.Year;
-- 17,520 rows inserted