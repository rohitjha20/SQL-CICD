CREATE FUNCTION [dbo].[fn_CalculateBonus]
(
    @Salary     DECIMAL(18, 2),
    @Department NVARCHAR(50)
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @BonusPercent DECIMAL(5, 2);

    SET @BonusPercent = CASE
        WHEN @Department = 'Engineering' THEN 15.00
        WHEN @Department = 'Product'     THEN 12.00
        WHEN @Department = 'DevOps'      THEN 13.00
        ELSE 10.00
    END;

    RETURN @Salary * @BonusPercent / 100.00;
END;
GO
