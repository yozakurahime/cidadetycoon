param(
    [string]$Root = "E:\Cidade RO\Nova-Base-2026\txData\Qbox_1A04D8.base\resources\[standalone]\cidade_transport_tycoon_infinito"
)

$cityConfig = Join-Path $Root "config\city.lua"
$outDir = Join-Path $Root "ui\images\vehicles"
$mapFile = Join-Path $Root "ui\vehicle_images.json"

if (!(Test-Path -LiteralPath $cityConfig)) { throw "city.lua not found: $cityConfig" }
if (!(Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

$content = Get-Content -LiteralPath $cityConfig -Raw
$matches = [regex]::Matches($content, "model\s*=\s*'([^']+)'")
$models = @{}
foreach ($m in $matches) {
    $model = $m.Groups[1].Value.ToLower()
    if ($model -ne "") { $models[$model] = $true }
}

$modelList = $models.Keys | Sort-Object
$map = @{}
$downloaded = 0
$skipped = 0
$placeholders = 0

foreach ($model in $modelList) {
    $url = "https://docs.fivem.net/vehicles/$model.webp"
    $map[$model] = $url

    $webpPath = Join-Path $outDir "$model.webp"
    $svgPath = Join-Path $outDir "$model.svg"
    if (Test-Path $webpPath) { $skipped++; continue }

    try {
        Invoke-WebRequest -Uri $url -OutFile $webpPath -TimeoutSec 12 -ErrorAction Stop
        $size = (Get-Item $webpPath).Length
        if ($size -lt 200) {
            Remove-Item -LiteralPath $webpPath -Force -ErrorAction SilentlyContinue
            throw "Tiny file"
        }
        $downloaded++
    } catch {
        $safe = $model.ToUpper()
        $svg = @"
<svg xmlns="http://www.w3.org/2000/svg" width="420" height="220">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
      <stop stop-color="#25374f"/>
      <stop offset="1" stop-color="#132033"/>
    </linearGradient>
  </defs>
  <rect width="100%" height="100%" fill="url(#g)"/>
  <text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle"
        font-family="Segoe UI, Arial" font-size="26" fill="#d5e4f5">$safe</text>
</svg>
"@
        Set-Content -LiteralPath $svgPath -Value $svg -Encoding UTF8
        $placeholders++
    }
}

$json = $map | ConvertTo-Json -Depth 5
Set-Content -LiteralPath $mapFile -Value $json -Encoding UTF8

Write-Host "Models: $($modelList.Count)"
Write-Host "Downloaded webp: $downloaded"
Write-Host "Skipped existing: $skipped"
Write-Host "SVG placeholders: $placeholders"
Write-Host "Map updated: $mapFile"
