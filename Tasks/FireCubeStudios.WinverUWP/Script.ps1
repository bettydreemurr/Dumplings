$RepoOwner = 'dongle-the-gadget'
$RepoName = 'WinverUWP'

# Récupérer les informations de la dernière version
$Object1 = Invoke-GitHubApi -Uri "https://api.github.com/repos/${RepoOwner}/${RepoName}/releases/latest"

# Installer
foreach ($arch in @('x86', 'x64', 'arm64')) {
    $AppxBundle = $Object1.assets | Where-Object { $_.name -like '*.AppxBundle' } | Select-Object -First 1
    if ($null -eq $AppxBundle) {
        Write-Error "No .AppxBundle files found for $arch in the assets for $RepoName."
        return
    }

    $InstallerUrl = $AppxBundle.browser_download_url | ConvertTo-UnescapedUri

    $this.CurrentState.Installer += [ordered]@{
        Architecture = $arch
        InstallerUrl = $InstallerUrl
    }
}

# Version
$this.CurrentState.Version = [regex]::Match($InstallerUrl, '_(\d+\.\d+\.\d+\.\d+)_').Groups[1].Value

# ReleaseTime
$this.CurrentState.ReleaseTime = $Object1.published_at.ToUniversalTime()

# Notes de version
if (-not [string]::IsNullOrWhiteSpace($Object1.body)) {
    $this.CurrentState.Locale += [ordered]@{
        Locale = 'en-US'
        Key    = 'ReleaseNotes'
        Value  = ($Object1.body | ConvertFrom-Markdown).Html | ConvertFrom-Html | Get-TextContent | Format-Text
    }
} else {
    $this.Log("No ReleaseNotes (en-US) for version $($this.CurrentState.Version)", 'Warning')
}

# URL des notes de version
$this.CurrentState.Locale += [ordered]@{
    Key   = 'ReleaseNotesUrl'
    Value = $Object1.html_url
}

# Gestion des états
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
