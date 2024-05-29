param(
    [Parameter(Mandatory = $true, ParameterSetName = 'AppVeyor')]
    [switch]$AppVeyor,
    [Parameter(Mandatory = $false, ParameterSetName = 'AppVeyor')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Console')]
    [string[]]$Tag = $null,
    [Parameter(Mandatory = $false, ParameterSetName = 'AppVeyor')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Console')]
    [string[]]$ExcludeTag = $null,
    [Parameter(Mandatory = $false, ParameterSetName = 'AppVeyor')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Console')]
    [switch]$CodeCoverage = $false
)
$srcPath = Resolve-Path -Path "$PSScriptRoot\..\Src"
$outputFile = [System.IO.Path]::GetTempFileName() + '.xml'
$codeCoveragePath = $outputFile.Replace('.xml', '.codecoverage.xml')

$pesterConfiguration = New-PesterConfiguration
$pesterConfiguration = [PesterConfiguration]@{
    Run          = @{
        Path     = $srcPath
        PassThru = $true
    }
    TestResult   = @{
        Enabled      = $true
        OutputFormat = 'NUnitXml'
        OutputFile   = $outputFile
    }
    Filter       = @{
        Tag        = $tag
        ExcludeTag = $ExcludeTag
    }
    Should       = @{
        ErrorAction = 'Continue'
    }
    Output       = @{
        Verbosity = 'Detailed'
    }
    CodeCoverage = @{
        Enabled    = [bool]$CodeCoverage
        OutputPath = $codeCoveragePath
    }
}

$pesterResult = Invoke-Pester -Configuration $pesterConfiguration
if ($CodeCoverage) {
    $pesterResult | Select-Object @{
        Name       = 'CommandsAnalyzed'
        Expression = { $_.CodeCoverage.CommandsAnalyzedCount }
    }, @{
        Name       = 'FilesAnalyzed'
        Expression = { $_.CodeCoverage.FilesAnalyzedCount }
    }, @{
        Name       = 'CommandsExecuted'
        Expression = { $_.CodeCoverage.CommandsAnalyzedCount }
    }, @{
        Name       = 'CommandsMissed'
        Expression = { $_.CodeCoverage.CommandsMissedCount }
    }
}

switch ($PSCmdlet.ParameterSetName) {
    'AppVeyor' {
        (New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", $outputFile)
        if ($pesterResult.FailedCount -gt 0) { 
            throw "$($pesterResult.FailedCount) tests failed."
        }        
    }
    'Console' {

    }
}