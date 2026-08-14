CREATE TABLE [dbo].[Projects] (
    [ProjectID]      INT IDENTITY(1,1) NOT NULL,
    [ProjectName]    NVARCHAR(150) NOT NULL,
    [DepartmentID]   INT NOT NULL,
    [StartDate]      DATE NOT NULL,
    [EndDate]        DATE NULL,
    [ProjectStatus]  NVARCHAR(20) NOT NULL DEFAULT 'Planning'
        CHECK ([ProjectStatus] IN ('Planning', 'In-Progress', 'Completed', 'On-Hold', 'Cancelled')),
    [EstimatedCost]  DECIMAL(18,2) NULL,
    [CreatedAt]      DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    PRIMARY KEY CLUSTERED ([ProjectID] ASC),
    CONSTRAINT [FK_Projects_Departments] FOREIGN KEY ([DepartmentID])
        REFERENCES [dbo].[Departments] ([DepartmentID]),
    CONSTRAINT [CK_Projects_DateOrder] CHECK ([EndDate] IS NULL OR [EndDate] >= [StartDate])
);
GO

CREATE NONCLUSTERED INDEX [IX_Projects_DepartmentID]
    ON [dbo].[Projects] ([DepartmentID] ASC);
GO
