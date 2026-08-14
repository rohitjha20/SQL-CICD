CREATE VIEW [dbo].[vw_ActiveEmployees]
AS
    SELECT
        [ID],
        [UniqueCode],
        [Name],
        [Department],
        [Salary],
        [CreatedAt]
    FROM
        [dbo].[SchemaEvolutionDemo]
    WHERE
        [Status] = 'Active';
GO
