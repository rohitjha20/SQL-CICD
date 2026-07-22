CREATE TABLE [dbo].[person] (
    [PersonID]   INT             IDENTITY (1, 1) NOT NULL,
    [Personname] NVARCHAR (100)  NOT NULL,
    [Relation]   NVARCHAR (50)   NULL,
    [Salary]       DECIMAL (10, 2) NULL,
    [JoiningDate]  DATE            NULL,
    [EmailID]       NVARCHAR (200) NULL,
    [PhoneNumber]   NVARCHAR (15)  NULL,
    [Address]   NVARCHAR (100)  NULL,
    [City] NVARCHAR (100)  NULL,
    PRIMARY KEY CLUSTERED ([EmployeeID] ASC)
);
GO
