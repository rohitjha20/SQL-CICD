CREATE VIEW [prod].[vw_ProductionHealth]
AS
    SELECT
        [SummaryID],
        [Environment],
        [ReleaseVersion],
        [DeployedAt],
        [Status]
    FROM [prod].[AuditSummary];
GO
