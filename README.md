# Throwing Mudd on the Wall (TMoW) - Instant ELt using Azure Data Factory

## This is a work in progress, it is not currently release quality

![Harry Mudd](https://www.syfy.com/sites/syfy/files/styles/1200x680/public/wire/legacy/Harry_Mudd.jpg)

Sometimes I just need data sourced from CSV files imported into a SQL Server table.  Nothing fancy, but I've needed it over and over again.  Why not take all that I've learned about building Data Factory Pipelines and do a no-compromises, best-practices implementation?  It will be reusable and consistent, upgradable and open.  I've done this enough times that I find it worth investing the time to create a generic, reusable and redeployable solution.

It provides the EL in ELt.  (Extract, Load, Transform)

My goal is to be the de-facto reference implementation for Azure Data Factory pipelines from a security, operational and deployment perspective.  It takes a lot of guts to aim that high.  I also know that I'm in the company of amazing technologists.  I'm hoping to attract them as contributors to this project.  Constructive criticism, especially with proscriptive direction, is always welcome.

Why open-source it?  This industry has been very good to me over the years and I'd like to contribute back.  This is a component of nearly every project I've ever worked on.  There is value in having a constitently deployable solution.

It also doesn't add a lot of business value and really isn't much of a competitive differentiator.  It's plumbing.  There's no value-add here.  I'd rather spend my time and my customer's money dealing with the things that are unique and valuable to their business, not charging them to build the same plumbing over-and-over again.

I'm creating a solution that will take data from a variety of sources and push that data into a variety of sinks.  If the sink doesn't exist, it should be magically created.

My intention is to create a consistently deployable matrix of solutions that all adhere to and demonstrate best practices while quickly and easily getting data (from whatever source) to its destination.

I'm open-sourcing this so that if someone 
- finds a problem 
- wants to add a new source and destination mapping, they can do it themselves and contribute their code back to the project
- finds a more secure way to provide services, the issue can be raised and addressed
- finds more performant way to provide services, the issue can be raised and addressed.

Sources and sinks I envision supporting:

- Azure SQL Database
- Azure CosmosDB
- Azure Data Warehouse/Azure Synapse
- CSV files in Azure Blob Storage/Azure Data Lake store
- JSON files in Azure Blob Storage/Azure Data Lake store
- Avro files in Azure Blob Storage/Azure Data Lake store
- Parquet files in Azure Blob Storage/Azure Data Lake store

Given this list, there are obvious opportunities to incorporate other storage platforms (S3, etc) and other file formats (XML, etc)

Operational Monitoring Scenarios:

- Use of Azure Monitor to monitor operations

Connection security: 

- SQL Server Connection String and connection data through runtime lookup of secrets stored in Azure Data Factory
- Use of Azure SQL Database-Azure Active Directory integration to assign SQL Server-level rights 
- Use of least-privilege accounts to support data movement
- Use of database roles to assign SQL-level permissions
- Use of Access Policy security to grant access to Azure Key Vault from Azure Data Factory
- Use of access keys to access blob storage
- Use of RBAC roles to access blob storage 

Use of Azure Active Directory assumes that AAD integration with Azure SQL Database is in place.  See https://docs.microsoft.com/en-us/azure/sql-database/sql-database-aad-authentication-configure

- Use of Azure ARM Templates and PowerShell to deploy Azure Resources
- Use of Azure ARM Template parameters to pass Secret Names of sensitive information at runtime
- Use of Azure Key Vault to provide secure storage of sensitive information
- Use of PowerShell's Az module to interact with Azure
- Use of Azure Active Directory to provide identity authentication services 
- Use of Azure Monitor and Azure Alerting to monitor operations
- Use of Azure Monitor Workbooks and PowerBI to monitor operations

AzDataFactoryDemo_GenericSqlSink does the following:

Quickly and easily pulls data from source to sink using security best practices.  If the target object (a relational table or a CosmosDB document) doesn't exist in the sink, it is magically created.  

The details:
- Reads structure metadata from a CSV file stored in blob storage
- Finds or Creates the SQL table in the target database that matches the structure of the CSV file
- - If there are zero matches, a new table is created to act as the sink for the data, the table name of the new table is used
- - If there is one match, the table name of the matching table is used
- - If there is more than one match, the system doesn't know where it should belong, a new table is created to act as the sink for the data, the table name of the new table is used

Operational metadata is logged to the target table as additional columns. The metadata collected is:

-   __sourceConnectionStringSecretName - Secret containing the connection string that points to the data source
-   __sinkConnectionStringSecretName - Secret containing the connection string that points to the data sink
-   __sourceObjectName - object data will be loaded from
-   __targetObjectName - object data will be loaded into
-   __dataFactoryName - Name of the Azure Data Factory used to load the data
-   __dataFactoryPipelineName - Name of the Azure Data Factory Pipeline used to load the data
-   __dataFactoryPipelineRunId - ID of the Data Factory Pipeline Run that loaded the data
-   __insertDateTimeUTC - Full date and time the data was loaded in the UTC timezone
                            
Onboarding checklist:

- Create or identify an Azure Key Vault instance that will hold your secrets
- Create or identify data sources and data sinks
- Create or identify the security context (AAD vs connection strings) to be used
- Grant security contexts rights to data sources and data sinks 
- Deploy sink Azure SQL Database objects to sink databases
- Create connection strings to data sources using security context identified above
- Save connection strings as named Azure Key Vault secrets
- Create or identify the Azure Data Factory that will be handling the data movement
- Grant the Data Factory Identity access to the Azure Key Vault holding the connection strings
- Grant the Data Factory Identity access to sources and sinks (or supply username/password or access key in the connection strings)
- Within the Data Factory create a linked service pointing at the Key Vault holding the secrets
- Set Triggers using KeyVaultSecretNames as parameters

Elevator Pitch:

Technical Audience:  

Pre written and pre parameterized Azure Data Factory Pipelines that follow operational, development, deployment and security best practices.
This takes care of the EL in ELT, at scale, in the cloud, right now. 

Business Audience:

Cloud based data movement and persistence capability that your IT Department will like. 

Partner Audience:

Soft release email:

I want to invite you to participate in an open source project called Throwing Mud on the Wall (TMoW).

It is a set of Azure Data Factory objects that implement in EL in ELT.  

Do you have a customer who needs to move and transform data using Azure Data Factory?  Are they currently comfortable with SSIS, but looking to move to cloud technologies that can handle big data workloads?

TMoW is implemented as a collection of source-to-sink Azure Data Factory Pipelines that are meant to be called by a higher-level orchestrator.  TMoW provides them with best practices, open source implementations for data movement and persistence based on Azure Data Factory, which is in turn based on Apache Spark.  Give them a pre-flight checklist and get them up and moving data.





Thanks to 
- Michael French
- Mark Kromer
- Andie Letourneau
- Jack Ma
- Bob Rubocki
