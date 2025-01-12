$Object1 = Invoke-WebRequest -Uri 'https://cevio.jp/guide/cevio_ai/'

# Installer
$this.CurrentState.Installer += [ordered]@{
  InstallerUrl = $InstallerUrl = $Object1.Links.Where({ try { $_.href.EndsWith('.msi') } catch {} }, 'First')[0].href
}

# Version
$versionFull = [regex]::Match($InstallerUrl, '\((\d+\.\d+\.\d+\.\d+)\)').Groups[1].Value
$this.CurrentState.Version = $versionFull -replace '\.0$', ''

switch -Regex ($this.Check()) {
  'New|Changed|Updated' {
    $Object2 = Invoke-RestMethod -Uri "${InstallerUrl}.sha256"

    # InstallerSha256
    $this.CurrentState.Installer[0]['InstallerSha256'] = $Object2.Split()[0].ToUpper()

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