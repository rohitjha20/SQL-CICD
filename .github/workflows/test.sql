INSERT INTO dbo.EmployeeDummy
(
    EmployeeName,
    Department,
    Salary,
    JoiningDate
)
VALUES
('Rahul Sharma', 'IT', 65000.00, '2024-01-15'),
('Priya Singh', 'Finance', 72000.00, '2023-08-20'),
('Amit Kumar', 'HR', 55000.00, '2022-11-10'),
('Neha Gupta', 'Sales', 68000.00, '2024-04-05'),
('Vikas Verma', 'Operations', 60000.00, '2023-02-28');


select * from dbo.EmployeeDummy

SELECT @@VERSION;


SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';


INSERT INTO dbo.EmployeeDummy
(
    EmployeeName,
    Department,
    Salary,
    JoiningDate
)
VALUES
('Rohit Jha', 'Data Engineering', 120000, '2026-07-22'),
('John Smith', 'Finance', 90000, '2025-01-10');


CREATE TABLE [dbo].[EmployeeDummy]
(
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeName NVARCHAR(100) NOT NULL,
    Department NVARCHAR(50),
    Salary DECIMAL(10,2),
    JoiningDate DATE,
);


SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'EmployeeDummy';


SELECT
    COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Person'
ORDER BY ORDINAL_POSITION;
select * from dbo.person

SELECT
    @@SERVERNAME AS ServerName,
    DB_NAME() AS DatabaseName,
    SUSER_SNAME() AS LoginName;


drop table dbo.EmployeeDummy;