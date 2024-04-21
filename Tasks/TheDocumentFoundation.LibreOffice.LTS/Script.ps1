# Version
$Object1 = Invoke-WebRequest -Uri 'https://www.libreoffice.org/download/download-libreoffice/' | ConvertFrom-Html
$ShortVersion = $Object1.SelectNodes('//span[@class="dl_version_number"]').InnerText | Sort-Object -Property { $_ -replace '\d+', { $_.Value.PadLeft(20) } } -Top 1

$Object2 = Invoke-WebRequest -Uri 'https://downloadarchive.documentfoundation.org/libreoffice/old/?C=N;O=D;V=1;F=0'
$this.CurrentState.Version = ($Object2.Links.href -match "^$([regex]::Escape($ShortVersion))[\d\.]+/$")[0].TrimEnd('/')

# Installer
$Prefix = 'https://downloadarchive.documentfoundation.org/libreoffice/old/'
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'x86'
  InstallerUrl = "${Prefix}$($this.CurrentState.Version)/win/x86/LibreOffice_$($this.CurrentState.Version)_Win_x86.msi"
}
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'x64'
  InstallerUrl = "${Prefix}$($this.CurrentState.Version)/win/x86_64/LibreOffice_$($this.CurrentState.Version)_Win_x86-64.msi"
}
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'arm64'
  InstallerUrl = "${Prefix}$($this.CurrentState.Version)/win/aarch64/LibreOffice_$($this.CurrentState.Version)_Win_aarch64.msi"
}

switch -Regex ($this.Check()) {
  'New|Changed|Updated' {
    try {
      $this.CurrentState.Locale += [ordered]@{
        Key   = 'ReleaseNotesUrl'
        Value = Get-RedirectedUrl -Uri "https://hub.libreoffice.org/ReleaseNotes/?LOvers=$($this.CurrentState.Version.Split('.')[0..1] -join '.')&LOlocale=en-US"
      }
    } catch {
      $_ | Out-Host
      $this.Log($_, 'Warning')
      # ReleaseNotesUrl
      $this.CurrentState.Locale += [ordered]@{
        Key   = 'ReleaseNotesUrl'
        Value = 'https://wiki.documentfoundation.org/ReleaseNotes'
      }
    }

    try {
      $this.CurrentState.Locale += [ordered]@{
        Locale = 'zh-CN'
        Key    = 'ReleaseNotesUrl'
        Value  = Get-RedirectedUrl -Uri "https://hub.libreoffice.org/ReleaseNotes/?LOvers=$($this.CurrentState.Version.Split('.')[0..1] -join '.')&LOlocale=zh-CN"
      }
    } catch {
      $_ | Out-Host
      $this.Log($_, 'Warning')
      # ReleaseNotesUrl
      $this.CurrentState.Locale += [ordered]@{
        Locale = 'zh-CN'
        Key    = 'ReleaseNotesUrl'
        Value  = 'https://wiki.documentfoundation.org/ReleaseNotes'
      }
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
