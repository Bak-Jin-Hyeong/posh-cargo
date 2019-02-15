@{

# Script module or binary module file associated with this manifest.
ModuleToProcess = 'posh-cargo.psm1'

# Version number of this module.
ModuleVersion = '0.1.2'

# ID used to uniquely identify this module
GUID = '1803191a-75c9-4000-b0aa-521ab6cd4ae9'

# Author of this module
Author = 'Bak, Jin Hyeong'

# Copyright statement for this module
Copyright = '(c) 2017 Bak, Jin Hyeong'

# Description of the functionality provided by this module
Description = 'Provides tab autocompletion of cargo (https://github.com/rust-lang/cargo)'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '3.0'

# Functions to export from this module
FunctionsToExport = @(
    'TabExpansion'
)

# Cmdlets to export from this module
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module
AliasesToExport = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess.
# This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{
        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('cargo', 'rust', 'rust-lang', 'tab', 'tab-completion', 'tab-expansion', 'tabexpansion')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/Bak-Jin-Hyeong/posh-cargo/blob/master/LICENSE.txt'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/Bak-Jin-Hyeong/posh-cargo'

        # ReleaseNotes of this module
        ReleaseNotes = 'https://github.com/Bak-Jin-Hyeong/posh-cargo/blob/master/CHANGELOG.md'
    }

}

}
