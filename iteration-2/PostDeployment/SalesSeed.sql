-- Seed reference data for sales.Customers
IF NOT EXISTS (SELECT 1 FROM [sales].[Customers] WHERE [CustomerCode] = 'CUST001')
BEGIN
    INSERT INTO [sales].[Customers] ([CustomerCode], [CustomerName], [Email], [Country])
    VALUES 
        ('CUST001', 'Reliance Industries', 'procurement@ril.com', 'India'),
        ('CUST002', 'Tata Consultancy',    'vendor@tcs.com',        'India'),
        ('CUST003', 'Infosys Ltd',         'orders@infosys.com',     'India');
    PRINT 'Inserted seed data into sales.Customers';
END
GO

-- Seed reference data for sales.Orders
IF NOT EXISTS (SELECT 1 FROM [sales].[Orders] WHERE [OrderNumber] = 'ORD-2026-001')
BEGIN
    INSERT INTO [sales].[Orders] ([OrderNumber], [CustomerID], [TotalAmount], [OrderStatus])
    VALUES 
        ('ORD-2026-001', 1, 150000.00, 'Delivered'),
        ('ORD-2026-002', 1, 45000.00,  'Shipped'),
        ('ORD-2026-003', 2, 85000.00,  'Processing'),
        ('ORD-2026-004', 3, 220000.00, 'Pending');
    PRINT 'Inserted seed data into sales.Orders';
END
GO
