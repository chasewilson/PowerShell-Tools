########################################################
#region Initialize Environment
########################################################
$path = (Get-Item $PSScriptRoot).Parent
Import-Module "$Path/ContentTools"
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

Import-Module posh-git

#-------------------------------------------------------
function bc
{
    Start-Process "${env:ProgramFiles}\Beyond Compare 4\BComp.exe" -ArgumentList $args
}
