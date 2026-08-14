-- Seed reference data for dbo.Departments
IF NOT EXISTS (SELECT 1 FROM [dbo].[Departments] WHERE [DepartmentName] = 'Engineering')
BEGIN
    INSERT INTO [dbo].[Departments] ([DepartmentName], [Budget], [IsActive])
    VALUES 
        ('Engineering',          500000.00, 1),
        ('Product Design',       300000.00, 1),
        ('Cloud Infrastructure', 350000.00, 1),
        ('Finance & Ops',        200000.00, 1);
    PRINT 'Inserted seed reference data into dbo.Departments';
END
GO
