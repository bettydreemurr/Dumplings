$RepoOwner = 'gottcode'
$RepoName = 'focuswriter'

$Object1 = Invoke-GitHubApi -Uri "https://api.github.com/repos/${RepoOwner}/${RepoName}/releases/latest"


# Fonction pour convertir une version au format X.X.X.X
function Convert-ToFourSegmentVersion {
    param (
        [string]$Version
    )
    # Séparer la version en segments
    $segments = $Version -split '\.'
    # Compléter avec des zéros pour atteindre 4 segments
    while ($segments.Count -lt 4) {
        $segments += '0'
    }
    # Rejoindre les segments avec des points
    return $segments -join '.'
}

# Version
$rawVersion = $Object1.tag_name -creplace '^v'
$this.CurrentState.Version = Convert-ToFourSegmentVersion $rawVersion


# Installer
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'x64'
  InstallerUrl = "https://cdn.files.community/files/stable/Files.Package_$($this.CurrentState.Version)_Stable_Test/Files.Package_$($this.CurrentState.Version)_x64_arm64_Stable.msixbundle"
}
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'x64'
  InstallerUrl = "https://cdn.files.community/files/stable/Files.Package_$($this.CurrentState.Version)_Stable_Test/Files.Package_$($this.CurrentState.Version)_x64_arm64_Stable.msixbundle"
}

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

switch -Regex ($this.Check()) {
  'New|Changed|Updated' {
    $this.Write()
  }
  'Changed|Updated' {
    $this.Print()
    $this.Message()
  }
  'Updated' {
    $this.Submit()
  }
}
