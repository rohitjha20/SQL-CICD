-- ✅ CORRECT: UAT/ folder with [uat] schema
CREATE TABLE [uat].[Inventory] (
    [InventoryID] INT IDENTITY(1,1) NOT NULL,
    [ProductName] NVARCHAR(200) NOT NULL,
    [Quantity]    INT NOT NULL DEFAULT 0,
    [UpdatedAt]   DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    PRIMARY KEY CLUSTERED ([InventoryID] ASC)
);
GO
