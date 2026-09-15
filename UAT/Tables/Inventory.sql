-- ❌ WRONG: This is in UAT/ folder but uses [roh] (production) schema!
CREATE TABLE [roh].[Inventory] (
    [InventoryID] INT IDENTITY(1,1) NOT NULL,
    [ProductName] NVARCHAR(200) NOT NULL,
    [Quantity]    INT NOT NULL DEFAULT 0,
    PRIMARY KEY CLUSTERED ([InventoryID] ASC)
);
GO
