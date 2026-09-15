-- ✅ CORRECT: This is in UAT/ folder and uses [uat] schema
CREATE TABLE [uat].[Products] (
    [ProductID]   INT IDENTITY(1,1) NOT NULL,
    [ProductName] NVARCHAR(200) NOT NULL,
    [Price]       DECIMAL(18,2) NOT NULL,
    PRIMARY KEY CLUSTERED ([ProductID] ASC)
);
GO
