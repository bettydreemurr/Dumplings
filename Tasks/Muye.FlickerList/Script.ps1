$Object1 = Invoke-RestMethod -Uri "https://static.flicker.cool/flicker/download/release/win32/latest.yml?noCache=$(Get-Random)" | ConvertFrom-Yaml

# Version
$this.CurrentState.Version = $Object1.version

# Installer
$this.CurrentState.Installer += [ordered]@{
  InstallerUrl = "https://static.flicker.cool/flicker/download/stable/$($this.CurrentState.Version)/win32/$($Object1.files[0].url)"
}

# ReleaseTime
$this.CurrentState.ReleaseTime = $Object1.releaseDate | Get-Date -AsUTC

switch -Regex ($this.Check()) {
  'New|Changed|Updated' {
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
