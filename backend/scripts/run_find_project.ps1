param(
  [Parameter(Mandatory=$true)][string] $Token
)

$env:VERCEL_TOKEN = $Token
Set-Location -Path (Split-Path -Path $MyInvocation.MyCommand.Path -Parent)
Set-Location -Path '..'  # go to backend root
node .\scripts\find_vercel_project.js
