# Executive Presentation: Azure SQL CI/CD Schema Evolution

This document serves as the final technical presentation material for the Azure SQL CI/CD Architecture. It proves how the state-based **DACPAC** (Declarative Database Model) paradigm perfectly orchestrates complex schema evolution with **zero manual migration scripts**.

By modifying our declarative `.sql` files, the pipeline seamlessly handles **Adding, Removing, Changing, and Dropping** database objects.

---

## 🏗️ 1. The 5 Core Schema Evolution Conditions

The declarative nature of our CI/CD pipeline means developers only ever define the **Desired State** of the database. The `SqlPackage` engine automatically compares the source `.sql` with the target Database and performs the delta.

### 1. Primary Key Condition
*   **Adding / Changing**: Define `PRIMARY KEY` on a column. The pipeline generates `ALTER TABLE ADD PRIMARY KEY`. If moving to another column, it automatically orchestrates a `DROP CONSTRAINT` on the old column, and an `ADD PRIMARY KEY` on the new one.
*   **Removing / Complete Drop**: Delete the `PRIMARY KEY` from the source `.sql`. The pipeline automatically executes `ALTER TABLE DROP CONSTRAINT`.

### 2. Unique Key Condition
*   **Adding / Changing**: Add the `UNIQUE` keyword. The pipeline executes `ALTER TABLE ADD CONSTRAINT ... UNIQUE`.
*   **Removing / Complete Drop**: Delete the `UNIQUE` keyword. The pipeline executes `ALTER TABLE DROP CONSTRAINT`.

### 3. Constraint Condition
*   **Adding / Changing**: Add a `CHECK` or `DEFAULT` constraint (e.g., `CHECK (Salary >= 0)`). The pipeline applies the new rules dynamically.
*   **Removing / Complete Drop**: Delete the constraint logic. The pipeline executes `ALTER TABLE DROP CONSTRAINT`.

### 4. Index Condition
*   **Adding / Changing**: Add or modify a `CREATE NONCLUSTERED INDEX` statement. If columns change, the pipeline will `DROP INDEX` and re-execute the `CREATE INDEX` statement.
*   **Removing / Complete Drop**: Delete the index block from the source file. The pipeline issues a `DROP INDEX`.

### 5. Stored Procedure Condition
*   **Adding / Changing**: Create a `.sql` file with `CREATE PROCEDURE`. The pipeline detects if it exists on the target. If it exists, it automatically translates your `CREATE` into an `ALTER PROCEDURE`.
*   **Removing / Complete Drop**: Delete the file from the repository. The pipeline issues a `DROP PROCEDURE`.

---

## 🔬 2. Real-World Testing & Proof of Execution

To prove the robustness of this architecture, we executed a test simulating all **5 destructive changes simultaneously** on a baseline table:

1.  **Moved the Primary Key** to a different column.
2.  **Dropped a Unique Key** entirely.
3.  **Added a Salary Check Constraint** (`Salary >= 0`).
4.  **Changed the Index** to point to a new column.
5.  **Modified Stored Procedure** logic.

### 🛡️ The "Zero Data Loss" Smart Rebuild
Because moving a clustered Primary Key alters how data is physically stored on disk, standard imperative migrations often fail or result in data loss. Our CI/CD pipeline handled this automatically without writing a single `ALTER` script. 

Here is the exact DDL the engine generated to handle it safely via a **Serializable Transaction**:

```sql
BEGIN TRANSACTION;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- 1. Create a Temporary Table matching our new Desired State
CREATE TABLE [dbo].[tmp_ms_xx_SchemaEvolutionDemo] (
    [ID]         INT             NOT NULL,
    [UniqueCode] NVARCHAR (50)   NOT NULL,
    [Name]       NVARCHAR (100)  NOT NULL,
    [Department] NVARCHAR (50)   NULL,
    [Salary]     DECIMAL (18, 2) NULL,
    [Status]     NVARCHAR (20)   DEFAULT 'Active' NOT NULL,
    [CreatedAt]  DATETIME2 (7)   DEFAULT SYSUTCDATETIME() NOT NULL,
    PRIMARY KEY CLUSTERED ([UniqueCode] ASC) -- New Primary Key
);

-- 2. Safely copy all existing data from the old table to the new one
IF EXISTS (SELECT TOP 1 1 FROM [dbo].[SchemaEvolutionDemo])
BEGIN
    INSERT INTO [dbo].[tmp_ms_xx_SchemaEvolutionDemo] ...
    SELECT ... FROM [dbo].[SchemaEvolutionDemo] ORDER BY [UniqueCode] ASC;
END

-- 3. Drop the old schema and rename the temp table
DROP TABLE [dbo].[SchemaEvolutionDemo];
EXECUTE sp_rename N'[dbo].[tmp_ms_xx_SchemaEvolutionDemo]', N'SchemaEvolutionDemo';

COMMIT TRANSACTION;
```

### ⚡ Automatic Constraint & Procedure Updates
After the table was safely rebuilt with its data intact, the pipeline continued applying the rest of the changes:

```sql
-- 4. Re-created the modified Index on the new column
CREATE NONCLUSTERED INDEX [IX_SchemaEvolutionDemo_Department] ON [dbo].[SchemaEvolutionDemo]([Name] ASC);

-- 5. Added our brand new Salary Constraint
ALTER TABLE [dbo].[SchemaEvolutionDemo] WITH NOCHECK ADD CHECK ([Salary] >= 0);

-- 6. Dynamically Altered the Stored Procedure
ALTER PROCEDURE [dbo].[GetEmployeeDetails]
    @EmployeeID INT
AS
BEGIN
    ...
```

---

## 🎯 Final Conclusion
This CI/CD architecture shifts the burden of database migrations from the developer to the compiler. By leveraging `SqlPackage` and `.sqlproj`, **developers never write `ALTER`, `DROP`, or data-preservation scripts.** 

Whether you are dropping an index or completely restructuring a clustered primary key, the pipeline guarantees **idempotent, data-safe schema evolution** across all environments.
