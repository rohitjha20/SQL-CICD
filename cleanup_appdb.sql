-- ==============================================================================
-- CLEANUP SCRIPT: Reset / Drop all objects in Azure SQL Database (appdb)
-- Target: freetier-sqlserver-central.database.windows.net / appdb
-- ==============================================================================

PRINT 'Starting cleanup of appdb database objects...';

-- 1. Drop Triggers
IF OBJECT_ID('dbo.trg_AuditEmployeeChanges', 'TR') IS NOT NULL
BEGIN
    DROP TRIGGER [dbo].[trg_AuditEmployeeChanges];
    PRINT 'Dropped TRIGGER: dbo.trg_AuditEmployeeChanges';
END
GO

-- 2. Drop Views
IF OBJECT_ID('sales.vw_HighValueOrders', 'V') IS NOT NULL
BEGIN
    DROP VIEW [sales].[vw_HighValueOrders];
    PRINT 'Dropped VIEW: sales.vw_HighValueOrders';
END
GO

IF OBJECT_ID('dbo.vw_ActiveEmployees', 'V') IS NOT NULL
BEGIN
    DROP VIEW [dbo].[vw_ActiveEmployees];
    PRINT 'Dropped VIEW: dbo.vw_ActiveEmployees';
END
GO

-- 3. Drop Stored Procedures
IF OBJECT_ID('sales.GetCustomerOrderSummary', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE [sales].[GetCustomerOrderSummary];
    PRINT 'Dropped PROCEDURE: sales.GetCustomerOrderSummary';
END
GO

IF OBJECT_ID('dbo.GetEmployeeDetails', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE [dbo].[GetEmployeeDetails];
    PRINT 'Dropped PROCEDURE: dbo.GetEmployeeDetails';
END
GO

-- 4. Drop Functions (Table-Valued & Scalar)
IF OBJECT_ID('dbo.fn_GetEmployeesByDepartment', 'IF') IS NOT NULL
   OR OBJECT_ID('dbo.fn_GetEmployeesByDepartment', 'TF') IS NOT NULL
BEGIN
    DROP FUNCTION [dbo].[fn_GetEmployeesByDepartment];
    PRINT 'Dropped FUNCTION: dbo.fn_GetEmployeesByDepartment';
END
GO

IF OBJECT_ID('dbo.fn_CalculateBonus', 'FN') IS NOT NULL
BEGIN
    DROP FUNCTION [dbo].[fn_CalculateBonus];
    PRINT 'Dropped FUNCTION: dbo.fn_CalculateBonus';
END
GO

-- 5. Drop Foreign Keys (if any)
DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql += N'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME(OBJECT_NAME(parent_object_id))
            + N' DROP CONSTRAINT ' + QUOTENAME(name) + N';' + CHAR(13)
FROM sys.foreign_keys;
IF @sql <> N''
BEGIN
    EXEC sp_executesql @sql;
    PRINT 'Dropped all foreign key constraints.';
END
GO

-- 6. Drop Tables
IF OBJECT_ID('sales.Orders', 'U') IS NOT NULL
BEGIN
    DROP TABLE [sales].[Orders];
    PRINT 'Dropped TABLE: sales.Orders';
END
GO

IF OBJECT_ID('sales.Customers', 'U') IS NOT NULL
BEGIN
    DROP TABLE [sales].[Customers];
    PRINT 'Dropped TABLE: sales.Customers';
END
GO

IF OBJECT_ID('dbo.ProjectAssignments', 'U') IS NOT NULL
BEGIN
    DROP TABLE [dbo].[ProjectAssignments];
    PRINT 'Dropped TABLE: dbo.ProjectAssignments';
END
GO

IF OBJECT_ID('dbo.Projects', 'U') IS NOT NULL
BEGIN
    DROP TABLE [dbo].[Projects];
    PRINT 'Dropped TABLE: dbo.Projects';
END
GO

IF OBJECT_ID('dbo.Departments', 'U') IS NOT NULL
BEGIN
    DROP TABLE [dbo].[Departments];
    PRINT 'Dropped TABLE: dbo.Departments';
END
GO

IF OBJECT_ID('dbo.AuditLog', 'U') IS NOT NULL
BEGIN
    DROP TABLE [dbo].[AuditLog];
    PRINT 'Dropped TABLE: dbo.AuditLog';
END
GO

IF OBJECT_ID('dbo.SchemaEvolutionDemo', 'U') IS NOT NULL
BEGIN
    DROP TABLE [dbo].[SchemaEvolutionDemo];
    PRINT 'Dropped TABLE: dbo.SchemaEvolutionDemo';
END
GO

IF OBJECT_ID('dbo.person', 'U') IS NOT NULL
BEGIN
    DROP TABLE [dbo].[person];
    PRINT 'Dropped TABLE: dbo.person';
END
GO

IF OBJECT_ID('dbo.EmployeeDummy', 'U') IS NOT NULL
BEGIN
    DROP TABLE [dbo].[EmployeeDummy];
    PRINT 'Dropped TABLE: dbo.EmployeeDummy';
END
GO

-- 7. Drop Schemas
IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'sales')
BEGIN
    DROP SCHEMA [sales];
    PRINT 'Dropped SCHEMA: sales';
END
GO

PRINT '==============================================================================';
PRINT 'Cleanup complete! appdb is now reset.';
PRINT '==============================================================================';
GO
