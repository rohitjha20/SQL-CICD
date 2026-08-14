-- ==============================================================================
-- CLEANUP SCRIPT: Reset / Drop all objects in Azure SQL Database (appdb)
-- Target: freetier-sqlserver-central.database.windows.net / appdb
-- Multi-Schema: dbo, sales, prod
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
IF OBJECT_ID('prod.vw_ProductionHealth', 'V') IS NOT NULL
BEGIN
    DROP VIEW [prod].[vw_ProductionHealth];
    PRINT 'Dropped VIEW: prod.vw_ProductionHealth';
END
GO

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
IF OBJECT_ID('prod.LogProductionDeployment', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE [prod].[LogProductionDeployment];
    PRINT 'Dropped PROCEDURE: prod.LogProductionDeployment';
END
GO

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

-- 6. Drop Tables (PROD Schema)
IF OBJECT_ID('prod.AuditSummary', 'U') IS NOT NULL DROP TABLE [prod].[AuditSummary];
IF OBJECT_ID('prod.Configuration', 'U') IS NOT NULL DROP TABLE [prod].[Configuration];
IF OBJECT_ID('prod.Projects', 'U') IS NOT NULL DROP TABLE [prod].[Projects];
IF OBJECT_ID('prod.Departments', 'U') IS NOT NULL DROP TABLE [prod].[Departments];
IF OBJECT_ID('prod.AuditLog', 'U') IS NOT NULL DROP TABLE [prod].[AuditLog];
IF OBJECT_ID('prod.SchemaEvolutionDemo', 'U') IS NOT NULL DROP TABLE [prod].[SchemaEvolutionDemo];
IF OBJECT_ID('prod.person', 'U') IS NOT NULL DROP TABLE [prod].[person];
IF OBJECT_ID('prod.EmployeeDummy', 'U') IS NOT NULL DROP TABLE [prod].[EmployeeDummy];
PRINT 'Dropped all prod schema tables.';
GO

-- 6b. Drop Tables (SALES Schema)
IF OBJECT_ID('sales.Orders', 'U') IS NOT NULL DROP TABLE [sales].[Orders];
IF OBJECT_ID('sales.Customers', 'U') IS NOT NULL DROP TABLE [sales].[Customers];
PRINT 'Dropped all sales schema tables.';
GO

-- 6c. Drop Tables (DBO Schema)
IF OBJECT_ID('dbo.Projects', 'U') IS NOT NULL DROP TABLE [dbo].[Projects];
IF OBJECT_ID('dbo.Departments', 'U') IS NOT NULL DROP TABLE [dbo].[Departments];
IF OBJECT_ID('dbo.AuditLog', 'U') IS NOT NULL DROP TABLE [dbo].[AuditLog];
IF OBJECT_ID('dbo.SchemaEvolutionDemo', 'U') IS NOT NULL DROP TABLE [dbo].[SchemaEvolutionDemo];
IF OBJECT_ID('dbo.person', 'U') IS NOT NULL DROP TABLE [dbo].[person];
IF OBJECT_ID('dbo.EmployeeDummy', 'U') IS NOT NULL DROP TABLE [dbo].[EmployeeDummy];
PRINT 'Dropped all dbo schema tables.';
GO

-- 7. Drop Schemas
IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'prod') DROP SCHEMA [prod];
IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'sales') DROP SCHEMA [sales];
PRINT 'Dropped schemas: prod, sales';
GO

PRINT '==============================================================================';
PRINT 'Cleanup complete! appdb is now reset across all schemas (dbo, sales, prod).';
PRINT '==============================================================================';
GO
