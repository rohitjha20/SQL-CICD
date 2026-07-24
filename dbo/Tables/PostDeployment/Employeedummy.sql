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