# mazzy@mazzy.ru, 21.07.2017
# https://github.com/mazzy-ax/Write-ProgressEx

@{
    # If authoring a script module, the RootModule is the name of your .psm1 file
    RootModule = 'Write-ProgressEx.psm1'

    Author = 'Sergey Mazurkin <mazzy@mazzy.ru>'

    CompanyName = 'mazzy'

    ModuleVersion = '0.1'

    # Use the New-Guid command to generate a GUID, and copy/paste into the next line
    GUID = '<05f1a40e-b5cc-4495-b73e-46e812e1b754>'

    Copyright = '(c) 2017. All rights reserved.'

    Description = 'Powershell Extended Write-Progress cmdlet'

    # Minimum PowerShell version supported by this module (optional, recommended)
    # PowerShellVersion = ''

    # Which PowerShell Editions does this module work with? (Core, Desktop)
    CompatiblePSEditions = @('Desktop', 'Core')

    # Which PowerShell functions are exported from your module? (eg. Get-CoolObject)
    FunctionsToExport = @('write-ProgressEx')

    # Which PowerShell aliases are exported from your module? (eg. gco)
    AliasesToExport = @('')

    # Which PowerShell variables are exported from your module? (eg. Fruits, Vegetables)
    VariablesToExport = @('')

    # PowerShell Gallery: Define your module's metadata
    PrivateData = @{
        PSData = @{
            # What keywords represent your PowerShell module? (eg. cloud, tools, framework, vendor)
            Tags = @('ProgressEx', 'Progress', 'ProgressBar', 'Progress Bar', 'Write-Progress', 'write-ProgressEx')

            # What software license is your code being released under? (see https://opensource.org/licenses)
            LicenseUri = ''

            # What is the URL to your project's website?
            ProjectUri = 'https://github.com/mazzy-ax/write-progressEx'

            # What is the URI to a custom icon file for your project? (optional)
            IconUri = ''

            # What new features, bug fixes, or deprecated features, are part of this release?
            ReleaseNotes = ''
        }
    }

    # If your module supports updateable help, what is the URI to the help archive? (optional)
    # HelpInfoURI = ''
}