$projectRoot = Resolve-Path $PSScriptRoot\..
$moduleRoot = Split-Path (Resolve-Path $projectRoot\*\*.psd1)
$moduleName = Split-Path $moduleRoot -Leaf

$changelog = 'CHANGELOG.md'

$script:manifest = $null

Describe 'Module Manifest Tests' -Tag 'Meta' {

    It 'has a valid module manifest file' {
        $script:manifest = Test-ModuleManifest -Path $moduleRoot\$moduleName.psd1
        $? | Should -Be $true
    }

    It 'has a valid name in the manifest' {
        $manifest.Name | Should Be Write-ProgressEx
    }

    It 'has a valid guid in the manifest' {
        $manifest.Guid | Should Be '5f01cd33-a0b5-4725-99f4-af22a86621d9'
    }

    It 'has a description in the manifest' {
        $manifest.Description | Should Not BeNullOrEmpty
    }

    It 'has release notes in the manifest' {
        $manifest.PrivateData.PSData.ReleaseNotes | Should Not BeNullOrEmpty
    }

    $publicFunctions = @('Write-ProgressEx', 'Get-ProgressEx', 'Set-ProgressEx')

    It 'has valid functions to export' {
        $manifest.ExportedFunctions.Keys | Should Be $publicFunctions
    }

    It 'has valid cmdlets to export' {
        $manifest.ExportedCmdlets.Keys | Should Be $publicFunctions
    }

    It 'has a valid version in the manifest' {
        $manifest.Version -as [Version] | Should Not BeNullOrEmpty
    }

    It "has a valid version on the top of $projectRoot\$changelog" {
        Get-Content -Path $projectRoot\$changelog |
            Where-Object { $_ -match '^\D*(?<Version>(\d+\.){1,3}\d+)' } |
            Select-Object -First 1 | Should Not BeNullOrEmpty

        $script:ChangelogVersion = $matches.Version
        $ChangelogVersion                | Should Not BeNullOrEmpty
        $ChangelogVersion -as [Version]  | Should Not BeNullOrEmpty
    }

    It 'changelog and manifest versions are the same' {
        $manifest.Version -as [Version] | Should be ( $ChangelogVersion -as [Version] )
    }

    It 'description have not back quote' {
        $manifest.Description | Should -Not -Match '`'
    }

    It 'release notes have not back quote' {
        $manifest.PrivateData.PSData.ReleaseNotes | Should -Not -Match '`'
    }

}

Describe 'Nuget specification Tests' -Tag 'Meta' {

    It 'has a valid nuspec file' {
        $file = Resolve-Path $projectRoot\$moduleName.nuspec
        [xml]$script:nuspec = Get-Content $file
        $nuspec | Should Not BeNullOrEmpty
    }

    It 'has a valid id' {
        $nuspec.package.metadata.id | Should Be ($moduleName)
    }

    It 'nuspec and manifest descriptions are same' {
        $nuspec.package.metadata.Description | Should Be ($manifest.Description)
    }

    It 'nuspec and manifest release notes are same' {
        $nuspecReleaseNotes = $nuspec.package.metadata.ReleaseNotes -replace '\s'
        $manifestReleaseNotes = $manifest.PrivateData.PSData.ReleaseNotes -replace '\s'

        $nuspecReleaseNotes | Should Be $manifestReleaseNotes
    }

    It 'nuspec and manifest projectUrl are same' {
        $nuspec.package.metadata.projectUrl | Should Be ($manifest.PrivateData.PSData.ProjectUri)
    }

    It 'nuspec and manifest licenseUrl notes are same' {
        $nuspec.package.metadata.licenseUrl | Should Be ($manifest.PrivateData.PSData.LicenseUri)
    }

}
