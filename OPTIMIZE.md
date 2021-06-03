# PLACEHOLDER: Optimizing Container image size

## Container image size
The smallest supported container image from Microsoft is based on Alpine linux.  In our dockerfile, we're already referencing it with `FROM mcr.microsoft.com/dotnet/runtime-deps:5.0-alpine-amd64 AS runtime`

## Structured Console Logger
Rather than calling `UsingGoogleDiagnostics` which uses gRPC, we can use a structured console logger directly to stdout which will automatically get picked up by Google Cloud Run, GKE, etc... By removing gRPC libraries we will save ~160mb on the container size.

1. Add the file `ContosoUniversity/Google.Cloud.Logging.Console/GoogleCloudConsoleFormatter.cs` from these two files:
    - https://raw.githubusercontent.com/googleapis/google-cloud-dotnet/master/apis/Google.Cloud.Logging.Console/Google.Cloud.Logging.Console/GoogleCloudConsoleFormatter.cs
    - https://raw.githubusercontent.com/googleapis/google-cloud-dotnet/master/apis/Google.Cloud.Logging.Console/Google.Cloud.Logging.Console/GoogleCloudConsoleFormatterOptions.cs  

1. Remove these references from `ContosoUniversity.csproj`
    ```diff
    -    <PackageReference Include="Google.Cloud.Diagnostics.AspNetCore" Version="4.2.0" />
    -    <PackageReference Include="Grpc.AspNetCore" Version="2.32.0" />
    ```

1. Change `ContosoUniversity/Program.cs` as follows:
    ```diff
                    {
                        if (webBuilder.GetSetting("ENVIRONMENT") == "Production")
                        {
    -                        webBuilder.UseGoogleDiagnostics();
    +                        // Configure the console logger
    +                        webBuilder.ConfigureLogging(loggingBuilder => loggingBuilder
    +                            .AddConsoleFormatter<GoogleCloudConsoleFormatter, GoogleCloudConsoleFormatterOptions>(options => options.IncludeScopes = true)
    +                            .AddConsole(options => options.FormatterName = nameof(GoogleCloudConsoleFormatter)));
                        }
                        webBuilder.UseStartup<Startup>();
                    });
    ```

## Use dive to examine container image size

1. Download the [dive](https://github.com/wagoodman/dive) tool to compare the container image sizes.  You will notice the original container image is ~260mb in size, while the new container image without gRPC is 113mb.