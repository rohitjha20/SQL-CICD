CREATE TABLE [dbo].[SchemaEvolutionDemo]
(
    -- 1. Primary Key Condition
    [ID] INT NOT NULL PRIMARY KEY,

    -- 2. Unique Key Condition
    [UniqueCode] NVARCHAR(50) NOT NULL UNIQUE,

    [Name] NVARCHAR(100) NOT NULL,
    [Department] NVARCHAR(50) NULL,
    [Salary] DECIMAL(18, 2) NULL,

    -- 3. Constraint Condition (CHECK and DEFAULT)
    [Status] NVARCHAR(20) NOT NULL DEFAULT 'Active' CHECK ([Status] IN ('Active', 'Inactive', 'Pending')),

    [CreatedAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- 4. Index Condition
CREATE NONCLUSTERED INDEX [IX_SchemaEvolutionDemo_Department]
    ON [dbo].[SchemaEvolutionDemo] ([Department] ASC);
GO
