CREATE TABLE [prod].[Departments]
(
    [DepartmentID]   INT IDENTITY(1,1) NOT NULL,
    [DepartmentCode] NVARCHAR(10) NULL,
    [DepartmentName] NVARCHAR(100) NOT NULL,
    [Budget]         DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    [IsActive]       BIT NOT NULL DEFAULT 1,
    [CreatedAt]      DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    PRIMARY KEY CLUSTERED ([DepartmentID] ASC)
);
GO
