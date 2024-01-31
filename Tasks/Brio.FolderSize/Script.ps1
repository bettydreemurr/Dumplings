$ProjectName = 'foldersize'

$Object1 = Invoke-RestMethod -Uri "https://sourceforge.net/projects/${ProjectName}/rss?path=/foldersize"

# Version
$this.CurrentState.Version = [regex]::Match(
  ($Object1.title.'#cdata-section' -match '^/foldersize/[\d\.]+/FolderSize-.+\.msi$')[0],
  '^/foldersize/([\d\.]+)/'
).Groups[1].Value

$Assets = $Object1.Where({ $_.title.'#cdata-section' -match "^/foldersize/$([regex]::Escape($this.CurrentState.Version))/FolderSize-.+\.msi$" })

# Installer
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'x86'
  InstallerUrl = $Assets.Where({ $_.title.'#cdata-section'.EndsWith('.msi') -and $_.title.'#cdata-section'.Contains('x86') })[0].link | ConvertTo-UnescapedUri
}
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'x64'
  InstallerUrl = $Assets.Where({ $_.title.'#cdata-section'.EndsWith('.msi') -and $_.title.'#cdata-section'.Contains('x64') })[0].link | ConvertTo-UnescapedUri
}

# ReleaseTime
$this.CurrentState.ReleaseTime = [datetime]::ParseExact(
  $Assets.Where({ $_.title.'#cdata-section'.EndsWith('.msi') -and $_.title.'#cdata-section'.Contains('x64') })[0].pubDate,
  'ddd, dd MMM yyyy HH:mm:ss "UT"',
  (Get-Culture -Name 'en-US')
) | ConvertTo-UtcDateTime -Id 'UTC'

switch ($this.Check()) {
  ({ $_ -ge 1 }) {
    try {
      $Object2 = Invoke-WebRequest -Uri 'https://foldersize.sourceforge.net/changelog.html' | ConvertFrom-Html

      $ReleaseNotesTitleNode = $Object2.SelectSingleNode("/html/body/h3[text()='Version $($this.CurrentState.Version)']")
      if ($ReleaseNotesTitleNode) {
        $ReleaseNotesNodes = [System.Collections.Generic.List[System.Object]]::new()
        for ($Node = $ReleaseNotesTitleNode.NextSibling; $Node -and $Node.Name -ne 'h3'; $Node = $Node.NextSibling) {
          $ReleaseNotesNodes.Add($Node)
        }
        # ReleaseNotes (en-US)
        $this.CurrentState.Locale += [ordered]@{
          Locale = 'en-US'
          Key    = 'ReleaseNotes'
          Value  = $ReleaseNotesNodes | Get-TextContent | Format-Text
        }
      } else {
        $this.Logging("No ReleaseNotes (en-US) for version $($this.CurrentState.Version)", 'Warning')
      }
    } catch {
      $_ | Out-Host
      $this.Logging($_, 'Warning')
    }

    $this.Write()
  }
  ({ $_ -ge 2 }) {
    $this.Message()
  }
  ({ $_ -ge 3 }) {
    $this.Submit()
  }
}
