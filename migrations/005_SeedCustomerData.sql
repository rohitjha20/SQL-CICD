-- Migration: Seed reference data
INSERT INTO [uat].[Customers] ([CustomerName], [Email])
VALUES 
    (N'Contoso Ltd', N'info@contoso.com'),
    (N'Fabrikam Inc', N'hello@fabrikam.com'),
    (N'Northwind Traders', N'sales@northwind.com');
GO
