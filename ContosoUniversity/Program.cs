using ContosoUniversity.DAL;
using Google.Cloud.Logging.Console;
using Microsoft.Extensions.Configuration.Json;

static void AddSecretConfig(IConfigurationBuilder config) 
{
    const string secretsPath = "secrets";

    var secretFileProvider = config.GetFileProvider()
        .GetDirectoryContents(secretsPath);

    if (secretFileProvider.Exists)
        foreach (var secret in secretFileProvider)
            config.AddJsonFile(secret.PhysicalPath, false, true);
}

var builder = WebApplication.CreateBuilder(args);

if (builder.Environment.IsProduction()) 
{
    builder.Logging.AddGoogleFormatLogger();
}

AddSecretConfig(builder.Configuration);

// Services
builder.Services.AddScoped<SchoolContext>(_ => 
    new SchoolContext(
        builder.Configuration.GetConnectionString("SchoolContext"))
);

// Add services to the container.
builder.Services.AddControllersWithViews();

var app = builder.Build();

app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

try 
{
    app.Run();
}
catch (Exception e)
{
    app.Logger.LogCritical(e, "Unhandled exception");
}