# Azure SQL Database CI/CD: Master Scenarios & Deployment Guide

This document is the definitive technical guide for the **SQL-CICD** project (`cicd.sqlproj`). It details the repository architecture, build process, GitHub Actions deployment workflow, and step-by-step documentation for **all 10 database CI/CD deployment scenarios**.

---

## Table of Contents
1. [Repository Architecture & Tech Stack](#1-repository-architecture--tech-stack)
2. [Local Build & Artifact Verification](#2-local-build--artifact-verification)
3. [All 10 Database CI/CD Deployment Scenarios](#3-all-10-database-cicd-deployment-scenarios)
   - [Scenario 1: Greenfield / Initial Database Deployment](#scenario-1-greenfield--initial-database-deployment)
   - [Scenario 2: Additive Schema Evolution (Zero Data Loss)](#scenario-2-additive-schema-evolution-zero-data-loss)
   - [Scenario 3: Destructive / Breaking Schema Changes & Safeguards](#scenario-3-destructive--breaking-schema-changes--safeguards)
   - [Scenario 4: Schema Drift Detection & Audit Reporting](#scenario-4-schema-drift-detection--audit-reporting)
   - [Scenario 5: Pre-Deployment Validation & Dry-Run Scripting](#scenario-5-pre-deployment-validation--dry-run-scripting)
   - [Scenario 6: Idempotent Post-Deployment Data Management](#scenario-6-idempotent-post-deployment-data-management)
   - [Scenario 7: Automated GitHub Actions Pipeline Workflow](#scenario-7-automated-github-actions-pipeline-workflow)
   - [Scenario 8: Multi-Environment Deployment Strategy (Dev -> Staging -> Prod)](#scenario-8-multi-environment-deployment-strategy-dev---staging---prod)
   - [Scenario 9: Rollback & Emergency Disaster Recovery (BACPAC/DACPAC)](#scenario-9-rollback--emergency-disaster-recovery-bacpacdacpac)
   - [Scenario 10: Operational State Verification & Testing](#scenario-10-operational-state-verification--testing)
4. [Master Deployment Scenarios Matrix](#4-master-deployment-scenarios-matrix)
5. [Troubleshooting & Frequently Encountered Errors](#5-troubleshooting--frequently-encountered-errors)

---

## 1. Repository Architecture & Tech Stack

The project utilizes the modern **SDK-style SQL Database Project** format powered by `Microsoft.Build.Sql` (v2.2.0), targeting **Azure SQL Database** (`SqlAzureV12`).

### Project Components
- **Project File**: `cicd.sqlproj`
  - SDK: `Microsoft.Build.Sql` (v2.2.0)
  - Target Framework: `netstandard2.1`
  - Target Platform: `SqlAzureV12`
- **Table Schemas**:
  - `dbo/Tables/EmployeeDummy.sql` (`[dbo].[EmployeeDummy]` schema definition)
  - `dbo/Tables/persondetails.sql` (`[dbo].[person]` schema definition)
- **Post-Deployment Data Scripts**:
  - `dbo/Tables/PostDeployment/Persondata.sql` (Reference data seeding script)
- **CI/CD Pipeline**:
  - `.github/workflows/main.yml` (GitHub Actions workflow targeting `windows-latest`)
- **Query & Testing Script**:
  - `.github/workflows/test.sql` (SQL queries for schema verification & operational testing)

---

## 2. Local Build & Artifact Verification

To build and compile the SQL Database project locally without requiring a live database connection:

```bash
dotnet build cicd.sqlproj --configuration Release
```

### Build Artifact Output
- **Path**: `bin/Release/cicd.dacpac`
- The Data-tier Application Package (**DACPAC**) contains the compiled declarative database model used by `SqlPackage` during deployment.

---

## 3. All 10 Database CI/CD Deployment Scenarios

### Scenario 1: Greenfield / Initial Database Deployment
**Use Case**: Deploying schema and seed data to a brand new, empty Azure SQL Database.

#### Execution Flow
1. `SqlPackage` inspects the target database and detects an empty schema.
2. `SqlPackage` compares target state with `cicd.dacpac`.
3. Tables `[dbo].[EmployeeDummy]` and `[dbo].[person]` are created via `CREATE TABLE` DDL.
4. Post-deployment script `Persondata.sql` runs automatically after table creation, populating default seed records into `dbo.person`.

#### DDL Generated
```sql
CREATE TABLE [dbo].[EmployeeDummy] (
    [EmployeeID]   INT IDENTITY (1, 1) NOT NULL,
    [EmployeeName] NVARCHAR (100) NOT NULL,
    [Department]   NVARCHAR (50) NULL,
    [Salary]       DECIMAL (10, 2) NULL,
    [JoiningDate]  DATE NULL,
    [EmailID]      NVARCHAR (200) NULL,
    [PhoneNumber]  NVARCHAR (15) NULL,
    [Address]      NVARCHAR (100) NULL,
    PRIMARY KEY CLUSTERED ([EmployeeID] ASC)
);

CREATE TABLE [dbo].[person] (
    [PersonID]     INT IDENTITY (1, 1) NOT NULL,
    [Personname]   NVARCHAR (100) NOT NULL,
    [Relation]     NVARCHAR (50) NULL,
    [Salary]       DECIMAL (10, 2) NULL,
    [JoiningDate]  DATE NULL,
    [EmailID]      NVARCHAR (200) NULL,
    [PhoneNumber]  NVARCHAR (15) NULL,
    [Address]      NVARCHAR (100) NULL,
    [City]         NVARCHAR (100) NULL,
    PRIMARY KEY CLUSTERED ([PersonID] ASC)
);
```

---

### Scenario 2: Additive Schema Evolution (Zero Data Loss)
**Use Case**: Adding new columns, tables, indexes, or views to an existing database with zero downtime and zero data loss.

#### Execution Flow
1. Developer adds a new column (e.g., `City NVARCHAR(100) NULL`) to `dbo/Tables/persondetails.sql`.
2. Developer commits changes to `main` branch.
3. `SqlPackage /Action:Publish` performs automated state diffing against target database.
4. `SqlPackage` issues an `ALTER TABLE` statement. Existing table rows remain completely intact.

#### DDL Generated
```sql
ALTER TABLE [dbo].[person] 
    ADD [City] NVARCHAR (100) NULL;
```

---

### Scenario 3: Destructive / Breaking Schema Changes & Safeguards
**Use Case**: Modifying existing column data types, dropping columns, or dropping tables.

#### Protection Mechanism
By default, `SqlPackage` enforces strict data-loss protection controls (`/p:BlockOnPossibleDataLoss=True`). If a schema change would result in table truncation or column drop:
- `SqlPackage` halts execution and throws an error to prevent accidental production data loss.

#### Overriding Block on Data Loss (When Intentional)
If data loss is intended, pass the following property to `SqlPackage`:
```powershell
SqlPackage `
  /Action:Publish `
  /SourceFile:"./bin/Release/cicd.dacpac" `
  /TargetConnectionString:"${{ secrets.SQL_CONNECTION_STRING }}" `
  /p:BlockOnPossibleDataLoss=False
```

---

### Scenario 4: Schema Drift Detection & Audit Reporting
**Use Case**: Detecting manual out-of-band changes made directly to Azure SQL DB outside the CI/CD pipeline.

#### Execution Flow
Before publishing, run `DeployReport` or `DriftReport` to inspect target DB state:
```powershell
SqlPackage `
  /Action:DeployReport `
  /SourceFile:"./bin/Release/cicd.dacpac" `
  /TargetConnectionString:"${{ secrets.SQL_CONNECTION_STRING }}" `
  /OutputPath:"./bin/Release/deploy_report.xml"
```
- Outputs an XML/HTML summary listing all actions (Creates, Alters, Drops) that will be performed against the target database.

---

### Scenario 5: Pre-Deployment Validation & Dry-Run Scripting
**Use Case**: Generating the exact SQL deployment script before running it against a target database for DBA code review.

#### Command Execution
```powershell
SqlPackage `
  /Action:Script `
  /SourceFile:"./bin/Release/cicd.dacpac" `
  /TargetConnectionString:"<YourConnectionString>" `
  /OutputPath:"./bin/Release/deploy_preview.sql"
```

#### Output
- `deploy_preview.sql`: Contains the exact SQL migration script `SqlPackage` would execute during publishing.

---

### Scenario 6: Idempotent Post-Deployment Data Management
**Use Case**: Seeding static or reference data (e.g., lookup values, initial configurations) safely during every deployment.

#### Configuration in `cicd.sqlproj`
```xml
<ItemGroup>
  <Build Remove="dbo\Tables\PostDeployment\Persondata.sql" />
  <PostDeploy Include="dbo\Tables\PostDeployment\Persondata.sql" />
</ItemGroup>
```

#### Idempotency Pattern (`Persondata.sql`)
To prevent duplicate key violations or duplicate records when the pipeline runs multiple times:
```sql
IF NOT EXISTS (SELECT 1 FROM dbo.person)
BEGIN
    INSERT INTO dbo.person
    (
        Personname, Relation, Salary, JoiningDate,
        EmailID, PhoneNumber, Address, City
    )
    VALUES
    ('Rahul Sharma', 'Brother', 55000.00, '2024-01-15', 'rahul.sharma@test.com', '9876543210', 'Sector 62', 'Noida'),
    ('Amit Kumar', 'Friend', 65000.00, '2023-06-20', 'amit.kumar@test.com', '9876543211', 'Indirapuram', 'Ghaziabad'),
    ('Priya Singh', 'Sister', 72000.00, '2022-11-10', 'priya.singh@test.com', '9876543212', 'Dwarka', 'Delhi');
END
```

---

### Scenario 7: Automated GitHub Actions Pipeline Workflow
**Use Case**: Automated continuous integration and continuous deployment triggered on git push or manual dispatch.

#### Workflow Triggers (`.github/workflows/main.yml`)
- `push` on `main` branch
- `workflow_dispatch` (manual trigger)

#### Complete Workflow Definition
```yaml
name: SQL Database CI/CD

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  build-and-deploy:
    runs-on: windows-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '8.0.x'

      - name: Build SQL Project
        run: dotnet build cicd.sqlproj --configuration Release

      - name: Install SqlPackage
        shell: pwsh
        run: |
          dotnet tool install --global microsoft.sqlpackage
          echo "$env:USERPROFILE\.dotnet\tools" | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append

      - name: Verify DACPAC
        shell: pwsh
        run: |
          Get-ChildItem -Recurse bin

      - name: Publish DACPAC
        shell: pwsh
        run: |
          SqlPackage `
            /Action:Publish `
            /SourceFile:"./bin/Release/cicd.dacpac" `
            /TargetConnectionString:"${{ secrets.SQL_CONNECTION_STRING }}"
```

#### GitHub Secrets Configuration
In GitHub Repository Settings -> Secrets and variables -> Actions:
- **Name**: `SQL_CONNECTION_STRING`
- **Value**:
  ```text
  Server=tcp:your-server.database.windows.net,1433;Initial Catalog=your-db;Persist Security Info=False;User ID=sqladmin;Password=YourPassword123!;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;
  ```

---

### Scenario 8: Multi-Environment Deployment Strategy (Dev -> Staging -> Prod)
**Use Case**: Promoting database updates across distinct environments with manual approval gates.

#### Workflow Architecture
```yaml
jobs:
  deploy-dev:
    runs-on: windows-latest
    environment: Development
    steps:
      - ...
      - run: SqlPackage /Action:Publish /SourceFile:"./bin/Release/cicd.dacpac" /TargetConnectionString:"${{ secrets.DEV_SQL_CONN }}"

  deploy-prod:
    needs: deploy-dev
    runs-on: windows-latest
    environment: Production # Configured with GitHub Environment Approval Gate
    steps:
      - ...
      - run: SqlPackage /Action:Publish /SourceFile:"./bin/Release/cicd.dacpac" /TargetConnectionString:"${{ secrets.PROD_SQL_CONN }}"
```

---

### Scenario 9: Rollback & Emergency Disaster Recovery (BACPAC/DACPAC)
**Use Case**: Rolling back an invalid database change or restoring from database backup.

#### 1. Instant Rollback via Previous DACPAC
To revert schema changes to a previous commit, redeploy the target DACPAC artifact generated from that commit:
```powershell
SqlPackage `
  /Action:Publish `
  /SourceFile:"./previous_release/cicd.dacpac" `
  /TargetConnectionString:"${{ secrets.SQL_CONNECTION_STRING }}"
```

#### 2. Backup & Restore via BACPAC Export/Import
```powershell
# Export database schema + data snapshot
SqlPackage `
  /Action:Export `
  /TargetFile:"./backup_2026.bacpac" `
  /SourceConnectionString:"${{ secrets.SQL_CONNECTION_STRING }}"

# Import/restore database snapshot
SqlPackage `
  /Action:Import `
  /SourceFile:"./backup_2026.bacpac" `
  /TargetConnectionString:"${{ secrets.SQL_CONNECTION_STRING }}"
```

---

### Scenario 10: Operational State Verification & Testing
**Use Case**: Validating database health, schema consistency, and row counts post-deployment.

#### Verification Script (`.github/workflows/test.sql`)
```sql
-- 1. Verify Connection & Session Info
SELECT
    @@SERVERNAME AS ServerName,
    DB_NAME() AS DatabaseName,
    SUSER_SNAME() AS LoginName;

-- 2. Verify Table Existence
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

-- 3. Verify Table Columns
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'person'
ORDER BY ORDINAL_POSITION;

-- 4. Verify Seed Data Count
SELECT COUNT(*) AS PersonCount FROM dbo.person;
```

---

## 4. Master Deployment Scenarios Matrix

| # | Scenario | Trigger / Action | SqlPackage Action | Key Parameters / Flags | Outcome |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | **Greenfield / Initial Deploy** | First deployment to empty DB | `/Action:Publish` | Default flags | Full schema creation + post-deployment seed data |
| **2** | **Additive Schema Evolution** | New tables/columns added | `/Action:Publish` | State-matching diff | Issues `ALTER TABLE ADD`, zero data loss |
| **3** | **Destructive Changes** | Drop column / type change | `/Action:Publish` | `/p:BlockOnPossibleDataLoss=True` | Halts safely; override with `False` if intended |
| **4** | **Schema Drift Audit** | Detect manual direct changes | `/Action:DeployReport` | `/OutputPath:report.xml` | Generates XML audit report before publishing |
| **5** | **Pre-Deploy Dry Run** | DBA Code Review | `/Action:Script` | `/OutputPath:script.sql` | Outputs preview DDL script without altering DB |
| **6** | **Idempotent Data Seeding** | Pipeline re-runs | Post-Deploy Execution | `IF NOT EXISTS` check | Prevents duplicate key errors on static data |
| **7** | **Automated CI/CD Pipeline** | Git push to `main` | GitHub Actions | `${{ secrets.SQL_CONNECTION_STRING }}` | Automated build, verification, and publication |
| **8** | **Multi-Environment Promotion** | Dev -> Staging -> Prod | Multi-stage Jobs | GitHub Environments | Environment approval gate before Prod publish |
| **9** | **Rollback & DR** | Revert breaking changes | `/Action:Export` / `Import` | `.bacpac` / `.dacpac` | Fast schema rollback or full snapshot restore |
| **10** | **Operational State Test** | Post-deploy validation | `sqlcmd` / Query step | `test.sql` script | Validates schema tables, columns, and data counts |

---

## 5. Troubleshooting & Frequently Encountered Errors

### 1. Error: `TargetConnectionString secret not found`
- **Cause**: The GitHub secret `SQL_CONNECTION_STRING` is not configured in repository settings.
- **Fix**: Navigate to Repository -> Settings -> Secrets and variables -> Actions, and add `SQL_CONNECTION_STRING`.

### 2. Error: `Cannot open server "your-server" requested by the login.`
- **Cause**: Azure SQL Firewall is blocking GitHub Actions runner IP addresses.
- **Fix**: In Azure Portal -> Azure SQL Server -> Networking, enable **"Allow Azure services and resources to access this server"**.

### 3. Error: `Rows were detected. The schema update is terminating because data loss might occur.`
- **Cause**: A column drop or incompatible type change was detected.
- **Fix**: If data loss is expected, set `/p:BlockOnPossibleDataLoss=False` in `SqlPackage` arguments or write a pre-deployment migration script to migrate data first.
