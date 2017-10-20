# mazzy@mazzy.ru, 2017-10-21
# https://github.com/mazzy-ax/write-progressEx

#requires -version 3.0

$me = $PSCommandPath | Split-Path -Leaf
$path = $PSCommandPath | Split-Path -Parent
$module = $path | Split-Path -Parent | Join-Path -ChildPath "Write-ProgressEx.psd1"
Import-Module -Force $module


1..500 | write-ProgressEx | ForEach-Object {
    # The progress name is equal to the script file name
}

function test-range {
    1..500 | write-ProgressEx | ForEach-Object {
        # The progress name is equal to the function name
    }
}

test-range