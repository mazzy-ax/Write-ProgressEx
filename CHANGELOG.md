# Changelog

All notable changes to the [project](https://github.com/mazzy-ax/Write-ProgressEx) will be documented in this file.
See also <https://github.com/mazzy-ax/Write-ProgressEx/releases>.

## [v0.21](https://github.com/mazzy-ax/Write-ProgressEx/compare/v0.20...v0.21)

* 

## [v0.20](https://github.com/mazzy-ax/Write-ProgressEx/compare/v0.19...v0.20) - 2018-05-13

* [System.Diagnostics.Stopwatch]$Stopwatch replaced on [DateTime]$StartDateTime and [TimeSpan]$Elapsed
* parameters removed:
  * `NoProgressBar`
* parameters added:
  * `ShowProgressBar` with `Auto`, `Force` and `None` values
  * `StartDateTime`
  * `ProgressDateTime`
  * `Elapsed`
  * `UpdateDateTime`
  * `UpdateInterval`
* fixed due changed parameters:
  * Get-ProgressEx, Set-ProgressEx, Write-ProgressEx cmdlets
  * examples
  * messages
* reamde and comments updated

## [v0.19](https://github.com/mazzy-ax/Write-ProgressEx/compare/v0.18...v0.19) - 2018-05-06

* The switch `Reset` added to `Write-ProgressEx` cmdlet.
* Deep refactoring in the cmdlet `Set-ProgressEx`.
* `On completed message` clarified.
* The directive `#require -module Write-ProgressEx` added to example scripts.
* Splatting example added.
* Examples and tests cleanup.
* Readme changed.

## [v0.18](https://github.com/mazzy-ax/Write-ProgressEx/compare/v0.17...v0.18) - 2018-05-06

* The function `Set-ProgressEx` fixed.
* The example `Write-ProgressEx.autoName.ps1` fixed.
* The cmdlet `Set-StrictMode` removed from project scripts.
* The directive `#require -version 3.0` removed from project scripts.
* The function `nz` extracted from `Write-ProgressExMessage`.
* The `chocolateyInstall.ps1` removed.
* The directory structure reorganized to remove media, examples and tests from nuget downloads and powershell gallery.
* The project meta info tests added.
* Tests fixed.
* Readme changed.
* Typo corrected.

## [v0.17](https://github.com/mazzy-ax/Write-ProgressEx/compare/v0.16...v0.17) - 2017-11-06

* The main goal is a code housekeeping and refactoring
* The internal function Write-ProgressExStd removed. It was not exported function.
* It has refactoring of Cmdlets
  * Set-ProgressEx show standard progress bar as is. This cmdlet does not make a changing of parameters.
  * Write-Progress maintains parameters and switches. It calculates RemainSeconds, PercentComplete, increment Current value, passthru InputValue. It call Set-ProgressEx to show standard progress bar and messages.

## [v0.16](https://github.com/mazzy-ax/Write-ProgressEx/compare/v0.15...v0.16) - 2017-10-27

* The cmdlet uses an array of scriptblocks for each event instead a scriptblock
* NoProgressBar error fixed

## [v0.15](https://github.com/mazzy-ax/Write-ProgressEx/compare/v0.14...v0.15) - 2017-10-22

* Message scriptblocks should display message instead return message string
* The region block for module variables added

## [v0.14](https://github.com/mazzy-ax/Write-ProgressEx/compare/v0.13...v0.14) - 2017-10-21

* The autoname functionality added: If user does not specify an Activity parameter, the Write-ProgressEx display the caller function name or the caller script file name as the Activity.
* A pipe with empty arg list fixed
* Events renamed

## [v0.13](https://github.com/mazzy-ax/Write-ProgressEx/compare/v0.12...v0.13) - 2017-10-14

### Added

* Example 'counter' demonstrate how to use [Write-ProgressEx cmdlet as counter](Examples/Write-ProgressEx.counter.ps1).
* Tests with tag build added. It need to run and test examples.

### Changed

* Message templates are scriptblock now
* Cmdlet show warning messages instead write to a host
* The total grow if the current pass over the total
* The total parameter is integer only. Yes, again. Sorry, a runtime checking is not comfortable for XML, files and other iterable ranges
* chocolateyInstall.ps1 moved to the [Tools](Tools/) directory

## [v0.12.1](https://github.com/mazzy-ax/Write-ProgressEx/compare/v0.12...v0.12.1) - 2017-10-10

* SecondsRemaining calculation fixed
* Screenshot with Result text fixed

## [v0.12](https://github.com/mazzy-ax/Write-ProgressEx/compare/v0.11...v0.12) - 2017-10-10

### Main goal

* Provide information about total iterations, elapsed time, start time, end time
* Provide template functionality to change information messages

### Added

* The ShowMessages switch
* The in-module cmdlet Write-ProgressExMessage to show event messages
* Event Messages: onBegin, onNewActivity, onNewStatus, onEnd.
* The NoProgressBar switch
* The in-module cmdlet Write-ProgressExStd to call standard cmdlet Write-Progress
* The Total parameter accept a integer and an array

### Changed

* The Current can be more then Total. It's used to make iterations when Total is not known.
* The Stopwatch redesigned: stopwatch start with first iterations. The messages uses the stopwatch to display a total elapsed time
* The module icon
* Examples and Readme

### Removed

* Iterations parameter
* Export module members in Write-ProgressEx.psm1. Module members exported by psd1-file only

## [v0.11](https://github.com/mazzy-ax/Write-ProgressEx/compare/v0.10...v0.11) - 2017-10-03

* The icon added
* FunctionsToExport fixed
* Begin and End messages added

## [v0.10](https://github.com/mazzy-ax/Write-ProgressEx/compare/v0.9...v0.10) - 2017-08-25

* Autocomplete with pipe
* Add autocomplete with pipe test
* Examples readme
* Module name First letter capitalized
* Requires version 4.0

## [v0.9](https://github.com/mazzy-ax/Write-ProgressEx/compare/v0.8...v0.9) - 2017-08-09

* Samples simplified
* Cancel stopwatch if -SecondsRemaining parameter specified

## [v0.8](https://github.com/mazzy-ax/Write-ProgressEx/compare/v0.7...v0.8) - 2017-08-08

* Minor improvements with usage of parameter storage $ProgressEx
* The function Complete-progressAndChildren refactored

## [v0.7](https://github.com/mazzy-ax/Write-ProgressEx/compare/v0.6...v0.7) - 2017-08-06

### Main goal

* Move parameter storage from a global to a module scope
* Provide a developer with functional to get/set actual parameters
* Provide a developer with a splatting
* Clarify and split logic to calculate progress parameters and logic to store its

### Added

* Change log
* Get-ProgressEx, Set-ProgressEx cmdlets
* Parameter Stopwatch added to Write-ProgressEx cmdlet
* A developer may use splatting with Write-ProgressEx using Get-ProgressEx
* A couple file with samples

### Changed

* Global variable ProgressExInfo moved to the module scope
* Storage type changed from array to hashtable
* Activity show current/total instead totals only
* Minor reorganize within Write-ProgressEx parameter calculation
* Mass refactoring of unit tests
* Samples moved to special catalog
* ISO 8601 date format used (YYYY-MM-DD)

### Removed

* $Global:ProgressExInfo
