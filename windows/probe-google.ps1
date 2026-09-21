$ErrorActionPreference="Stop"
$headers=@{"User-Agent"="Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}

function Probe([string]$sl,[string]$tl,[string]$q){
  $encoded=[Uri]::EscapeDataString($q)
  $uri="https://clients5.google.com/translate_a/t?client=dict-chrome-ex&sl=$sl&tl=$tl&q=$encoded"
  Write-Host "URI: $uri"
  $r=Invoke-RestMethod -Uri $uri -Headers $headers -TimeoutSec 20
  Write-Host "TYPE: $($r.GetType().FullName)"
  $r | ConvertTo-Json -Depth 20
}

Write-Host "--- en -> ar ---"
Probe "en" "ar" "hello my friend"
Write-Host "--- ar -> en ---"
Probe "ar" "en" "مرحبا يا صديقي"
