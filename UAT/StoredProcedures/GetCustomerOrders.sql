CREATE PROCEDURE [uat].[GetCustomerOrders]
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT o.[OrderID], o.[OrderDate], o.[TotalAmount]
    FROM [uat].[Orders] o
    WHERE o.[CustomerID] = @CustomerID
    ORDER BY o.[OrderDate] DESC;
END
GO
