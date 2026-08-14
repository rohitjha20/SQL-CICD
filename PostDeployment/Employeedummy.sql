IF NOT EXISTS (SELECT 1 FROM dbo.EmployeeDummy)
BEGIN
    INSERT INTO dbo.EmployeeDummy
        (
        EmployeeName,
        Department,
        Salary,
        EmailID,
        PhoneNumber,
        Address
        )
    VALUES
        ('Rahul Sharma', 'IT', 65000.00, 'rahul@example.com', '9876543210', '123 Tech Park'),
        ('Priya Singh', 'Finance', 72000.00, 'priya@example.com', '9876543211', '456 Financial District'),
        ('Amit Kumar', 'HR', 55000.00, 'amit@example.com', '9876543212', '789 Corporate Blvd'),
        ('Neha Gupta', 'Sales', 68000.00, 'neha@example.com', '9876543213', '101 Market St'),
        ('Vikas Verma', 'Operations', 60000.00, 'vikas@example.com', '9876543214', '202 Logistics Way');
    PRINT 'Inserted seed data into dbo.EmployeeDummy';
END
GO