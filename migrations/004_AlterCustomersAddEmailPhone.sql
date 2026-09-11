-- Migration: Add Email column to Customers
-- This is an ALTER script — DbUp handles this natively
ALTER TABLE [uat].[Customers]
ADD [Email] NVARCHAR(200) NULL;
GO

ALTER TABLE [uat].[Customers]
ADD [Phone] NVARCHAR(20) NULL;
GO
