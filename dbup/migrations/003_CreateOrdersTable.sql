CREATE TABLE [uat].[Orders] (
    [OrderID]    INT IDENTITY(1,1) NOT NULL,
    [CustomerID] INT NOT NULL,
    [OrderDate]  DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    [TotalAmount] DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    PRIMARY KEY CLUSTERED ([OrderID] ASC),
    CONSTRAINT [FK_Orders_Customers] FOREIGN KEY ([CustomerID])
        REFERENCES [uat].[Customers] ([CustomerID])
);
GO
