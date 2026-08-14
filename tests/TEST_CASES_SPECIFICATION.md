# 🧪 Azure SQL CI/CD: Automated Test Cases Specification

> **Target Database**: `freetier-sqlserver-central.database.windows.net` / `appdb`  
> **Test Harness File**: [`tests/run_all_tests.sql`](file:///Users/rohitjha/Documents/Git-master/SQL-CICD/tests/run_all_tests.sql)  
> **Test Runner**: [`tests/test_runner.sh`](file:///Users/rohitjha/Documents/Git-master/SQL-CICD/tests/test_runner.sh)

---

## 📋 Test Matrix Overview

| Test # | Component | Test Scenario Name | Type | Assertion Criteria |
| :--- | :--- | :--- | :--- | :--- |
| **TC-01** | `Schema` | Verify All Database Objects Exist | Structural | All 4 tables, 1 view, 1 SP, 2 functions, and 1 trigger exist in `sys.objects` |
| **TC-02** | `Tables` | Default Constraints on `SchemaEvolutionDemo` | Functional | Insert without `Status` or `CreatedAt` yields `'Active'` and `SYSUTCDATETIME()` |
| **TC-03** | `Constraints` | Negative Test: CHECK Constraint Rejection | Negative | Insert with invalid `Status = 'Suspended'` raises SQL Error `547` |
| **TC-04** | `PostDeploy` | Post-Deployment Seed Data Verification | Data Quality | `dbo.person` $\ge 3$ rows and `dbo.EmployeeDummy` $\ge 3$ rows |
| **TC-05** | `Views` | `vw_ActiveEmployees` Status Filtering | Logic | View returns only records where `Status = 'Active'` and filters out `Inactive` |
| **TC-06** | `Functions` | `fn_CalculateBonus` Department Logic | Business Logic | Engineering = 15%, Product = 12%, DevOps = 13%, Default = 10% |
| **TC-07** | `Functions` | `fn_GetEmployeesByDepartment` Table Return | Data Filter | Returns only rows where `Department` equals the input parameter |
| **TC-08** | `Triggers` | Audit Log Capture on `INSERT` | Event Logging | `AFTER INSERT` trigger creates a record in `dbo.AuditLog` with `Operation = 'INSERT'` |
| **TC-09** | `Triggers` | Audit Log Capture on `UPDATE` | Event Logging | `AFTER UPDATE` trigger logs both old values and new values to `dbo.AuditLog` |
| **TC-10** | `StoredProcedures` | `GetEmployeeDetails` Procedure Execution | Execution | Procedure returns correct employee record by `@EmployeeID` |

---

## 🔍 Detailed Test Case Specifications

---

### Test Case 1: Schema Object Existence
* **Test ID**: `TC-01`
* **Objective**: Confirm that all expected database schema objects have been deployed by DACPAC.
* **Objects Checked**:
  - Tables: `dbo.EmployeeDummy`, `dbo.person`, `dbo.SchemaEvolutionDemo`, `dbo.AuditLog`
  - Views: `dbo.vw_ActiveEmployees`
  - Stored Procedures: `dbo.GetEmployeeDetails`
  - Functions: `dbo.fn_CalculateBonus`, `dbo.fn_GetEmployeesByDepartment`
  - Triggers: `dbo.trg_AuditEmployeeChanges`
* **Pass Condition**: Count of missing objects equals `0`.

---

### Test Case 2: Default Constraints Verification
* **Test ID**: `TC-02`
* **Objective**: Verify that default values for `Status` and `CreatedAt` are properly applied on record insertion.
* **Action**:
  ```sql
  INSERT INTO dbo.SchemaEvolutionDemo ([ID], [UniqueCode], [Name], [Department], [Salary])
  VALUES (9001, 'TEST_CODE_9001', 'Test Default User', 'Engineering', 90000.00);
  ```
* **Pass Condition**: `Status = 'Active'` and `CreatedAt IS NOT NULL`.

---

### Test Case 3: Negative Test — CHECK Constraint Rejection
* **Test ID**: `TC-03`
* **Objective**: Ensure data integrity rules prevent invalid values from being inserted into the database.
* **Action**:
  ```sql
  INSERT INTO dbo.SchemaEvolutionDemo ([ID], [UniqueCode], [Name], [Department], [Salary], [Status])
  VALUES (9002, 'TEST_CODE_9002', 'Invalid User', 'HR', 50000.00, 'Suspended');
  ```
* **Pass Condition**: Operation fails and throws SQL Error `547` (CHECK constraint violation).

---

### Test Case 4: Post-Deployment Seed Data Verification
* **Test ID**: `TC-04`
* **Objective**: Verify that post-deployment scripts executed and populated reference data.
* **Action**:
  ```sql
  SELECT COUNT(*) FROM dbo.person;
  SELECT COUNT(*) FROM dbo.EmployeeDummy;
  ```
* **Pass Condition**: `dbo.person >= 3` and `dbo.EmployeeDummy >= 3`.

---

### Test Case 5: View Filtering Logic (`vw_ActiveEmployees`)
* **Test ID**: `TC-05`
* **Objective**: Verify that `dbo.vw_ActiveEmployees` only returns active records and filters out inactive ones.
* **Action**:
  Insert two test rows (one `Status = 'Active'`, one `Status = 'Inactive'`). Query `dbo.vw_ActiveEmployees`.
* **Pass Condition**: Active record is returned; Inactive record is excluded.

---

### Test Case 6: Scalar Function Logic (`fn_CalculateBonus`)
* **Test ID**: `TC-06`
* **Objective**: Verify business calculation rules for employee bonus by department.
* **Expected Output**:
  - `Engineering` ($100,000) $\to$ **$15,000** (15%)
  - `Product` ($100,000) $\to$ **$12,000** (12%)
  - `DevOps` ($100,000) $\to$ **$13,000** (13%)
  - `Marketing` ($100,000) $\to$ **$10,000** (10% default)
* **Pass Condition**: All 4 calculated bonuses match expected values.

---

### Test Case 7: Table-Valued Function (`fn_GetEmployeesByDepartment`)
* **Test ID**: `TC-07`
* **Objective**: Verify that the table-valued function returns matching rows for a department.
* **Action**:
  ```sql
  SELECT * FROM dbo.fn_GetEmployeesByDepartment('Engineering');
  ```
* **Pass Condition**: Returned rows only belong to `Engineering` department.

---

### Test Case 8: Trigger Audit Logging on INSERT
* **Test ID**: `TC-08`
* **Objective**: Verify that `trg_AuditEmployeeChanges` logs new rows to `dbo.AuditLog`.
* **Action**:
  Insert a test record into `SchemaEvolutionDemo`.
* **Pass Condition**: A row is inserted in `dbo.AuditLog` with `Operation = 'INSERT'` and `TableName = 'SchemaEvolutionDemo'`.

---

### Test Case 9: Trigger Audit Logging on UPDATE
* **Test ID**: `TC-09`
* **Objective**: Verify that `trg_AuditEmployeeChanges` logs old and new column values on update.
* **Action**:
  Update `Department` from `'Product'` to `'Engineering'` and `Status` to `'Inactive'`.
* **Pass Condition**: A row is inserted in `dbo.AuditLog` with `Operation = 'UPDATE'` containing `OldValues` and `NewValues`.

---

### Test Case 10: Stored Procedure Execution (`GetEmployeeDetails`)
* **Test ID**: `TC-10`
* **Objective**: Verify that `dbo.GetEmployeeDetails` returns the expected employee fields.
* **Action**:
  ```sql
  EXEC dbo.GetEmployeeDetails @EmployeeID = 9009;
  ```
* **Pass Condition**: Procedure successfully executes and returns the correct name, department, and status.

---

## 🚀 How to Execute the Tests

### Option A: Via Azure Portal Query Editor (Interactive)
1. Open [Azure Portal](https://portal.azure.com) $\to$ **`freetier-sqlserver-central`** $\to$ **`appdb`** $\to$ **Query editor**.
2. Open [`tests/run_all_tests.sql`](file:///Users/rohitjha/Documents/Git-master/SQL-CICD/tests/run_all_tests.sql).
3. Click **Run**.
4. Review the results table showing `✅ PASSED` for all 10 test scenarios.

### Option B: Via Terminal Test Runner
```bash
export SQL_CONNECTION_STRING="Server=tcp:freetier-sqlserver-central.database.windows.net,1433;Initial Catalog=appdb;Persist Security Info=False;User ID=<USER>;Password=<PASS>;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

./tests/test_runner.sh
```
