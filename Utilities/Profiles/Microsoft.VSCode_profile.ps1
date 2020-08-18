########################################################
#region Initialize Environment
########################################################
$path = (Get-Item $PSScriptRoot).Parent
Import-Module "$path/ContentTools"
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

#-------------------------------------------------------
