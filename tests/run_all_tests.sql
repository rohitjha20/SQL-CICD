-- ==============================================================================
-- AUTOMATED TEST SUITE FOR AZURE SQL DATABASE (appdb)
-- Multi-Schema Test Harness (dbo, sales, prod)
-- ==============================================================================

SET NOCOUNT ON;

-- 1. Create Temporary Test Harness Table
IF OBJECT_ID('tempdb..#TestResults') IS NOT NULL DROP TABLE #TestResults;
CREATE TABLE #TestResults (
    [TestID]      INT IDENTITY(1,1) PRIMARY KEY,
    [TestNumber]  INT NOT NULL,
    [Component]   NVARCHAR(50) NOT NULL,
    [TestName]    NVARCHAR(150) NOT NULL,
    [Status]      NVARCHAR(10) NOT NULL, -- 'PASSED' or 'FAILED'
    [Details]     NVARCHAR(500) NULL,
    [ExecutedAt]  DATETIME2 DEFAULT SYSUTCDATETIME()
);

PRINT '==============================================================================';
PRINT '🧪 EXECUTING MULTI-SCHEMA AZURE SQL TEST SUITE (dbo, sales, prod)';
PRINT 'Target Server: freetier-sqlserver-central.database.windows.net | Database: appdb';
PRINT '==============================================================================' + CHAR(13);

-- ==============================================================================
-- TEST 1: Schema Object Existence Verification (dbo, sales, prod)
-- ==============================================================================
BEGIN TRY
    DECLARE @MissingObjects NVARCHAR(500) = '';

    -- DBO schema
    IF OBJECT_ID('dbo.EmployeeDummy', 'U') IS NULL SET @MissingObjects += 'Table:dbo.EmployeeDummy, ';
    IF OBJECT_ID('dbo.person', 'U') IS NULL SET @MissingObjects += 'Table:dbo.person, ';
    IF OBJECT_ID('dbo.SchemaEvolutionDemo', 'U') IS NULL SET @MissingObjects += 'Table:dbo.SchemaEvolutionDemo, ';
    IF OBJECT_ID('dbo.AuditLog', 'U') IS NULL SET @MissingObjects += 'Table:dbo.AuditLog, ';
    IF OBJECT_ID('dbo.Departments', 'U') IS NULL SET @MissingObjects += 'Table:dbo.Departments, ';
    IF OBJECT_ID('dbo.Projects', 'U') IS NULL SET @MissingObjects += 'Table:dbo.Projects, ';
    IF OBJECT_ID('dbo.vw_ActiveEmployees', 'V') IS NULL SET @MissingObjects += 'View:dbo.vw_ActiveEmployees, ';
    IF OBJECT_ID('dbo.GetEmployeeDetails', 'P') IS NULL SET @MissingObjects += 'SP:dbo.GetEmployeeDetails, ';
    IF OBJECT_ID('dbo.fn_CalculateBonus', 'FN') IS NULL SET @MissingObjects += 'ScalarFunc:dbo.fn_CalculateBonus, ';
    IF OBJECT_ID('dbo.fn_GetEmployeesByDepartment', 'IF') IS NULL 
       AND OBJECT_ID('dbo.fn_GetEmployeesByDepartment', 'TF') IS NULL SET @MissingObjects += 'TVF:dbo.fn_GetEmployeesByDepartment, ';
    IF OBJECT_ID('dbo.trg_AuditEmployeeChanges', 'TR') IS NULL SET @MissingObjects += 'Trigger:dbo.trg_AuditEmployeeChanges, ';

    -- SALES schema
    IF OBJECT_ID('sales.Customers', 'U') IS NULL SET @MissingObjects += 'Table:sales.Customers, ';
    IF OBJECT_ID('sales.Orders', 'U') IS NULL SET @MissingObjects += 'Table:sales.Orders, ';
    IF OBJECT_ID('sales.vw_HighValueOrders', 'V') IS NULL SET @MissingObjects += 'View:sales.vw_HighValueOrders, ';
    IF OBJECT_ID('sales.GetCustomerOrderSummary', 'P') IS NULL SET @MissingObjects += 'SP:sales.GetCustomerOrderSummary, ';

    -- PROD schema
    IF OBJECT_ID('prod.EmployeeDummy', 'U') IS NULL SET @MissingObjects += 'Table:prod.EmployeeDummy, ';
    IF OBJECT_ID('prod.person', 'U') IS NULL SET @MissingObjects += 'Table:prod.person, ';
    IF OBJECT_ID('prod.Departments', 'U') IS NULL SET @MissingObjects += 'Table:prod.Departments, ';
    IF OBJECT_ID('prod.Projects', 'U') IS NULL SET @MissingObjects += 'Table:prod.Projects, ';
    IF OBJECT_ID('prod.SchemaEvolutionDemo', 'U') IS NULL SET @MissingObjects += 'Table:prod.SchemaEvolutionDemo, ';
    IF OBJECT_ID('prod.AuditLog', 'U') IS NULL SET @MissingObjects += 'Table:prod.AuditLog, ';
    IF OBJECT_ID('prod.AuditSummary', 'U') IS NULL SET @MissingObjects += 'Table:prod.AuditSummary, ';
    IF OBJECT_ID('prod.Configuration', 'U') IS NULL SET @MissingObjects += 'Table:prod.Configuration, ';
    IF OBJECT_ID('prod.vw_ProductionHealth', 'V') IS NULL SET @MissingObjects += 'View:prod.vw_ProductionHealth, ';
    IF OBJECT_ID('prod.LogProductionDeployment', 'P') IS NULL SET @MissingObjects += 'SP:prod.LogProductionDeployment, ';

    IF @MissingObjects = ''
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (1, 'Schema', 'Verify All Multi-Schema Objects Exist', 'PASSED', 'All objects in dbo, sales, and prod schemas exist.');
    ELSE
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (1, 'Schema', 'Verify All Multi-Schema Objects Exist', 'FAILED', 'Missing objects: ' + @MissingObjects);
END TRY
BEGIN CATCH
    INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
    VALUES (1, 'Schema', 'Verify All Multi-Schema Objects Exist', 'FAILED', ERROR_MESSAGE());
END CATCH;

-- ==============================================================================
-- TEST 2: Table Constraints & Defaults (SchemaEvolutionDemo)
-- ==============================================================================
BEGIN TRY
    DELETE FROM dbo.SchemaEvolutionDemo WHERE [ID] = 9001;
    INSERT INTO dbo.SchemaEvolutionDemo ([ID], [UniqueCode], [Name], [Department], [Salary])
    VALUES (9001, 'TEST_CODE_9001', 'Test Default User', 'Engineering', 90000.00);

    DECLARE @DefaultStatus NVARCHAR(20);
    DECLARE @DefaultCreatedAt DATETIME2;
    SELECT @DefaultStatus = [Status], @DefaultCreatedAt = [CreatedAt]
    FROM dbo.SchemaEvolutionDemo WHERE [ID] = 9001;

    IF @DefaultStatus = 'Active' AND @DefaultCreatedAt IS NOT NULL
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (2, 'Tables', 'SchemaEvolutionDemo Default Constraints', 'PASSED', 'Default Status=''Active'' and CreatedAt correctly set.');
    ELSE
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (2, 'Tables', 'SchemaEvolutionDemo Default Constraints', 'FAILED', 'Unexpected defaults: Status=' + ISNULL(@DefaultStatus,'NULL'));

    DELETE FROM dbo.SchemaEvolutionDemo WHERE [ID] = 9001;
END TRY
BEGIN CATCH
    INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
    VALUES (2, 'Tables', 'SchemaEvolutionDemo Default Constraints', 'FAILED', ERROR_MESSAGE());
    DELETE FROM dbo.SchemaEvolutionDemo WHERE [ID] = 9001;
END CATCH;

-- ==============================================================================
-- TEST 3: Negative Test - CHECK Constraint Rejection
-- ==============================================================================
BEGIN TRY
    INSERT INTO dbo.SchemaEvolutionDemo ([ID], [UniqueCode], [Name], [Department], [Salary], [Status])
    VALUES (9002, 'TEST_CODE_9002', 'Invalid Status User', 'HR', 50000.00, 'Suspended');

    INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
    VALUES (3, 'Constraints', 'CHECK Constraint Rejection Test', 'FAILED', 'Invalid status ''Suspended'' was unexpectedly accepted.');
    DELETE FROM dbo.SchemaEvolutionDemo WHERE [ID] = 9002;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 547
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (3, 'Constraints', 'CHECK Constraint Rejection Test', 'PASSED', 'CHECK constraint successfully rejected invalid Status value (Error 547).');
    ELSE
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (3, 'Constraints', 'CHECK Constraint Rejection Test', 'FAILED', 'Unexpected error: ' + ERROR_MESSAGE());
END CATCH;

-- ==============================================================================
-- TEST 4: Post-Deployment Reference & Seed Data Verification (dbo, sales, prod)
-- ==============================================================================
BEGIN TRY
    DECLARE @PersonCount INT = (SELECT COUNT(*) FROM dbo.person);
    DECLARE @CustomerCount INT = (SELECT COUNT(*) FROM sales.Customers);
    DECLARE @ProdConfigCount INT = (SELECT COUNT(*) FROM prod.Configuration);

    IF @PersonCount >= 3 AND @CustomerCount >= 3 AND @ProdConfigCount >= 3
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (4, 'PostDeploy', 'Multi-Schema Seed Data Verification', 'PASSED', 'person=' + CAST(@PersonCount AS VARCHAR) + ', sales.Customers=' + CAST(@CustomerCount AS VARCHAR) + ', prod.Config=' + CAST(@ProdConfigCount AS VARCHAR));
    ELSE
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (4, 'PostDeploy', 'Multi-Schema Seed Data Verification', 'FAILED', 'Insufficient seed data.');
END TRY
BEGIN CATCH
    INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
    VALUES (4, 'PostDeploy', 'Multi-Schema Seed Data Verification', 'FAILED', ERROR_MESSAGE());
END CATCH;

-- ==============================================================================
-- TEST 5: View Logic (vw_ActiveEmployees)
-- ==============================================================================
BEGIN TRY
    DELETE FROM dbo.SchemaEvolutionDemo WHERE [ID] IN (9003, 9004);
    INSERT INTO dbo.SchemaEvolutionDemo ([ID], [UniqueCode], [Name], [Department], [Salary], [Status])
    VALUES 
        (9003, 'TEST_CODE_9003', 'Active View User', 'Engineering', 80000.00, 'Active'),
        (9004, 'TEST_CODE_9004', 'Inactive View User', 'Engineering', 80000.00, 'Inactive');

    DECLARE @ActiveVisible INT = (SELECT COUNT(*) FROM dbo.vw_ActiveEmployees WHERE [ID] = 9003);
    DECLARE @InactiveVisible INT = (SELECT COUNT(*) FROM dbo.vw_ActiveEmployees WHERE [ID] = 9004);

    IF @ActiveVisible = 1 AND @InactiveVisible = 0
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (5, 'Views', 'vw_ActiveEmployees Status Filtering', 'PASSED', 'View correctly returns Active records and filters out Inactive records.');
    ELSE
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (5, 'Views', 'vw_ActiveEmployees Status Filtering', 'FAILED', 'Active Visible=' + CAST(@ActiveVisible AS VARCHAR) + ', Inactive Visible=' + CAST(@InactiveVisible AS VARCHAR));

    DELETE FROM dbo.SchemaEvolutionDemo WHERE [ID] IN (9003, 9004);
END TRY
BEGIN CATCH
    INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
    VALUES (5, 'Views', 'vw_ActiveEmployees Status Filtering', 'FAILED', ERROR_MESSAGE());
    DELETE FROM dbo.SchemaEvolutionDemo WHERE [ID] IN (9003, 9004);
END CATCH;

-- ==============================================================================
-- TEST 6: Scalar Function (fn_CalculateBonus)
-- ==============================================================================
BEGIN TRY
    DECLARE @EngBonus DECIMAL(18,2) = dbo.fn_CalculateBonus(100000.00, 'Engineering');
    DECLARE @ProdBonus DECIMAL(18,2) = dbo.fn_CalculateBonus(100000.00, 'Product');
    DECLARE @DevOpsBonus DECIMAL(18,2) = dbo.fn_CalculateBonus(100000.00, 'DevOps');
    DECLARE @OtherBonus DECIMAL(18,2) = dbo.fn_CalculateBonus(100000.00, 'Marketing');

    IF @EngBonus = 15000.00 AND @ProdBonus = 12000.00 AND @DevOpsBonus = 13000.00 AND @OtherBonus = 10000.00
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (6, 'Functions', 'fn_CalculateBonus Department Logic', 'PASSED', 'Correct bonus rates computed for Engineering (15%), Product (12%), DevOps (13%), Default (10%).');
    ELSE
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (6, 'Functions', 'fn_CalculateBonus Department Logic', 'FAILED', 'Calculated bonuses mismatch expected values.');
END TRY
BEGIN CATCH
    INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
    VALUES (6, 'Functions', 'fn_CalculateBonus Department Logic', 'FAILED', ERROR_MESSAGE());
END CATCH;

-- ==============================================================================
-- TEST 7: Table-Valued Function (fn_GetEmployeesByDepartment)
-- ==============================================================================
BEGIN TRY
    DELETE FROM dbo.SchemaEvolutionDemo WHERE [ID] IN (9005, 9006);
    INSERT INTO dbo.SchemaEvolutionDemo ([ID], [UniqueCode], [Name], [Department], [Salary], [Status])
    VALUES 
        (9005, 'TEST_CODE_9005', 'TVF Eng User', 'Engineering', 95000.00, 'Active'),
        (9006, 'TEST_CODE_9006', 'TVF Sales User', 'Sales', 65000.00, 'Active');

    DECLARE @EngCount INT = (SELECT COUNT(*) FROM dbo.fn_GetEmployeesByDepartment('Engineering') WHERE [ID] = 9005);
    DECLARE @NonEngCount INT = (SELECT COUNT(*) FROM dbo.fn_GetEmployeesByDepartment('Engineering') WHERE [ID] = 9006);

    IF @EngCount = 1 AND @NonEngCount = 0
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (7, 'Functions', 'fn_GetEmployeesByDepartment Output Validation', 'PASSED', 'TVF correctly returned matching department rows and excluded others.');
    ELSE
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (7, 'Functions', 'fn_GetEmployeesByDepartment Output Validation', 'FAILED', 'EngCount=' + CAST(@EngCount AS VARCHAR) + ', NonEngCount=' + CAST(@NonEngCount AS VARCHAR));

    DELETE FROM dbo.SchemaEvolutionDemo WHERE [ID] IN (9005, 9006);
END TRY
BEGIN CATCH
    INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
    VALUES (7, 'Functions', 'fn_GetEmployeesByDepartment Output Validation', 'FAILED', ERROR_MESSAGE());
    DELETE FROM dbo.SchemaEvolutionDemo WHERE [ID] IN (9005, 9006);
END CATCH;

-- ==============================================================================
-- TEST 8: Trigger Audit Logging - INSERT Operation
-- ==============================================================================
BEGIN TRY
    DELETE FROM dbo.AuditLog WHERE [RecordID] = 9007 AND [TableName] = 'SchemaEvolutionDemo';
    DELETE FROM dbo.SchemaEvolutionDemo WHERE [ID] = 9007;

    INSERT INTO dbo.SchemaEvolutionDemo ([ID], [UniqueCode], [Name], [Department], [Salary], [Status])
    VALUES (9007, 'TEST_CODE_9007', 'Trigger Insert User', 'DevOps', 99000.00, 'Active');

    DECLARE @InsertAuditFound INT = (SELECT COUNT(*) FROM dbo.AuditLog WHERE [TableName] = 'SchemaEvolutionDemo' AND [RecordID] = 9007 AND [Operation] = 'INSERT');

    IF @InsertAuditFound >= 1
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (8, 'Triggers', 'Trigger Audit Log on INSERT', 'PASSED', 'Trigger successfully captured INSERT operation into dbo.AuditLog.');
    ELSE
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (8, 'Triggers', 'Trigger Audit Log on INSERT', 'FAILED', 'No audit entry found for RecordID=9007.');

    DELETE FROM dbo.AuditLog WHERE [RecordID] = 9007 AND [TableName] = 'SchemaEvolutionDemo';
    DELETE FROM dbo.SchemaEvolutionDemo WHERE [ID] = 9007;
END TRY
BEGIN CATCH
    INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
    VALUES (8, 'Triggers', 'Trigger Audit Log on INSERT', 'FAILED', ERROR_MESSAGE());
    DELETE FROM dbo.AuditLog WHERE [RecordID] = 9007 AND [TableName] = 'SchemaEvolutionDemo';
    DELETE FROM dbo.SchemaEvolutionDemo WHERE [ID] = 9007;
END CATCH;

-- ==============================================================================
-- TEST 9: Trigger Audit Logging - UPDATE Operation
-- ==============================================================================
BEGIN TRY
    DELETE FROM dbo.AuditLog WHERE [RecordID] = 9008 AND [TableName] = 'SchemaEvolutionDemo';
    DELETE FROM dbo.SchemaEvolutionDemo WHERE [ID] = 9008;

    INSERT INTO dbo.SchemaEvolutionDemo ([ID], [UniqueCode], [Name], [Department], [Salary], [Status])
    VALUES (9008, 'TEST_CODE_9008', 'Trigger Update User', 'Product', 85000.00, 'Active');

    DELETE FROM dbo.AuditLog WHERE [RecordID] = 9008;

    UPDATE dbo.SchemaEvolutionDemo
    SET [Status] = 'Inactive', [Department] = 'Engineering'
    WHERE [ID] = 9008;

    DECLARE @UpdateAuditFound INT = 0;
    DECLARE @OldVal NVARCHAR(MAX);
    DECLARE @NewVal NVARCHAR(MAX);

    SELECT @UpdateAuditFound = COUNT(*), @OldVal = MAX([OldValues]), @NewVal = MAX([NewValues])
    FROM dbo.AuditLog
    WHERE [TableName] = 'SchemaEvolutionDemo' AND [RecordID] = 9008 AND [Operation] = 'UPDATE';

    IF @UpdateAuditFound >= 1 AND @OldVal LIKE '%Dept=Product%' AND @NewVal LIKE '%Dept=Engineering%'
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (9, 'Triggers', 'Trigger Audit Log on UPDATE', 'PASSED', 'Trigger captured old values and new values on UPDATE.');
    ELSE
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (9, 'Triggers', 'Trigger Audit Log on UPDATE', 'FAILED', 'Update audit entry missing or values incorrect.');

    DELETE FROM dbo.AuditLog WHERE [RecordID] = 9008 AND [TableName] = 'SchemaEvolutionDemo';
    DELETE FROM dbo.SchemaEvolutionDemo WHERE [ID] = 9008;
END TRY
BEGIN CATCH
    INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
    VALUES (9, 'Triggers', 'Trigger Audit Log on UPDATE', 'FAILED', ERROR_MESSAGE());
    DELETE FROM dbo.AuditLog WHERE [RecordID] = 9008 AND [TableName] = 'SchemaEvolutionDemo';
    DELETE FROM dbo.SchemaEvolutionDemo WHERE [ID] = 9008;
END CATCH;

-- ==============================================================================
-- TEST 10: Sales Schema View (vw_HighValueOrders)
-- ==============================================================================
BEGIN TRY
    DECLARE @HighValueCount INT = (SELECT COUNT(*) FROM sales.vw_HighValueOrders WHERE TotalAmount >= 50000.00);
    DECLARE @LowValueCount INT = (SELECT COUNT(*) FROM sales.vw_HighValueOrders WHERE TotalAmount < 50000.00);

    IF @HighValueCount >= 1 AND @LowValueCount = 0
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (10, 'SalesSchema', 'sales.vw_HighValueOrders Filter Validation', 'PASSED', 'View correctly filtered orders >= 50,000.');
    ELSE
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (10, 'SalesSchema', 'sales.vw_HighValueOrders Filter Validation', 'FAILED', 'Unexpected view output.');
END TRY
BEGIN CATCH
    INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
    VALUES (10, 'SalesSchema', 'sales.vw_HighValueOrders Filter Validation', 'FAILED', ERROR_MESSAGE());
END CATCH;

-- ==============================================================================
-- TEST 11: Sales Schema Stored Procedure (GetCustomerOrderSummary)
-- ==============================================================================
BEGIN TRY
    IF OBJECT_ID('tempdb..#CustomerSummary') IS NOT NULL DROP TABLE #CustomerSummary;
    CREATE TABLE #CustomerSummary (
        [CustomerID] INT,
        [CustomerCode] NVARCHAR(20),
        [CustomerName] NVARCHAR(150),
        [Email] NVARCHAR(200),
        [TotalOrders] INT,
        [LifetimeSpend] DECIMAL(18,2)
    );

    INSERT INTO #CustomerSummary
    EXEC sales.GetCustomerOrderSummary @CustomerID = 1;

    DECLARE @TotalOrders INT = (SELECT [TotalOrders] FROM #CustomerSummary);

    IF @TotalOrders >= 1
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (11, 'SalesSchema', 'sales.GetCustomerOrderSummary Execution', 'PASSED', 'SP returned customer aggregate metrics successfully.');
    ELSE
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (11, 'SalesSchema', 'sales.GetCustomerOrderSummary Execution', 'FAILED', 'SP did not return expected orders.');

    IF OBJECT_ID('tempdb..#CustomerSummary') IS NOT NULL DROP TABLE #CustomerSummary;
END TRY
BEGIN CATCH
    INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
    VALUES (11, 'SalesSchema', 'sales.GetCustomerOrderSummary Execution', 'FAILED', ERROR_MESSAGE());
    IF OBJECT_ID('tempdb..#CustomerSummary') IS NOT NULL DROP TABLE #CustomerSummary;
END CATCH;

-- ==============================================================================
-- TEST 12: Prod Schema Deployment Logging & Health View
-- ==============================================================================
BEGIN TRY
    -- Execute prod logging procedure
    EXEC prod.LogProductionDeployment @ReleaseVersion = 'v2.0.0-TEST', @Status = 'Success';

    DECLARE @LogFound INT = (SELECT COUNT(*) FROM prod.vw_ProductionHealth WHERE [ReleaseVersion] = 'v2.0.0-TEST');

    IF @LogFound >= 1
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (12, 'ProdSchema', 'prod.LogProductionDeployment & Health View', 'PASSED', 'Procedure logged deployment event and view exposed the record.');
    ELSE
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (12, 'ProdSchema', 'prod.LogProductionDeployment & Health View', 'FAILED', 'Deployment log not found in prod view.');

    -- Cleanup
    DELETE FROM prod.AuditSummary WHERE [ReleaseVersion] = 'v2.0.0-TEST';
END TRY
BEGIN CATCH
    INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
    VALUES (12, 'ProdSchema', 'prod.LogProductionDeployment & Health View', 'FAILED', ERROR_MESSAGE());
    DELETE FROM prod.AuditSummary WHERE [ReleaseVersion] = 'v2.0.0-TEST';
END CATCH;

-- ==============================================================================
-- FINAL TEST REPORT OUTPUT
-- ==============================================================================
SELECT 
    [TestNumber] AS [Test #],
    [Component],
    [TestName]   AS [Test Scenario],
    CASE [Status]
        WHEN 'PASSED' THEN '✅ PASSED'
        ELSE '❌ FAILED'
    END AS [Result],
    [Details]
FROM #TestResults
ORDER BY [TestNumber] ASC;

-- Summary Metrics
DECLARE @TotalTests INT = (SELECT COUNT(*) FROM #TestResults);
DECLARE @PassedTests INT = (SELECT COUNT(*) FROM #TestResults WHERE [Status] = 'PASSED');
DECLARE @FailedTests INT = (SELECT COUNT(*) FROM #TestResults WHERE [Status] = 'FAILED');

PRINT CHAR(13) + '==============================================================================';
PRINT '📊 TEST EXECUTION SUMMARY:';
PRINT '   Total Tests:  ' + CAST(@TotalTests AS VARCHAR);
PRINT '   Passed:       ' + CAST(@PassedTests AS VARCHAR) + ' ✅';
PRINT '   Failed:       ' + CAST(@FailedTests AS VARCHAR) + ' ❌';
PRINT '   Success Rate: ' + CAST((@PassedTests * 100 / @TotalTests) AS VARCHAR) + '%';
PRINT '==============================================================================';

IF @FailedTests > 0
BEGIN
    RAISERROR('One or more automated SQL test cases failed!', 16, 1);
END
GO
