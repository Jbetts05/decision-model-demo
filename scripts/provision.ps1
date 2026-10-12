param(
    [string]$Subscription = '556dc8cb-5da1-41d7-8a10-1be2cd6de16e',
    [string]$ResourceGroup = 'rg-receipt-benchmark',
    [string]$Name = 'decision-model-demo',
    [string]$Location = 'westeurope',
    [string]$Repository = 'Jbetts05/decision-model-demo',
    [string]$AllowedGitHubUsers = 'Jbetts05'
)

$ErrorActionPreference = 'Stop'
$env:AZURE_EXTENSION_USE_DYNAMIC_INSTALL = 'no'

$existing = az staticwebapp list --subscription $Subscription `
    --resource-group $ResourceGroup --query "[?name=='$Name'].name" -o tsv
if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect Static Web Apps.' }

if (-not $existing) {
    $template = Join-Path $PSScriptRoot '..\infra\main.bicep'
    az deployment group create --subscription $Subscription --resource-group $ResourceGroup `
        --name 'decision-demo' --template-file $template `
        --parameters "name=$Name" "location=$Location" --mode Incremental --output none
    if ($LASTEXITCODE -ne 0) { throw 'Static Web App creation failed.' }
}

$foundryKey = az cognitiveservices account keys list --subscription $Subscription `
    --resource-group rg-receipt-benchmark --name aireceiptbench556dc8 `
    --query key1 --output tsv
if ($LASTEXITCODE -ne 0 -or -not $foundryKey) { throw 'Unable to retrieve existing Foundry credential.' }

try {
    az staticwebapp appsettings set --subscription $Subscription --resource-group $ResourceGroup `
        --name $Name --setting-names `
        "FOUNDRY_ENDPOINT=https://aireceiptbench556dc8.services.ai.azure.com" `
        "FOUNDRY_API_KEY=$foundryKey" `
        "ALLOWED_GITHUB_USERS=$AllowedGitHubUsers" --output none
    if ($LASTEXITCODE -ne 0) { throw 'Unable to configure API application settings.' }
} finally {
    $foundryKey = $null
}

$deploymentToken = az staticwebapp secrets list --subscription $Subscription `
    --resource-group $ResourceGroup --name $Name --query properties.apiKey --output tsv
if ($LASTEXITCODE -ne 0 -or -not $deploymentToken) { throw 'Unable to retrieve deployment token.' }
try {
    $deploymentToken | gh secret set AZURE_STATIC_WEB_APPS_API_TOKEN --repo $Repository
    if ($LASTEXITCODE -ne 0) { throw 'Unable to store GitHub Actions deployment secret.' }
} finally {
    $deploymentToken = $null
}

az staticwebapp show --subscription $Subscription --resource-group $ResourceGroup `
    --name $Name --query '{hostname:defaultHostname,state:provisioningState}' --output json
if ($LASTEXITCODE -ne 0) { throw 'Unable to read provisioned app.' }
