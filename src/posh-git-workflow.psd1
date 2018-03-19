@{
    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('git', 'PullRequest', 'GitHub', 'VSTS', 'VisualStudioOnline', 'TFS')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/4ux-nbIx/posh-git-workflow/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/4ux-nbIx/posh-git-workflow'

            # A URL to an icon representing this module.
            # IconUri = 'https://github.com/___/icon.png'

            # ReleaseNotes of this module - our ReleaseNotes are in
            # the file ReleaseNotes.md
            ReleaseNotes = 'Initial release'

        } # End of PSData hashtable

    } # End of PrivateData hashtable

# Script module or binary module file associated with this manifest.
RootModule = 'posh-git-workflow.psm1'

# Version number of this module.
ModuleVersion = '1.0.1'

# ID used to uniquely identify this module
GUID = '3ff4d4b6-ade9-46f3-a4f2-2ad6f5508388'

# Author of this module
Author = 'Roman Novitsky'

# Company or vendor of this module
# CompanyName = 'Unknown'

# Copyright statement for this module
Copyright = '(c) 2016 Roman Novitsky. All rights reserved.'

# Description of the functionality provided by this module
Description = 'posh-git-workflow is a PowerShell module that automates GitHub Flow (https://guides.github.com/introduction/flow/) and similar branching models with a set of cmdlets to sync a fork, create/push a feature branch and submit a pull request. It also facilitates teams with longer release cycles with a set of release branch management cmdlets.'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module - explicitly list each function that should be
# exported.  This improves performance of PowerShell when discovering the commands in
# module.
FunctionsToExport = @(
    'Sync-Fork',
    'New-Feature',
    'New-Release',
    'New-ReleaseFix',
    'Complete-Feature',
    'Complete-ReleaseFix',
    'Complete-Release',
    'Push-Feature',
    'Push-ReleaseFix',
    'Set-PullRequestUrl',
    'Get-Features',
    'Get-Releases',
    'Get-ReleaseFixes')

# Cmdlets to export from this module
# CmdletsToExport = '*'

# Variables to export from this module
# VariablesToExport = '*'

# Aliases to export from this module
# AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
DefaultCommandPrefix = 'Git'

}

