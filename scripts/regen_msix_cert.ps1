# Régénère le certificat de signature MSIX auto-signé d'ARENA Admin Desktop.
#
# Génère un nouveau certificat code-signing (sujet = Publisher du pubspec),
# un NOUVEAU mot de passe aléatoire, exporte le .pfx (clé privée) + le .cer
# (public, à distribuer) et met à jour INFOS.txt. Aucun secret n'est écrit
# dans un fichier versionné : tout le dossier windows/certificates/ est
# gitignoré.
#
# Usage :
#   .\scripts\regen_msix_cert.ps1                 # mot de passe auto-généré
#   .\scripts\regen_msix_cert.ps1 -Password "..." # mot de passe imposé
#   .\scripts\regen_msix_cert.ps1 -Years 5
#
# IMPORTANT — le sujet DOIT rester identique au champ `publisher:` du
# msix_config (pubspec.yaml), sinon la signature est rejetée. Changer le
# sujet casse aussi la chaîne de mise à jour MSIX (nouvelle identité
# d'éditeur → les postes doivent réinstaller, pas mettre à jour).

param(
    [string]$Subject = 'CN=Arena Admin',
    [int]$Years = 5,
    [string]$Password,
    [string]$OutDir = (Join-Path (Split-Path $PSScriptRoot -Parent) 'windows\certificates')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

# Mot de passe : aléatoire fort si non fourni (24 alphanum + complexité).
if ([string]::IsNullOrWhiteSpace($Password)) {
    $alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789'
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $bytes = New-Object byte[] 24
    $rng.GetBytes($bytes)
    $sb = New-Object System.Text.StringBuilder
    foreach ($b in $bytes) { [void]$sb.Append($alphabet[$b % $alphabet.Length]) }
    # Garantit majuscule + minuscule + chiffre + symbole.
    $Password = 'Arn-' + $sb.ToString() + '-9X!'
}

$pfxPath  = Join-Path $OutDir 'arena_admin.pfx'
$cerPath  = Join-Path $OutDir 'arena_admin.cer'
$infoPath = Join-Path $OutDir 'INFOS.txt'

# Sauvegarde horodatée de l'ancien matériel (l'ancien étant compromis, on
# le garde juste le temps de valider le nouveau, puis à supprimer du coffre).
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
foreach ($p in @($pfxPath, $cerPath, $infoPath)) {
    if (Test-Path $p) { Copy-Item $p "$p.$stamp.bak" -Force }
}

Write-Host "Génération du certificat (sujet=$Subject, validité=$Years ans)..."
$cert = New-SelfSignedCertificate `
    -Type CodeSigningCert `
    -Subject $Subject `
    -KeyUsage DigitalSignature `
    -KeyAlgorithm RSA -KeyLength 2048 `
    -FriendlyName 'ARENA Admin Desktop Signing' `
    -CertStoreLocation 'Cert:\CurrentUser\My' `
    -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3', '2.5.29.19={text}') `
    -NotAfter (Get-Date).AddYears($Years)

$securePwd = ConvertTo-SecureString -String $Password -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $securePwd | Out-Null
Export-Certificate   -Cert $cert -FilePath $cerPath | Out-Null

$notAfter = $cert.NotAfter.ToString('yyyy-MM-dd')
@"
Certificat de signature ARENA Admin Desktop (auto-signé)
==========================================================
Fichiers :
  - arena_admin.pfx : certificat + clé privée (pour SIGNER le .msix)
  - arena_admin.cer : certificat public (à INSTALLER sur les autres postes)

Sujet (= publisher du pubspec) : $Subject
Empreinte (thumbprint)         : $($cert.Thumbprint)
Généré le                      : $(Get-Date -Format 'yyyy-MM-dd')
Expire le                      : $notAfter

Mot de passe du .pfx : $Password

Build : le mot de passe N'EST PAS dans le pubspec. Le passer au build :
  `$env:ARENA_MSIX_CERT_PASSWORD = '<le mot de passe ci-dessus>'
  dart run msix:create --password `$env:ARENA_MSIX_CERT_PASSWORD

⚠️ SAUVEGARDER ce dossier avec le keystore Android (même criticité :
sans le .pfx, impossible de signer les mises à jour de l'app desktop
avec la même identité).

Régénération : .\scripts\regen_msix_cert.ps1
"@ | Set-Content -Path $infoPath -Encoding UTF8

Write-Host ''
Write-Host 'Certificat régénéré avec succès.'
Write-Host "  Thumbprint : $($cert.Thumbprint)"
Write-Host "  Expire le  : $notAfter"
Write-Host "  PFX        : $pfxPath"
Write-Host "  CER        : $cerPath"
Write-Host "  Mot de passe écrit dans : $infoPath (gitignoré)"
Write-Host ''
Write-Host 'Sauvegardes de l ancien materiel : *.bak (a supprimer du coffre une fois le nouveau valide).'
