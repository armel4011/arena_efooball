# Crée arena-site.zip avec des chemins en SLASH (/) conformes au spec ZIP,
# pour une extraction correcte sur cPanel/Linux. Exclut downloads/ (APK lourds)
# et les artefacts. À lancer depuis le dossier landing-src/.
#   powershell -ExecutionPolicy Bypass -File build-zip.ps1
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$zip  = Join-Path $root 'arena-site.zip'
if (Test-Path $zip) { Remove-Item $zip -Force }

$exclude = @('downloads', 'arena-site.zip', '.git')
$excludeFiles = @('README.md', 'build-zip.ps1', '.gitignore')  # fichiers de repo, pas de site
$files = Get-ChildItem -Path $root -Recurse -File -Force | Where-Object {
  $rel = $_.FullName.Substring($root.Length + 1)
  $top = $rel.Split([IO.Path]::DirectorySeparatorChar)[0]
  ($exclude -notcontains $top) -and ($excludeFiles -notcontains $_.Name) -and ($_.Name -notlike '*.apk')
}

$fs = [IO.File]::Open($zip, [IO.FileMode]::Create)
$archive = New-Object IO.Compression.ZipArchive($fs, [IO.Compression.ZipArchiveMode]::Create)
foreach ($f in $files) {
  $name = $f.FullName.Substring($root.Length + 1).Replace('\', '/')  # slashes !
  $entry = $archive.CreateEntry($name, [IO.Compression.CompressionLevel]::Optimal)
  $es = $entry.Open(); $bytes = [IO.File]::ReadAllBytes($f.FullName)
  $es.Write($bytes, 0, $bytes.Length); $es.Close()
}
$archive.Dispose(); $fs.Close()
'{0} fichiers — {1:N2} MB' -f $files.Count, ((Get-Item $zip).Length / 1MB)
