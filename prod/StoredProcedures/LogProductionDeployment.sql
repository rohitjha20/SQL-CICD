CREATE PROCEDURE [prod].[LogProductionDeployment]
    @ReleaseVersion NVARCHAR(50),
    @Status         NVARCHAR(20) = 'Success'
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [prod].[AuditSummary] ([ReleaseVersion], [Status])
    VALUES (@ReleaseVersion, @Status);
END;
GO
