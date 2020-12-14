function Compare-DocVersions
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $DocName,

        [Parameter()]
        [string]
        $DocFolder = 'C:\Source\Repos\PowerShell-Docs',

        [Parameter()]
        [ValidateSet('5.1','7.0','7.1', '7.2')]
        [string]
        $ReferenceVersion = '5.1'
    )

    $allVersions = @('5.1','7.0','7.1', '7.2')
    $differenceVersions = $allVersions | Where-Object -FilterScript {$_ -ne $ReferenceVersion}
    $differenceArticles = @()

    foreach ($version in $differenceVersions)
    {
        $differenceArticles += (Get-ChildItem -Path "$DocFolder\reference\$version" -Filter "$DocName.md" -Recurse).FullName
    }

    $referenceArticle = (Get-ChildItem -Path "$DocFolder\reference\$ReferenceVersion" -Filter "$DocName.md" -Recurse).FullName
    foreach ($differenceArticle in $differenceArticles)
    {
        Start-Process -Wait "${env:ProgramFiles}\Beyond Compare 4\BComp.exe" -ArgumentList $referenceArticle,$differenceArticle
    }
}

function Open-PowerShellDocs
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [string]
        $DocName,

        [Parameter()]
        [string]
        $DocFolder = 'C:\Source\Repos\PowerShell-Docs',

        [Parameter()]
        [ValidateSet('5.1', '7.0', '7.1', '7.2')]
        [string[]]
        $Version
    )

    if ($Version)
    {
        $articles = @()

        foreach ($ver in $Version)
        {
            $articles += (Get-ChildItem -Path "$DocFolder\reference\$ver" -Filter "$DocName.md" -Recurse).FullName
        }
    }
    else
    {
        $articles = (Get-ChildItem -Path $DocFolder  -Filter "$DocName.md" -Recurse).FullName
    }

    code $articles
}

function Switch-Prompt
{
    if ($function:prompt.tostring().length -gt 100)
    {
        $function:prompt = { 'PS> ' }
    }
    else
    {
        $function:prompt = $GitPromptScriptBlock
    }
}

function Switch-RulerLines
{
    $settingsfile = "$env:USERPROFILE\AppData\Roaming\Code\User\settings.json"
    $content = Get-Content $settingsfile
    $matchingLines = ($content | Select-String -Pattern 'editor.rulers')
    foreach ($line in $matchingLines)
    {
        $lineIndex = $line.LineNumber -1

        $newLine = $line | ForEach-Object {
            if ($_ -match '//')
            {
                $_ -replace '\s\s\s\s\s\s\s\s//"', '        "'
            }
            else
            {
                $_ -replace '\s\s\s\s\s\s\s\s"', '        //"'
            }
        }

        $newLine = $newLine.Trim('"')

        $content[$lineIndex] = $newLine.Trim('"')

        set-content -path $settingsfile -value $content -force
    }
}

function Switch-WordWrapPower
{
    param()

    $settingsfile = "$env:USERPROFILE\AppData\Roaming\Code\User\settings.json"
    $content = Get-Content $settingsfile
    $matchingLines = ($content | Select-String -Pattern '"editor.wordWrap": "wordWrapColumn",').line
    foreach ($line in $matchingLines)
    {
        $lineIndex = (($content | Select-String -Pattern "$line").LineNumber) - 1

        $newLine = $line | ForEach-Object {
            if ($_ -match '//')
            {
                $_ -replace '\s\s\s\s\s\s\s\s//"', '        "'
            }
            else
            {
                $_ -replace '\s\s\s\s\s\s\s\s"', '        //"'
            }
        }

        $newLine = $newLine.Trim('"')

        $content[$lineIndex] = $newLine.Trim('"')

        set-content -path $settingsfile -value $content -force
    }
}

function Switch-WordWrapSettings
{
    $settingsfile = "$env:USERPROFILE\AppData\Roaming\Code\User\settings.json"
    $content = Get-Content $settingsfile
    $matchingLines = ($content | Select-String -Pattern 'reflowMarkdown.preferredLineLength', 'editor.wordWrapColumn').line
    foreach ($line in $matchingLines)
    {
        $lineIndex = (($content | Select-String -Pattern "$line").LineNumber) - 1

        $newLine = $line | ForEach-Object {
            if ($_ -match '//')
            {
                $_ -replace '\s\s\s\s\s\s\s\s//"', '        "'
            }
            else
            {
                $_ -replace '\s\s\s\s\s\s\s\s"', '        //"'
            }
        }

        $newLine = $newLine.Trim('"')

        $content[$lineIndex] = $newLine.Trim('"')

        set-content -path $settingsfile -value $content -force
    }
}
