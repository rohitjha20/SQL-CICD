CREATE VIEW [sales].[vw_HighValueOrders]
AS
    SELECT
        o.[OrderID],
        o.[OrderNumber],
        o.[CustomerID],
        c.[CustomerName],
        c.[Email],
        o.[OrderDate],
        o.[TotalAmount],
        o.[OrderStatus]
    FROM [sales].[Orders] o
    INNER JOIN [sales].[Customers] c ON o.[CustomerID] = c.[CustomerID]
    WHERE o.[TotalAmount] >= 50000.00;
GO
