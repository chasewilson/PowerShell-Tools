function New-DevOpsWorkItem {
    param
    (
        [Parameter(Mandatory=$true)]
        [string]
        $Title,

        [Parameter(Mandatory=$true)]
        [string]
        $Description,

        [Parameter()]
        [int]
        $ParentId,

        [Parameter()]
        [string[]]
        $Tags,

        [Parameter()]
        [ValidateSet('Task','User%20Story')]
        [string]
        $WiType = 'Task',

        [Parameter()]
        [ValidateSet(
          'TechnicalContent\Carmon Mills Org',
          'TechnicalContent\Carmon Mills Org\Management\PowerShell',
          'TechnicalContent\Carmon Mills Org\Management\PowerShell\Cmdlet Ref',
          'TechnicalContent\Carmon Mills Org\Management\PowerShell\Core',
          'TechnicalContent\Carmon Mills Org\Management\PowerShell\Developer',
          'TechnicalContent\Carmon Mills Org\Management\PowerShell\DSC',
          'TechnicalContent\Azure\Compute\Management\Config\PowerShell'
        )]
        [string]
        $Areapath = 'TechnicalContent\Azure\Compute\Management\Config\PowerShell',

        [Parameter()]
        [string]
        $Iterationpath,

        [Parameter()]
        [ValidateSet('sewhee','phwilson','robreed','dcoulte','v-dasmat')]
        [string]
        $Assignee='phwilson'
    )

    $username = ' '
    $password =  ConvertTo-SecureString $env:MSENG_OAUTH_TOKEN -AsPlainText -Force
    $cred = [PSCredential]::new($username, $password)

    if (-not $Iterationpath)
    {
        $Iterationpath = Get-IterationPath
    }

    $vsuri = 'https://dev.azure.com'
    $org = 'mseng'
    $project = 'TechnicalContent'
    $apiurl = "$vsuri/$org/$project/_apis/wit/workitems/$" + $WiType +"?api-version=5.1"

    $widata = [System.Collections.Generic.List[psobject]]::new()

    $field = New-Object -type PSObject -prop @{
        op = "add"
        path = "/fields/System.Title"
        value = $Title
    }
    $widata.Add($field)

    $field = New-Object -type PSObject -prop @{
        op = "add"
        path = "/fields/System.AreaPath"
        value = $Areapath
    }

    $widata.Add($field)

    $field = New-Object -type PSObject -prop @{
        op = "add"
        path = "/fields/System.IterationPath"
        value = $Iterationpath
    }

    $widata.Add($field)

    if ($ParentId -ne 0)
    {
        $field = New-Object -type PSObject -prop @{
            op = "add"
            path = "/relations/-"
            value = @{
                rel = 'System.LinkTypes.Hierarchy-Reverse'
                url = "$vsuri/$org/$project/_apis/wit/workitems/$ParentId"
            }
        }

        $widata.Add($field)
    }

    if ($Tags.count -ne 0)
    {
        $field = New-Object -type PSObject -prop @{
            op = "add"
            path = "/fields/System.Tags"
            value = $Tags -join '; '
        }

        $widata.Add($field)
    }

    $field = New-Object -type PSObject -prop @{
        op = "add"
        path = "/fields/System.AssignedTo"
        value = $Assignee + '@microsoft.com'
    }

    $widata.Add($field)

    $field = New-Object -type PSObject -prop @{
        op = "add"
        path = "/fields/System.Description"
        value = $Description
    }

    $widata.Add($field)
    $query = ConvertTo-Json $widata

    $params = @{
        uri = $apiurl
        Authentication = 'Basic'
        Credential = $cred
        Method = 'Post'
        ContentType = 'application/json-patch+json'
        Body = $query
    }

    $results = Invoke-RestMethod @params

    $results |
        Select-Object @{l='Id';e={$_.Id}},
            @{l='State'; e={$_.fields.'System.State'}},
            @{l='Parent';e={$_.fields.'System.Parent'}},
            @{l='AssignedTo'; e={$_.fields.'System.AssignedTo'.displayName}},
            @{l='AreaPath';e={$_.fields.'System.AreaPath'}},
            @{l='IterationPath'; e={$_.fields.'System.IterationPath'}},
            @{l='Title';e={$_.fields.'System.Title'}},
            @{l='AttachedFiles'; e={$_.fields.'System.AttachedFileCount'}},
            @{l='ExternalLinks';e={$_.fields.'System.ExternalLinkCount'}},
            @{l='HyperLinks'; e={$_.fields.'System.HyperLinkCount'}},
            @{l='Reason';e={$_.fields.'System.Reason'}},
            @{l='RelatedLinks'; e={$_.fields.'System.RelatedLinkCount'}},
            @{l='RemoteLinks';e={$_.fields.'System.RemoteLinkCount'}},
            @{l='Tags'; e={$_.fields.'System.Tags'}},
            @{l='Description';e={$_.fields.'System.Description'}}
}

function Get-IterationPath
{
    param()

    $date = Get-Date
    $year = $date.Year
    $month = $date.Month
    if ($month -lt 10)
    {
        $month = "0$month"
    }

    return "TechnicalContent\CY$year\$($month)_$year"
}

function Import-GitHubIssueToTFS
{
    param
    (
        [Parameter(Mandatory=$true)]
        [uri]
        $IssueUrl,

        [Parameter()]
        [ValidateSet(
            'TechnicalContent\Carmon Mills Org',
            'TechnicalContent\Carmon Mills Org\Management\PowerShell',
            'TechnicalContent\Carmon Mills Org\Management\PowerShell\Cmdlet Ref',
            'TechnicalContent\Carmon Mills Org\Management\PowerShell\Core',
            'TechnicalContent\Carmon Mills Org\Management\PowerShell\Developer',
            'TechnicalContent\Carmon Mills Org\Management\PowerShell\DSC',
            'TechnicalContent\Azure\Compute\Management\Config\PowerShell'
        )]
        [string]
        $AreaPath='TechnicalContent\Azure\Compute\Management\Config\PowerShell',

        [Parameter()]
        [string]
        $Iterationpath,

        [Parameter()]
        [ValidateSet('sewhee','phwilson','robreed','dcoulte','v-dasmat')]
        [string]
        $Assignee='phwilson',

        [Parameter()]
        [switch]
        $SkipBranch
    )

    function Get-Issue
    {
        param
        (
            [Parameter(ParameterSetName='bynamenum',Mandatory=$true)]
            [string]
            $repo,

            [Parameter(ParameterSetName='bynamenum',Mandatory=$true)]
            [int]
            $num,

            [Parameter(ParameterSetName='byurl',Mandatory=$true)]
            [uri]
            $issueurl
        )

        $hdr = @{
            Accept = 'application/vnd.github.v3+json'
            Authorization = "token ${Env:\GITHUB_OAUTH_TOKEN}"
        }

        if ($issueurl -ne '')
        {
            $repo = ($issueurl.Segments[1..2] -join '').trim('/')
            $issuename = $issueurl.Segments[1..4] -join ''
            $num = $issueurl.Segments[-1]
        }

        $apiurl = "https://api.github.com/repos/$repo/issues/$num"
        $issue = (Invoke-RestMethod $apiurl -Headers $hdr)
        $apiurl = "https://api.github.com/repos/$repo/issues/$num/comments"
        $comments = (Invoke-RestMethod $apiurl -Headers $hdr) | Select-Object -ExpandProperty body
        $retval = New-Object -TypeName psobject -Property ([ordered]@{
            number = $issue.number
            name = $issuename
            url=$issue.html_url
            created_at=$issue.created_at
            assignee=$issue.assignee.login
            title='[GitHub #{0}] {1}' -f $issue.number,$issue.title
            labels=$issue.labels.name
            body=$issue.body
            comments=$comments -join "`n"
        })

        $retval
    }

    if (-not $Iterationpath)
    {
        $Iterationpath = Get-IterationPath
    }

    $issue = Get-Issue -issueurl $issueurl
    $description = "Issue: <a href='{0}'>{1}</a><BR>" -f $issue.url,$issue.name
    $description += "Created: {0}<BR>" -f $issue.created_at
    $description += "Labels: {0}<BR>" -f ($issue.labels -join ',')

    $wiParams = @{
        title = $issue.title
        description = $description
        parentId = 1669514
        areapath = $Areapath
        iterationpath = $Iterationpath
        wiType = 'Task'
        assignee = $Assignee
    }

    New-DevOpsWorkItem @wiParams
    $apiurl = "https://api.github.com/repos/$repo/issues/$num"

    if ($SkipBranch)
    {

    }
    else
    {
        New-GitHubIssueBranch -IssueNumber $issue.Number
    }
    #Update-IssueAssignee -ApiUrl $apiurl
}

function New-GitHubIssueBranch
{
    param
    (
        [Parameter()]
        [string]
        $IssueNumber
    )

    $branchName = "chasewilson-ghi$IssueNumber"
    # Switch to staging
    git checkout staging

    # Rebase staging to the upstream
    git fetch upstream staging
    git rebase upstream/staging
    git push --force

    # Create new branch
    git checkout -b $branchName

    # Push to the upstream branch
    git push --set-upstream origin $branchName
}

function Update-IssueAssignee
{
    param
    (
        [Parameter()]
        [string]
        $ApiUrl,

        [Parameter()]
        [string]
        $Assignee = 'chasewilson'
    )

    $hdr = @{
        Accept        = 'application/vnd.github.v3+json'
        Authorization = "token ${Env:\GITHUB_OAUTH_TOKEN}"
        Assignees     = $Assignee
    }

    Invoke-RestMethod -Uri $ApiUrl -Headers $hdr -Method Post
}
#endregion
#-------------------------------------------------------

function Clear-Git
{
    param
    (
        [Parameter()]
        [string[]]
        $PreserveBranch = 'staging',

        [Parameter()]
        [string]
        $MainBranch = 'staging'
    )
    # Checkout main branch to avoid deleting
    git checkout $MainBranch

    # Prune
    git remote prune origin

    # Get list of branches to remove
    $allBranches = git branch
    $branchesToRemove = $allBranches | Where-Object -FilterScript {$_ -notin $PreserveBranch}

    # Prompt the user to let them know this will permanantly erase these branches if they want to coninue
    $continue = Read-Host -Prompt "This will permanently delete these branches:`n$branchesToRemove`nWould you like to continue? (Y/N)"
    while ($continue -ne 'Y' -and $continue -ne 'N')
    {
        $continue = Read-Host -Prompt "`"$continue`" is not a valid response.`nWould you like to permanently delete the listed branches? (Y/N)"
    }

    if ($continue -eq 'Y')
    {}
    else
    {
        return
    }

    foreach ($branch in $branchesToRemove)
    {
        $branch = $branch.trim()
        git branch -d $branch --force
        git push origin --delete $branch --force
    }
}

function New-PoshDocsPr
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Title,

        [Parameter(Mandatory = $true)]
        [string]
        $Description,

        [Parameter()]
        [AllowEmptyString()]
        [string]
        $DevopsWorkItem,

        [Parameter()]
        [string]
        $UserName = 'chasewilson',

        [Parameter()]
        [string]
        $BaseBranch = 'staging',

        [Parameter()]
        [switch]
        $WorkInProgress
    )

    if (-not $DevopsWorkItem)
    {
        $DevOpsWorkItem = Read-Host "You don't have a DevOps Work Item`nPlease enter one or leave blank"
    }

    $prInfo = Get-PrInfo -Description $Description -DevopsWorkItem $DevopsWorkItem
    if (-not $Title)
    {
        $Title = Get-Title -Branch $prInfo.Branch -Updates $prInfo.UpdatedFiles -IssueNumber $prInfo.IssueNumber -WorkInProgress $WorkInProgress
    }

    $content = New-PrTemplate -PrInfo $prInfo
    $body = @{
        title = $Title
        body  = $content
        head  = $UserName + ':' + $prInfo.Branch
        base  = $BaseBranch
    } | ConvertTo-Json

    Invoke-PullRequest -Body $body
}

function New-PRMap
{
    param()

    return @(
        [pscustomobject]@{path = 'reference/5.1'                                ; line = 32},
        [pscustomobject]@{path = 'reference/7.0'                                ; line = 31},
        [pscustomobject]@{path = 'reference/7.1'                                ; line = 30},
        [pscustomobject]@{path = 'reference/7.2'                                ; line = 29},
        [pscustomobject]@{path = 'reference/docs-conceptual/community'          ; line = 22},
        [pscustomobject]@{path = 'reference/docs-conceptual/dev-cross-plat'     ; line = 25},
        [pscustomobject]@{path = 'reference/docs-conceptual/developer'          ; line = 26},
        [pscustomobject]@{path = 'reference/docs-conceptual/dsc'                ; line = 21},
        [pscustomobject]@{path = 'reference/docs-conceptual/gallery'            ; line = 24},
        [pscustomobject]@{path = 'reference/docs-conceptual/install'            ; line = 13},
        [pscustomobject]@{path = 'reference/docs-conceptual/learn'              ; line = 14},
        [pscustomobject]@{path = 'reference/docs-conceptual/learn/deep-dives'   ; line = 16},
        [pscustomobject]@{path = 'reference/docs-conceptual/learn/ps101'        ; line = 15},
        [pscustomobject]@{path = 'reference/docs-conceptual/learn/remoting'     ; line = 17},
        [pscustomobject]@{path = 'reference/docs-conceptual/samples'            ; line = 23},
        [pscustomobject]@{path = 'reference/docs-conceptual/whats-new'          ; line = 18},
        [pscustomobject]@{path = 'reference/docs-conceptual/windows-powershell' ; line = 19}
    )
}

function Sync-Path
{
    param
    (
        [Parameter()]
        [string]
        $Path,

        [Parameter()]
        $PathMap
    )

    foreach ($map in $PathMap)
    {
        if ($Path.StartsWith($map.path))
        {
            $line = $map.line
        }
    }

    $line
}

function Get-PrInfo
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $Description,

        [Parameter()]
        [AllowEmptyString()]
        [string]
        $DevopsWorkItem
    )

    $branch = git branch --show-current
    $issueNumber = ($branch | Select-String -Pattern '(?<=.*ghi).*\d').Matches.Value
    $updates = Get-ChangedFiles -CurrentBranch $branch -UpdateStaging

    $return = @{
        Description  = $Description
        Branch       = $branch
        IssueNumber  = $issueNumber
        DevopsWi     = $DevopsWorkItem
        UpdatedFiles = $updates
    }

    return $return
}

function Get-Title
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string[]]
        $Branch,

        [Parameter()]
        [string[]]
        $Updates,

        [Parameter()]
        [string]
        $IssueNumber,

        [Parameter()]
        [bool]
        $WorkInProgress
    )

    $uniqueFiles = Get-UniqueFiles -Files $Updates
    if ($uniqueFiles.count -gt 1)
    {
        $extraFileCount = $uniqueFiles.count - 1
        $titleFileName = $uniqueFiles[0]
        $title = "Fixes #$IssueNumber - Updates $titleFileName + $extraFileCount more"
    }
    else
    {
        $title = "Fixes #$IssueNumber - Updates $uniqueFiles"
    }

    if($WorkInProgress)
    {
        $title = "[WIP] $Title"
    }

    return $title
}

function Get-UniqueFiles
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string[]]
        $Files
    )
    $return = @()
    foreach ($file in $Files)
    {
        $return += ($file.Split('/'))[-1].Split('.')[0]
    }

    $return = $return | Select-Object -Unique
    return $return
}

function Get-ChangedFiles
{
    [CmdletBinding()]
    [OutputType([string[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $CurrentBranch,

        [Parameter()]
        [switch]
        $UpdateStaging
    )

    if ($UpdateStaging)
    {
        $null = git checkout staging
        $null = git fetch upstream staging
        $null = git rebase upstream/staging
        $null = git push
    }

    $null = git checkout $CurrentBranch
    $files = git diff --name-only staging...

    return $files
}

function New-PrTemplate
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        $PrInfo
    )

    $template = Format-PrTemplate -UpdatedFiles $PrInfo.UpdatedFiles
    switch (7,6,2)
    {
        (2)
        {
            $template[2] = $PrInfo.Description
        }
        (6)
        {
            if ($PrInfo.IssueNumber)
            {
                $template[6] = "Fixes #$($PrInfo.IssueNumber)"
            }
            else {
                $template[6] = "No Linked issues"
            }
        }
        (7)
        {
            if ($PrInfo.DevopsWi)
            {
                $template[7] = "Fixes AB#$($PrInfo.DevopsWi)"
            }
            else {
                $template[7] = "No Linked Azure Work Items"
            }
        }
    }

    $content = $template -join "`r`n"
    return $content
}

function Format-PrTemplate
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [array]
        $UpdatedFiles
    )

    $pathMap = New-PRMap
    [System.Collections.ArrayList]$template = Get-Content 'C:\Source\Repos\PowerShell-Docs\.github\PULL_REQUEST_TEMPLATE.md'

    foreach ($file in $UpdatedFiles)
    {
        $line = Sync-Path -Path $file -PathMap $pathMap
        $template[$line] = $template[$line] -replace [regex]::Escape('[ ]'),'[x]'
    }

    foreach ($num in 36..41){
        $template[$num] = $template[$num] -replace [regex]::Escape('[ ]'),'[x]'
    }

    foreach ($i in 1..6)
    {
        if ($i -lt 2)
        {
            $template.RemoveAt(1)
        }
        else
        {
            $template.RemoveAt(3)
        }
    }

    foreach ($num in 1..5)
    {
        if ($num -lt 3)
        {
            $template.Insert(1, '')
        }
        else {
            $template.Insert(5, '')
        }
    }

    return $template
}

function Invoke-PullRequest
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        $Body
    )

    $hdr = @{
        Accept        = 'application/vnd.github.VERSION.raw+json'
        Authorization = "token ${Env:GITHUB_OAUTH_TOKEN}"
    }

    $apiurl = 'https://api.github.com/repos/MicrosoftDocs/PowerShell-Docs/pulls'
    try
    {
        $i = Invoke-RestMethod -Uri $apiurl -Headers $hdr -Method POST -Body $Body
        Start-Process $i.html_url
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException]
    {
        $e = $_.ErrorDetails.Message | ConvertFrom-Json | Select-Object -ExpandProperty errors
        write-error $e.message
        $error.Clear()
    }
}
