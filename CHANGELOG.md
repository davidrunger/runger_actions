## Unreleased
### Docs
- Mention in README.md that `shaped` needs to be installed explicitly/manually as a dependency in the user's own
  `Gemfile`.

## 0.5.0 - 2020-06-16
### Added
- Use [`shaped`](https://github.com/davidrunger/shaped/) gem to describe the shape of Hahes and
  Arrays

## 0.4.0 - 2020-06-16
### Added
- Raise an `ActiveActions::MissingResultValue` error if a promised return value (as declared via the
  `returns` class method on the action) has not been set by the action's `#execute` method.

## 0.3.1 - 2020-06-16
### Fixed
- Don't raise an error when running an action that doesn't have any `requires` / input params

## 0.3.0 - 2020-06-15
### Added
- Add `ActiveActions::Base#run!` method that will raise `ActiveActions::InvalidParam` if there are
  any ActiveRecord params provided to the action that fail any validation(s) specified for that
  param. This can be used as an (error-raising) alternative to manually checking `action.valid?`.

## 0.2.2 - 2020-06-15
### Added
- Prevent mutating a returned `result` from outside of the action

### Maintenance
- Don't install a specific `bundler` version in Travis
- Run tests on Travis via `bin/rspec` (rather than (implicitly) via `bundle exec rake`)
- Run rubocop in Travis

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
