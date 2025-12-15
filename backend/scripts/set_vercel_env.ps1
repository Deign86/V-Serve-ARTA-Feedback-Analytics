<#
Sets multiple environment variables for a Vercel project using the Vercel REST API.

Prerequisites:
- You must have a Vercel personal token with `project` scope saved in the environment variable `VERCEL_TOKEN`.
- You must know the Vercel project ID and set it in `VERCEL_PROJECT_ID` env var.

Usage (PowerShell):
  $env:VERCEL_TOKEN = '<your-token>'
  $env:VERCEL_PROJECT_ID = '<your-project-id>'
  Set-Location -Path ..\..\backend
  .\scripts\set_vercel_env.ps1 -PublicKey '<public>' -PrivateKey '<private>' -Subject 'mailto:you@domain.com' -AdminEmail 'admin@domain.com'

This will create environment variables in the project for `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `WEB_PUSH_SUBJECT`, `ADMIN_EMAIL` for all targets.
#>

param(
  [Parameter(Mandatory = $true)] [string] $PublicKey,
  [Parameter(Mandatory = $true)] [string] $PrivateKey,
  [Parameter(Mandatory = $true)] [string] $Subject,
  [Parameter(Mandatory = $true)] [string] $AdminEmail
)

if (-not $env:VERCEL_TOKEN) {
  Write-Error "VERCEL_TOKEN environment variable is required (create a personal token in Vercel)"> $null
  exit 1
}
if (-not $env:VERCEL_PROJECT_ID) {
  Write-Error "VERCEL_PROJECT_ID environment variable is required (project ID from Vercel dashboard)"> $null
  exit 1
}

$token = $env:VERCEL_TOKEN
$projectId = $env:VERCEL_PROJECT_ID

function Add-VercelEnv($key, $value) {
  $body = @{ key = $key; value = $value; target = @('preview','production','development'); type = 'encrypted' } | ConvertTo-Json
  $url = "https://api.vercel.com/v9/projects/$projectId/env"
  try {
    $resp = Invoke-RestMethod -Method Post -Uri $url -Headers @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' } -Body $body
    Write-Host "Created env $key"
  } catch {
    Write-Warning "Failed to create $key: $($_.Exception.Message)"
  }
}

Add-VercelEnv -key 'VAPID_PUBLIC_KEY' -value $PublicKey
Add-VercelEnv -key 'VAPID_PRIVATE_KEY' -value $PrivateKey
Add-VercelEnv -key 'WEB_PUSH_SUBJECT' -value $Subject
Add-VercelEnv -key 'ADMIN_EMAIL' -value $AdminEmail

Write-Host "Done. Trigger a redeploy from Vercel dashboard or run 'vercel --prod' to pick up new vars." 
