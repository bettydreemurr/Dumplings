$Object1 = Invoke-RestMethod -Uri 'https://windbg.download.prss.microsoft.com/dbazure/prod/1-0-0/windbg.appinstaller'

# Version
$this.CurrentState.Version = $Object1.AppInstaller.MainBundle.Version

# Installer
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'x86'
  InstallerUrl = $Object1.AppInstaller.MainBundle.Uri
}
# Installer
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'x64'
  InstallerUrl = $Object1.AppInstaller.MainBundle.Uri
}
# Installer
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'arm64'
  InstallerUrl = $Object1.AppInstaller.MainBundle.Uri
}

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
