-- 5. Stored Procedure Condition
CREATE PROCEDURE [dbo].[GetEmployeeDetails]
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        [ID],
        [UniqueCode],
        [Name],
        [Department],
        [Status]
    FROM 
        [dbo].[SchemaEvolutionDemo]
    WHERE 
        [ID] = @EmployeeID;
END
GO
