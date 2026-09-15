CREATE PROCEDURE [roh].[GetCustomerOrders]
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT o.[OrderID], o.[OrderDate], o.[TotalAmount]
    FROM [roh].[Orders] o
    WHERE o.[CustomerID] = @CustomerID
    ORDER BY o.[OrderDate] DESC;
END
GO
