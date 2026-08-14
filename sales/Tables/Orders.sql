CREATE TABLE [sales].[Orders] (
    [OrderID]       INT IDENTITY(1,1) NOT NULL,
    [OrderNumber]   NVARCHAR(50) NOT NULL,
    [CustomerID]    INT NOT NULL,
    [OrderDate]     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    [TotalAmount]   DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    [OrderStatus]   NVARCHAR(20) NOT NULL DEFAULT 'Pending',
    [CreatedAt]     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    PRIMARY KEY CLUSTERED ([OrderID] ASC),
    CONSTRAINT [CK_Orders_Status] CHECK ([OrderStatus] IN ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled')),
    CONSTRAINT [UQ_Orders_OrderNumber] UNIQUE ([OrderNumber])
);
GO

CREATE NONCLUSTERED INDEX [IX_Orders_CustomerID]
    ON [sales].[Orders] ([CustomerID] ASC);
GO
