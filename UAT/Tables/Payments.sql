-- ❌ WRONG: [roh] schema in UAT/ folder — should be [uat]
CREATE TABLE [roh].[Payments] (
    [PaymentID]  INT IDENTITY(1,1) NOT NULL,
    [OrderID]    INT NOT NULL,
    [Amount]     DECIMAL(18,2) NOT NULL,
    [PaidAt]     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [FK_Payments_Orders] FOREIGN KEY ([OrderID])
        REFERENCES [roh].[Orders] ([OrderID]),
    PRIMARY KEY CLUSTERED ([PaymentID] ASC)
);
GO
