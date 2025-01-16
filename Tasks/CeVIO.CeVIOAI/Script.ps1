$Object1 = Invoke-WebRequest -Uri 'https://cevio.jp/guide/cevio_ai/'

# Installer
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'x64'
  InstallerUrl = $InstallerUrl = $Object1.Links.Where({ try { $_.href.EndsWith('.msi') } catch {} }, 'First')[0].href
}

# Version
$versionFull = [regex]::Match($InstallerUrl, '\((\d+\.\d+\.\d+\.\d+)\)').Groups[1].Value
$this.CurrentState.Version = $versionFull -replace '\.0$', ''

switch -Regex ($this.Check()) {
  'New|Changed|Updated' {
    try {
        # Télécharger l'installateur MSI
        $installerPath = "$PSScriptRoot\installer.msi"
        Invoke-WebRequest -Uri $InstallerUrl -OutFile $installerPath

        # Calculer le hash SHA256
        $sha256Hash = Get-FileHash -Path $installerPath -Algorithm SHA256
        $this.CurrentState.Installer[0]['InstallerSha256'] = $sha256Hash.Hash.ToUpper()

        # Supprimer le fichier après usage
        Remove-Item -Path $installerPath -Force
    } catch {
        Write-Error "Erreur critique : Impossible de télécharger ou calculer le hash SHA256. Programme arrêté."
        throw
    }

    $this.Print()
    $this.Write()
  }
  'Changed|Updated' {
    $this.Message()
  }
  'Updated' {
    $this.Submit()
  }
}