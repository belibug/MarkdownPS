﻿$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"
$VerbosePreference="SilentlyContinue"
$newLine=[System.Environment]::NewLine
Describe "New-MDTable" {
    It "-Object is null" {
        Invoke-Command -ScriptBlock {TRY{New-MDTable -Object $null} CATCH{Return $_.FullyQualifiedErrorId}} | Should Be "ParameterArgumentValidationErrorNullNotAllowed,New-MDTable"
    }
}
Describe "New-MDTable without columns" {
    $object=Get-Command New-MDTable |Select-Object Name,CommandType
    It "-NoNewLine not specified" {
        $expected=4
        ((New-MDTable -Object $object) -split [System.Environment]::NewLine ).Length| Should Be $expected
        (($object | New-MDTable) -split [System.Environment]::NewLine ).Length| Should Be $expected
        ((@($object,$object) | New-MDTable)  -split [System.Environment]::NewLine ).Length | Should Be ($expected+1)
    }
    It "-NoNewLine specified" {
        $expected=3
        ((New-MDTable -Object $object -NoNewLine) -split [System.Environment]::NewLine ).Length| Should Be $expected
        (($object | New-MDTable -NoNewLine) -split [System.Environment]::NewLine ).Length| Should Be $expected
        ((@($object,$object) | New-MDTable -NoNewLine)  -split [System.Environment]::NewLine ).Length | Should Be ($expected+1)
    }
}
Describe "New-MDTable with columns" {
    $object=Get-Command New-MDTable 
    $columns=@{
        Name=$null
        CommandType="left"
        Version="center"
        Source="right"
    }
    It "-NoNewLine not specified" {
        $expected=4
        ((New-MDTable -Object $object -Columns $columns) -split [System.Environment]::NewLine ).Length| Should Be $expected
        (($object | New-MDTable -Columns $columns) -split [System.Environment]::NewLine ).Length| Should Be $expected
        ((@($object,$object) | New-MDTable -Columns $columns)  -split [System.Environment]::NewLine ).Length | Should Be ($expected+1)
    }
    It "-NoNewLine specified" {
        $expected=3
        ((New-MDTable -Object $object -Columns $columns -NoNewLine) -split [System.Environment]::NewLine ).Length| Should Be $expected
        (($object | New-MDTable -Columns $columns -NoNewLine) -split [System.Environment]::NewLine ).Length| Should Be $expected
        ((@($object,$object) | New-MDTable -Columns $columns -NoNewLine)  -split [System.Environment]::NewLine ).Length | Should Be ($expected+1)
    }
}

Describe "New-MDTable with ordered hashtable and without columns" {
    $object=[PSCustomObject]@{
        Name = "This should be the first value"
        ZProperty = "This should be in the middle"
        AnotherProperty = "This should be the last value"
    }
    It "-NoNewLine not specified" {
        $expected=4
        ((New-MDTable -Object $object) -split [System.Environment]::NewLine).Length | Should Be $expected
        (($object | New-MDTable) -split [System.Environment]::NewLine).Length | Should Be $expected
        ((@($object, $object) | New-MDTable) -split [System.Environment]::NewLine).Length | Should Be ($expected+1)
    }
    It "-NoNewLine not specified" {
        $expected=3
        ((New-MDTable -Object $object -NoNewLine) -split [System.Environment]::NewLine).Length | Should Be $expected
        (($object | New-MDTable -NoNewLine) -split [System.Environment]::NewLine).Length | Should Be $expected
        ((@($object, $object) | New-MDTable -NoNewLine) -split [System.Environment]::NewLine).Length | Should Be ($expected+1)
    }
    It "Header should be in correct order" {
        $HeaderRegex = "^\|\s([\w\d]+)\s*\|\s([\w\d]+)\s*\|\s([\w\d]+)\s*\|$"
        $expectedHeader = ($object.PsObject.Members | Where-Object {$_.MemberType -eq "NoteProperty"})[0..2].Name
        (((New-MDTable -Object $object) -split [System.Environment]::NewLine)[0]) -match $HeaderRegex
        $Matches[1..3] | Should Be $expectedHeader

        ((($object | New-MDTable) -split [System.Environment]::NewLine)[0]) -match $HeaderRegex
        $Matches[1..3] | Should Be $expectedHeader

        (((@($object, $object) | New-MDTable) -split [System.Environment]::NewLine)[0]) -match $HeaderRegex
        $Matches[1..3] | Should Be $expectedHeader
    }
}

Describe "New-MDTable with ordered columns" {
    $object=Get-Command New-MDTable 
    $columns=[ordered]@{
        Name=$null
        CommandType="left"
        Version="center"
        Source="right"
    }
    It "Test column header sequence" {
        $rows=(New-MDTable -Object $object -Columns $columns) -split [System.Environment]::NewLine 
        $elements=$rows[0] -split '\|'
        $elements.Count | Should Be 6
        $elements[0].Length | Should Be 0
        $elements[1] | Should  Match "Name"
        $elements[2] | Should  Match "CommandType"
        $elements[3] | Should  Match "Version"
        $elements[4] | Should  Match "Source"
        $elements[5].Length | Should Be 0
    }
    It "Test column alignment " {
        $rows=(New-MDTable -Object $object -Columns $columns) -split [System.Environment]::NewLine 
        $elements=$rows[1] -split '\|'
        
        $elements.Count | Should Be 6
        $elements[0].Length | Should Be 0
        $elements[1] | Should  Match " -* "
        $elements[2] | Should  Match " -* "
        $elements[3] | Should  Match ":-*:"
        $elements[4] | Should  Match " -*:"
        $elements[5].Length | Should Be 0
    }
}