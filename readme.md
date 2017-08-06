mazzy@mazzy.ru, 2017-08-06, [https://github.com/mazzy-ax/Write-ProgressEx](https://github.com/mazzy-ax/Write-ProgressEx)

# Write-ProgressEx: extended write-progress cmdlet

![version][version-badge] ![license][license-badge]

**Write-ProgressEx** extend the functionality of the standard powershell cmdlet. It provide a simple way to use -PercentComplete and -SecondsRemaining switches.

The cmdlet:
* works with pipe;
* works with empty activity string;
* automatically displays totals;
* automatically calculate percents;
* uses [system.diagnostic.stopwatch] to calculate remaning seconds;
* completes all inner progresses if no parameters;
* stores totals, current values and actual parameters into the module hashtable;
* provide get/set cmdlets to access actual parameters

Note: the cmdlet is not safe with multi-thread.

## Samples

```powershell
$range1 = 1..20
write-ProgressEx "loop 1" -Total $range1.Count
$range1 | write-ProgressEx -Status "$_" -increment | ForEach-Object {
        # ....
    }
}

$range2 = 1..15
write-ProgressEx "loop 2" -Total $range2.Count
$range2 | ForEach-Object {
        # ....
        write-ProgressEx -Status "$_" -increment
    }
}

write-ProgressEx #close all progress bars
```

Sample with pipe and nested loops:

```powershell
$outer = 1..20
$inner = 1..50

write-ProgressEx "pipe nodes" -Total $outer.Count
$outer | write-ProgressEx -Status "outer" | ForEach-Object {

    write-ProgressEx "pipe names" -Total $inner.Count -id 1
    $inner | write-ProgressEx -id 1 -status "inner" | ForEach-Object {
        # ....
    }

}
write-ProgressEx #close all progress bars
```

![screenshot: Write-ProgressEx](./media/sample.pipe.png)

More samples are in the folder [Samples].

[CHANGELOG.md][Changelog]


[version-badge]: https://img.shields.io/badge/version-0.7-green.svg
[license-badge]: https://img.shields.io/badge/license-MIT-blue.svg
[Samples]: samples/
[Changelog]: CHANGELOG.md