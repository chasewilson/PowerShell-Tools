 <#
    .SYNOPSIS
        Generates a file containing function stubs of all cmdlets from the module
        given as a parameter.

    .PARAMETER ModuleName
        The name of the module to load and generate stubs from. This module must
        exist on the computer where this function is run.

    .PARAMETER OutputPath
        Path to where to write the stubs file. The filename will be generated
        from the module name.

    .PARAMETER ModuleVersion
        The module version to stub. If no Module Version is defined, it well select
        the most recent version to stub.

    .EXAMPLE
        $writeModuleStubFileParameters = @{
            ModuleName    = 'FailoverClusters'
            OutputPath    = 'C:\Source'
            ModuleVersion = 1.0.0.0
        }

        Write-ModuleStubFile @writeModuleStubFileParameters
#>
function Write-ModuleStubFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $OutputPath,

        [Parameter()]
        $ModuleVersion
    )

    if (Test-Path -Path "$OutputPath\$($ModuleName)Stub.psm1")
    {
        Remove-Item -Path "$OutputPath\$($ModuleName)Stub.psm1"
    }

    if ($null -ne $ModuleVersion)
    {
        $fqModule = @{
            ModuleName = $ModuleName
            ModuleVersion = $ModuleVersion
        }
    }
    else
    {
        $module = (Get-Module -Name $ModuleName -ListAvailable)[0]

        $fqModule = @{
            ModuleName = $module.Name
            ModuleVersion = $module.Version
        }
    }

    New-StubModuleFile -Path "$OutputPath\$($ModuleName)Stub.psm1" -Module $fqModule.ModuleName

    Import-Module -FullyQualifiedName $fqModule
    $cmdletToStub = Get-Command -FullyQualifiedModule $fqModule

    foreach ($command in $cmdletToStub)
    {
        $parametersToAdd = Get-StubParameters -Command $command

        $stringParamSection = Get-StringParamSection -Parameters $parametersToAdd

        Write-CommandStub -Module $fqModule -CommandName $command -OutputPath $OutputPath -ParameterString $stringParamSection
    }
}

<#
    .SYNOPSIS
        Returns a list of the parameters not including Common Parameters

    .PARAMETER Command
        The command object that contains the parameters to return
#>
function Get-StubParameters
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object[]]
        $Command
    )

    $ignoreParameters = [System.Management.Automation.Cmdlet]::CommonParameters + [System.Management.Automation.Cmdlet]::OptionalCommonParameters
    $parameters = $Command.Parameters
    $returnParams = @()

    foreach ($param in $parameters.keys)
    {
        if ($param -notin $ignoreParameters)
        {
            $paramObject = $parameters.$param
            $returnParams += $paramObject
        }
    }

    return $returnParams
}

<#
    .SYNOPSIS
        Returns a string object of a best practice param section

    .PARAMETER Parameters
        Parameters to convert to a string object
#>
function Get-StringParamSection
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        $Parameters
    )

    $stubparams = $null
    $count = 1
    $paramCount = $Parameters.count

    foreach ($param in $Parameters)
    {
        if ($param.Attributes.Mandatory)
        {
            $mandatory = 'Mandatory = $true'
        }
        else
        {
            $mandatory = $null
        }

        if ($null -ne $param.ParameterType)
        {
            $objectType = "        [$($param.ParameterType)]`n"
        }
        else
        {
            $objectType = $null
        }

        [string[]] $parameterSet = $param.ParameterSets.Keys

        if ($parameterSet -eq "__AllParameterSets")
        {
            if ($count -lt $paramCount)
            {
                $stringparameter = "        [Parameter($mandatory)]`n$objectType        `$$($param.name),`n`n"

                $stubparams += $stringparameter

                $count++
            }
            else
            {
                $stringparameter = "        [Parameter($mandatory)]`n$objectType        `$$($param.name)"

                $stubparams += $stringparameter
            }
        }
        else
        {
            $paramSetString = Get-ParameterSetString -ParameterSet $param.ParameterSets

            if ($count -lt $paramCount)
            {
                $stringparameter = "$($paramSetString)`n$objectType        `$$($param.name),`n`n"

                $stubparams += $stringparameter

                $count++
            }
            else
            {
                $stringparameter = "$($paramSetString -split ";")`n$objectType        `$$($param.name)"

                $stubparams += $stringparameter
            }
        }
    }

    return $stubparams
}

<#
    .SYNOPSIS
        Writes the stub function to a stub function module

    .PARAMETER Module
        Module being stubbed

    .PARAMETER CommandName
        Command name to stub

    .PARAMETER OutputPath
        Path where to find the stub function module

    .PARAMETER ParameterString
        String object of params to add to the stubbed command
#>
function Write-CommandStub
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        $Module,

        [Parameter(Mandatory = $true)]
        [string]
        $CommandName,

        [Parameter(Mandatory = $true)]
        [string]
        $OutputPath,

        [Parameter()]
        [AllowNull()]
        $ParameterString
    )

    $operatingSystemInformation = Get-CimInstance -class Win32_OperatingSystem

    ForEach-Object -InputObject $CommandName -Process {
        "<#"
        "    .SYNOPSIS"
        "        This is stub cmdlets for module: $($Module.ModuleName) version: $($Module.ModuleVersion) which can be used in"
        "        Pester unit tests to be able to test code without having the actual module installed."
        ""
        "    .NOTES"
        "        Generated from module $($Module) on"
        "        operating system $($operatingSystemInformation.Caption) $($operatingSystemInformation.OSArchitecture) ($($operatingSystemInformation.Version))"
        "#>"
        "function $($CommandName)"
        "{"
        "    [CmdletBinding()]"
        "    param"
        "    ("
                ($ParameterString -split "`n")
        "    )"
        ""
        "    throw '{0}: StubNotImplemented' -f `$MyInvocation.MyCommand"
        "}"
        ""
    } | Out-File (Join-Path -Path $OutputPath -ChildPath "$($Module.ModuleName)Stub.psm1") -Encoding utf8 -Append
}

<#
    .SYNOPSIS
        Creates a stub function module

    .PARAMETER Module
        Module being stubbed

    .PARAMETER Path
        Path where the Stub Module will be created
#>
function New-StubModuleFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Module,

        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    ForEach-Object -InputObject $Path -Process {
        "# This section suppresses rules PsScriptAnalyzer may catch in stub functions. "
        "[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams', '')]"
        "[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '')]"
        "[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUsePSCredentialType', '')]"
        "param ()"
        ""
    } | Out-File (Join-Path -Path $OutputPath -ChildPath "$($Module)Stub.psm1") -Encoding utf8 -Append
}

<#
    .SYNOPSIS
        Builds the parameter section into a string format to use when the stub is written.

    .PARAMETER ParameterSet
        The set of parameteers to turn into a string format.
#>
function Get-ParameterSetString
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [psobject[]]
        $ParameterSet
    )

    $returnSet = $null
    $count = 1
    foreach ($key in $ParameterSet.Keys)
    {
        if ($ParameterSet.$key.IsMandatory -eq $true)
        {
            $mandatory = "Mandatory = `$true, "
        }
        else
        {
            $mandatory = $null
        }

        if ($count -lt $ParameterSet.Keys.Count)
        {
            $returnSet += "        [Parameter($($mandatory)ParameterSetName = `'$($key)`')]`n"
        }
        else
        {
            $returnSet += "        [Parameter($($mandatory)ParameterSetName = `'$($key)`')]"
        }

        $count++
    }

    return $returnSet
}



#RANDOM TEST CHANGE! DELETE ME IF YOU SEE ME!!