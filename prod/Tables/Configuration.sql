CREATE TABLE [prod].[Configuration] (
    [ConfigKey]     NVARCHAR(100) NOT NULL,
    [ConfigValue]   NVARCHAR(500) NOT NULL,
    [Description]   NVARCHAR(250) NULL,
    [LastUpdated]   DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    PRIMARY KEY CLUSTERED ([ConfigKey] ASC)
);
GO
