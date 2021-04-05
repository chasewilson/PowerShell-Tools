# Module manifest for module 'chase.utilities'
@{
    RootModule = 'ContentTools.psm1'
    ModuleVersion = '1.1'
    CompatiblePSEditions = 'Desktop'
    GUID = '53f11c02-d131-446f-ac40-87c15987e555'
    Author = 'Chase.Wilson'
    CompanyName = 'chase.wilson'
    Copyright = '(c) 2019 Chase Wilson. All rights reserved.'
    Description = "Chase's collection of utilities"
    PowerShellVersion = '4.0'
    #RequiredAssemblies = @("$env:ProgramW6432\System.Data.SQLite\netstandard2.0\System.Data.SQLite.dll",'System.Web')
    NestedModules = @(
        'gittools'
    )
    FunctionsToExport = @(
      # contenttools
        "Compare-DocVersions",
        "Format-Headers",
        "Open-PowerShellDocs",
        "Switch-Prompt",
        "Switch-RulerLines",
        "Switch-WordWrapPower",
        "Switch-WordWrapSettings",
      # gittools
        "Clear-Git",
        "Import-GitHubIssueToTFS",
        "New-DevOpsWorkItem",
        "New-PoshDocsPr"
    )
#    CmdletsToExport = @()
#    VariablesToExport = '*'
    AliasesToExport = @()
    ModuleList = @(
        'contenttools',
        'gittools'
    )
#    FileList = @()
#    PrivateData = @{
#        PSData = @{
#            # Tags = @()
#            # LicenseUri = ''
#            # ProjectUri = ''
#            # IconUri = ''
#            # ReleaseNotes = ''
#        }
#    }
#    HelpInfoURI = ''
#    DefaultCommandPrefix = ''
}
