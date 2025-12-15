param(
  [Parameter(Mandatory=$true)][string] $Token,
  [Parameter(Mandatory=$true)][string] $ProjectId,
  [Parameter(Mandatory=$true)][string] $Key,
  [Parameter(Mandatory=$true)][string] $Value
)

$env:VERCEL_TOKEN = $Token
Set-Location -Path (Split-Path -Path $MyInvocation.MyCommand.Path -Parent)
Set-Location -Path '..'  # backend root
node .\scripts\add_vercel_env_var.js $ProjectId $Key $Value
