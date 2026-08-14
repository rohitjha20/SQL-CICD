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
