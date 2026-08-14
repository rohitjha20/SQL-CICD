IF NOT EXISTS (SELECT 1
FROM dbo.EmployeeDummy)
BEGIN

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
END
IF NOT EXISTS (SELECT 1 FROM dbo.person)
BEGIN

    INSERT INTO dbo.person
    (
        Personname,
        Relation,
        Salary,
        JoiningDate,
        EmailID,
        PhoneNumber,
        Address,
        City
    )
    VALUES
    ('Rahul Sharma', 'Brother', 55000.00, '2024-01-15',
     'rahul.sharma@test.com', '9876543210',
     'Sector 62', 'Noida'),

    ('Amit Kumar', 'Friend', 65000.00, '2023-06-20',
     'amit.kumar@test.com', '9876543211',
     'Indirapuram', 'Ghaziabad'),

    ('Priya Singh', 'Sister', 72000.00, '2022-11-10',
     'priya.singh@test.com', '9876543212',
     'Dwarka', 'Delhi'),

    ('Vikas Verma', 'Father', 80000.00, '2020-05-05',
     'vikas.verma@test.com', '9876543213',
     'Vaishali', 'Ghaziabad'),

    ('Neha Gupta', 'Mother', 60000.00, '2021-08-18',
     'neha.gupta@test.com', '9876543214',
     'Noida Extension', 'Greater Noida');

END
-- AuditLog table requires no seed data.
-- This file is a placeholder for future reference data inserts.
PRINT 'AuditLog table ready — no seed data required.';

GO
