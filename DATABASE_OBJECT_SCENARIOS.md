# Database Object Schema Evolution Scenarios

This guide details exactly how the `SqlPackage` (DACPAC) engine natively handles schema evolution for various database objects within this CI/CD project.

By using the declarative SDK-style SQL project, developers **do not** need to write imperative `ALTER` or `DROP` statements. The CI/CD pipeline dynamically calculates the delta between the source `.sql` file and the target database.

Below is the definitive guide on how to handle the 5 core conditions: Primary Keys, Unique Keys, Constraints, Indexes, and Stored Procedures.

---

## 1. Primary Key Condition

**Source Reference:** `dbo/Tables/SchemaEvolutionDemo.sql`

*   **Adding**: To add a primary key, add `PRIMARY KEY` to the column definition or add a `CONSTRAINT [PK_Name] PRIMARY KEY (ColumnName)` block to the `.sql` file. `SqlPackage` will generate:
    ```sql
    ALTER TABLE [dbo].[TableName] ADD PRIMARY KEY ([ID]);
    ```
*   **Changing to Another Column**: To change the PK, remove it from the old column in the `.sql` file and add it to the new column. `SqlPackage` will generate:
    ```sql
    ALTER TABLE [dbo].[TableName] DROP CONSTRAINT [PK_OldName];
    ALTER TABLE [dbo].[TableName] ADD PRIMARY KEY ([NewColumnID]);
    ```
*   **Removing / Complete Drop**: Delete the `PRIMARY KEY` declaration from the `.sql` file. `SqlPackage` will automatically detect its absence and generate:
    ```sql
    ALTER TABLE [dbo].[TableName] DROP CONSTRAINT [PK_Name];
    ```

---

## 2. Unique Key Condition

**Source Reference:** `dbo/Tables/SchemaEvolutionDemo.sql`

*   **Adding**: Add `UNIQUE` to the column or define a `CONSTRAINT [UK_Name] UNIQUE ([Column])`. `SqlPackage` generates:
    ```sql
    ALTER TABLE [dbo].[TableName] ADD CONSTRAINT [UK_Name] UNIQUE ([UniqueCode]);
    ```
*   **Changing to Another Column**: Remove the `UNIQUE` keyword from the old column and add it to the new one. `SqlPackage` generates:
    ```sql
    ALTER TABLE [dbo].[TableName] DROP CONSTRAINT [UK_Old];
    ALTER TABLE [dbo].[TableName] ADD CONSTRAINT [UK_New] UNIQUE ([NewColumn]);
    ```
*   **Removing / Complete Drop**: Delete the `UNIQUE` declaration. `SqlPackage` generates:
    ```sql
    ALTER TABLE [dbo].[TableName] DROP CONSTRAINT [UK_Name];
    ```

---

## 3. Constraint Condition (CHECK & DEFAULT)

**Source Reference:** `dbo/Tables/SchemaEvolutionDemo.sql`

*   **Adding**: Add `DEFAULT 'Value'` or `CHECK (Condition)` to a column. `SqlPackage` generates:
    ```sql
    ALTER TABLE [dbo].[TableName] ADD CONSTRAINT [CHK_Status] CHECK ([Status] IN ('Active', 'Inactive'));
    ALTER TABLE [dbo].[TableName] ADD DEFAULT ('Active') FOR [Status];
    ```
*   **Changing**: Modify the condition (e.g., from `IN ('Active', 'Inactive')` to `IN ('Active', 'Inactive', 'Pending')`). `SqlPackage` automatically drops the old constraint and creates the new one:
    ```sql
    ALTER TABLE [dbo].[TableName] DROP CONSTRAINT [CHK_Status];
    ALTER TABLE [dbo].[TableName] ADD CONSTRAINT [CHK_Status] CHECK ([Status] IN ('Active', 'Inactive', 'Pending'));
    ```
*   **Removing / Complete Drop**: Remove the `CHECK` or `DEFAULT` keyword from the `.sql` file. `SqlPackage` generates:
    ```sql
    ALTER TABLE [dbo].[TableName] DROP CONSTRAINT [CHK_Status];
    ```

---

## 4. Index Condition

**Source Reference:** `dbo/Tables/SchemaEvolutionDemo.sql`

*   **Adding**: Add a `CREATE NONCLUSTERED INDEX` statement to the `.sql` file. `SqlPackage` generates the exact `CREATE INDEX` statement during deployment.
*   **Changing**: Change the columns in the `CREATE INDEX` definition (e.g., add an `INCLUDE` column or change the sort order). `SqlPackage` will generate:
    ```sql
    DROP INDEX [IX_Name] ON [dbo].[TableName];
    CREATE NONCLUSTERED INDEX [IX_Name] ON [dbo].[TableName] ([NewColumn]);
    ```
*   **Removing / Complete Drop**: Delete the `CREATE INDEX` statement from the `.sql` file. `SqlPackage` generates:
    ```sql
    DROP INDEX [IX_Name] ON [dbo].[TableName];
    ```

---

## 5. Stored Procedure Condition

**Source Reference:** `dbo/StoredProcedures/GetEmployeeDetails.sql`

*   **Adding**: Create a new `.sql` file in the project with a `CREATE PROCEDURE` statement. `SqlPackage` generates the `CREATE PROCEDURE` execution.
*   **Changing**: Modify the parameters, body, or name in the `CREATE PROCEDURE` file. Even though the source code says `CREATE PROCEDURE`, `SqlPackage` intelligently detects that the procedure already exists and will generate:
    ```sql
    ALTER PROCEDURE [dbo].[GetEmployeeDetails] ...
    ```
*   **Removing / Complete Drop**: Delete the `GetEmployeeDetails.sql` file from the repository (or exclude it in the `.sqlproj`). `SqlPackage` detects it is missing from the DACPAC and generates:
    ```sql
    DROP PROCEDURE [dbo].[GetEmployeeDetails];
    ```

---
> **Important Note:** In all of these scenarios, if a change could result in data loss (like changing a primary key that drops an underlying table), the pipeline will block execution automatically because `/p:BlockOnPossibleDataLoss=True` is enabled in the workflow by default.
