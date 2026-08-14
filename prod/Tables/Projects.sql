CREATE TABLE [prod].[Projects] (
    [ProjectID]      INT IDENTITY(1,1) NOT NULL,
    [ProjectName]    NVARCHAR(150) NOT NULL,
    [DepartmentID]   INT NOT NULL,
    [StartDate]      DATE NOT NULL,
    [EndDate]        DATE NULL,
    [ProjectStatus]  NVARCHAR(20) NOT NULL DEFAULT 'Planning',
    [EstimatedCost]  DECIMAL(18,2) NULL,
    [CreatedAt]      DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    PRIMARY KEY CLUSTERED ([ProjectID] ASC),
    CONSTRAINT [CK_prod_Projects_ProjectStatus] CHECK ([ProjectStatus] IN ('Planning', 'In-Progress', 'Completed', 'On-Hold', 'Cancelled')),
    CONSTRAINT [CK_prod_Projects_DateOrder] CHECK ([EndDate] IS NULL OR [EndDate] >= [StartDate])
);
GO

CREATE NONCLUSTERED INDEX [IX_prod_Projects_DepartmentID]
    ON [prod].[Projects] ([DepartmentID] ASC);
GO
