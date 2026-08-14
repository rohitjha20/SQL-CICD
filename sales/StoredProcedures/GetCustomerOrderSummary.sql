CREATE PROCEDURE [sales].[GetCustomerOrderSummary]
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        c.[CustomerID],
        c.[CustomerCode],
        c.[CustomerName],
        c.[Email],
        COUNT(o.[OrderID]) AS TotalOrders,
        ISNULL(SUM(o.[TotalAmount]), 0.00) AS LifetimeSpend
    FROM [sales].[Customers] c
    LEFT JOIN [sales].[Orders] o ON c.[CustomerID] = o.[CustomerID]
    WHERE c.[CustomerID] = @CustomerID
    GROUP BY c.[CustomerID], c.[CustomerCode], c.[CustomerName], c.[Email];
END;
GO
