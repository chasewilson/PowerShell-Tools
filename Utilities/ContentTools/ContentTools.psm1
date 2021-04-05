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
        [string[]]
        $DocNames,

        [Parameter()]
        [string]
        $DocFolder = 'C:\Source\Repos\PowerShell-Docs',

        [Parameter()]
        [ValidateSet('5.1', '7.0', '7.1', '7.2')]
        [string[]]
        $Version
    )

    $articles = @()
    if ($Version)
    {
        foreach ($ver in $Version)
        {
            foreach ($doc in $DocNames)
            {
                if ($doc -match 'https:\/\/')
                {
                    $doc = Get-DocNameFromUrl -Url $doc
                }

                $articles += (Get-ChildItem -Path "$DocFolder\reference\$ver" -Filter "$doc.md" -Recurse).FullName
            }
        }
    }
    else
    {
        foreach ($doc in $DocNames)
        {
            if ($doc -match 'https:\/\/')
            {
                $doc = Get-DocNameFromUrl -Url $doc
            }

            $articles += (Get-ChildItem -Path $DocFolder  -Filter "$doc.md" -Recurse).FullName
        }
    }

    code $articles
}

function Get-DocNameFromUrl
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $Url
    )

    if ($Url -match '.*\.md$')
    {
        return ($Url | Select-String -Pattern '([^\/]+)(?=\.md?$)').Matches.Value
    }
    elseif ($Url -match '.*\?view.*')
    {
        return ($Url | Select-String -Pattern '([^\/]+)(?=\?view?)').Matches.Value
    }
    else
    {
        throw "Function: Get-DocNameFromUrl
    URL: $Url
    Doesn't match convention."
    }
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

function Format-Headers
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $FilePath
    )

    $content = Get-Content -Path $FilePath

    $headerMatches = $content | Select-String -Pattern '^##\s[A-Z]*(?![a-z])(\s[A-Z]*)*'
    if ($matches)
    {
        foreach ($match in $headerMatches)
        {
            $newHeader = New-Header -Header $match.ToString()
            $content = $content -replace $match.ToString(), $newHeader
        }

        Set-Content -Path $FilePath -Value $content -Force
    }
}

function New-Header
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Header
    )

    $hTitle = ($Header -split ' ', 2)[1]
    $returnTitle = (Get-Culture).TextInfo.ToTitleCase($hTitle.ToLower())

    return "## $returnTitle"
}
