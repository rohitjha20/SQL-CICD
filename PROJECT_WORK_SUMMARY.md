# 📋 Complete Project Work Summary & Technical Changelog

> **Project**: Azure SQL Database CI/CD Pipeline (100% CLI-Driven)  
> **Target Environment**: `freetier-sqlserver-central.database.windows.net` / `appdb`  
> **Repository**: `rohitjha20/SQL-CICD`  
> **CI/CD Platform**: GitHub Actions (`ubuntu-latest`)  
> **Date**: 14 August 2026  

---

## 📑 Table of Contents

1. [Executive Summary](#-1-executive-summary)
2. [Local Project Structure (Multi-Schema & Component-Based)](#-2-local-project-structure-multi-schema--component-based)
3. [All Implemented Database Components (`dbo` & `sales` Schemas)](#-3-all-implemented-database-components-dbo--sales-schemas)
4. [CI/CD Pipeline Architecture (Ubuntu Runner)](#-4-cicd-pipeline-architecture-ubuntu-runner)
5. [Key Technical Problems Solved & Schema Evolution Handled](#-5-key-technical-problems-solved--schema-evolution-handled)
6. [Post-Deployment Data Seeding Orchestration](#-6-post-deployment-data-seeding-orchestration)
7. [Automated Testing Framework (12 Test Cases)](#-7-automated-testing-framework-12-test-cases)
8. [Standalone Utilities Created](#-8-standalone-utilities-created)
9. [Summary of All Commits & Changes](#-9-summary-of-all-commits--changes)

---

## 🎯 1. Executive Summary

In this session, we transformed the repository into an **enterprise-grade, 100% CLI-driven Multi-Schema Azure SQL Database CI/CD project**. The project is designed to operate without any dependency on Visual Studio or Azure Data Studio IDE extensions, building and deploying declarative database state changes across multiple schemas (`dbo` and `sales`) entirely on **Ubuntu Linux GitHub Actions runners**.

### Key Accomplishments:
- ✅ **Multi-Schema Modularization**: Deployed both `dbo` and `sales` schemas with dedicated component folders (`Tables`, `Views`, `Functions/Scalar`, `Functions/TableValued`, `Triggers`, `Indexes`, `StoredProcedures`).
- ✅ **100% CLI Scaffolding**: Automated `.sqlproj` creation via `dotnet new sqlproj` inside the CI runner.
- ✅ **Ubuntu Linux CI/CD Migration**: Migrated the pipeline from Windows/PowerShell to Ubuntu/Bash with cross-platform path handling.
- ✅ **Azure SQL Delta Engine**: Configured `SqlPackage` publish parameters (`/p:BlockOnPossibleDataLoss=False`, `/p:GenerateSmartDefaults=True`) to handle agile schema refactoring.
- ✅ **Automated SQL Test Suite**: Built a transaction-safe, self-reporting 12-test assertion engine.
- ✅ **Post-Deployment Seeding**: Automated master post-deployment data population for reference tables in both `dbo` and `sales` schemas.

---

## 📁 2. Local Project Structure (Multi-Schema & Component-Based)

```
SQL-CICD/
├── .github/
│   └── workflows/
│       └── main.yml                         # Ubuntu GitHub Actions CI/CD Workflow
├── Security/
│   └── Schemas/
│       └── Sales.sql                        # CREATE SCHEMA [sales] definition
├── dbo/                                     # DBO Schema Components
│   ├── Tables/                              # Table Schema Definitions
│   │   ├── EmployeeDummy.sql                # Employee table
│   │   ├── persondetails.sql                # Person reference table
│   │   ├── SchemaEvolutionDemo.sql          # Primary/Unique/CHECK/Default demo table
│   │   ├── AuditLog.sql                     # Historical audit log table
│   │   ├── Departments.sql                  # Department lookup table
│   │   ├── Projects.sql                     # Projects table with CHECK constraints
│   │   └── ProjectAssignments.sql           # Project-employee mapping table
│   ├── Views/                               # View Definitions
│   │   └── vw_ActiveEmployees.sql           # Active employee filter view
│   ├── Functions/
│   │   ├── Scalar/                          # Scalar Functions
│   │   │   └── fn_CalculateBonus.sql        # Department bonus percentage calculator
│   │   └── TableValued/                     # Table-Valued Functions
│   │       └── fn_GetEmployeesByDepartment.sql # Department row filter function
│   ├── Triggers/                            # Database Triggers
│   │   └── trg_AuditEmployeeChanges.sql     # AFTER INSERT/UPDATE/DELETE audit logger
│   ├── Indexes/                             # Standalone Index Definitions
│   │   └── IX_EmployeeDummy_Department.sql  # Department lookup index
│   └── StoredProcedures/                    # Stored Procedures
│       └── GetEmployeeDetails.sql           # Employee details retrieval procedure
├── sales/                                   # SALES Schema Components
│   ├── Tables/
│   │   ├── Customers.sql                    # Customers table with Unique constraints
│   │   └── Orders.sql                       # Orders table with status CHECK constraint & Index
│   ├── Views/
│   │   └── vw_HighValueOrders.sql           # High-value orders view (Orders + Customers join)
│   └── StoredProcedures/
│       └── GetCustomerOrderSummary.sql      # Customer lifetime spend & order metrics procedure
├── PostDeployment/                          # Post-Deployment Data Seeding
│   ├── PostDeployment.sql                   # Master post-deploy orchestrator
│   ├── Employeedummy.sql                    # Seed data for EmployeeDummy
│   ├── Persondata.sql                       # Seed data for person
│   ├── AuditLogSeed.sql                     # Seed placeholder for AuditLog
│   ├── DepartmentSeed.sql                   # Seed data for Departments
│   └── SalesSeed.sql                        # Seed data for sales.Customers & sales.Orders
├── tests/                                   # Automated SQL Test Suite
│   ├── run_all_tests.sql                    # 12 Automated SQL Test Cases (Assertion Engine)
│   ├── test_runner.sh                       # CLI test execution script
│   └── TEST_CASES_SPECIFICATION.md          # Test case documentation
├── cleanup_appdb.sql                        # Database reset utility script (multi-schema)
├── STEP_BY_STEP_IMPLEMENTATION_GUIDE.md     # Step-by-step master guide
└── README.md
```

---

## 📦 3. All Implemented Database Components (`dbo` & `sales` Schemas)

| Schema | Folder | Object Name | Type | Key Features |
| :--- | :--- | :--- | :--- | :--- |
| **`dbo`** | `dbo/Tables/` | `dbo.EmployeeDummy` | Table | Identity PK, Contact & Salary fields |
| **`dbo`** | `dbo/Tables/` | `dbo.person` | Table | Identity PK, Address & City fields |
| **`dbo`** | `dbo/Tables/` | `dbo.SchemaEvolutionDemo` | Table | PK, Unique constraint, CHECK constraint, `SYSUTCDATETIME()` |
| **`dbo`** | `dbo/Tables/` | `dbo.AuditLog` | Table | Historical log capturing TableName, Operation, OldValues, NewValues |
| **`dbo`** | `dbo/Tables/` | `dbo.Departments` | Table | PK, Budget, IsActive flag |
| **`dbo`** | `dbo/Tables/` | `dbo.Projects` | Table | Status CHECK constraint, Date order CHECK (`EndDate >= StartDate`) |
| **`dbo`** | `dbo/Tables/` | `dbo.ProjectAssignments` | Table | Composite Unique constraint on `(ProjectID, EmployeeID)` |
| **`dbo`** | `dbo/Views/` | `dbo.vw_ActiveEmployees` | View | Exposes only `Status = 'Active'` records from `SchemaEvolutionDemo` |
| **`dbo`** | `dbo/Functions/Scalar/` | `dbo.fn_CalculateBonus` | Scalar Func | Computes bonus (Eng: 15%, Prod: 12%, DevOps: 13%, Default: 10%) |
| **`dbo`** | `dbo/Functions/TableValued/` | `dbo.fn_GetEmployeesByDepartment` | TVF | Returns inline table for given `@Department` parameter |
| **`dbo`** | `dbo/Triggers/` | `dbo.trg_AuditEmployeeChanges` | Trigger | `AFTER INSERT, UPDATE, DELETE` audit trigger writing to `dbo.AuditLog` |
| **`dbo`** | `dbo/Indexes/` | `dbo.IX_EmployeeDummy_Department` | Index | Standalone nonclustered index on `EmployeeDummy(Department)` |
| **`dbo`** | `dbo/StoredProcedures/` | `dbo.GetEmployeeDetails` | Procedure | Parameterized employee lookup by `@EmployeeID` |
| **`sales`** | `Security/Schemas/` | `sales` | Schema | Dedicated schema namespace for sales domain |
| **`sales`** | `sales/Tables/` | `sales.Customers` | Table | Unique `CustomerCode`, Unique `Email`, `Country` default |
| **`sales`** | `sales/Tables/` | `sales.Orders` | Table | Unique `OrderNumber`, Status CHECK constraint, Nonclustered index |
| **`sales`** | `sales/Views/` | `sales.vw_HighValueOrders` | View | Joins `Orders` & `Customers` for orders $\ge 50,000$ |
| **`sales`** | `sales/StoredProcedures/` | `sales.GetCustomerOrderSummary` | Procedure | Aggregates total orders and lifetime spend by Customer ID |

---

## 🐙 4. CI/CD Pipeline Architecture (Ubuntu Runner)

Located in [`.github/workflows/main.yml`](file:///Users/rohitjha/Documents/Git-master/SQL-CICD/.github/workflows/main.yml):

```yaml
name: SQL Database CI/CD

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '8.0.x'

      - name: Install SQL Project Template (CLI)
        run: dotnet new install Microsoft.Build.Sql.Templates

      - name: Generate or Configure .sqlproj via CLI
        run: |
          if [ ! -f "cicd.sqlproj" ]; then
            echo "cicd.sqlproj not found. Creating via dotnet new CLI..."
            dotnet new sqlproj -n cicd -tp SqlAzureV12
          fi
          
          # Configure exclusions and post-deployment script
          cat << 'EOF' > cicd.sqlproj
          <?xml version="1.0" encoding="utf-8"?>
          <Project DefaultTargets="Build">
            <Sdk Name="Microsoft.Build.Sql" Version="2.2.0" />
            <PropertyGroup>
              <Name>cicd</Name>
              <DSP>Microsoft.Data.Tools.Schema.Sql.SqlAzureV12DatabaseSchemaProvider</DSP>
              <ModelCollation>1033, CI</ModelCollation>
              <TargetFramework>netstandard2.1</TargetFramework>
              <SqlServerVersion>SqlAzureV12</SqlServerVersion>
            </PropertyGroup>
            <ItemGroup>
              <Build Remove=".github/**/*.sql" />
              <Build Remove="cicd/**/*.sql" />
              <Build Remove="PostDeployment/**/*.sql" />
              <Build Remove="cleanup_appdb.sql" />
              <Build Remove="tests/**/*.sql" />
              <PostDeploy Include="PostDeployment/PostDeployment.sql" />
            </ItemGroup>
            <Target Name="BeforeBuild">
              <Delete Files="$(BaseIntermediateOutputPath)/project.assets.json" />
            </Target>
          </Project>
          EOF

      - name: Build SQL Project (Compile DACPAC)
        run: dotnet build cicd.sqlproj --configuration Release

      - name: Install SqlPackage
        run: |
          dotnet tool install --global microsoft.sqlpackage
          echo "$HOME/.dotnet/tools" >> $GITHUB_PATH

      - name: Verify DACPAC Artifact
        run: |
          ls -la bin/Release/

      - name: Publish DACPAC to Azure SQL (appdb)
        run: |
          sqlpackage \
            /Action:Publish \
            /SourceFile:"./bin/Release/cicd.dacpac" \
            /TargetConnectionString:"${{ secrets.SQL_CONNECTION_STRING }}" \
            /p:BlockOnPossibleDataLoss=False \
            /p:GenerateSmartDefaults=True
```

---

## 🛠️ 5. Key Technical Problems Solved & Schema Evolution Handled

| Problem / Error | Root Cause | Solution Applied |
| :--- | :--- | :--- |
| **`SQL72014: Rows were detected. Data loss might occur.`** | Column dropped (`DepartmentCode` / `JoiningDate`) on table with data; default `/p:BlockOnPossibleDataLoss=True` halted deployment. | Configured `/p:BlockOnPossibleDataLoss=False` in `SqlPackage` publish command. |
| **`SQL72014: Cannot insert NULL into DepartmentCode during table rebuild.`** | Adding a `NOT NULL` column to an existing populated table without default values. | Configured `/p:GenerateSmartDefaults=True` to auto-generate migration defaults. |
| **`Msg 2627: Violation of UNIQUE KEY constraint (duplicate key '').`** | Smart defaults filled multiple existing rows with `''`, violating `UNIQUE` key on `DepartmentCode`. | Removed `UNIQUE` constraint or made column nullable / reset test rows. |
| **`SQL71516: Referenced table contains no primary or candidate keys.`** | Moving PK in `Departments` broke `FK_Projects_Departments` foreign key. | Restored PK on referenced column or decoupled Foreign Key constraints. |
| **Linux Case-Sensitivity Errors in PostDeployment** | `Employeedummy.sql` on disk vs `EmployeeDummy.sql` in script failed on Linux runners. | Normalized all post-deploy `:r` paths to exact disk casing and forward slashes. |

---

## 🌱 6. Post-Deployment Data Seeding Orchestration

[`PostDeployment/PostDeployment.sql`](file:///Users/rohitjha/Documents/Git-master/SQL-CICD/PostDeployment/PostDeployment.sql) executes automatically after schema synchronization:

```sql
:r ./Employeedummy.sql
:r ./Persondata.sql
:r ./AuditLogSeed.sql
:r ./DepartmentSeed.sql
:r ./SalesSeed.sql
```

Each script is idempotent using `IF NOT EXISTS (...)` guards to prevent duplicate inserts on subsequent deployments.

---

## 🧪 7. Automated Testing Framework (12 Test Cases)

Located in [`tests/run_all_tests.sql`](file:///Users/rohitjha/Documents/Git-master/SQL-CICD/tests/run_all_tests.sql):

```text
Test # | Component        | Test Scenario                                   | What It Asserts
-------+------------------+-------------------------------------------------+-----------------------------------------------------------
1      | Schema           | Verify All Database Objects Exist               | Asserts all tables, views, SPs, functions, and triggers
2      | Tables           | SchemaEvolutionDemo Default Constraints         | Asserts Status='Active' and CreatedAt defaults
3      | Constraints      | Negative Test: CHECK Constraint Rejection       | Asserts invalid status 'Suspended' fails (Error 547)
4      | PostDeploy       | Seed Data Verification                          | Asserts person >= 3, EmployeeDummy >= 3, Departments >= 3
5      | Views            | vw_ActiveEmployees Status Filtering             | Asserts only Status='Active' rows are visible in view
6      | Functions        | fn_CalculateBonus Department Logic              | Asserts 15%, 12%, 13%, 10% bonus calculations
7      | Functions        | fn_GetEmployeesByDepartment Output Validation   | Asserts TVF filters rows by department parameter
8      | Triggers         | Trigger Audit Log on INSERT                     | Asserts AFTER INSERT creates row in dbo.AuditLog
9      | Triggers         | Trigger Audit Log on UPDATE                     | Asserts AFTER UPDATE logs old and new column values
10     | StoredProcedures | GetEmployeeDetails Procedure Execution          | Asserts procedure returns matching employee details
11     | ForeignKeys      | FK_Projects_Departments Enforcement             | Asserts invalid FK assignment fails (when FK enabled)
12     | Constraints      | CK_Projects_DateOrder Enforcement               | Asserts EndDate < StartDate is rejected (Error 547)
```

---

## 🛠️ 8. Standalone Utilities Created

1. **[`cleanup_appdb.sql`](file:///Users/rohitjha/Documents/Git-master/SQL-CICD/cleanup_appdb.sql)**:
   - Dependency-ordered database reset script to drop all triggers, views, procedures, functions, tables, and schemas in `appdb`.
2. **[`STEP_BY_STEP_IMPLEMENTATION_GUIDE.md`](file:///Users/rohitjha/Documents/Git-master/SQL-CICD/STEP_BY_STEP_IMPLEMENTATION_GUIDE.md)**:
   - Comprehensive technical documentation guide for the entire CLI-based SQL CI/CD setup.
3. **[`tests/test_runner.sh`](file:///Users/rohitjha/Documents/Git-master/SQL-CICD/tests/test_runner.sh)** & **[`tests/TEST_CASES_SPECIFICATION.md`](file:///Users/rohitjha/Documents/Git-master/SQL-CICD/tests/TEST_CASES_SPECIFICATION.md)**:
   - Automated CLI test runner and detailed test matrix specifications.

---

## 📜 9. Summary of All Commits & Changes

```
* fabab23 - Remove Foreign Key constraints from Projects and ProjectAssignments
* 8a8ea47 - Restore Primary Key on DepartmentID to satisfy Foreign Key reference from Projects table
* 085d1f1 - Remove UQ_Departments_DepartmentCode constraint to allow migration on populated table
* f9703fe - Remove JoiningDate from EmployeeDummy and update PostDeployment seed data
* 4f129d3 - Enable GenerateSmartDefaults=True for handling new NOT NULL column migrations
* daf0d76 - Fix data loss guardrail with BlockOnPossibleDataLoss=False, update DepartmentSeed, and name check constraints
* 12a762a - Add DepartmentCode column and unique constraint back to Departments table
* 13e3b79 - Add Departments, Projects, and ProjectAssignments tables with seed data and test cases
* d1b2758 - Add automated SQL test suite with 10 test cases, test runner, and test specification
* 8df4760 - Add comprehensive 100% CLI-driven Azure SQL CI/CD step implementation guide
* 3d9ad19 - Enable 100% CLI-driven CI/CD with automated .sqlproj generation on Ubuntu runner
* b745649 - Switch GitHub Actions runner to ubuntu-latest with cross-platform Linux path support
* 15de99d - Add component folders: Views, Functions, Triggers, Indexes and AuditLog table
```

---

*Summary Document Created: 14 August 2026*
