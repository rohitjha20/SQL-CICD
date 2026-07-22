CREATE TABLE [dbo].[EmployeeDummy] (
    [EmployeeID]   INT             IDENTITY (1, 1) NOT NULL,
    [EmployeeName] NVARCHAR (100)  NOT NULL,
    [Department]   NVARCHAR (50)   NULL,
    [Salary]       DECIMAL (10, 2) NULL,
    [JoiningDate]  DATE            NULL,
    [EmailID]       NVARCHAR (200) NULL,
    PRIMARY KEY CLUSTERED ([EmployeeID] ASC)
);
GO

