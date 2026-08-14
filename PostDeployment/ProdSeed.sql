-- Seed reference data for prod.Configuration
IF NOT EXISTS (SELECT 1 FROM [prod].[Configuration] WHERE [ConfigKey] = 'APP_ENV')
BEGIN
    INSERT INTO [prod].[Configuration] ([ConfigKey], [ConfigValue], [Description])
    VALUES 
        ('APP_ENV',         'Production', 'Active application environment mode'),
        ('MAX_RETRIES',     '5',          'Database transaction retry limit'),
        ('FEATURE_FLAG_V2', 'true',       'Enable Next-Gen features in prod');
    PRINT 'Inserted seed data into prod.Configuration';
END
GO

-- Seed reference data for prod.AuditSummary
IF NOT EXISTS (SELECT 1 FROM [prod].[AuditSummary] WHERE [ReleaseVersion] = 'v1.0.0-RELEASE')
BEGIN
    INSERT INTO [prod].[AuditSummary] ([ReleaseVersion], [Status])
    VALUES ('v1.0.0-RELEASE', 'Success');
    PRINT 'Inserted seed data into prod.AuditSummary';
END
GO

-- Seed reference data for prod.Departments
IF NOT EXISTS (SELECT 1 FROM [prod].[Departments] WHERE [DepartmentName] = 'Engineering')
BEGIN
    INSERT INTO [prod].[Departments] ([DepartmentCode], [DepartmentName], [Budget], [IsActive])
    VALUES 
        ('ENG',    'Engineering', 250000.00, 1),
        ('PROD',   'Product',     180000.00, 1),
        ('DEVOPS', 'DevOps',      120000.00, 1),
        ('FIN',    'Finance',     95000.00,  1);
    PRINT 'Inserted seed data into prod.Departments';
END
GO

-- Seed reference data for prod.EmployeeDummy
IF NOT EXISTS (SELECT 1 FROM [prod].[EmployeeDummy] WHERE [EmployeeName] = 'John Doe')
BEGIN
    INSERT INTO [prod].[EmployeeDummy] ([EmployeeName], [Department], [Salary], [EmailID], [PhoneNumber], [Address])
    VALUES 
        ('John Doe',   'Engineering', 95000.00, 'john.doe@company.com',   '9876543210', '123 Tech Park'),
        ('Jane Smith', 'Product',     88000.00, 'jane.smith@company.com', '9876543211', '456 Innovation Blvd'),
        ('Bob Wilson', 'DevOps',      92000.00, 'bob.wilson@company.com', '9876543212', '789 Cloud Ave');
    PRINT 'Inserted seed data into prod.EmployeeDummy';
END
GO
