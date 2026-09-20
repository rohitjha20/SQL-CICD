# Iteration 2 — UAT → Prod Pipeline

Self-contained SQL DACPAC project with a **two-environment promotion pipeline** (UAT → Production).

## Folder Structure

```
iteration-2/
├── .github/workflows/
│   └── main.yml                         ← CI/CD pipeline (UAT → Prod)
├── cicd.sqlproj                         ← SQL project file (compiled to DACPAC)
├── dbo/
│   ├── Tables/
│   │   ├── AuditLog.sql
│   │   ├── Departments.sql
│   │   ├── EmployeeDummy.sql
│   │   ├── persondetails.sql
│   │   ├── Projects.sql
│   │   ├── ProjectAssignments.sql
│   │   └── SchemaEvolutionDemo.sql
│   ├── StoredProcedures/
│   │   └── GetEmployeeDetails.sql
│   ├── Views/
│   │   └── vw_ActiveEmployees.sql
│   ├── Triggers/
│   │   └── trg_AuditEmployeeChanges.sql
│   ├── Indexes/
│   │   └── IX_EmployeeDummy_Department.sql
│   └── Functions/
│       ├── Scalar/
│       │   └── fn_CalculateBonus.sql
│       └── TableValued/
│           └── fn_GetEmployeesByDepartment.sql
└── PostDeployment/
    ├── PostDeployment.sql               ← Orchestrator (runs seed scripts)
    ├── Employeedummy.sql
    ├── Persondata.sql
    ├── AuditLogSeed.sql
    ├── DepartmentSeed.sql
    ├── SalesSeed.sql
    └── ProdSeed.sql
```

## Pipeline Flow

```
Push to main (iteration-2/**)
  │
  ├── 1. BUILD — dotnet build cicd.sqlproj → cicd.dacpac
  │
  ├── 2. UAT — SqlPackage Publish (auto-deploy)
  │
  └── 3. PROD — SqlPackage Publish (manual approval required)
```

## Safety Features

| Feature | Detail |
|:---|:---|
| **Concurrency Control** | Only one pipeline at a time; newer pushes cancel older runs |
| **Path Scoping** | Pipeline only triggers on changes inside `iteration-2/` |
| **Prod Approval Gate** | `environment: Production` — requires manual approval in GitHub |
| **Data Loss Prevention** | `BlockOnPossibleDataLoss=True` on Prod |

## GitHub Setup Required

1. **Settings → Environments → Create `UAT`**
   - Add secret: `SQL_CONNECTION_STRING_UAT`

2. **Settings → Environments → Create `Production`**
   - Add secret: `SQL_CONNECTION_STRING_PROD`
   - Enable: **Required reviewers**

## How to Make Changes

1. Edit any `.sql` file inside `iteration-2/dbo/`
2. Commit and push to `main`
3. Pipeline auto-deploys to UAT
4. Approve in GitHub Actions to promote to Prod
