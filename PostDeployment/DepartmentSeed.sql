-- Seed reference data for dbo.Departments
IF NOT EXISTS (SELECT 1 FROM [dbo].[Departments] WHERE [DepartmentCode] = 'ENG')
BEGIN
    INSERT INTO [dbo].[Departments] ([DepartmentCode], [DepartmentName], [Budget], [IsActive])
    VALUES 
        ('ENG',    'Engineering',      500000.00, 1),
        ('PROD',   'Product Design',   300000.00, 1),
        ('DEVOPS', 'Cloud Infrastructure', 350000.00, 1),
        ('FIN',    'Finance & Ops',    200000.00, 1);
    PRINT 'Inserted seed reference data into dbo.Departments';
END
GO
