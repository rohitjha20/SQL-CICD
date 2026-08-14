CREATE TABLE [prod].[AuditSummary] (
    [SummaryID]      INT IDENTITY(1,1) NOT NULL,
    [Environment]    NVARCHAR(20) NOT NULL DEFAULT 'Production',
    [ReleaseVersion] NVARCHAR(50) NOT NULL,
    [DeployedAt]     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    [Status]         NVARCHAR(20) NOT NULL DEFAULT 'Success',
    PRIMARY KEY CLUSTERED ([SummaryID] ASC)
);
GO
