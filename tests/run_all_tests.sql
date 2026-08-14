-- ==============================================================================
-- AUTOMATED TEST SUITE FOR AZURE SQL DATABASE (appdb)
-- Test Harness: Transaction-safe, self-reporting assertion engine
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
PRINT '🧪 EXECUTING AZURE SQL CI/CD AUTOMATED TEST SUITE';
PRINT 'Target Server: freetier-sqlserver-central.database.windows.net | Database: appdb';
PRINT '==============================================================================' + CHAR(13);

-- ==============================================================================
-- TEST 1: Schema Object Existence Verification
-- ==============================================================================
BEGIN TRY
    DECLARE @MissingObjects NVARCHAR(500) = '';

    IF OBJECT_ID('dbo.EmployeeDummy', 'U') IS NULL SET @MissingObjects += 'Table:EmployeeDummy, ';
    IF OBJECT_ID('dbo.person', 'U') IS NULL SET @MissingObjects += 'Table:person, ';
    IF OBJECT_ID('dbo.SchemaEvolutionDemo', 'U') IS NULL SET @MissingObjects += 'Table:SchemaEvolutionDemo, ';
    IF OBJECT_ID('dbo.AuditLog', 'U') IS NULL SET @MissingObjects += 'Table:AuditLog, ';
    IF OBJECT_ID('dbo.vw_ActiveEmployees', 'V') IS NULL SET @MissingObjects += 'View:vw_ActiveEmployees, ';
    IF OBJECT_ID('dbo.GetEmployeeDetails', 'P') IS NULL SET @MissingObjects += 'SP:GetEmployeeDetails, ';
    IF OBJECT_ID('dbo.fn_CalculateBonus', 'FN') IS NULL SET @MissingObjects += 'ScalarFunc:fn_CalculateBonus, ';
    IF OBJECT_ID('dbo.fn_GetEmployeesByDepartment', 'IF') IS NULL 
       AND OBJECT_ID('dbo.fn_GetEmployeesByDepartment', 'TF') IS NULL SET @MissingObjects += 'TVF:fn_GetEmployeesByDepartment, ';
    IF OBJECT_ID('dbo.trg_AuditEmployeeChanges', 'TR') IS NULL SET @MissingObjects += 'Trigger:trg_AuditEmployeeChanges, ';

    IF @MissingObjects = ''
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (1, 'Schema', 'Verify All Database Objects Exist', 'PASSED', 'All 4 tables, 1 view, 1 SP, 2 functions, and 1 trigger exist.');
    ELSE
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (1, 'Schema', 'Verify All Database Objects Exist', 'FAILED', 'Missing objects: ' + @MissingObjects);
END TRY
BEGIN CATCH
    INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
    VALUES (1, 'Schema', 'Verify All Database Objects Exist', 'FAILED', ERROR_MESSAGE());
END CATCH;

-- ==============================================================================
-- TEST 2: Table Constraints & Defaults (SchemaEvolutionDemo)
-- ==============================================================================
BEGIN TRY
    -- Insert test record relying on DEFAULTs for Status ('Active') and CreatedAt
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

    -- Cleanup
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
    -- This insert MUST fail due to CHECK constraint ([Status] IN ('Active', 'Inactive', 'Pending'))
    INSERT INTO dbo.SchemaEvolutionDemo ([ID], [UniqueCode], [Name], [Department], [Salary], [Status])
    VALUES (9002, 'TEST_CODE_9002', 'Invalid Status User', 'HR', 50000.00, 'Suspended');

    -- If we reach here, the check constraint failed to block invalid data
    INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
    VALUES (3, 'Constraints', 'CHECK Constraint Rejection Test', 'FAILED', 'Invalid status ''Suspended'' was unexpectedly accepted.');
    DELETE FROM dbo.SchemaEvolutionDemo WHERE [ID] = 9002;
END TRY
BEGIN CATCH
    -- Error 547 is the SQL Server CHECK constraint violation error
    IF ERROR_NUMBER() = 547
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (3, 'Constraints', 'CHECK Constraint Rejection Test', 'PASSED', 'CHECK constraint successfully rejected invalid Status value (Error 547).');
    ELSE
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (3, 'Constraints', 'CHECK Constraint Rejection Test', 'FAILED', 'Unexpected error: ' + ERROR_MESSAGE());
END CATCH;

-- ==============================================================================
-- TEST 4: Post-Deployment Reference & Seed Data Verification
-- ==============================================================================
BEGIN TRY
    DECLARE @PersonCount INT = 0;
    DECLARE @EmployeeCount INT = 0;

    SELECT @PersonCount = COUNT(*) FROM dbo.person;
    SELECT @EmployeeCount = COUNT(*) FROM dbo.EmployeeDummy;

    IF @PersonCount >= 3 AND @EmployeeCount >= 3
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (4, 'PostDeploy', 'Seed Data Verification', 'PASSED', 'dbo.person count=' + CAST(@PersonCount AS VARCHAR) + ', dbo.EmployeeDummy count=' + CAST(@EmployeeCount AS VARCHAR));
    ELSE
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (4, 'PostDeploy', 'Seed Data Verification', 'FAILED', 'Insufficient seed data: person=' + CAST(@PersonCount AS VARCHAR) + ', EmployeeDummy=' + CAST(@EmployeeCount AS VARCHAR));
END TRY
BEGIN CATCH
    INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
    VALUES (4, 'PostDeploy', 'Seed Data Verification', 'FAILED', ERROR_MESSAGE());
END CATCH;

-- ==============================================================================
-- TEST 5: View Logic (vw_ActiveEmployees)
-- ==============================================================================
BEGIN TRY
    -- Insert 1 Active and 1 Inactive record
    DELETE FROM dbo.SchemaEvolutionDemo WHERE [ID] IN (9003, 9004);
    INSERT INTO dbo.SchemaEvolutionDemo ([ID], [UniqueCode], [Name], [Department], [Salary], [Status])
    VALUES 
        (9003, 'TEST_CODE_9003', 'Active View User', 'Engineering', 80000.00, 'Active'),
        (9004, 'TEST_CODE_9004', 'Inactive View User', 'Engineering', 80000.00, 'Inactive');

    DECLARE @ActiveVisible INT = 0;
    DECLARE @InactiveVisible INT = 0;

    SELECT @ActiveVisible = COUNT(*) FROM dbo.vw_ActiveEmployees WHERE [ID] = 9003;
    SELECT @InactiveVisible = COUNT(*) FROM dbo.vw_ActiveEmployees WHERE [ID] = 9004;

    IF @ActiveVisible = 1 AND @InactiveVisible = 0
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (5, 'Views', 'vw_ActiveEmployees Status Filtering', 'PASSED', 'View correctly returns Active records and filters out Inactive records.');
    ELSE
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (5, 'Views', 'vw_ActiveEmployees Status Filtering', 'FAILED', 'Active Visible=' + CAST(@ActiveVisible AS VARCHAR) + ', Inactive Visible=' + CAST(@InactiveVisible AS VARCHAR));

    -- Cleanup
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
    DECLARE @EngBonus DECIMAL(18,2) = dbo.fn_CalculateBonus(100000.00, 'Engineering'); -- Expected: 15000.00 (15%)
    DECLARE @ProdBonus DECIMAL(18,2) = dbo.fn_CalculateBonus(100000.00, 'Product');     -- Expected: 12000.00 (12%)
    DECLARE @DevOpsBonus DECIMAL(18,2) = dbo.fn_CalculateBonus(100000.00, 'DevOps');   -- Expected: 13000.00 (13%)
    DECLARE @OtherBonus DECIMAL(18,2) = dbo.fn_CalculateBonus(100000.00, 'Marketing'); -- Expected: 10000.00 (10%)

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

    DECLARE @EngCount INT = 0;
    DECLARE @NonEngCount INT = 0;

    SELECT @EngCount = COUNT(*) FROM dbo.fn_GetEmployeesByDepartment('Engineering') WHERE [ID] = 9005;
    SELECT @NonEngCount = COUNT(*) FROM dbo.fn_GetEmployeesByDepartment('Engineering') WHERE [ID] = 9006;

    IF @EngCount = 1 AND @NonEngCount = 0
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (7, 'Functions', 'fn_GetEmployeesByDepartment Output Validation', 'PASSED', 'TVF correctly returned matching department rows and excluded others.');
    ELSE
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (7, 'Functions', 'fn_GetEmployeesByDepartment Output Validation', 'FAILED', 'EngCount=' + CAST(@EngCount AS VARCHAR) + ', NonEngCount=' + CAST(@NonEngCount AS VARCHAR));

    -- Cleanup
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

    -- Perform INSERT
    INSERT INTO dbo.SchemaEvolutionDemo ([ID], [UniqueCode], [Name], [Department], [Salary], [Status])
    VALUES (9007, 'TEST_CODE_9007', 'Trigger Insert User', 'DevOps', 99000.00, 'Active');

    DECLARE @InsertAuditFound INT = 0;
    SELECT @InsertAuditFound = COUNT(*)
    FROM dbo.AuditLog
    WHERE [TableName] = 'SchemaEvolutionDemo' AND [RecordID] = 9007 AND [Operation] = 'INSERT';

    IF @InsertAuditFound >= 1
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (8, 'Triggers', 'Trigger Audit Log on INSERT', 'PASSED', 'Trigger successfully captured INSERT operation into dbo.AuditLog.');
    ELSE
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (8, 'Triggers', 'Trigger Audit Log on INSERT', 'FAILED', 'No audit entry found for RecordID=9007 with Operation=INSERT.');

    -- Cleanup
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

    -- Setup base record
    INSERT INTO dbo.SchemaEvolutionDemo ([ID], [UniqueCode], [Name], [Department], [Salary], [Status])
    VALUES (9008, 'TEST_CODE_9008', 'Trigger Update User', 'Product', 85000.00, 'Active');

    -- Clear insert audit
    DELETE FROM dbo.AuditLog WHERE [RecordID] = 9008;

    -- Perform UPDATE
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

    -- Cleanup
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
-- TEST 10: Stored Procedure Execution (GetEmployeeDetails)
-- ==============================================================================
BEGIN TRY
    DELETE FROM dbo.SchemaEvolutionDemo WHERE [ID] = 9009;
    INSERT INTO dbo.SchemaEvolutionDemo ([ID], [UniqueCode], [Name], [Department], [Salary], [Status])
    VALUES (9009, 'TEST_CODE_9009', 'SP Test User', 'Operations', 70000.00, 'Active');

    IF OBJECT_ID('tempdb..#SPResult') IS NOT NULL DROP TABLE #SPResult;
    CREATE TABLE #SPResult (
        [ID] INT,
        [UniqueCode] NVARCHAR(50),
        [Name] NVARCHAR(100),
        [Department] NVARCHAR(50),
        [Status] NVARCHAR(20)
    );

    INSERT INTO #SPResult
    EXEC dbo.GetEmployeeDetails @EmployeeID = 9009;

    DECLARE @SPName NVARCHAR(100);
    SELECT @SPName = [Name] FROM #SPResult;

    IF @SPName = 'SP Test User'
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (10, 'StoredProcedures', 'GetEmployeeDetails Procedure Execution', 'PASSED', 'Stored procedure executed and returned expected employee record.');
    ELSE
        INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
        VALUES (10, 'StoredProcedures', 'GetEmployeeDetails Procedure Execution', 'FAILED', 'SP returned unexpected name: ' + ISNULL(@SPName, 'NULL'));

    -- Cleanup
    DELETE FROM dbo.SchemaEvolutionDemo WHERE [ID] = 9009;
    IF OBJECT_ID('tempdb..#SPResult') IS NOT NULL DROP TABLE #SPResult;
END TRY
BEGIN CATCH
    INSERT INTO #TestResults (TestNumber, Component, TestName, Status, Details)
    VALUES (10, 'StoredProcedures', 'GetEmployeeDetails Procedure Execution', 'FAILED', ERROR_MESSAGE());
    DELETE FROM dbo.SchemaEvolutionDemo WHERE [ID] = 9009;
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
