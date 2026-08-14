CREATE TABLE [dbo].[AuditLog] (
    [AuditID]      INT            IDENTITY (1, 1) NOT NULL,
    [TableName]    NVARCHAR (128) NOT NULL,
    [Operation]    NVARCHAR (10)  NOT NULL,
    [RecordID]     INT            NOT NULL,
    [ChangedBy]    NVARCHAR (128) NOT NULL DEFAULT SUSER_SNAME(),
    [ChangedAt]    DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    [OldValues]    NVARCHAR (MAX) NULL,
    [NewValues]    NVARCHAR (MAX) NULL,
    PRIMARY KEY CLUSTERED ([AuditID] ASC)
);
GO
