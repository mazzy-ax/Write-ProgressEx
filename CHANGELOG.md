# Changelog

mazzy@mazzy.ru, 2017-08-06, [https://github.com/mazzy-ax/Write-ProgressEx](https://github.com/mazzy-ax/Write-ProgressEx)

All notable changes to this project will be documented in this file.

## [v0.7.0] - 2017-08-06

### Main target

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
