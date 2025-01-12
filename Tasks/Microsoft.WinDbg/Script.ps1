# Télécharge le fichier .appinstaller
$response = Invoke-WebRequest -Uri 'https://windbg.download.prss.microsoft.com/dbazure/prod/1-0-0/windbg.appinstaller'

# Convertit le contenu en texte et nettoie le BOM
$contentString = [System.Text.Encoding]::UTF8.GetString($response.Content)
$contentString = $contentString.TrimStart([char]0xFEFF)

# Charger le XML
$xmlContent = [xml]$contentString

# Valider le contenu XML
if (-not $xmlContent.DocumentElement) {
    Write-Error "Le contenu téléchargé n'est pas un XML valide."
    return
}

# Gérer l'espace de noms
$namespaceManager = New-Object System.Xml.XmlNamespaceManager($xmlContent.NameTable)
$namespaceManager.AddNamespace('appx', 'http://schemas.microsoft.com/appx/appinstaller/2018')

# Accéder aux nœuds
$appInstallerNode = $xmlContent.SelectSingleNode('//appx:AppInstaller', $namespaceManager)
$mainBundleNode = $appInstallerNode.SelectSingleNode('appx:MainBundle', $namespaceManager)

# Utiliser les données
$this.CurrentState.Version = $mainBundleNode.Version
$this.CurrentState.Installer += [ordered]@{
    Architecture = 'x86'
    InstallerUrl = $mainBundleNode.Uri
}
$this.CurrentState.Installer += [ordered]@{
    Architecture = 'x64'
    InstallerUrl = $mainBundleNode.Uri
}
$this.CurrentState.Installer += [ordered]@{
    Architecture = 'arm64'
    InstallerUrl = $mainBundleNode.Uri
}

# Check et actions
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
