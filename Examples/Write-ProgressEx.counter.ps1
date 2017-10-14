# mazzy@mazzy.ru, 2017-10-14
# https://github.com/mazzy-ax/write-progressEx

$me = Split-Path -Leaf $PSCommandPath
$path = Split-Path -Parent $PSCommandPath
$module = Join-Path (Split-Path -Parent $path) "Write-ProgressEx.psd1"
Import-Module -Force $module

Get-ChildItem (Join-Path $path Write-ProgressEx.*.ps1) | write-ProgressEx -id 0 "files in Exapmle directory" -ShowMessages | ForEach-Object {
    # ....
    If ( $_.Name -notmatch '\.Tests\.ps1' ) {
        Write-ProgressEx "Examples" -Increment -id 1 -ParentId -1 -NoProgressBar -MessageOnEnd {param([hashtable]$pInfo) "$($pInfo.Activity): $($pInfo.Current)"}
    }
}
Write-ProgressEx -id 1 -Completed
