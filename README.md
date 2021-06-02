# Running a legacy ASP.NET MVC app as-is on GKE Windows

This sample walks through a complete tutorial of running [Contoso University](https://docs.microsoft.com/en-us/aspnet/mvc/overview/getting-started/getting-started-with-ef-using-mvc/creating-an-entity-framework-data-model-for-an-asp-net-mvc-application) on Google Kubernetes Engine in a Windows Container.  This app is a traditional Microsoft ASP.NET Framework MVC + Entity Framework sample that was built with .NET Framework 4.5 and EntityFramework 6.  We also leverage [Cloud SQL for SQL Server](https://cloud.google.com/sql-server) a managed Microsoft SQL Server 2017 database in Google Cloud. 

### Table of Contents  
* [Prerequisites](#Prerequisites)   
* [Setup](#Setup) 
* [Deploy](#Deploy)

## Prerequisites

1. Visual Studio 2019 – (Community Edition or any edition)

1. (Optional) [Install Docker](https://docs.docker.com/docker-for-windows/install/) on your local machine.  Don't worry if you cannot install Docker in your environment, we have a solution for you!

1. Install [.NET 5 SDK](https://dotnet.microsoft.com/download/dotnet/5.0)

1. Download and install the Google Cloud SDK following these [instructions](https://cloud.google.com/sdk/docs/install) or clone this repo.

## Setup

Either [Download the original Microsoft sample](https://webpifeed.blob.core.windows.net/webpifeed/Partners/ASP.NET%20MVC%20Application%20Using%20Entity%20Framework%20Code%20First.zip) and unzip it to a local directory, or clone this repository and checkout the `start` tag:

```cmd
git clone https://github.com/jjdelorme/ContosoUniversity

git checkout start
```

### Setup Cloud SQL for SQL Server

Start by setting up the Google Cloud SQL for SQL Server instance.  

1. [Create an instance](https://cloud.google.com/sql/docs/sqlserver/create-instance?hl=en_US>).  For the purposes of this tutorial you can use the SQL Server 2017 Express Edition which has $0 licensing costs.

1. [Create a database](https://cloud.google.com/sql/docs/sqlserver/create-manage-databases?hl=en_US>) named `ContosoUniversity` 

1. [Add a user](https://cloud.google.com/sql/docs/sqlserver/create-manage-users?hl=en_US) to connect to the database.    

1. Make sure that the IP you will be connecting to the database from is added to the [Authorized networks](https://cloud.google.com/sql/docs/sqlserver/configure-ip?hl=en_US#console) or for the purposes of this demo (**and never in production**), you can allow all public IPs (0.0.0.0/0) to connect:
![Allow All Public IPs](_figures/allowpublicip.png)

### Connect to the database

Open `ContosoUniversity.sln` with Visual Studio 2019.

Using the Cloud SQL Server IP address, database name, user and password you created above, modify your connection string in the `Web.config` file:

```XML
  <connectionStrings>
    <add name="SchoolContext" connectionString="Data Source=1.1.1.1;Initial Catalog=ContosoUniversity;User ID=sqlserver;Password=XXXXX;" providerName="System.Data.SqlClient" />
  </connectionStrings>
```

In Visual Studio open the Package Manager Console from the **View** menu -> **Other Windows** -> **Package Manager Console** and enter this command:

```cmd
PM> update-database
```

This will create the schema and seed the database with data.  If you are interested in how this works, it's automatic done using Entity Framework and the `DAL\SchoolInitializer.cs` class.

### Test the application 

Confirm the application builds and functions as desired before staring the migration.  
1. From Visual Studio 2019 press `Ctrl+F5` to build and run the project. 

1. You should see the home page:
![Home Page](./_figures/homepage.png)

1. Verify it can access the database by clicking on one of the tabs, i.e. Departments.

## Deploy to GKE Windows

Use the steps here [Windows Container and deploying to GKE](GKE.md).
