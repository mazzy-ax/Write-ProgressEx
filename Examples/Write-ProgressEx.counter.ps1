$projectRoot = Resolve-Path $PSScriptRoot\..

$projectRoot | Join-Path -ChildPath Write-ProgressEx.*.ps1 | Get-ChildItem | write-ProgressEx -id 0 "files in Exapmle directory" -ShowMessagesOnCompleted -NoProgressBar | ForEach-Object {
    # ....
    If ( $_.Name -notmatch '\.Tests\.ps1' ) {
        Write-ProgressEx "Examples" -Increment -id 1 -ParentId -1 -NoProgressBar -MessageOnCompleted {param([hashtable]$pInfo) Write-Warning "$($pInfo.Activity): $($pInfo.Current)"}
    }
}
Write-ProgressEx -id 1 -Completed
