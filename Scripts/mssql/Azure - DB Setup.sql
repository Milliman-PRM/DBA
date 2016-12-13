/*
    ## CODE OWNERS: Ben Wyatt

    ### OBJECTIVE:
		Configure standard permissions for new Azure SQL Databases in our (PRM's) tenancy.

    ### DEVELOPER NOTES:
		This script can only be run by the Azure SQL database administrator account.
*/

-- Create logins
CREATE USER [prm-readwrite]
	FOR LOGIN [prm-readwrite]
	WITH DEFAULT_SCHEMA = [dbo]
GO

CREATE USER [prm-readonly]
	FOR LOGIN [prm-readonly]
	WITH DEFAULT_SCHEMA = [dbo]
GO


-- Set role memberships
EXEC sp_addrolemember N'db_ddladmin', N'prm-readwrite'
GO
EXEC sp_addrolemember N'db_datareader', N'prm-readwrite'
GO
EXEC sp_addrolemember N'db_datawriter', N'prm-readwrite'
GO
EXEC sp_addrolemember N'db_datareader', N'prm-readonly'
GO
