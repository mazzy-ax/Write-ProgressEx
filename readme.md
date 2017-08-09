mazzy@mazzy.ru, 2017-08-09, [https://github.com/mazzy-ax/Write-ProgressEx](https://github.com/mazzy-ax/Write-ProgressEx)

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

## [Changelog]

# Samples

```powershell
$range1 = 1..20
$range1 | write-ProgressEx "loop 1" -Total $range1.Count -increment | ForEach-Object {
        # ....
    }
}

$range2 = 1..15
$range2 | ForEach-Object {
        # ....
        write-ProgressEx "loop 2" -Total $range2.Count -increment
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


[version-badge]: https://img.shields.io/badge/version-0.9-green.svg
[license-badge]: https://img.shields.io/badge/license-MIT-blue.svg
[Samples]: /samples
[Changelog]: /CHANGELOG.md