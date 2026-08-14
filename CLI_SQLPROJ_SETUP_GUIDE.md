# Creating `.sqlproj` via CLI — No Extension Required

> **Purpose**: This guide shows how to create and configure an Azure SQL Database Project entirely from the **command line** using `dotnet` CLI — without installing the Database Projects extension in VS Code or Azure Data Studio.

---

## Table of Contents

1. [Why CLI Instead of the Extension?](#-1-why-cli-instead-of-the-extension)
2. [Prerequisites](#-2-prerequisites)
3. [Step 1 — Install the SQL Project Template](#-step-1--install-the-sql-project-template)
4. [Step 2 — Create the `.sqlproj` via CLI](#-step-2--create-the-sqlproj-via-cli)
5. [Step 3 — Understanding the Generated `.sqlproj`](#-step-3--understanding-the-generated-sqlproj)
6. [Step 4 — Create the Folder Structure](#-step-4--create-the-folder-structure)
7. [Step 5 — Add SQL Schema Files](#-step-5--add-sql-schema-files)
8. [Step 6 — Configure Build Exclusions & Post-Deploy](#-step-6--configure-build-exclusions--post-deploy)
9. [Step 7 — Build Locally & Verify](#-step-7--build-locally--verify)
10. [Step 8 — Set Up GitHub Actions CI/CD](#-step-8--set-up-github-actions-cicd)
11. [CLI vs Extension — Comparison](#-cli-vs-extension--comparison)
12. [Common CLI Commands Reference](#-common-cli-commands-reference)

---

## 🎯 1. Why CLI Instead of the Extension?

The traditional approach to creating a SQL Database Project (`.sqlproj`) is through the **Database Projects extension** in VS Code or Azure Data Studio. This extension provides a GUI to create projects, add tables, and manage references — but it has limitations:

| Concern | Extension Approach | CLI Approach |
| :--- | :--- | :--- |
| **IDE Dependency** | Requires VS Code or Azure Data Studio with the extension installed | Works on any terminal — no IDE required |
| **Reproducibility** | Manual, point-and-click setup — hard to script or document | Fully scriptable and reproducible via shell commands |
| **CI/CD Friendly** | Extension is irrelevant in CI/CD runners — only the `.sqlproj` file matters | CLI is exactly what CI/CD runners use to build |
| **Team Onboarding** | Every developer must install the extension | Developers only need .NET SDK |
| **Automation** | Cannot automate project scaffolding | Can scaffold entire project structure in a single script |
| **Headless Environments** | Doesn't work on servers or containers without a GUI | Works everywhere — servers, containers, SSH sessions |

> **Bottom Line**: The extension is a convenience wrapper. The CLI gives you the same result with full transparency and control.

---

## 📋 2. Prerequisites

Before starting, ensure the following tools are installed:

| Tool | Minimum Version | Install Command | Verify Command |
| :--- | :--- | :--- | :--- |
| **.NET SDK** | 8.0.x | `brew install --cask dotnet-sdk` (macOS) | `dotnet --version` |
| **Git** | 2.x+ | `brew install git` (macOS) | `git --version` |
| **SqlPackage** | 170.x+ | `dotnet tool install --global microsoft.sqlpackage` | `sqlpackage /version` |

### Install .NET SDK

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

**Verify:**
```bash
dotnet --version
# Expected output: 8.0.xxx
```

---

## 🔧 Step 1 — Install the SQL Project Template

The `dotnet new` command uses **templates** to scaffold projects. The SQL Database Project template is provided by Microsoft in the `Microsoft.Build.Sql.Templates` package.

### Install the Template

```bash
dotnet new install Microsoft.Build.Sql.Templates
```

### Expected Output

```
The following template packages will be installed:
   Microsoft.Build.Sql.Templates

Success: Microsoft.Build.Sql.Templates installed the following templates:
Template Name                    Short Name  Language
-------------------------------  ----------  --------
SQL Server Database Project      sqlproj     SQL
```

### Verify the Template is Available

```bash
dotnet new list sqlproj
```

**Expected Output:**
```
Template Name                    Short Name  Language  Tags
-------------------------------  ----------  --------  ---------------------------
SQL Server Database Project      sqlproj     SQL       SQL/Database/Azure/sqlproj
```

> **What This Does**: Registers the `sqlproj` template with `dotnet new` so you can create SQL Database Projects the same way you'd create a C# console app (`dotnet new console`) or a web API (`dotnet new webapi`).

---

## 🏗️ Step 2 — Create the `.sqlproj` via CLI

### Navigate to Your Project Directory

```bash
# Create and enter the project directory
mkdir SQL-CICD && cd SQL-CICD

# Initialize Git repository
git init
```

### Create the SQL Database Project

```bash
dotnet new sqlproj -n cicd -tp SqlAzureV12
```

### Parameter Breakdown

| Parameter | Value | Purpose |
| :--- | :--- | :--- |
| `dotnet new sqlproj` | — | Creates a new SQL Database Project using the installed template |
| `-n cicd` | `cicd` | Sets the project name → generates `cicd.sqlproj` |
| `-tp SqlAzureV12` | `SqlAzureV12` | Sets the target platform to **Azure SQL Database V12** |

### All Available Target Platforms (`-tp`)

| Platform Value | Target Database | Use Case |
| :--- | :--- | :--- |
| `SqlAzureV12` | Azure SQL Database | ✅ **This project** — Cloud-hosted Azure SQL |
| `Sql160` | SQL Server 2022 | On-premise SQL Server 2022 |
| `Sql150` | SQL Server 2019 | On-premise SQL Server 2019 |
| `Sql140` | SQL Server 2017 | On-premise SQL Server 2017 |
| `Sql130` | SQL Server 2016 | Legacy SQL Server 2016 |
| `Sql120` | SQL Server 2014 | Legacy SQL Server 2014 |
| `SqlDwUnified` | Azure Synapse Analytics | Data warehouse workloads |

### What Gets Generated

After running the command, you'll see a single file created:

```
SQL-CICD/
└── cicd.sqlproj          # The generated SQL Database Project file
```

---

## 📄 Step 3 — Understanding the Generated `.sqlproj`

The generated `cicd.sqlproj` is an XML file that tells MSBuild how to compile your SQL files into a DACPAC. Here is the file with annotations:

```xml
<?xml version="1.0" encoding="utf-8"?>

<Project DefaultTargets="Build">

  <!-- SDK Reference: This is the MSBuild SDK that understands SQL projects -->
  <Sdk Name="Microsoft.Build.Sql" Version="2.2.0" />

  <PropertyGroup>
    <!-- Project name (matches the -n parameter) -->
    <Name>cicd</Name>

    <!-- Unique identifier for the project -->
    <ProjectGuid>{F64078A6-8885-41B6-88F2-CFC1AADC22D5}</ProjectGuid>

    <!-- Database Schema Provider: Determines which T-SQL syntax/features are valid -->
    <!-- SqlAzureV12 = Azure SQL Database feature set -->
    <DSP>Microsoft.Data.Tools.Schema.Sql.SqlAzureV12DatabaseSchemaProvider</DSP>

    <!-- Collation: 1033 = English, CI = Case Insensitive -->
    <ModelCollation>1033, CI</ModelCollation>

    <!-- .NET framework for cross-platform compilation -->
    <TargetFramework>netstandard2.1</TargetFramework>

    <!-- Matches the -tp parameter -->
    <SqlServerVersion>SqlAzureV12</SqlServerVersion>
  </PropertyGroup>

</Project>
```

### Key Elements Explained

| XML Element | Purpose | Impact |
| :--- | :--- | :--- |
| `<Sdk Name="Microsoft.Build.Sql">` | References the SQL MSBuild SDK | Enables `dotnet build` to compile `.sql` files |
| `<DSP>` | Database Schema Provider | Validates your SQL against Azure SQL syntax (e.g., rejects `USE [database]` which isn't valid in Azure SQL) |
| `<ModelCollation>` | Default collation model | `1033, CI` = English, Case-Insensitive |
| `<TargetFramework>` | .NET framework target | `netstandard2.1` for cross-platform support |
| `<SqlServerVersion>` | Target SQL Server version | Determines which features are available during compilation |
| `<ProjectGuid>` | Unique project ID | Auto-generated; used internally by MSBuild |

---

## 📂 Step 4 — Create the Folder Structure

SQL Database Projects follow a convention-based folder structure that mirrors the database schema hierarchy:

### Create All Required Directories

```bash
# Create the schema-based folder structure
mkdir -p dbo/Tables
mkdir -p dbo/StoredProcedures
mkdir -p PostDeployment
mkdir -p .github/workflows
```

### Resulting Structure

```
SQL-CICD/
├── cicd.sqlproj                     # SQL Database Project file (created in Step 2)
├── dbo/                             # Schema namespace (matches [dbo] in SQL Server)
│   ├── Tables/                      # All CREATE TABLE definitions
│   └── StoredProcedures/            # All CREATE PROCEDURE definitions
├── PostDeployment/                  # Scripts that run AFTER schema deployment
│   │                                #   (seed data, reference data, cleanup)
└── .github/
    └── workflows/                   # GitHub Actions CI/CD pipeline definitions
```

### Folder Purpose Explained

| Folder | What Goes Here | Build Behavior |
| :--- | :--- | :--- |
| `dbo/Tables/` | `CREATE TABLE` statements — one file per table | **Included** in DACPAC build automatically |
| `dbo/StoredProcedures/` | `CREATE PROCEDURE` statements — one file per SP | **Included** in DACPAC build automatically |
| `PostDeployment/` | Data seeding scripts (`INSERT`, `MERGE`) | **Excluded** from schema build; run after deployment |
| `.github/workflows/` | GitHub Actions YAML pipeline definitions | **Excluded** from SQL build entirely |

> **Convention**: The `Microsoft.Build.Sql` SDK automatically includes all `.sql` files in the project directory tree. You only need to **exclude** files that should NOT be compiled (like test scripts or post-deployment data scripts).

---

## ✏️ Step 5 — Add SQL Schema Files

Create your database object definitions as individual `.sql` files. Each file should contain exactly **one** database object using `CREATE` syntax.

### Create a Table

```bash
cat > dbo/Tables/EmployeeDummy.sql << 'EOF'
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
EOF
```

### Create Another Table

```bash
cat > dbo/Tables/persondetails.sql << 'EOF'
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
EOF
```

### Create a Table with PK, Unique Key, CHECK, DEFAULT, and Index

```bash
cat > dbo/Tables/SchemaEvolutionDemo.sql << 'EOF'
CREATE TABLE [dbo].[SchemaEvolutionDemo]
(
    [ID] INT NOT NULL PRIMARY KEY,
    [UniqueCode] NVARCHAR(50) NOT NULL UNIQUE,
    [Name] NVARCHAR(100) NOT NULL,
    [Department] NVARCHAR(50) NULL,
    [Salary] DECIMAL(18, 2) NULL,
    [Status] NVARCHAR(20) NOT NULL
        DEFAULT 'Active'
        CHECK ([Status] IN ('Active', 'Inactive', 'Pending')),
    [CreatedAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE NONCLUSTERED INDEX [IX_SchemaEvolutionDemo_Department]
    ON [dbo].[SchemaEvolutionDemo] ([Department] ASC);
GO
EOF
```

### Create a Stored Procedure

```bash
cat > dbo/StoredProcedures/GetEmployeeDetails.sql << 'EOF'
CREATE PROCEDURE [dbo].[GetEmployeeDetails]
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT [ID], [UniqueCode], [Name], [Department], [Status]
    FROM [dbo].[SchemaEvolutionDemo]
    WHERE [ID] = @EmployeeID;
END
EOF
```

### Create Post-Deployment Scripts

**Master orchestrator** (runs all sub-scripts in order):
```bash
cat > PostDeployment/PostDeployment.sql << 'EOF'
:r .\Persondata.sql
:r .\Employeedummy.sql
EOF
```

**Seed data for `person` table:**
```bash
cat > PostDeployment/Persondata.sql << 'EOF'
-- Seed reference data for dbo.person
IF NOT EXISTS (SELECT 1 FROM [dbo].[person] WHERE [PersonID] = 1)
BEGIN
    SET IDENTITY_INSERT [dbo].[person] ON;
    INSERT INTO [dbo].[person] ([PersonID],[Personname],[Relation],[Salary],[JoiningDate],[EmailID],[PhoneNumber],[Address],[City])
    VALUES
        (1, 'Rohit Jha',     'Self',    85000.00, '2020-01-15', 'rohit@example.com',  '9876543210', '123 Main St',   'Mumbai'),
        (2, 'Priya Sharma',  'Spouse',  72000.00, '2021-03-22', 'priya@example.com',  '9876543211', '456 Oak Ave',   'Delhi'),
        (3, 'Amit Kumar',    'Brother', 65000.00, '2019-07-10', 'amit@example.com',   '9876543212', '789 Pine Rd',   'Bangalore');
    SET IDENTITY_INSERT [dbo].[person] OFF;
END
EOF
```

**Seed data for `EmployeeDummy` table:**
```bash
cat > PostDeployment/Employeedummy.sql << 'EOF'
-- Seed reference data for dbo.EmployeeDummy
IF NOT EXISTS (SELECT 1 FROM [dbo].[EmployeeDummy] WHERE [EmployeeID] = 1)
BEGIN
    SET IDENTITY_INSERT [dbo].[EmployeeDummy] ON;
    INSERT INTO [dbo].[EmployeeDummy] ([EmployeeID],[EmployeeName],[Department],[Salary],[JoiningDate],[EmailID],[PhoneNumber],[Address])
    VALUES
        (1, 'Rohit Jha',     'Engineering', 95000.00, '2020-01-15', 'rohit@company.com',  '9876543210', '123 Tech Park'),
        (2, 'Sneha Patel',   'Product',     88000.00, '2021-06-01', 'sneha@company.com',  '9876543213', '456 Innovation Hub'),
        (3, 'Vikram Singh',  'DevOps',      92000.00, '2019-11-20', 'vikram@company.com', '9876543214', '789 Cloud Center');
    SET IDENTITY_INSERT [dbo].[EmployeeDummy] OFF;
END
EOF
```

---

## ⚙️ Step 6 — Configure Build Exclusions & Post-Deploy

By default, the `Microsoft.Build.Sql` SDK includes **all** `.sql` files in the project tree for compilation. Files in `PostDeployment/` and `.github/` contain data scripts and test queries — NOT schema definitions — so they must be **excluded** from the build and handled separately.

### Edit `cicd.sqlproj`

Open the file and add the `<ItemGroup>` and `<Target>` sections:

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

  <!-- Exclude non-schema SQL files from compilation -->
  <ItemGroup>
    <!-- Exclude GitHub Actions test/utility scripts -->
    <Build Remove=".github\**\*.sql" />

    <!-- Exclude any files in the cicd/ subfolder (if present) -->
    <Build Remove="cicd\**\*.sql" />

    <!-- Exclude all PostDeployment scripts from schema compilation -->
    <Build Remove="PostDeployment\**\*.sql" />

    <!-- Register the master post-deployment script (runs AFTER schema deploy) -->
    <PostDeploy Include="PostDeployment\PostDeployment.sql" />
  </ItemGroup>

  <!-- Clean NuGet cache before each build to avoid stale dependency issues -->
  <Target Name="BeforeBuild">
    <Delete Files="$(BaseIntermediateOutputPath)\project.assets.json" />
  </Target>

</Project>
```

### What Each Exclusion Does

| Rule | Effect |
| :--- | :--- |
| `<Build Remove=".github\**\*.sql" />` | Prevents `test.sql` and any workflow scripts from being compiled as schema |
| `<Build Remove="cicd\**\*.sql" />` | Prevents any SQL files in a `cicd/` subfolder from being compiled |
| `<Build Remove="PostDeployment\**\*.sql" />` | Prevents data seed scripts from being compiled as schema objects |
| `<PostDeploy Include="PostDeployment\PostDeployment.sql" />` | Registers `PostDeployment.sql` as the **post-deploy entry point** — SqlPackage executes this after all schema changes |
| `<Target Name="BeforeBuild">` | Deletes stale NuGet cache to prevent "SDK not found" errors on CI runners |

---

## 🔨 Step 7 — Build Locally & Verify

### Run the Build

```bash
dotnet build cicd.sqlproj --configuration Release
```

### Expected Output

```
MSBuild version 17.x.x for .NET
  Determining projects to restore...
  Restored /path/to/SQL-CICD/cicd.sqlproj (in xxx ms).
  cicd -> /path/to/SQL-CICD/bin/Release/cicd.dacpac

Build succeeded.
    0 Warning(s)
    0 Error(s)
```

### Verify the DACPAC was Created

```bash
ls -la bin/Release/
```

**Expected Output:**
```
-rw-r--r--  1 user  staff  XXXX  Aug 14 12:00  cicd.dacpac
```

### What is a DACPAC?

| Property | Detail |
| :--- | :--- |
| **Full Name** | Data-tier Application Package |
| **File Format** | ZIP archive containing XML model + metadata |
| **Contents** | Compiled representation of ALL database objects (tables, SPs, indexes, constraints) |
| **Used By** | `SqlPackage` to deploy schema changes to Azure SQL |
| **Analogy** | Like a `.jar` for Java or a `.dll` for .NET — a compiled, deployable artifact |

### (Optional) Inspect DACPAC Contents

Since a DACPAC is a ZIP file, you can inspect it:

```bash
# Unzip and inspect (macOS/Linux)
mkdir -p /tmp/dacpac-inspect
cp bin/Release/cicd.dacpac /tmp/dacpac-inspect/cicd.zip
cd /tmp/dacpac-inspect && unzip cicd.zip

# Key files inside:
# model.xml       — Full database model in XML
# Origin.xml      — Build metadata
# DacMetadata.xml — Package metadata
# [Content_Types].xml — Package manifest
```

---

## 🚀 Step 8 — Set Up GitHub Actions CI/CD

### Create the Workflow File

```bash
cat > .github/workflows/main.yml << 'EOF'
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
EOF
```

### Configure the GitHub Secret

1. Go to your GitHub repository
2. Navigate to **Settings → Secrets and variables → Actions**
3. Click **New repository secret**
4. Add:

| Name | Value |
| :--- | :--- |
| `SQL_CONNECTION_STRING` | `Server=tcp:<server>.database.windows.net,1433;Initial Catalog=<db>;Persist Security Info=False;User ID=<user>;Password=<pass>;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;` |

### Push to GitHub & Trigger the Pipeline

```bash
git add .
git commit -m "Initial SQL CICD project setup via CLI"
git remote add origin https://github.com/<your-username>/SQL-CICD.git
git push -u origin main
```

The pipeline will automatically trigger on push to `main`.

---

## ⚖️ CLI vs Extension — Comparison

| Aspect | Database Projects Extension | `dotnet` CLI (This Guide) |
| :--- | :--- | :--- |
| **Setup** | Install extension in VS Code or Azure Data Studio | `dotnet new install Microsoft.Build.Sql.Templates` |
| **Create Project** | Right-click → New Database Project → Fill wizard | `dotnet new sqlproj -n cicd -tp SqlAzureV12` |
| **Add Table** | Right-click → Add Table → Enter name → Edit in GUI | Create `.sql` file manually in `dbo/Tables/` |
| **Build** | Click "Build" button in extension | `dotnet build cicd.sqlproj --configuration Release` |
| **Deploy** | Click "Publish" in extension UI | `sqlpackage /Action:Publish /SourceFile:...` |
| **IDE Required?** | ✅ Yes — VS Code or Azure Data Studio | ❌ No — Any terminal works |
| **Scriptable?** | ❌ Not easily | ✅ Fully scriptable |
| **CI/CD Ready?** | ❌ Extension not available on CI runners | ✅ Exactly what CI runners use |
| **Reproducible?** | ❌ Manual steps are hard to document | ✅ Copy-paste commands |
| **Headless?** | ❌ Needs GUI | ✅ Works over SSH, in containers |
| **Result** | Generates the same `.sqlproj` and DACPAC | Generates the same `.sqlproj` and DACPAC |

> **Key Insight**: Both approaches produce **identical output** — a `.sqlproj` file and a `.dacpac` artifact. The extension is a GUI wrapper around the same MSBuild toolchain. The CLI gives you transparency and repeatability.

---

## 📖 Common CLI Commands Reference

### Project Setup

| Command | Purpose |
| :--- | :--- |
| `dotnet new install Microsoft.Build.Sql.Templates` | Install the SQL project template |
| `dotnet new sqlproj -n <name> -tp <platform>` | Create a new SQL Database Project |
| `dotnet new list sqlproj` | Verify the template is installed |
| `dotnet new uninstall Microsoft.Build.Sql.Templates` | Remove the template |

### Build & Compile

| Command | Purpose |
| :--- | :--- |
| `dotnet build <name>.sqlproj --configuration Release` | Compile SQL files → DACPAC |
| `dotnet build <name>.sqlproj --configuration Debug` | Debug build (includes symbols) |
| `dotnet clean <name>.sqlproj` | Clean build artifacts |
| `dotnet restore <name>.sqlproj` | Restore NuGet packages only |

### Deploy & Publish

| Command | Purpose |
| :--- | :--- |
| `sqlpackage /Action:Publish /SourceFile:<dacpac> /TargetConnectionString:<conn>` | Deploy DACPAC to database |
| `sqlpackage /Action:Script /SourceFile:<dacpac> /TargetConnectionString:<conn> /OutputPath:<file>` | Generate preview SQL (dry run) |
| `sqlpackage /Action:DeployReport /SourceFile:<dacpac> /TargetConnectionString:<conn> /OutputPath:<file>` | Generate XML change report |

### Backup & Restore

| Command | Purpose |
| :--- | :--- |
| `sqlpackage /Action:Export /TargetFile:<bacpac> /SourceConnectionString:<conn>` | Export schema + data to BACPAC |
| `sqlpackage /Action:Import /SourceFile:<bacpac> /TargetConnectionString:<conn>` | Restore from BACPAC |

### SqlPackage Tool Management

| Command | Purpose |
| :--- | :--- |
| `dotnet tool install --global microsoft.sqlpackage` | Install SqlPackage |
| `dotnet tool update --global microsoft.sqlpackage` | Update to latest version |
| `sqlpackage /version` | Check installed version |

---

## 🔄 Complete CLI Workflow — From Scratch to Deployed

Here is the entire process consolidated into a single script:

```bash
#!/bin/bash
# ============================================================
# SQL CI/CD Project Setup — Complete CLI Workflow
# ============================================================

# 1. Install the SQL project template
dotnet new install Microsoft.Build.Sql.Templates

# 2. Create project directory and initialize Git
mkdir SQL-CICD && cd SQL-CICD
git init

# 3. Create the .sqlproj file via CLI
dotnet new sqlproj -n cicd -tp SqlAzureV12

# 4. Create folder structure
mkdir -p dbo/Tables dbo/StoredProcedures PostDeployment .github/workflows

# 5. Create table schema files
# (Use your preferred editor or cat/heredoc as shown in Step 5)

# 6. Edit cicd.sqlproj to add Build exclusions
# (Add ItemGroup and Target sections as shown in Step 6)

# 7. Build and verify
dotnet build cicd.sqlproj --configuration Release
ls -la bin/Release/cicd.dacpac

# 8. Create GitHub Actions workflow
# (Create .github/workflows/main.yml as shown in Step 8)

# 9. Push to GitHub
git add .
git commit -m "Initial SQL CICD project setup via CLI"
git remote add origin https://github.com/<your-username>/SQL-CICD.git
git push -u origin main

echo "✅ Done! Pipeline will trigger automatically on push to main."
```

---

*Document Version: 1.0 — CLI-Based SQL Project Setup Guide*
*Created: 14 August 2026*
