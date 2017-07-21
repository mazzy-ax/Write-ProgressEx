# Write-ProgressEx: extended write-progress cmdlet
mazzy@mazzy.ru, 21.07.2017, [https://github.com/mazzy-ax/Write-ProgressEx](https://github.com/mazzy-ax/Write-ProgressEx)



**Write-ProgressEx** extend the functionality of the standard powershell cmdlet. It provide a simple way to use -PercentComplete and -SecondsRemaining switches.

The cmdlet:
* works with pipe;
* works with empty activity string;
* automatically displays totals;
* completes all inner progresses if no parameters;
* stores totals and a current values into the global array;
* uses [system.diagnostic.stopwatch] to calculate remaning seconds;

NOTE: the cmdlet is not safe with multi-thread.

![screenshot: Write-ProgressEx](./media/sample.pipe.png)

Sample:
```powershell
$outer = 1..20
$inner = 1..50

write-ProgressEx "pipe nodes" -Total $outer.Count
$outer | write-ProgressEx -Status "outer $_" -increment | ForEach-Object {
    write-ProgressEx "pipe names" -Total $inner.Count -id 1
    $inner | write-ProgressEx -id 1 -increment -status "inner $_" | ForEach-Object {
        # ....
    }
}
write-ProgressEx #close all progress bars

