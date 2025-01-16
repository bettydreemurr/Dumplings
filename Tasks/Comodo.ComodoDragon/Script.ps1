# Initialisation des installateurs
$this.CurrentState.Installer = @(
    [ordered]@{
        Architecture = 'x86'
        InstallerUrl = "https://cdn.download.comodo.com/browser/release/dragon/x86/dragonsetup.exe"
    },
    [ordered]@{
        Architecture = 'x64'
        InstallerUrl = "https://cdn.download.comodo.com/browser/release/dragon/x64/dragonsetup.exe"
    }
)

# Fonction pour télécharger et vérifier les versions des fichiers d'installation
function DownloadAndVerify-Installers {
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
    $x86Version = (Get-Item $localPaths['x86']).VersionInfo.ProductVersion
    $x64Version = (Get-Item $localPaths['x64']).VersionInfo.ProductVersion

    # Vérifier si les versions sont identiques
    if ($x86Version -ne $x64Version) {
        throw "Les versions des installateurs ne correspondent pas : x86 = $x86Version, x64 = $x64Version"
    }

    # Mettre à jour la version dans CurrentState
    $this.CurrentState.Version = $x86Version

    # Retourner les chemins des fichiers si nécessaire
    return $localPaths
}

# Main
try {
    # Télécharger et vérifier les versions des installateurs
    $installerPaths = DownloadAndVerify-Installers

    # Logique pour vérifier et mettre à jour l'état
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
} catch {
    # Gérer les erreurs
    Write-Error $_.Exception.Message
}
