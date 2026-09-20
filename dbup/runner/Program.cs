using System;
using System.IO;
using System.Linq;
using DbUp;
using DbUp.Engine;

// ── Read connection string and migrations path from args or env ──
var connectionString = args.Length > 0
    ? args[0]
    : Environment.GetEnvironmentVariable("DBUP_CONNECTION_STRING")
      ?? "Server=localhost,1433;Database=TestDB;User Id=sa;Password=YourStrong!Passw0rd;TrustServerCertificate=True;";

var scriptsPath = args.Length > 1
    ? args[1]
    : Environment.GetEnvironmentVariable("DBUP_SCRIPTS_PATH")
      ?? Path.Combine(Directory.GetCurrentDirectory(), "..", "migrations");

// Resolve to absolute path
scriptsPath = Path.GetFullPath(scriptsPath);

Console.WriteLine("╔══════════════════════════════════════════════╗");
Console.WriteLine("║         DbUp Migration Runner               ║");
Console.WriteLine("╠══════════════════════════════════════════════╣");
Console.WriteLine($"║  Scripts: {scriptsPath}");
Console.WriteLine($"║  Server:  {connectionString.Split(';').FirstOrDefault()}");
Console.WriteLine("╚══════════════════════════════════════════════╝");
Console.WriteLine();

// ── Verify scripts directory exists ──
if (!Directory.Exists(scriptsPath))
{
    Console.WriteLine($"❌ Scripts directory not found: {scriptsPath}");
    Environment.Exit(1);
}

// ── List discovered scripts ──
var sqlFiles = Directory.GetFiles(scriptsPath, "*.sql").OrderBy(f => f).ToArray();
Console.WriteLine($"📁 Found {sqlFiles.Length} migration scripts:");
foreach (var file in sqlFiles)
{
    Console.WriteLine($"   → {Path.GetFileName(file)}");
}
Console.WriteLine();

// ── Ensure database exists ──
EnsureDatabase.For.SqlDatabase(connectionString);
Console.WriteLine("✅ Database exists (or was created)");

// ── Build and run the upgrader ──
var upgrader = DeployChanges.To
    .SqlDatabase(connectionString)
    .WithScriptsFromFileSystem(scriptsPath, new DbUp.ScriptProviders.FileSystemScriptOptions
    {
        IncludeSubDirectories = false,
        Extensions = new[] { ".sql" }
    })
    .WithTransactionPerScript()       // Each script in its own transaction
    .LogToConsole()
    .Build();

// ── Check which scripts are pending ──
var pending = upgrader.GetScriptsToExecute();
Console.WriteLine($"\n📋 Pending migrations: {pending.Count}");
foreach (var script in pending)
{
    Console.WriteLine($"   🔶 {script.Name}");
}

if (pending.Count == 0)
{
    Console.WriteLine("\n✅ Database is up to date — no new migrations to run.");
    Environment.Exit(0);
}

// ── Execute pending migrations ──
Console.WriteLine("\n🚀 Running migrations...\n");
var result = upgrader.PerformUpgrade();

if (!result.Successful)
{
    Console.ForegroundColor = ConsoleColor.Red;
    Console.WriteLine("╔══════════════════════════════════════════════╗");
    Console.WriteLine("║  ❌ MIGRATION FAILED                        ║");
    Console.WriteLine("╚══════════════════════════════════════════════╝");
    Console.WriteLine(result.Error);
    Console.ResetColor();
    Environment.Exit(1);
}

Console.ForegroundColor = ConsoleColor.Green;
Console.WriteLine("╔══════════════════════════════════════════════╗");
Console.WriteLine("║  ✅ ALL MIGRATIONS COMPLETED SUCCESSFULLY   ║");
Console.WriteLine("╚══════════════════════════════════════════════╝");
Console.ResetColor();

// ── Show executed scripts ──
Console.WriteLine($"\n📊 Executed {pending.Count} migration(s):");
foreach (var script in pending)
{
    Console.WriteLine($"   ✅ {script.Name}");
}

Environment.Exit(0);
