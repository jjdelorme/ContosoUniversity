# Demo Script

## Guide
- `start` tag is code as-is from Microsoft sample
- `upgraded` tag is after upgrade-assistant completes
- `demo` branch is the starting point for the app after it fully compiles and runs in linux container

## Preconditions
- Database is setup
- Permissions for Cloud Build & Cloud Run are ready
- `git checkout start` tag and `git clean -f -d`
- Other machine is set to `git checkout upgraded` tag

## FROM Windows box
- Explain this is the same source that Ido ran....

- [RUN] `upgrade-assistant --skip-backup --non-interactive ContosoUniversity.sln`
    * explain that this tool is continuously improving, so your results could be slightly different
	* ... in fact explain extensibility mechanism
    * Talk about code changes required by scrolling through the [README](https://github.com/jjdelorme/ContosoUniversity#readme)... stop at .NET 5 Configuration

    * Takes a little while, so switch over to a different machine and look at the result.

## When upgrade-assistant completes
- [RUN] `git diff --stat start`

- [RUN] `git checkout demo`

## Open VS Code
- replace connection string:
    ```
    {
        "ConnectionStrings": {
            "SchoolContext": "Data Source=1.1.1.1;Initial Catalog=ContosoUniversity;User ID=sqlserver;Password=XXXXX;"
            }
    }
    ```

- [RUN] `dotnet run --project ContosoUniversity\ContosoUniversity.csproj`

- Launch a browser to http://localhost:5000

## Build a linux container
- Open the `\Dockerfile` and explain multi-stage build

- Open `\cloudbuild.yaml` and explain that we will use cloud build to build AND deploy to cloud run

- [RUN] `gcloud builds submit`
    - Explain this is going to take a few minutes, but when it's done we'll end up with the app running in Cloud Run.

- NOTE: there is one glaring problem with our app, it's that we've deployed this appsettings.Development.json file in plain text with our database secrets.  Let's fix this.

## Modify to use Google Secret Manager

- Add this line to `.gitignore`

    ```
    **/appsettings.Development.json
    ```

- Create a secret called `connectionstrings` using VS Code Secret Manager with the value of the connection string being the same as what you put in `appsettings.Development.json`.

- Change `cloudbuild.yaml` to deploy using secret.
    ```diff
    -   - '--update-env-vars=ASPNETCORE_ENVIRONMENT=Development'
    +   - '--update-secrets=/app/secrets/appsettings.json=connectionstrings:latest'
    ```

- Modify `Program.cs` to read secret file.
```diff
         public static IHostBuilder CreateHostBuilder(string[] args) =>
             Host.CreateDefaultBuilder(args)
+                .ConfigureAppConfiguration(AddSecretConfig)
                 .ConfigureWebHostDefaults(webBuilder =>

```

```csharp
        private static void AddSecretConfig(HostBuilderContext context,
            IConfigurationBuilder config)
        {
            string secretsPath = context.Configuration.GetValue("SECRETS_PATH",
                "secrets");

            var secretFileProvider = context.HostingEnvironment.ContentRootFileProvider
                .GetDirectoryContents(secretsPath);

            if (secretFileProvider.Exists)
            {
                foreach (var secret in secretFileProvider)
                {
                    if (!secret.IsDirectory && secret.Name.ToUpper().EndsWith(".JSON"))
                        config.AddJsonFile(secret.PhysicalPath, false, true);
                }
            }
        }
```

## Modify to use Google Cloud Diagnostics

- Take advantage of Google Logging, Error Reporting and Tracing

- Add these packages to `ContosoUniversity\ContosoUniversity.csproj`

```xml
    <PackageReference Include="Google.Cloud.Diagnostics.AspNetCore" Version="4.2.0" />
    <PackageReference Include="Grpc.AspNetCore" Version="2.32.0" />
```    

- Add these lines to `Program.cs`
```csharp
using Google.Cloud.Diagnostics.AspNetCore;
...
                 .ConfigureWebHostDefaults(webBuilder =>
                 {
                    if (webBuilder.GetSetting("ENVIRONMENT") == "Production")
                    {
                        webBuilder.UseGoogleDiagnostics();
                    }
                     webBuilder.UseStartup<Startup>();
                 });
```