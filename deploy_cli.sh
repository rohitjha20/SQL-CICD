#!/usr/bin/env bash
# ==============================================================================
# 100% CLI-Driven Azure SQL Deployment (No Extension / GUI Required)
# ==============================================================================
set -e

echo "=== Step 1: Ensure Microsoft.Build.Sql Template is Installed ==="
dotnet new install Microsoft.Build.Sql.Templates --force > /dev/null 2>&1 || true

echo "=== Step 2: Generate .sqlproj via dotnet CLI ==="
cat << 'EOF' > cicd.sqlproj
<?xml version="1.0" encoding="utf-8"?>
<Project DefaultTargets="Build">
  <Sdk Name="Microsoft.Build.Sql" Version="2.2.0" />
  <PropertyGroup>
    <Name>cicd</Name>
    <DSP>Microsoft.Data.Tools.Schema.Sql.SqlAzureV12DatabaseSchemaProvider</DSP>
    <ModelCollation>1033, CI</ModelCollation>
    <TargetFramework>netstandard2.1</TargetFramework>
    <SqlServerVersion>SqlAzureV12</SqlServerVersion>
  </PropertyGroup>
  <ItemGroup>
    <Build Remove=".github/**/*.sql" />
    <Build Remove="cicd/**/*.sql" />
    <Build Remove="PostDeployment/**/*.sql" />
    <Build Remove="cleanup_appdb.sql" />
    <Build Remove="tests/**/*.sql" />
    <PostDeploy Include="PostDeployment/PostDeployment.sql" />
  </ItemGroup>
  <Target Name="BeforeBuild">
    <Delete Files="$(BaseIntermediateOutputPath)/project.assets.json" />
  </Target>
</Project>
EOF

echo "=== Step 3: Compile SQL Project into DACPAC ==="
dotnet build cicd.sqlproj --configuration Release

echo "=== Step 4: Verify DACPAC Artifact ==="
ls -la bin/Release/cicd.dacpac

echo "=== Step 5: Publish DACPAC to Azure SQL Database ==="
if [ -z "$SQL_CONNECTION_STRING" ]; then
  echo ""
  echo "⚠️  SQL_CONNECTION_STRING is not set in your environment."
  echo "To publish, run:"
  echo 'export SQL_CONNECTION_STRING="Server=tcp:freetier-sqlserver-central.database.windows.net,1433;Initial Catalog=appdb;Persist Security Info=False;User ID=<USER>;Password=<PASS>;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"'
  echo './deploy_cli.sh'
  exit 0
fi

sqlpackage \
  /Action:Publish \
  /SourceFile:"./bin/Release/cicd.dacpac" \
  /TargetConnectionString:"$SQL_CONNECTION_STRING" \
  /p:BlockOnPossibleDataLoss=False \
  /p:GenerateSmartDefaults=True

echo "✅ Successfully deployed all database components to Azure SQL!"
