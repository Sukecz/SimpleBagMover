$ErrorActionPreference = 'Stop'
$target = 'C:\Games\World of Warcraft\_classic_beta_\Interface\AddOns'
$stage = Join-Path ([IO.Path]::GetTempPath()) ('simplebagmover-' + [guid]::NewGuid().ToString('N'))
try {
    if (-not (Test-Path -LiteralPath $target -PathType Container)) {
        throw "Forever AddOns folder not found: $target"
    }
    New-Item -ItemType Directory -Path $stage | Out-Null
    & tar.exe -xzf (Join-Path $PSScriptRoot 'SimpleBagMover.tar.gz') -C $stage
    if ($LASTEXITCODE -ne 0) { throw 'Archive extraction failed.' }
    $source = Join-Path $stage 'SimpleBagMover'
    $files = @('Core.lua', 'SimpleBagMover_Camelot.toc', 'assets\addon-icon.tga')
    foreach ($file in $files) {
        if (-not (Test-Path -LiteralPath (Join-Path $source $file) -PathType Leaf)) { throw "Missing runtime file: $file" }
    }
    $destination = Join-Path $target 'SimpleBagMover'
    & robocopy.exe $source $destination /E /R:2 /W:1 /NFL /NDL /NJH /NJS /NP
    if ($LASTEXITCODE -ge 8) { throw 'Simple Bag Mover copy failed.' }
    foreach ($file in $files) {
        $expected = (Get-FileHash -LiteralPath (Join-Path $source $file) -Algorithm SHA256).Hash
        $actual = (Get-FileHash -LiteralPath (Join-Path $destination $file) -Algorithm SHA256).Hash
        if ($expected -ne $actual) { throw "Deployed file hash mismatch: $file" }
    }
    $oldDestination = Join-Path $target 'MoveBags'
    if (Test-Path -LiteralPath $oldDestination -PathType Container) {
        Remove-Item -LiteralPath $oldDestination -Recurse -Force
    }
    Write-Host 'Simple Bag Mover deployed to Forever; runtime hashes verified. The old MoveBags folder was removed if present.'
}
catch { Write-Error $_; exit 1 }
finally { if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force } }
exit 0
