
mazzy@mazzy.ru, 2017-08-25, [https://github.com/mazzy-ax/Write-ProgressEx](https://github.com/mazzy-ax/Write-ProgressEx)

# Changelog

All notable changes to this project will be documented in this file.

## [v0.10] - 2017-08-25

- Autocomplete with pipe
- Add autocomplete with pipe test
- Samples readme[!!!]
- Module name First letter capitalized
- Requires version 4.0

## [v0.9] - 2017-08-09

- Samples simplified
- Cancel stopwatch if -SecondsRemaining parameter specified

## [v0.8] - 2017-08-08

- Minor improvements with useage of parameter storage $ProgressEx
- The function Complete-progressAndChildren refactored

## [v0.7] - 2017-08-06

### Main goal

- Move parmeter storage from a global to a module scope
- Provide a developer with functional to get/set actual parameters
- Provide a developer with a splatting
- Clarify and split logic to calculate progress parameters and logic to store its

### Added

- Change log
- Get-ProgressEx, Set-ProgressEx cmdlets
- Parameter Stopwatch added to Write-ProgressEx cmdlet
- A developer may use splatting with Write-ProgressEx using Get-ProgressEx
- A couple file with samples

### Changed

- Global variable ProgressExInfo moved to the module scope
- Storage type changed from array to hashtable
- Activity show current/total instead totals only
- Minor reorganize within Write-ProgressEx parameter calculation
- Mass refactoring of unit tests
- Samples moved to special catalog
- ISO 8601 date format used (YYYY-MM-DD)

### Removed

- $Global:ProgressExInfo

[v0.10]: https://github.com/mazzy-ax/Write-ProgressEx/compare/v0.9...v0.10
[v0.9]: https://github.com/mazzy-ax/Write-ProgressEx/compare/v0.8...v0.9
[v0.8]: https://github.com/mazzy-ax/Write-ProgressEx/compare/v0.7...v0.8
[v0.7]: https://github.com/mazzy-ax/Write-ProgressEx/compare/v0.6...v0.7