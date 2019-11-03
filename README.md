# Throwing Mud on the Wall with Azure Data Factory and AzureDataFactoryDemo_GenericSqlSink

## This is a work in progress, it is not currently release quality

Sometimes I just need data sourced from CSV files imported into a SQL Server table.  Nothing fancy, just quick-and-dirty while using security, operational and deployment best-practices.  I've done this enough times that I find it worth investing the time to create a generic, reusable and redeployable solution.

I'm creating a solution that will take data from a variety of sources and push that data into a variety of sinks.  I'm starting off with reading a CSV file into a SQL Server table.  My intention is to create a matrix of solutions that all adhere to and demonstrate best practices while quickly and easily getting data (from whatever source) to its destination.

I'm open-sourcing this so that if someone 
- finds a problem 
- wants to add a new source and destination mapping, they can do it themselves and contribute their code back to the project
- finds a more secure way to provide services, the issue can be raised and addressed
- finds a faster way to provide services, the issue can be raised and addressed.

Sources and sinks I envision supporting:

- Azure SQL Database (source, sink)
- CSV files
- JSON files
- Azure CosmosDB
- Azure SQL Data Warehouse
- Blob Storage
- Azure Data Lake Storage

Logging options to be supported:

- CSV logging 
- JSON logging
- Logging to an Event Hub

Operational Monitoring Scenarios:

- Use of Azure Monitor to monitor operations
- Use of PowerBI to read from supported logging sources

SQL Server connection security: 

- SQL Server Connection String providing username, password and connection data through runtime parameters
- Use of Azure SQL Database-Azure Active Directory integration to assign SQL Server-level rights 
- Use of least-privilege accounts to support data movement

Blob Storage connection security 

- Use of RBAC

Security Best Practices adhered to:

- Use of Azure ARM Templates to deploy Azure Resources
- Use of Azure ARM Template parameters to pass sensitive information at deployment time
- Use of Azure Key Vault to provide secure storage of sensitive information
- Use of PowerShell's Az module to interact with Azure
- Use of Azure Active Directory to provide identity authentication services 
- Use of Azure's RBAC security to provide authorization services\
- Aggressive logging of operations to a SQL Server table in the destination database
- Using Azure Monitor and Azure Alerting to monitor operations

AzureDataFactoryDemo_GenericSqlSink does the following:

- Reads structure metadata from a CSV file stored in blob storage

- Finds or Creates the SQL table in the target database that matches the structure of the CSV file

- - If there are zero matches, a new table and view are created to act as the sink for the data, the table and view name of the new table is used

- - If there is one match, the table and view name of the matching table is used

- - If there is more than one match, the system doesn't know where it should belong, a new table and view are created to act as the sink for the data, the table and view name of the new table is used


Operational metadata is logged to the target view.  The metadata collected is:
- __StorageAccountName:  Source blob storage account name
- __FileName:  Name of the file used as the source of data
- __DataFactoryName:  Name of the Azure Data Factory used to load the data
- __DataFactoryPipelineName:  Name of the Azure Data Factory Pipeline used to load the data
- __DataFactoryPipelineRunId:  ID of the Data Factory Pipeline Run that loaded the data
- __InsertDateTimeUTC:  Full date and time the data was loaded in the UTC timezone, sourced from the Data Factory



Thanks to Mark Kromer and Jack Ma.  They rock!
