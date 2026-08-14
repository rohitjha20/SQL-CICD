CREATE TABLE [dbo].[ProjectAssignments] (
    [AssignmentID]   INT IDENTITY(1,1) NOT NULL,
    [ProjectID]      INT NOT NULL,
    [EmployeeID]     INT NOT NULL,
    [RoleInProject]  NVARCHAR(50) NOT NULL DEFAULT 'Contributor',
    [AssignedDate]   DATE NOT NULL DEFAULT CAST(SYSUTCDATETIME() AS DATE),
    [HoursAllocated] INT NOT NULL DEFAULT 40 CHECK ([HoursAllocated] > 0),
    PRIMARY KEY CLUSTERED ([AssignmentID] ASC),
    CONSTRAINT [UQ_Project_Employee_Assignment] UNIQUE ([ProjectID], [EmployeeID])
);
GO

CREATE NONCLUSTERED INDEX [IX_ProjectAssignments_EmployeeID]
    ON [dbo].[ProjectAssignments] ([EmployeeID] ASC);
GO
