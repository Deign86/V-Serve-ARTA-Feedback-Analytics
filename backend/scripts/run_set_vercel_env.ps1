param(
  [Parameter(Mandatory=$true)][string] $Token,
  [Parameter(Mandatory=$true)][string] $ProjectId,
  [Parameter(Mandatory=$true)][string] $PublicKey,
  [Parameter(Mandatory=$true)][string] $PrivateKey,
  [Parameter(Mandatory=$true)][string] $Subject,
  [Parameter(Mandatory=$true)][string] $AdminEmail
)

$env:VERCEL_TOKEN = $Token
$env:VERCEL_PROJECT_ID = $ProjectId

Set-Location -Path (Split-Path -Path $MyInvocation.MyCommand.Path -Parent)
Set-Location -Path '..'  # backend root

.\scripts\set_vercel_env.ps1 -PublicKey $PublicKey -PrivateKey $PrivateKey -Subject $Subject -AdminEmail $AdminEmail
