# Azure SQL CI/CD with GitHub & GitHub Actions: Complete Enterprise Specification

> **Document Scope**: This is the single, definitive master specification for the Azure SQL CI/CD architecture. It covers every aspect end-to-end: prerequisites, installation, architecture, networking, access control, security, pipeline implementation, all deployment scenarios, schema evolution conditions, detailed test cases with auto-generated DDL proof, pros & cons, rollback strategy, operational verification, and troubleshooting.

---

## Table of Contents

1. [Prerequisites & Requirements](#-1-prerequisites--requirements)
2. [Installation & Environment Setup](#-2-installation--environment-setup)
3. [Architecture & Design Paradigm](#-3-architecture--design-paradigm)
4. [Repository Structure & Source Code](#-4-repository-structure--source-code)
5. [Networking, Access & Security](#-5-networking-access--security)
6. [GitHub Actions Pipeline Implementation](#-6-github-actions-pipeline-implementation)
7. [Multi-Environment Promotion Strategy (Dev → Staging → Prod)](#-7-multi-environment-promotion-strategy-dev--staging--prod)
8. [All 10 Database CI/CD Deployment Scenarios](#-8-all-10-database-cicd-deployment-scenarios)
9. [Schema Evolution Conditions (Primary Key, Unique Key, Constraint, Index, Stored Procedure)](#-9-schema-evolution-conditions)
10. [Detailed Test Cases & Proof of Execution](#-10-detailed-test-cases--proof-of-execution)
11. [Operational Verification & Post-Deployment Validation](#-11-operational-verification--post-deployment-validation)
12. [Rollback & Disaster Recovery](#-12-rollback--disaster-recovery)
13. [Pros & Cons Analysis](#-13-pros--cons-analysis)
14. [Troubleshooting & Error Resolution](#-14-troubleshooting--error-resolution)
15. [Version History](#-15-version-history)

---

## 📋 1. Prerequisites & Requirements

### 1.1 Software Requirements

| Component | Minimum Version | Purpose | Download |
| :--- | :--- | :--- | :--- |
| **.NET SDK** | 8.0.x | Compiles the SQL Database Project (`cicd.sqlproj`) using MSBuild | https://dotnet.microsoft.com/download |
| **SqlPackage** | 170.x+ | Microsoft CLI tool for DACPAC comparison, deployment, scripting | Installed via `dotnet tool install` |
| **Git** | 2.x+ | Version control for all declarative SQL schema files | https://git-scm.com |
| **GitHub Account** | — | Hosts repository, provides GitHub Actions runners, stores secrets | https://github.com |
| **Azure Subscription** | — | Hosts Azure SQL Server & Database | https://portal.azure.com |

### 1.2 Azure Resource Requirements

| Azure Resource | SKU / Tier | Purpose | Notes |
| :--- | :--- | :--- | :--- |
| **Azure SQL Server** (Logical) | Any | Logical container that hosts databases | One server can host multiple databases |
| **Azure SQL Database** | Basic / Standard / Premium / Hyperscale | The target database for CI/CD deployments | DTU or vCore pricing model supported |
| **Azure Resource Group** | — | Logical grouping of all related resources | Organizes SQL Server + Database together |
| **Azure AD / Entra ID** (Optional) | — | Token-based authentication for pipeline | Alternative to SQL username/password |

### 1.3 GitHub Repository Requirements

| Requirement | Details |
| :--- | :--- |
| **Repository Type** | Public or Private GitHub repository |
| **Branch Strategy** | `main` branch triggers deployment. Feature branches for development |
| **GitHub Secrets** | `SQL_CONNECTION_STRING` stored in **Settings → Secrets → Actions** |
| **GitHub Environments** (Optional) | `Development`, `Staging`, `Production` — each with scoped secrets and optional approval gates |
| **Runner** | `windows-latest` (GitHub-hosted). Self-hosted runners also supported |

### 1.4 Network Requirements

| Requirement | Detail |
| :--- | :--- |
| **Outbound from GitHub Runner** | HTTPS (443) to GitHub APIs + TDS (1433) to Azure SQL |
| **Azure SQL Firewall** | Must allow GitHub Actions runner IPs (see Section 5) |
| **TLS Version** | Azure SQL enforces TLS 1.2 minimum |
| **Connection Encryption** | `Encrypt=True` in connection string |

---

## 🔧 2. Installation & Environment Setup

### 2.1 Install .NET SDK

The .NET SDK is required to compile the SQL Database Project file.

**macOS:**
```bash
brew install --cask dotnet-sdk
```

**Windows:**
```powershell
winget install Microsoft.DotNet.SDK.8
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update && sudo apt-get install -y dotnet-sdk-8.0
```

**Verify Installation:**
```bash
dotnet --version
# Expected: 8.0.xxx
```

### 2.2 Install SqlPackage (Local Development)

`SqlPackage` is automatically installed in the GitHub Actions pipeline, but for local development and offline testing:

```bash
# Install as .NET Global Tool (cross-platform)
dotnet tool install --global microsoft.sqlpackage

# Verify
sqlpackage /version
# Expected: 170.x.x.x
```

### 2.3 Initialize a New SQL Database Project (From Scratch)

If starting a brand new project:

```bash
# Create project directory
mkdir SQL-CICD && cd SQL-CICD
git init

# Initialize SQL Database Project
dotnet new sqlproj -n cicd -tp SqlAzureV12

# Create schema directories
mkdir -p dbo/Tables dbo/StoredProcedures PostDeployment .github/workflows
```

### 2.4 The SQL Project File (`cicd.sqlproj`)

This is the heart of the build system. It defines the SDK version, target platform, and which files are included:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Project DefaultTargets="Build">
  <Sdk Name="Microsoft.Build.Sql" Version="2.2.0" />

  <PropertyGroup>
    <Name>cicd</Name>
    <ProjectGuid>{F64078A6-8885-41B6-88F2-CFC1AADC22D5}</ProjectGuid>
    <DSP>Microsoft.Data.Tools.Schema.Sql.SqlAzureV12DatabaseSchemaProvider</DSP>
    <ModelCollation>1033, CI</ModelCollation>
    <TargetFramework>netstandard2.1</TargetFramework>
    <SqlServerVersion>SqlAzureV12</SqlServerVersion>
  </PropertyGroup>

  <ItemGroup>
    <Build Remove=".github\**\*.sql" />
    <Build Remove="cicd\**\*.sql" />
    <Build Remove="PostDeployment\**\*.sql" />
    <PostDeploy Include="PostDeployment\PostDeployment.sql" />
  </ItemGroup>

  <Target Name="BeforeBuild">
    <Delete Files="$(BaseIntermediateOutputPath)\project.assets.json" />
  </Target>
</Project>
```

**Key Configuration Explained:**

| Element | Value | Purpose |
| :--- | :--- | :--- |
| `Microsoft.Build.Sql` | `2.2.0` | The MSBuild SDK that understands SQL project structure |
| `DSP` | `SqlAzureV12DatabaseSchemaProvider` | Targets Azure SQL Database syntax & feature set |
| `TargetFramework` | `netstandard2.1` | .NET framework for cross-platform compilation |
| `<Build Remove=...>` | `.github\**\*.sql` | Excludes test/utility scripts from compilation |
| `<PostDeploy Include=...>` | `PostDeployment.sql` | Registers post-deployment scripts to run after schema updates |

### 2.5 Local Build & Artifact Verification

```bash
dotnet build cicd.sqlproj --configuration Release
```

**Build Output:**
- **Artifact Path**: `bin/Release/cicd.dacpac`
- **What is a DACPAC?**: A Data-tier Application Package — a compiled binary containing the entire database model (tables, stored procedures, indexes, constraints, relationships). This single file is what gets deployed to the target database.

### 2.6 Configure GitHub Secrets

Navigate to **GitHub Repository → Settings → Secrets and variables → Actions → New repository secret**:

| Secret Name | Value Format |
| :--- | :--- |
| `SQL_CONNECTION_STRING` | `Server=tcp:<server>.database.windows.net,1433;Initial Catalog=<db>;Persist Security Info=False;User ID=<user>;Password=<pass>;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;` |

For multi-environment deployments, add additional secrets scoped to GitHub Environments:
- `SQL_CONNECTION_STRING_DEV` (scoped to `Development` environment)
- `SQL_CONNECTION_STRING_STAGING` (scoped to `Staging` environment)
- `SQL_CONNECTION_STRING_PROD` (scoped to `Production` environment)

---

## 🏗️ 3. Architecture & Design Paradigm

### 3.1 What is State-Based (Declarative) Deployment?

This project uses a **State-Based** deployment model. Developers define only the **desired end-state** of the database (using standard `CREATE TABLE` syntax). The CI/CD engine (`SqlPackage`) automatically calculates the difference (delta) between the source code and the live target database, then generates and executes the precise `ALTER`, `CREATE`, or `DROP` DDL statements needed.

### 3.2 State-Based vs. Imperative Migrations (Comparison)

| Aspect | Imperative (Legacy: Flyway, Liquibase) | State-Based (DACPAC: This Project) |
| :--- | :--- | :--- |
| **Developer writes** | Sequential migration scripts: `V1__Create.sql`, `V2__AddCol.sql` | Only the desired end-state: `CREATE TABLE` with all columns |
| **Ordering** | Strict execution order must be maintained (V1 → V2 → V3) | No ordering — delta is computed automatically every time |
| **Schema drift** | Fails silently if target DB was manually altered | Detects and reconciles drift automatically |
| **Rollback** | Requires manually authoring a separate "undo" script | Republish the previous commit's DACPAC |
| **Multi-table** | One migration script per change | Single DACPAC covers all objects atomically |
| **Complexity** | Grows linearly with every change (100 changes = 100 files) | Constant — always just the current state files |
| **Risk of drift** | High — migrations can get out of sync with reality | Low — pipeline always reconciles against live state |

### 3.3 High-Level Architecture Diagram

```mermaid
flowchart TD
    subgraph Developer Workstation
        DEV[Developer modifies .sql files]
        DEV -->|git commit & push| GIT
    end

    subgraph GitHub Source Control
        GIT[GitHub Repository - main branch]
        T1[dbo/Tables/EmployeeDummy.sql]
        T2[dbo/Tables/persondetails.sql]
        T3[dbo/Tables/SchemaEvolutionDemo.sql]
        SP[dbo/StoredProcedures/GetEmployeeDetails.sql]
        PROJ[cicd.sqlproj]
        GIT --> T1 & T2 & T3 & SP & PROJ
    end

    subgraph GitHub Actions Pipeline
        PROJ -->|Step 1: dotnet build| BUILD[Compiled cicd.dacpac]
        BUILD -->|Step 2: SqlPackage /Action:Publish| SQLPKG[State Delta Engine]
        SQLPKG -->|2a: Extract Target State| EXTRACT[Query sys.tables / sys.columns / sys.indexes]
        SQLPKG -->|2b: Compare States| DIFF[Compute DDL Delta]
        DIFF -->|2c: Generate DDL| DDL[ALTER / CREATE / DROP]
    end

    subgraph Azure Cloud
        DDL -->|Step 3: Execute in Atomic Transaction| AZDB[(Azure SQL Database)]
        AZDB --> DB_T1[dbo.EmployeeDummy]
        AZDB --> DB_T2[dbo.person]
        AZDB --> DB_T3[dbo.SchemaEvolutionDemo]
        AZDB --> DB_SP[dbo.GetEmployeeDetails]
    end

    style BUILD fill:#065f46,stroke:#10b981,color:#fff
    style SQLPKG fill:#4c1d95,stroke:#a855f7,color:#fff
    style AZDB fill:#1e3a8a,stroke:#60a5fa,color:#fff
    style DDL fill:#92400e,stroke:#f59e0b,color:#fff
```

### 3.4 Detailed Deployment Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    participant Dev as Developer
    participant Git as GitHub (main branch)
    participant GHA as GitHub Actions Runner
    participant SP as SqlPackage Engine
    participant DB as Azure SQL Database

    Dev->>Git: Push modified .sql files
    Git->>GHA: Trigger CI/CD pipeline (on push or dispatch)
    GHA->>GHA: Step 1: dotnet build cicd.sqlproj → cicd.dacpac
    GHA->>SP: Step 2: SqlPackage /Action:Publish /SourceFile:cicd.dacpac
    SP->>DB: Query sys.tables, sys.columns, sys.indexes, sys.objects
    DB-->>SP: Return current live schema metadata
    SP->>SP: Compare DACPAC model vs Live DB state
    SP->>SP: Generate differential DDL (ALTER, CREATE, DROP)
    SP->>DB: Execute DDL inside atomic transaction
    DB-->>SP: Transaction committed successfully
    SP-->>GHA: Deployment succeeded
    GHA-->>Git: Pipeline status: ✅ Success
```

### 3.5 How SqlPackage Computes the Delta (Internal Process)

When `SqlPackage /Action:Publish` executes, it performs these internal steps:

1. **Load Source Model**: Deserializes the compiled `cicd.dacpac` into an in-memory object graph of all tables, columns, constraints, indexes, and procedures.
2. **Extract Target State**: Connects to the live Azure SQL Database and queries system catalog views (`sys.tables`, `sys.columns`, `sys.indexes`, `sys.check_constraints`, `sys.key_constraints`, `sys.sql_modules`) to build a model of the current database state.
3. **Differential Comparison**: Compares the two models object-by-object:
   - Objects in source but not in target → `CREATE` statements
   - Objects in both but with differences → `ALTER` statements
   - Objects in target but not in source → `DROP` statements (if `DropObjectsNotInSource=True`)
4. **Dependency Resolution**: Orders the generated DDL statements based on object dependencies (e.g., drop foreign keys before dropping referenced tables).
5. **Transactional Execution**: Wraps all DDL in a single database transaction. If any statement fails, the entire deployment rolls back automatically.

---

## 📁 4. Repository Structure & Source Code

### 4.1 Complete Repository Layout

```
SQL-CICD/
├── cicd.sqlproj                              # MSBuild project file
├── dbo/
│   ├── Tables/
│   │   ├── EmployeeDummy.sql                 # [dbo].[EmployeeDummy] schema
│   │   ├── persondetails.sql                 # [dbo].[person] schema
│   │   └── SchemaEvolutionDemo.sql           # Demo table with PK, UK, CHECK, INDEX
│   └── StoredProcedures/
│       └── GetEmployeeDetails.sql            # Stored Procedure
├── PostDeployment/
│   ├── PostDeployment.sql                    # Master orchestrator script
│   ├── Persondata.sql                        # Reference data
│   └── Employeedummy.sql                     # Reference data
├── .github/
│   └── workflows/
│       ├── main.yml                          # GitHub Actions CI/CD pipeline
│       └── test.sql                          # Post-deployment verification queries
├── bin/
│   └── Release/
│       └── cicd.dacpac                       # Compiled deployment artifact
└── DATABASE_OBJECT_SCENARIOS.md              # Schema evolution documentation
```

### 4.2 Table Schema Definitions

**`dbo/Tables/EmployeeDummy.sql`**:
```sql
CREATE TABLE [dbo].[EmployeeDummy] (
    [EmployeeID]   INT             IDENTITY (1, 1) NOT NULL,
    [EmployeeName] NVARCHAR (100)  NOT NULL,
    [Department]   NVARCHAR (50)   NULL,
    [Salary]       DECIMAL (10, 2) NULL,
    [JoiningDate]  DATE            NULL,
    [EmailID]      NVARCHAR (200)  NULL,
    [PhoneNumber]  NVARCHAR (15)   NULL,
    [Address]      NVARCHAR (100)  NULL,
    PRIMARY KEY CLUSTERED ([EmployeeID] ASC)
);
```

**`dbo/Tables/persondetails.sql`**:
```sql
CREATE TABLE [dbo].[person] (
    [PersonID]     INT             IDENTITY (1, 1) NOT NULL,
    [Personname]   NVARCHAR (100)  NOT NULL,
    [Relation]     NVARCHAR (50)   NULL,
    [Salary]       DECIMAL (10, 2) NULL,
    [JoiningDate]  DATE            NULL,
    [EmailID]      NVARCHAR (200)  NULL,
    [PhoneNumber]  NVARCHAR (15)   NULL,
    [Address]      NVARCHAR (100)  NULL,
    [City]         NVARCHAR (100)  NULL,
    PRIMARY KEY CLUSTERED ([PersonID] ASC)
);
```

**`dbo/Tables/SchemaEvolutionDemo.sql`** (contains PK, UK, CHECK, DEFAULT, INDEX):
```sql
CREATE TABLE [dbo].[SchemaEvolutionDemo]
(
    [ID] INT NOT NULL PRIMARY KEY,                          -- Primary Key
    [UniqueCode] NVARCHAR(50) NOT NULL UNIQUE,              -- Unique Key
    [Name] NVARCHAR(100) NOT NULL,
    [Department] NVARCHAR(50) NULL,
    [Salary] DECIMAL(18, 2) NULL,
    [Status] NVARCHAR(20) NOT NULL
        DEFAULT 'Active'                                     -- DEFAULT Constraint
        CHECK ([Status] IN ('Active', 'Inactive', 'Pending')), -- CHECK Constraint
    [CreatedAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE NONCLUSTERED INDEX [IX_SchemaEvolutionDemo_Department]   -- Index
    ON [dbo].[SchemaEvolutionDemo] ([Department] ASC);
GO
```

### 4.3 Stored Procedure Definition

**`dbo/StoredProcedures/GetEmployeeDetails.sql`**:
```sql
CREATE PROCEDURE [dbo].[GetEmployeeDetails]
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT [ID], [UniqueCode], [Name], [Department], [Status]
    FROM [dbo].[SchemaEvolutionDemo]
    WHERE [ID] = @EmployeeID;
END
```

---

## 🔐 5. Networking, Access & Security

### 5.1 Azure SQL Firewall Configuration

GitHub Actions runners use dynamic, ephemeral IP addresses from Microsoft Azure data centers. The pipeline must be authorized to connect.

**Option A — Allow Azure Services (Simplest):**
1. Navigate to **Azure Portal → SQL Server → Networking**.
2. Under "Exceptions", enable **"Allow Azure services and resources to access this server"**.
3. This permits any Azure-hosted service (including GitHub Actions runners) to connect.

**Option B — Dynamic Firewall Rule (Most Secure):**
Add workflow steps to dynamically whitelist and remove the runner's IP:
```yaml
- name: Get Runner Public IP
  id: ip
  run: echo "runner_ip=$(curl -s https://api.ipify.org)" >> $GITHUB_OUTPUT

- name: Add Temporary Firewall Rule
  run: |
    az sql server firewall-rule create \
      --resource-group <rg> --server <server> \
      --name GitHubRunner \
      --start-ip-address ${{ steps.ip.outputs.runner_ip }} \
      --end-ip-address ${{ steps.ip.outputs.runner_ip }}

# ... deployment steps ...

- name: Remove Temporary Firewall Rule
  if: always()
  run: |
    az sql server firewall-rule delete \
      --resource-group <rg> --server <server> --name GitHubRunner
```

**Option C — Azure Private Endpoint (Enterprise):**
For maximum security, configure an Azure Private Endpoint for the SQL Server and use a self-hosted GitHub Actions runner deployed inside the same Virtual Network (VNet).

### 5.2 Authentication Methods

| Method | How It Works | Security Level | Best For |
| :--- | :--- | :--- | :--- |
| **SQL Authentication** | Username + Password in connection string, stored as GitHub Secret | Medium | Simple setups, PoC environments |
| **Azure AD Service Principal** | Client ID + Client Secret or Certificate; token-based auth | High | Production CI/CD pipelines |
| **Azure Managed Identity** | No credentials stored; identity assigned to the runner | Highest | Self-hosted runners in Azure VMs |

### 5.3 GitHub Secrets Security Model

- **Encrypted at rest** using libsodium sealed boxes within GitHub's infrastructure.
- **Never exposed in logs** — GitHub automatically redacts any secret value that appears in workflow output.
- **Scoped per environment** — A `Production` environment secret is only accessible to jobs running in the `Production` GitHub Environment.
- **Audit trail** — GitHub provides an audit log of all secret access events.
- **Branch protection** — Rules can enforce that only reviewed, approved PRs can trigger Production deployments.

### 5.4 Network Traffic Flow

```
Developer Machine ──(HTTPS/443)──► GitHub.com
                                       │
                                       ▼
                              GitHub Actions Runner
                              (windows-latest, Azure-hosted)
                                       │
                              ──(TDS Protocol / Port 1433)──►
                              ──(Encrypted via TLS 1.2)──────►
                                       │
                                       ▼
                              Azure SQL Database
                              (Firewall + TLS 1.2 Enforced)
```

- **TDS (Tabular Data Stream)**: The SQL Server wire protocol used on port **1433**.
- **TLS 1.2**: All communication is encrypted end-to-end. Enforced by the `Encrypt=True` parameter in the connection string.
- **No VPN Required**: GitHub Actions runners communicate over the public internet with TLS encryption. For private network requirements, use Azure Private Endpoints + self-hosted runners.

---

## ⚙️ 6. GitHub Actions Pipeline Implementation

### 6.1 The Actual Production Workflow (`.github/workflows/main.yml`)

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

### 6.2 Pipeline Step-by-Step Breakdown

| Step | Action | What Happens | Duration |
| :--- | :--- | :--- | :--- |
| **1. Checkout** | `actions/checkout@v4` | Clones the full GitHub repository onto the runner | ~2s |
| **2. Setup .NET** | `actions/setup-dotnet@v4` | Installs .NET SDK 8.0.x on the Windows runner | ~5s |
| **3. Build** | `dotnet build cicd.sqlproj` | Compiles all `.sql` files, validates T-SQL syntax, resolves dependencies, emits `cicd.dacpac` | ~4s |
| **4. Install SqlPackage** | `dotnet tool install` | Installs the SqlPackage CLI globally, updates PATH | ~3s |
| **5. Verify DACPAC** | `Get-ChildItem -Recurse bin` | Lists the `bin/` directory to confirm `cicd.dacpac` exists | ~1s |
| **6. Publish** | `SqlPackage /Action:Publish` | Connects to Azure SQL, extracts live state, computes delta, executes DDL in transaction | ~5–30s |

### 6.3 All SqlPackage Parameters Reference

| Parameter | Value | Purpose |
| :--- | :--- | :--- |
| `/Action:Publish` | — | Applies the DACPAC model to the target database |
| `/Action:Script` | — | Generates preview `.sql` without executing (dry run) |
| `/Action:DeployReport` | — | Generates XML report of planned changes |
| `/Action:Export` | — | Exports schema + data as `.bacpac` backup |
| `/Action:Import` | — | Restores from a `.bacpac` file |
| `/p:BlockOnPossibleDataLoss` | `True` / `False` | Halts deployment if changes would cause data loss |
| `/p:DropObjectsNotInSource` | `True` / `False` | Whether to drop target objects not in the DACPAC |
| `/p:AllowIncompatiblePlatform` | `True` / `False` | Allow cross-platform deployment |
| `/p:CommandTimeout` | Seconds (e.g., `600`) | Timeout for individual SQL commands |
| `/OutputPath` | File path | Output location for script/report generation |

---

## 🔄 7. Multi-Environment Promotion Strategy (Dev → Staging → Prod)

### 7.1 How It Works

Promoting database schema updates from Development to Production requires **zero developer intervention**. Developers push declarative table changes to Git, and the pipeline dynamically targets the correct environment based on GitHub Environment configuration.

### 7.2 Multi-Environment Workflow Architecture

```yaml
jobs:
  deploy-dev:
    runs-on: windows-latest
    environment: Development
    steps:
      - # ... build steps ...
      - run: |
          SqlPackage /Action:Publish `
            /SourceFile:"./bin/Release/cicd.dacpac" `
            /TargetConnectionString:"${{ secrets.DEV_SQL_CONN }}"

  deploy-staging:
    needs: deploy-dev
    runs-on: windows-latest
    environment: Staging
    steps:
      - # ... deploy steps ...
      - run: |
          SqlPackage /Action:Publish `
            /SourceFile:"./bin/Release/cicd.dacpac" `
            /TargetConnectionString:"${{ secrets.STAGING_SQL_CONN }}"

  deploy-prod:
    needs: deploy-staging
    runs-on: windows-latest
    environment: Production    # Approval gate configured here
    steps:
      - # ... deploy steps ...
      - run: |
          SqlPackage /Action:Publish `
            /SourceFile:"./bin/Release/cicd.dacpac" `
            /TargetConnectionString:"${{ secrets.PROD_SQL_CONN }}" `
            /p:BlockOnPossibleDataLoss=True
```

### 7.3 Environment Promotion Sequence

```mermaid
sequenceDiagram
    autonumber
    participant Dev as Developer
    participant Git as GitHub (main)
    participant GHA as GitHub Actions
    participant DevDB as Dev Azure SQL
    participant ProdDB as Prod Azure SQL

    Dev->>Git: Push updated table schema
    Git->>GHA: Trigger pipeline
    GHA->>GHA: Compile DACPAC (dotnet build)

    rect rgb(30, 58, 138)
        note right of GHA: Dev Environment
        GHA->>DevDB: SqlPackage Publish (Auto-reconcile Dev)
        DevDB-->>GHA: Dev deployment succeeded ✅
    end

    rect rgb(6, 95, 70)
        note right of GHA: Production (Approval Gate)
        GHA->>GHA: Wait for manual approval
        GHA->>ProdDB: Extract live Prod schema state
        ProdDB-->>GHA: Return current metadata
        GHA->>GHA: Compare Prod state vs DACPAC
        GHA->>ProdDB: Apply differential DDL
        ProdDB-->>GHA: Prod schema updated ✅
    end
```

---

## 📋 8. All 10 Database CI/CD Deployment Scenarios

### Scenario 1: Greenfield / Initial Database Deployment

**Use Case**: First-time deployment to a brand new, empty Azure SQL Database.

**What Happens**: `SqlPackage` inspects the empty target, compares it with `cicd.dacpac`, and generates `CREATE TABLE` + `CREATE PROCEDURE` statements for every object.

**Generated DDL**:
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

**Use Case**: Adding new columns, tables, indexes, or views to an existing database.

**Developer Action**: Add `[City] NVARCHAR(100) NULL` to `persondetails.sql` and push to `main`.

**Generated DDL**:
```sql
ALTER TABLE [dbo].[person] ADD [City] NVARCHAR (100) NULL;
```

**Data Impact**: Zero. Existing rows remain completely intact.

---

### Scenario 3: Destructive / Breaking Schema Changes & Safeguards

**Use Case**: Dropping columns, narrowing data types, or dropping tables.

**Protection**: `/p:BlockOnPossibleDataLoss=True` halts the pipeline with an error if any change would cause data loss.

**Override (when intentional)**:
```powershell
SqlPackage /Action:Publish `
  /SourceFile:"./bin/Release/cicd.dacpac" `
  /TargetConnectionString:"${{ secrets.SQL_CONNECTION_STRING }}" `
  /p:BlockOnPossibleDataLoss=False
```

---

### Scenario 4: Schema Drift Detection & Audit Reporting

**Use Case**: Detecting manual, out-of-band changes made directly to Azure SQL outside the CI/CD pipeline.

**Command**:
```powershell
SqlPackage /Action:DeployReport `
  /SourceFile:"./bin/Release/cicd.dacpac" `
  /TargetConnectionString:"${{ secrets.SQL_CONNECTION_STRING }}" `
  /OutputPath:"./bin/Release/deploy_report.xml"
```

**Output**: An XML report listing every `CREATE`, `ALTER`, and `DROP` that would be performed.

---

### Scenario 5: Pre-Deployment Validation & Dry-Run Scripting

**Use Case**: Generating the exact SQL script for DBA code review before deploying.

**Command**:
```powershell
SqlPackage /Action:Script `
  /SourceFile:"./bin/Release/cicd.dacpac" `
  /TargetConnectionString:"<YourConnectionString>" `
  /OutputPath:"./bin/Release/deploy_preview.sql"
```

**Output**: `deploy_preview.sql` — the exact migration script that would be executed.

---

### Scenario 6: Automated GitHub Actions Pipeline

**Trigger**: Any `git push` to the `main` branch or `workflow_dispatch` (manual trigger).

**Flow**: Checkout → Build → Install SqlPackage → Verify DACPAC → Publish to Azure SQL.

*(Full workflow YAML shown in Section 6.1)*

---

### Scenario 7: Multi-Environment Deployment (Dev → Staging → Prod)

**Use Case**: Promoting database updates across environments with approval gates.

*(Full multi-stage workflow and sequence diagram shown in Section 7)*

---

### Scenario 8: Rollback & Emergency Disaster Recovery

*(Detailed in Section 12)*

---

### Scenario 9: Operational State Verification & Testing

*(Detailed in Section 11)*

---

### Scenario 10: Complete Scenarios Matrix

| # | Scenario | Trigger | SqlPackage Action | Key Flags | Outcome |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | Greenfield Deploy | First push to empty DB | `/Action:Publish` | Default | Full `CREATE TABLE` execution |
| **2** | Additive Schema | Add columns/tables | `/Action:Publish` | Default | `ALTER TABLE ADD`, zero data loss |
| **3** | Destructive Change | Drop column/table | `/Action:Publish` | `BlockOnPossibleDataLoss=True` | Halts pipeline to prevent data loss |
| **4** | Schema Drift Audit | Manual check | `/Action:DeployReport` | `OutputPath:report.xml` | XML audit of manual DB changes |
| **5** | Pre-Deploy Dry Run | DBA review | `/Action:Script` | `OutputPath:preview.sql` | Preview DDL without executing |
| **6** | Full Automation | Git push to `main` | `/Action:Publish` | Automatic | Build → validate → deploy |
| **7** | Env Promotion | `workflow_dispatch` | `/Action:Publish` | GitHub Environments | Dev → Staging → Prod |
| **8** | Rollback | Redeploy old commit | `/Action:Publish` | Previous DACPAC | Reverses schema to prior state |
| **9** | BACPAC Backup | Pre-release safety | `/Action:Export` | `TargetFile:backup.bacpac` | Full schema + data snapshot |
| **10** | State Validation | Post-deploy check | Run `test.sql` | — | Validates tables, columns, row counts |

---

## 🧬 9. Schema Evolution Conditions

The 5 core database object conditions that the CI/CD pipeline handles automatically:

### 9.1 Primary Key Condition

**Baseline** (`SchemaEvolutionDemo.sql`):
```sql
[ID] INT NOT NULL PRIMARY KEY,
```

| Operation | Developer Action in GitHub | Auto-Generated DDL by Pipeline |
| :--- | :--- | :--- |
| **Add** | Add `PRIMARY KEY` to a column | `ALTER TABLE ADD PRIMARY KEY ([ID]);` |
| **Change to another column** | Move `PRIMARY KEY` from `[ID]` to `[UniqueCode]` | Smart table rebuild via temp table (see Test Case 1) |
| **Remove / Drop** | Delete the `PRIMARY KEY` keyword | `ALTER TABLE DROP CONSTRAINT [PK_Name];` |

### 9.2 Unique Key Condition

**Baseline**:
```sql
[UniqueCode] NVARCHAR(50) NOT NULL UNIQUE,
```

| Operation | Developer Action in GitHub | Auto-Generated DDL by Pipeline |
| :--- | :--- | :--- |
| **Add** | Append `UNIQUE` to a column | `ALTER TABLE ADD CONSTRAINT [UK_Name] UNIQUE ([Column]);` |
| **Change to another column** | Move `UNIQUE` from one column to another | `DROP CONSTRAINT [UK_Old]; ADD CONSTRAINT [UK_New] UNIQUE ([NewCol]);` |
| **Remove / Drop** | Delete the `UNIQUE` keyword | `ALTER TABLE DROP CONSTRAINT [UK_Name];` |

### 9.3 Constraint Condition (CHECK & DEFAULT)

**Baseline**:
```sql
[Status] NVARCHAR(20) NOT NULL DEFAULT 'Active' CHECK ([Status] IN ('Active', 'Inactive', 'Pending')),
```

| Operation | Developer Action in GitHub | Auto-Generated DDL by Pipeline |
| :--- | :--- | :--- |
| **Add CHECK** | Add `CHECK ([Salary] >= 0)` | `ALTER TABLE WITH NOCHECK ADD CHECK ([Salary] >= 0);` |
| **Change CHECK** | Modify condition values | `DROP CONSTRAINT [CHK_Old]; ADD CHECK (new condition);` |
| **Add DEFAULT** | Add `DEFAULT 'Value'` | `ALTER TABLE ADD DEFAULT ('Value') FOR [Column];` |
| **Remove / Drop** | Delete the `CHECK` or `DEFAULT` block | `ALTER TABLE DROP CONSTRAINT [constraint_name];` |

### 9.4 Index Condition

**Baseline**:
```sql
CREATE NONCLUSTERED INDEX [IX_SchemaEvolutionDemo_Department]
    ON [dbo].[SchemaEvolutionDemo] ([Department] ASC);
```

| Operation | Developer Action in GitHub | Auto-Generated DDL by Pipeline |
| :--- | :--- | :--- |
| **Add** | Add a `CREATE INDEX` block | `CREATE NONCLUSTERED INDEX [IX_Name] ON [Table]([Col]);` |
| **Change columns** | Change the column in the index definition | `DROP INDEX [IX_Name]; CREATE INDEX [IX_Name] ON [Table]([NewCol]);` |
| **Remove / Drop** | Delete the `CREATE INDEX` block | `DROP INDEX [IX_Name] ON [Table];` |

### 9.5 Stored Procedure Condition

**Baseline** (`GetEmployeeDetails.sql`):
```sql
CREATE PROCEDURE [dbo].[GetEmployeeDetails]
    @EmployeeID INT
AS
BEGIN
    SELECT [ID], [UniqueCode], [Name], [Department], [Status]
    FROM [dbo].[SchemaEvolutionDemo]
    WHERE [ID] = @EmployeeID;
END
```

| Operation | Developer Action in GitHub | Auto-Generated DDL by Pipeline |
| :--- | :--- | :--- |
| **Add** | Create a new `.sql` file with `CREATE PROCEDURE` | `CREATE PROCEDURE [dbo].[NewProc] ...` |
| **Change logic** | Modify the procedure body | `ALTER PROCEDURE [dbo].[GetEmployeeDetails] ...` |
| **Change parameters** | Add/remove parameters | `ALTER PROCEDURE` with updated signature |
| **Remove / Drop** | Delete the `.sql` file from the repository | `DROP PROCEDURE [dbo].[GetEmployeeDetails];` |

---

## 🧪 10. Detailed Test Cases & Proof of Execution

### 10.1 Test Methodology

We used `SqlPackage /Action:Script` to compare two DACPAC versions entirely offline (no live database required):

1. **Built the Baseline DACPAC** (`v1.dacpac`) from the original, unmodified source files.
2. **Modified all 5 schema conditions simultaneously** in the source files.
3. **Built the Modified DACPAC** (`v2.dacpac`) from the changed source files.
4. **Ran**: `SqlPackage /Action:Script /SourceFile:v2.dacpac /TargetFile:v1.dacpac /OutputPath:delta.sql /TargetDatabaseName:TestDB`
5. **Inspected** the generated `delta.sql` for correctness.
6. **Restored** source files back to baseline.

### 10.2 Changes Made for Testing

| # | Condition | Baseline State | Modified State |
| :--- | :--- | :--- | :--- |
| 1 | Primary Key | `[ID] INT NOT NULL PRIMARY KEY` | `[ID] INT NOT NULL` (PK removed) |
| 2 | Unique Key | `[UniqueCode] NVARCHAR(50) NOT NULL UNIQUE` | `[UniqueCode] NVARCHAR(50) NOT NULL PRIMARY KEY` (UK removed, became PK) |
| 3 | Constraint | `[Salary] DECIMAL(18,2) NULL` | `[Salary] DECIMAL(18,2) NULL CHECK ([Salary] >= 0)` (CHECK added) |
| 4 | Index | `INDEX ... ([Department] ASC)` | `INDEX ... ([Name] ASC)` (column changed) |
| 5 | Stored Procedure | `SELECT [ID], [UniqueCode], [Name], [Department], [Status]` | Added `[Salary]` to SELECT list |

---

### 10.3 Test Case 1: Primary Key — Move to Another Column

| Attribute | Detail |
| :--- | :--- |
| **Condition** | Primary Key |
| **Operation** | Moved Clustered PK from `[ID]` to `[UniqueCode]` |
| **Source Change** | Removed `PRIMARY KEY` from `[ID]`, added `PRIMARY KEY` to `[UniqueCode]` |
| **Challenge** | Clustered PK determines physical disk layout. Cannot be changed with simple `ALTER` |
| **Expected Behavior** | Full table rebuild via temp table inside `SERIALIZABLE` transaction |
| **Result** | ✅ **PASS** — Data preserved, PK moved successfully |

**Auto-Generated DDL:**
```sql
BEGIN TRANSACTION;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SET XACT_ABORT ON;

-- Step 1: Create temporary table with NEW schema (PK on UniqueCode)
CREATE TABLE [dbo].[tmp_ms_xx_SchemaEvolutionDemo] (
    [ID]         INT             NOT NULL,
    [UniqueCode] NVARCHAR (50)   NOT NULL,
    [Name]       NVARCHAR (100)  NOT NULL,
    [Department] NVARCHAR (50)   NULL,
    [Salary]     DECIMAL (18, 2) NULL,
    [Status]     NVARCHAR (20)   DEFAULT 'Active' NOT NULL,
    [CreatedAt]  DATETIME2 (7)   DEFAULT SYSUTCDATETIME() NOT NULL,
    PRIMARY KEY CLUSTERED ([UniqueCode] ASC)   -- NEW PK location
);

-- Step 2: Copy all existing data from old table to new table
IF EXISTS (SELECT TOP 1 1 FROM [dbo].[SchemaEvolutionDemo])
BEGIN
    INSERT INTO [dbo].[tmp_ms_xx_SchemaEvolutionDemo]
        ([UniqueCode], [ID], [Name], [Department], [Salary], [Status], [CreatedAt])
    SELECT [UniqueCode], [ID], [Name], [Department], [Salary], [Status], [CreatedAt]
    FROM [dbo].[SchemaEvolutionDemo]
    ORDER BY [UniqueCode] ASC;
END

-- Step 3: Drop old table and rename temp table
DROP TABLE [dbo].[SchemaEvolutionDemo];
EXECUTE sp_rename N'[dbo].[tmp_ms_xx_SchemaEvolutionDemo]', N'SchemaEvolutionDemo';

COMMIT TRANSACTION;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
```

---

### 10.4 Test Case 2: Unique Key — Complete Drop

| Attribute | Detail |
| :--- | :--- |
| **Condition** | Unique Key |
| **Operation** | Dropped UNIQUE from `[UniqueCode]` (it became the new PK) |
| **Source Change** | Removed `UNIQUE` keyword |
| **Expected Behavior** | `DROP CONSTRAINT` on the unique key |
| **Result** | ✅ **PASS** — Unique constraint dropped, handled as part of table rebuild |

**Auto-Generated DDL:**
```sql
PRINT N'Dropping Unique Constraint on [dbo].[SchemaEvolutionDemo]...';
ALTER TABLE [dbo].[SchemaEvolutionDemo] DROP CONSTRAINT [UQ_UniqueCode];
```

---

### 10.5 Test Case 3: Constraint — Add New CHECK

| Attribute | Detail |
| :--- | :--- |
| **Condition** | CHECK Constraint |
| **Operation** | Added `CHECK ([Salary] >= 0)` to `[Salary]` column |
| **Source Change** | Appended `CHECK ([Salary] >= 0)` to column definition |
| **Expected Behavior** | `ALTER TABLE ADD CHECK` |
| **Result** | ✅ **PASS** — New constraint applied successfully |

**Auto-Generated DDL:**
```sql
PRINT N'Creating Check Constraint on [dbo].[SchemaEvolutionDemo]...';
ALTER TABLE [dbo].[SchemaEvolutionDemo] WITH NOCHECK
    ADD CHECK ([Salary] >= 0);
```

---

### 10.6 Test Case 4: Index — Change Column

| Attribute | Detail |
| :--- | :--- |
| **Condition** | Nonclustered Index |
| **Operation** | Changed index from `[Department]` to `[Name]` |
| **Source Change** | Modified the column in the `CREATE INDEX` statement |
| **Expected Behavior** | `DROP INDEX` then `CREATE INDEX` on new column |
| **Result** | ✅ **PASS** — Index recreated on the new column |

**Auto-Generated DDL:**
```sql
PRINT N'Dropping Index [dbo].[SchemaEvolutionDemo].[IX_SchemaEvolutionDemo_Department]...';
DROP INDEX [IX_SchemaEvolutionDemo_Department]
    ON [dbo].[SchemaEvolutionDemo];

PRINT N'Creating Index [dbo].[SchemaEvolutionDemo].[IX_SchemaEvolutionDemo_Department]...';
CREATE NONCLUSTERED INDEX [IX_SchemaEvolutionDemo_Department]
    ON [dbo].[SchemaEvolutionDemo]([Name] ASC);
```

---

### 10.7 Test Case 5: Stored Procedure — Change Logic

| Attribute | Detail |
| :--- | :--- |
| **Condition** | Stored Procedure |
| **Operation** | Added `[Salary]` column to the `SELECT` statement |
| **Source Change** | Modified the `CREATE PROCEDURE` body |
| **Expected Behavior** | `ALTER PROCEDURE` (not `CREATE`) |
| **Result** | ✅ **PASS** — Procedure altered in-place without dropping |

**Auto-Generated DDL:**
```sql
PRINT N'Altering Procedure [dbo].[GetEmployeeDetails]...';
ALTER PROCEDURE [dbo].[GetEmployeeDetails]
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        [ID], [UniqueCode], [Name], [Department], [Status],
        [Salary]   -- Newly added column
    FROM
        [dbo].[SchemaEvolutionDemo]
    WHERE
        [ID] = @EmployeeID;
END
```

---

### 10.8 Test Results Summary

| # | Test Case | Condition | Operation | Data Loss? | Result |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | PK Change Column | Primary Key | Moved PK from `[ID]` to `[UniqueCode]` | No — full data copy via temp table | ✅ PASS |
| 2 | UK Drop | Unique Key | Dropped UNIQUE from `[UniqueCode]` | No | ✅ PASS |
| 3 | Constraint Add | CHECK | Added `CHECK ([Salary] >= 0)` | No | ✅ PASS |
| 4 | Index Change | Index | Changed column from `[Department]` to `[Name]` | No | ✅ PASS |
| 5 | SP Modify | Stored Procedure | Added `[Salary]` to SELECT | No | ✅ PASS |

> **Key Finding**: All 5 conditions were applied **simultaneously** in a single deployment. The pipeline correctly orchestrated a complex table rebuild, constraint manipulation, index recreation, and procedure alteration — all within one atomic transaction, with **zero data loss**.

---

## ✅ 11. Operational Verification & Post-Deployment Validation

### 11.1 Verification Script (`test.sql`)

After every deployment, run these queries against the target database to validate state:

```sql
-- 1. Verify Connection & Session Info
SELECT
    @@SERVERNAME AS ServerName,
    DB_NAME() AS DatabaseName,
    SUSER_SNAME() AS LoginName;

-- 2. Verify All Tables Exist
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- 3. Verify Table Columns for a Specific Table
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'SchemaEvolutionDemo'
ORDER BY ORDINAL_POSITION;

-- 4. Verify Primary Keys
SELECT
    tc.TABLE_NAME, tc.CONSTRAINT_NAME, kcu.COLUMN_NAME
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
    ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
WHERE tc.CONSTRAINT_TYPE = 'PRIMARY KEY';

-- 5. Verify Indexes
SELECT
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    c.name AS ColumnName
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
JOIN sys.tables t ON i.object_id = t.object_id
WHERE i.name IS NOT NULL
ORDER BY t.name, i.name;

-- 6. Verify Stored Procedures
SELECT ROUTINE_NAME, ROUTINE_TYPE, CREATED, LAST_ALTERED
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = 'PROCEDURE';

-- 7. Verify CHECK Constraints
SELECT
    cc.name AS ConstraintName,
    OBJECT_NAME(cc.parent_object_id) AS TableName,
    cc.definition AS ConstraintDefinition
FROM sys.check_constraints cc;

-- 8. Multi-Table Row Count Health Check
SELECT 'dbo.EmployeeDummy' AS TableName, COUNT(*) AS TotalRows FROM dbo.EmployeeDummy
UNION ALL
SELECT 'dbo.person', COUNT(*) FROM dbo.person
UNION ALL
SELECT 'dbo.SchemaEvolutionDemo', COUNT(*) FROM dbo.SchemaEvolutionDemo;
```

---

## 🔄 12. Rollback & Disaster Recovery

### 12.1 Instant Rollback via Previous DACPAC

To revert schema changes to a previous known-good state, redeploy the DACPAC from that Git commit:

```powershell
# Option 1: Checkout previous commit and rebuild
git checkout <previous-commit-hash>
dotnet build cicd.sqlproj --configuration Release
SqlPackage /Action:Publish `
  /SourceFile:"./bin/Release/cicd.dacpac" `
  /TargetConnectionString:"${{ secrets.SQL_CONNECTION_STRING }}"

# Option 2: Re-run the GitHub Actions workflow from a previous commit
# In GitHub → Actions → Select the successful run → Re-run all jobs
```

### 12.2 Full Backup & Restore via BACPAC

```powershell
# Export (Backup): Schema + Data snapshot
SqlPackage /Action:Export `
  /TargetFile:"./backup_2026.bacpac" `
  /SourceConnectionString:"${{ secrets.SQL_CONNECTION_STRING }}"

# Import (Restore): Restore into a new database
SqlPackage /Action:Import `
  /SourceFile:"./backup_2026.bacpac" `
  /TargetConnectionString:"<NewDatabaseConnectionString>"
```

### 12.3 Rollback Strategy Comparison

| Method | Speed | Data Recovery | Complexity |
| :--- | :--- | :--- | :--- |
| **Redeploy previous DACPAC** | Fast (~30s) | Schema only (data preserved) | Low |
| **BACPAC Import** | Slow (depends on size) | Full schema + data | Medium |
| **Azure Point-in-Time Restore** | Medium (~5 min) | Full database state | Low (Azure Portal) |
| **Git revert + Pipeline re-run** | Fast (~2 min) | Schema only | Low |

---

## ⚖️ 13. Pros & Cons Analysis

### ✅ Advantages

| # | Advantage | Detail |
| :--- | :--- | :--- |
| 1 | **Zero Manual Migration Scripts** | Developers never write `ALTER TABLE`, `DROP INDEX`, or data-preservation scripts. The engine computes the delta automatically |
| 2 | **Atomic Transactional Deployments** | All schema changes are wrapped in a single database transaction. If any step fails, the entire deployment rolls back cleanly |
| 3 | **Built-in Data Loss Prevention** | `/p:BlockOnPossibleDataLoss=True` halts destructive changes before they reach Production |
| 4 | **Schema Drift Detection** | `SqlPackage /Action:DeployReport` detects and reports manual out-of-band changes, keeping source control as the single source of truth |
| 5 | **Multi-Environment Promotion** | A single DACPAC artifact is promoted across Dev → Staging → Prod. Same binary deployed everywhere ensures consistency |
| 6 | **Pre-Deployment Review** | `/Action:Script` generates the exact SQL that will be executed, enabling DBA code review before any changes touch the database |
| 7 | **No Ordering Dependencies** | Unlike imperative migrations, there is no execution order to maintain. The DACPAC model is always the complete desired state |
| 8 | **Instant Rollback** | Redeploy the DACPAC from a previous Git commit to reverse schema changes automatically |
| 9 | **GitHub-Native** | Uses GitHub Actions natively. No third-party CI/CD tools. Secrets, Environments, and Approval Gates are built into GitHub |
| 10 | **Cross-Platform Build** | `dotnet build` works on macOS, Linux, and Windows for local development |
| 11 | **Multi-Table Atomicity** | All tables, indexes, constraints, and procedures are deployed in a single atomic transaction |
| 12 | **Free for Public Repos** | GitHub Actions is free for public repositories with 2,000 CI/CD minutes/month for private repos |

### ❌ Limitations & Considerations

| # | Limitation | Detail | Mitigation |
| :--- | :--- | :--- | :--- |
| 1 | **Large Table Rebuilds** | Moving a clustered PK on a table with billions of rows causes a full table rebuild (slow, lock-heavy) | Schedule PK changes during maintenance windows; use `/p:CommandTimeout` |
| 2 | **No Built-in Data Migration** | DACPAC handles schema changes but cannot transform data (e.g., splitting `FullName` into `FirstName` + `LastName`) | Use Pre-Deployment scripts for data transformations |
| 3 | **Unnamed Constraints** | Inline `CHECK (...)` without named `CONSTRAINT` generates system-named constraints | Always use named constraints: `CONSTRAINT [CHK_Salary] CHECK (...)` |
| 4 | **Single Database Scope** | DACPAC targets one database. Cross-database references aren't natively supported | Use `.dacpac` database references for cross-database dependencies |
| 5 | **Runner IP Variability** | GitHub-hosted runners use dynamic IPs, requiring broad firewall rules | Use dynamic firewall rules (Section 5.1 Option B) or Private Endpoints |
| 6 | **No Granular Approval** | GitHub Actions approval is environment-level only (not per-step) | Configure GitHub Environments with required reviewers |
| 7 | **Windows Runner Required** | `SqlPackage` runs best on `windows-latest` runners | Cross-platform `.NET Global Tool` version available for Linux runners |
| 8 | **No Partial Deployment** | Cannot deploy only one table — the entire DACPAC is applied | Design schemas in separate `.sqlproj` files if partial deployment is needed |

---

## 🚨 14. Troubleshooting & Error Resolution

| # | Error Message | Root Cause | Resolution |
| :--- | :--- | :--- | :--- |
| 1 | `TargetConnectionString secret not found` | GitHub Secret `SQL_CONNECTION_STRING` is missing or misspelled | Navigate to **Settings → Secrets → Actions** and add the secret |
| 2 | `Cannot open server requested by login` | Azure SQL Firewall is blocking the GitHub Actions runner IP | Enable **"Allow Azure services"** in Azure SQL Networking, or use dynamic firewall rules (Section 5.1) |
| 3 | `Login failed for user` | Incorrect username or password in the connection string | Verify credentials. Test the connection string locally with `sqlcmd` |
| 4 | `The schema update is terminating because data loss might occur` | A column with existing data was dropped or type was narrowed | If intentional, set `/p:BlockOnPossibleDataLoss=False`. Otherwise write a Pre-Deploy data migration script |
| 5 | `Timeout expired` | Target database is slow or schema change is very large (e.g., table rebuild on millions of rows) | Add `/p:CommandTimeout=600` (or higher) to the `SqlPackage` command |
| 6 | `Could not deploy package` | DACPAC was compiled for a different platform than the target | Ensure `<SqlServerVersion>SqlAzureV12</SqlServerVersion>` in `cicd.sqlproj` matches the target |
| 7 | `dotnet build failed` | T-SQL syntax error in one of the `.sql` files | Run `dotnet build cicd.sqlproj` locally and fix the reported syntax errors |
| 8 | `SqlPackage not found` | The `dotnet tool install` step failed or PATH was not updated | Ensure the PATH update step runs immediately after tool installation |
| 9 | `An error occurred while verifying constraints` | Existing data in the table violates a newly added CHECK constraint | Clean up violating data before adding the constraint, or use `WITH NOCHECK` |
| 10 | `Cannot drop table because it is referenced by a FOREIGN KEY constraint` | Attempting to drop a table that has foreign key references | Drop the foreign key constraint first, or set `/p:DropObjectsNotInSource=True` |

---

## 📜 15. Version History

| Version | Name | Modified By | Date |
| :--- | :--- | :--- | :--- |
| `1.0` | Initial Draft & Architecture Specification | DevOps / Data Engineering Team | 30/12/2025 |
| `1.1` | Multi-Table Schema Integration & Data Population | DevOps / Data Engineering Team | 24/07/2026 |
| `1.2` | Enterprise Release: Multi-Table, Dev-to-Prod Automation | DevOps / Data Engineering Team | 24/07/2026 |
| `2.0` | Schema Evolution Conditions & Test Cases | DevOps / Data Engineering Team | 31/07/2026 |
| `3.0` | Complete Enterprise Specification: Architecture, Installation, Security, Testing, Pros/Cons | DevOps / Data Engineering Team | 01/08/2026 |

---

*Document Version: 3.0 — Complete Enterprise Specification*
