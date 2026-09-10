CREATE FUNCTION [dbo].[fn_GetEmployeesByDepartment]
(
    @Department NVARCHAR(50)
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        [ID],
        [UniqueCode],
        [Name],
        [Department],
        [Salary],
        [Status],
        [CreatedAt]
    FROM
        [dbo].[SchemaEvolutionDemo]
    WHERE
        [Department] = @Department
);
GO
