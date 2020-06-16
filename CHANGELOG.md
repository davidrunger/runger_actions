## Unreleased
### Added
- Prevent mutating a returned `result` from outside of the action

### Maintenance
- Don't install a specific `bundler` version in Travis

## 0.2.1 - 2020-06-15
### Added
- Raise an explicit error if action class fails to implement #execute

## 0.2.0 - 2020-06-15
### Added
- Add stricter type validations and better error messages for type validation failures
- Add support for arrays of allowed classes (rather than only allowing a single allowed class type
  to be specified)

### Maintenance
- Only send Travis notifications when builds fail (not when they pass)
- Specify Ruby 2.7.0 (not 2.7.1)
- Specify `os: linux` for Travis
- Specify `dist: bionic` for Travis

## 0.1.3 - 2020-06-14
### Fixed
- Allow #result to return a result even w/o any returns or fails_with

## 0.1.2 - 2020-06-14
### Fixed
- Create reader methods on `Result` object for `returns`ed values

## 0.1.1 - 2020-06-14
### Docs
- Add usage instructions (including code example) to README.md and make other tweaks to README.md.

### Maintenance
- Add `bin/release` executable

### Refactor
- Autocorrect all autocorrectable rubocop violations

## 0.1.0 - 2020-06-14
- Initial release of ActiveActions! Organize and validate the business logic of your Rails
  application with this combined form object / command object.
