Param(
  [Parameter(Mandatory=$true)][string]$ProjectRef,
  [Parameter(Mandatory=$true)][string]$Pat,
  [Parameter(ParameterSetName='Inline', Mandatory=$false)][string]$Query,
  [Parameter(ParameterSetName='File', Mandatory=$false)][string]$File
)

if ($PSCmdlet.ParameterSetName -eq 'File') {
  if (-not (Test-Path $File)) { throw "SQL file not found: $File" }
  $Query = Get-Content -Raw -Path $File
}

if (-not $Query) { throw "Provide -Query or -File" }

$url = "https://api.supabase.com/v1/projects/$ProjectRef/database/query"
$headers = @{
  Authorization = "Bearer $Pat"
  apikey        = $Pat
  'Content-Type' = 'application/json'
}
$body = @{ query = $Query } | ConvertTo-Json -Depth 4

try {
  $res = Invoke-WebRequest -Uri $url -Method Post -Headers $headers -Body $body
  Write-Output ("Status: {0}" -f $res.StatusCode)
  if ($res.Content) { Write-Output $res.Content }
} catch {
  $resp = $_.Exception.Response
  if ($resp) {
    $status = $resp.StatusCode.value__
    $stream = $resp.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $errText = $reader.ReadToEnd()
    Write-Error "Status: $status`n$errText"
  } else {
    throw
  }
  exit 1
}
