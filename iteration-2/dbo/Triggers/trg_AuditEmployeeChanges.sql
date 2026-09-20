CREATE TRIGGER [dbo].[trg_AuditEmployeeChanges]
ON [dbo].[SchemaEvolutionDemo]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Log INSERTs
    INSERT INTO [dbo].[AuditLog] ([TableName], [Operation], [RecordID], [NewValues])
    SELECT
        'SchemaEvolutionDemo',
        'INSERT',
        i.[ID],
        CONCAT('Name=', i.[Name], '|Dept=', i.[Department], '|Status=', i.[Status])
    FROM inserted i
    WHERE NOT EXISTS (SELECT 1 FROM deleted d WHERE d.[ID] = i.[ID]);

    -- Log DELETEs
    INSERT INTO [dbo].[AuditLog] ([TableName], [Operation], [RecordID], [OldValues])
    SELECT
        'SchemaEvolutionDemo',
        'DELETE',
        d.[ID],
        CONCAT('Name=', d.[Name], '|Dept=', d.[Department], '|Status=', d.[Status])
    FROM deleted d
    WHERE NOT EXISTS (SELECT 1 FROM inserted i WHERE i.[ID] = d.[ID]);

    -- Log UPDATEs
    INSERT INTO [dbo].[AuditLog] ([TableName], [Operation], [RecordID], [OldValues], [NewValues])
    SELECT
        'SchemaEvolutionDemo',
        'UPDATE',
        i.[ID],
        CONCAT('Name=', d.[Name], '|Dept=', d.[Department], '|Status=', d.[Status]),
        CONCAT('Name=', i.[Name], '|Dept=', i.[Department], '|Status=', i.[Status])
    FROM inserted i
    INNER JOIN deleted d ON i.[ID] = d.[ID];
END;
GO
