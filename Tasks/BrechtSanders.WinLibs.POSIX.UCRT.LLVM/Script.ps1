$RepoOwner = 'brechtsanders'
$RepoName = 'winlibs_mingw'

$Object1 = (Invoke-GitHubApi -Uri "https://api.github.com/repos/${RepoOwner}/${RepoName}/releases").Where({ -not $_.prerelease -and $_.tag_name.Contains('posix') -and $_.tag_name.Contains('ucrt') }, 'First')[0]

$VersionMatches = [regex]::Match($Object1.tag_name, '(?<gcc>\d+(?:\.\d+)+)posix(?:-(?<llvm>\d+(?:\.\d+)+))?-(?<mingw>\d+(?:\.\d+)+)-ucrt-r(?<release>\d+)')
if (-not $VersionMatches.Groups['llvm'].Success) {
  throw "The build $($Object1.tag_name) does not contain LLVM"
}

# Version
$this.CurrentState.Version = "$($VersionMatches.Groups['gcc'].Value)-$($VersionMatches.Groups['llvm'].Value)-$($VersionMatches.Groups['mingw'].Value)-r$($VersionMatches.Groups['release'].Value)"

# Installer
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'x86'
  InstallerUrl = $Object1.assets.Where({ $_.name.EndsWith('.zip') -and $_.name.Contains('llvm') -and $_.name.Contains('i686') }, 'First')[0].browser_download_url | ConvertTo-UnescapedUri
}
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'x64'
  InstallerUrl = $Object1.assets.Where({ $_.name.EndsWith('.zip') -and $_.name.Contains('llvm') -and $_.name.Contains('x86_64') }, 'First')[0].browser_download_url | ConvertTo-UnescapedUri
}

switch -Regex ($this.Check()) {
  'New|Changed|Updated' {
    try {
      # ReleaseTime
      $this.CurrentState.ReleaseTime = $Object1.published_at.ToUniversalTime()

      if (-not [string]::IsNullOrWhiteSpace($Object1.body)) {
        # ReleaseNotes (en-US)
        $this.CurrentState.Locale += [ordered]@{
          Locale = 'en-US'
          Key    = 'ReleaseNotes'
          Value  = ($Object1.body | ConvertFrom-Markdown).Html | ConvertFrom-Html | Get-TextContent | Format-Text
        }
      } else {
        $this.Log("No ReleaseNotes (en-US) for version $($this.CurrentState.Version)", 'Warning')
      }

      # ReleaseNotesUrl
      $this.CurrentState.Locale += [ordered]@{
        Key   = 'ReleaseNotesUrl'
        Value = $Object1.html_url
      }
    } catch {
      $_ | Out-Host
      $this.Log($_, 'Warning')
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
