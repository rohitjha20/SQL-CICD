-- ❌ This file has [uat] schema — should FAIL on PR to main (production)
CREATE TABLE [uat].[TestGuardrail] (
    [ID]   INT IDENTITY(1,1) NOT NULL,
    [Name] NVARCHAR(100) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);
GO
