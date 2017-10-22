mazzy@mazzy.ru, 2017-10-22, [https://github.com/mazzy-ax/Write-ProgressEx](https://github.com/mazzy-ax/Write-ProgressEx)

# Changelog

All notable changes to this project will be documented in this file.

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
* Tests with tag build added. It need to run and test exapmles.

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
* Exapmles and Readme

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

* Minor improvements with useage of parameter storage $ProgressEx
* The function Complete-progressAndChildren refactored

## [v0.7](https://github.com/mazzy-ax/Write-ProgressEx/compare/v0.6...v0.7) - 2017-08-06

### Main goal

* Move parmeter storage from a global to a module scope
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

