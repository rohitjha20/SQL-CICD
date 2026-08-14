CREATE TABLE [sales].[Customers] (
    [CustomerID]    INT IDENTITY(1,1) NOT NULL,
    [CustomerCode]  NVARCHAR(20) NOT NULL,
    [CustomerName]  NVARCHAR(150) NOT NULL,
    [Email]         NVARCHAR(200) NOT NULL,
    [Country]       NVARCHAR(50) NOT NULL DEFAULT 'India',
    [IsActive]      BIT NOT NULL DEFAULT 1,
    [CreatedAt]     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    PRIMARY KEY CLUSTERED ([CustomerID] ASC),
    CONSTRAINT [UQ_Customers_CustomerCode] UNIQUE ([CustomerCode]),
    CONSTRAINT [UQ_Customers_Email] UNIQUE ([Email])
);
GO
