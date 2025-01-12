# URL de la page contenant les informations de téléchargement
$DownloadPageUrl = 'https://cevio.jp/guide/cevio_ai/'

# Télécharger le contenu de la page
$response = Invoke-WebRequest -Uri $DownloadPageUrl

# Vérifier si la requête a réussi
if ($response.StatusCode -eq 200) {
    # Extraire le contenu HTML
    $htmlContent = $response.Content

    # Rechercher le lien de téléchargement du fichier .msi
    $downloadLink = $htmlContent -match "onclick=""location.href='([^']*CeVIO_AI_Setup_.*?\.msi)'"""

    if ($downloadLink) {
        # Extraire l'URL complète du fichier .msi
        $installerUrl = $matches[1]

        # Compléter l'URL si nécessaire
        if ($installerUrl -notmatch '^https?://') {
            $installerUrl = [Uri]::new($DownloadPageUrl, $installerUrl).AbsoluteUri
        }

        # Extraire la version à partir du nom du fichier
        if ($installerUrl -match 'CeVIO_AI_Setup_([0-9\.]+)\.msi') {
            $version = $matches[1]

            # Retirer ".0" à la fin si présent
            if ($version -like '*.*.*.0') {
                $version = $version -replace '\.0$', ''
            }

            # Mettre à jour l'état actuel
            $this.CurrentState.Version = $version
            $this.CurrentState.Installer += [ordered]@{
                InstallerUrl = $installerUrl
            }

            # Effectuer les actions en fonction de l'état
            switch -Regex ($this.Check()) {
                'New|Changed|Updated' {
                    try {
                        # Définir l'heure de publication à l'heure actuelle
                        $this.CurrentState.ReleaseTime = [DateTime]::UtcNow

                        # Ajouter les notes de version si disponibles
                        $releaseNotes = "Consultez les détails de la version sur $DownloadPageUrl"
                        $this.CurrentState.Locale += [ordered]@{
                            Locale = 'en-US'
                            Key    = 'ReleaseNotes'
                            Value  = $releaseNotes
                        }

                        # Ajouter l'URL des notes de version
                        $this.CurrentState.Locale += [ordered]@{
                            Key   = 'ReleaseNotesUrl'
                            Value = $DownloadPageUrl
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
        } else {
            $this.Log("Impossible d'extraire la version du nom du fichier.", 'Error')
        }
    } else {
        $this.Log("Lien de téléchargement .msi introuvable sur la page.", 'Error')
    }
} else {
    $this.Log("Échec du téléchargement de la page. Code de statut : $($response.StatusCode)", 'Error')
}
