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

# Fonction pour télécharger, vérifier les versions, puis supprimer les fichiers
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
    $x86Version = (Get-Item $localPaths['x86']).VersionInfo.ProductVersion
    $x64Version = (Get-Item $localPaths['x64']).VersionInfo.ProductVersion

    # Vérifier si les versions sont identiques
    if ($x86Version -ne $x64Version) {
        # Nettoyer les fichiers avant de lancer une exception
        Remove-Item $localPaths['x86'], $localPaths['x64'] -ErrorAction SilentlyContinue
        throw "Les versions des installateurs ne correspondent pas : x86 = $x86Version, x64 = $x64Version"
    }

    # Mettre à jour la version dans CurrentState
    $this.CurrentState.Version = $x86Version

    # Nettoyer les fichiers après la vérification
    Write-Host "Suppression des fichiers téléchargés..."
    Remove-Item $localPaths['x86'], $localPaths['x64'] -ErrorAction SilentlyContinue

    Write-Host "Téléchargements vérifiés et fichiers nettoyés."
}

# Main
try {
    # Télécharger, vérifier et nettoyer les installateurs
    DownloadVerifyAndClean-Installers

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
