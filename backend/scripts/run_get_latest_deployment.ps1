param(
  [Parameter(Mandatory=$true)][string] $Token,
  [Parameter(Mandatory=$true)][string] $ProjectId
)

$env:VERCEL_TOKEN = $Token
Set-Location -Path (Split-Path -Path $MyInvocation.MyCommand.Path -Parent)
Set-Location -Path '..'  # backend root
node .\scripts\get_latest_deployment.js $ProjectId
