$RepoOwner = 'cinnyapp'
$RepoName = 'cinny-desktop'

$Object1 = Invoke-GitHubApi -Uri "https://api.github.com/repos/${RepoOwner}/${RepoName}/releases/latest"

# Initialisation des installateurs
$this.CurrentState.Installer = @(
    [ordered]@{
        Architecture = 'x64'
        InstallerUrl = $Object1.assets.Where({ $_.name.EndsWith('.exe') -and !($_.name.Contains('arm64')) }, 'First')[0].browser_download_url | ConvertTo-UnescapedUri
    },
    [ordered]@{
        Architecture = 'arm64'
        InstallerUrl = $Object1.assets.Where({ $_.name.EndsWith('.exe') -and $_.name.Contains('arm64') }, 'First')[0].browser_download_url | ConvertTo-UnescapedUri
    }
)

function DownloadVerifyAndClean-Installers {
    # Préparer les chemins locaux pour chaque fichier
    $localPaths = @{}
    foreach ($installer in $this.CurrentState.Installer) {
        $architecture = $installer.Architecture
        $url = $installer.InstallerUrl

        # Définir un chemin unique pour chaque fichier
        $localPath = "$PSScriptRoot\dragonsetup_$architecture.exe"
        $localPaths[$architecture] = $localPath

        # Télécharger le fichier
        Write-Host "Téléchargement du fichier pour $architecture depuis $url..."
        Invoke-WebRequest -Uri $url -OutFile $localPath
    }

    # Obtenir les versions des exécutables
    $x64Version = (Get-Item $localPaths['x64']).VersionInfo.ProductVersion
    $arm64Version = (Get-Item $localPaths['arm64']).VersionInfo.ProductVersion

    # Vérifier si les versions sont identiques
    if ($x64Version -ne $arm64Version) {
        # Nettoyer les fichiers avant de lancer une exception
        Remove-Item $localPaths['x64'], $localPaths['arm64'] -ErrorAction SilentlyContinue
        throw "Les versions des installateurs ne correspondent pas : x64 = $x64Version, arm64 = $arm64Version"
    }

    # Mettre à jour la version dans CurrentState
    $this.CurrentState.Version = $x64Version.Split('+')[0]

    # Nettoyer les fichiers après la vérification
    Write-Host "Suppression des fichiers téléchargés..."
    Remove-Item $localPaths['x64'], $localPaths['arm64'] -ErrorAction SilentlyContinue

    Write-Host "Téléchargements vérifiés et fichiers nettoyés."
}

switch -Regex ($this.Check()) {
  'New|Changed|Updated' {
    try {
      DownloadVerifyAndClean-Installers
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
