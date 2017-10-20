# mazzy@mazzy.ru, 2017-10-21
# https://github.com/mazzy-ax/write-progressEx

#requires -version 3.0

$me = $PSCommandPath | Split-Path -Leaf
$path = $PSCommandPath | Split-Path -Parent
$module = $path | Split-Path -Parent | Join-Path -ChildPath "Write-ProgressEx.psd1"
Import-Module -Force $module

$path | Join-Path -ChildPath Write-ProgressEx.*.ps1 | Get-ChildItem | write-ProgressEx -id 0 "files in Exapmle directory" -ShowMessagesOnCompleted -NoProgressBar | ForEach-Object {
    # ....
    If ( $_.Name -notmatch '\.Tests\.ps1' ) {
        Write-ProgressEx "Examples" -Increment -id 1 -ParentId -1 -NoProgressBar -MessageOnCompleted {param([hashtable]$pInfo) "$($pInfo.Activity): $($pInfo.Current)"}
    }
}
Write-ProgressEx -id 1 -Completed
