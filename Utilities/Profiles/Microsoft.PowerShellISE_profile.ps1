########################################################
#region Initialize Environment
########################################################
Import-Module "$PSScriptRoot/chase.utilities"
#endregion
#-------------------------------------------------------
#region Aliases & Globals
#-------------------------------------------------------

#endregion
#-------------------------------------------------------
#region Git Functions
$env:GITHUB_ORG         = 'MicrosoftDocs'
$env:GITHUB_USERNAME    = 'chasewilson'

$global:gitRepoRoots = 'C:\Source\Repos'

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Import-Module posh-git
#endregion
