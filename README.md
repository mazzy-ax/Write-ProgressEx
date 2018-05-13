# Write-ProgressEx &ndash; extended write-progress cmdlet

[project]:https://github.com/mazzy-ax/Write-ProgressEx
[license]:https://github.com/mazzy-ax/Write-ProgressEx/blob/master/LICENSE
[ps]:https://www.powershellgallery.com/packages/Write-ProgressEx
[nuget]:https://www.nuget.org/packages/Write-ProgressEx

[version.svg]:https://img.shields.io/badge/version-0.20-green.svg
[license.svg]:https://img.shields.io/badge/license-MIT-blue.svg
[ps.svg]:https://img.shields.io/badge/Powershell-Gallery-4682B4.svg
[nuget.svg]:https://img.shields.io/badge/downloads-NuGet-orange.svg

[![version][version.svg]][project] [![license MIT][license.svg]][license] [![PowerShell Gallery][ps.svg]][ps] [![NuGet][nuget.svg]][nuget]

[Write-ProgressEx][project] extends the functionality of the standard powershell cmdlet. Write-ProgressEx is a powershell native cmdlet that provides a simple way to show ProgressBars with PercentComplete and SecondsRemaining.

![Write-ProgressEx icon](Media/Write-ProgressEx-icon.png "Write-ProgressEx")

The cmdlet:

* works with pipe;
* works with empty activity string;
* completes all inner progresses if no parameters;
* automatically completes with pipe;
* automatically calculates percents, remaining seconds and elapsed time;
* automatically displays current iteration and totals on progress bar;
* automatically set parent id for a inner loop;
* stores totals, current values and actual parameters into the module hashtable;
* provides get/set cmdlets to access actual parameters;
* uses script blocks to show messages with date, time, iterations and elapsed time on events:
  * first iteration;
  * activity changed;
  * status changed;
  * completed.
* provides a counter functional. See [Write-ProgressEx as a counter](Examples/Write-ProgressEx.counter.ps1);
* uses the caller function name or the caller script file name as the Activity;
* accepts `-ShowProgressBar Auto` parameter to reduce the overhead for redrawing a screen. It recognizes `None` and `Force` values also.

Note: the cmdlet is not safe with multi-thread.

## Examples

A pipe and a simple loop:

```powershell
$range1 = 1..20
$range1 | Write-ProgressEx "loop 1" -Total $range1.Count -ShowMessages | ForEach-Object {
    # ....
}

$range2 = 1..15
$range2 | ForEach-Object {
    # ....
    Write-ProgressEx "loop 2" -Total $range2.Count -Increment
}

Write-ProgressEx #close all progress bars
```

Pipes in nested loops:

```powershell
$outer = 1..20
$inner = 1..50

$outer | Write-ProgressEx "pipe nodes" -Status "outer" -Total $outer.Count -ShowMessages | ForEach-Object {
    $inner | Write-ProgressEx "pipe names" -id 1 -Status "inner" -Total $inner.Count | ForEach-Object {
        # ....
    }
}
```

![screenshot: Write-ProgressEx](Media/examples.pipe.png)

![screenshot: Result messages](Media/examples.messages.png)

A long time command:

```powershell
$files = Get-ChildItem $env:homepath -recurse | Write-ProgressEx -Activity $env:homepath
```

More samples are in the folder [Examples](Examples).

## Installation

Automatic install Write-ProgressEx module from the [PowerShell Gallery][ps]:

```powershell
Install-Module -Name Write-ProgressEx
Import-Module Write-ProgressEx
```

Automatic install Write-ProgressEx module from the [NuGet.org][nuget]:

```powershell
Install-Package -Name Write-ProgressEx
Import-Module Write-ProgressEx
```

or manual:

* Download and unblock the latest .zip file.
* Extract the .zip into your `$PSModulePath`, e.g. `~\Documents\WindowsPowerShell\Modules`.
* Ensure the extracted folder is named `Write-ProgressEx`.
* Set an execution policy to `RemoteSigned` or `Unrestricted` to execute not signed modules `Set-ExecutionPolicy RemoteSigned`.
* Run `Import-Module Write-ProgressEx`.

## Changelog

* [CHANGELOG.md](CHANGELOG.md)
* <https://github.com/mazzy-ax/Write-ProgressEx/releases>.

## License

This project is [licensed under the MIT License][license].

mazzy@mazzy.ru