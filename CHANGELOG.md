## Unreleased
[no unreleased changes yet]

## v0.19.1 (2023-05-30)
### Changed
- Move from Memoist to MemoWise

## v0.19.0 (2023-05-20)
### Added
- Release gem via RubyGems.

## v0.18.0 (2023-05-20)
### Breaking Changes
- Change project name from "ActiveActions" to "RungerActions"

## v0.17.1 (2021-03-23)
### Fixed
- Remove no-longe-accurate claim in README.md that `shaped` must be listed in apps' `Gemfile`s

## v0.17.0 (2021-02-17)
### Added
- Allow setting `error_message` on the result object when invoking a `fails_with` case

### Maintenance
- Specify Ruby 3.0.0 for gem development

## v0.16.1 (2021-02-13)
### Docs
- Fix README.md typo (change `requires` to `returns`)

## v0.16.0 (2021-02-01)
### Dependencies
- Bump `shaped` from 0.7.0 to 0.8.0

## v0.15.1 (2021-01-28)
### Fixed
- Mention the correct class (the action class rather than the result class) in error messages when
  invoking a failure condition when executing via `run!`

## v0.15.0 (2021-01-28)
### BREAKING CHANGES
- Change the behavior of the `#run!` instance method to also raise an error if any failure
  conditions (i.e. failures set via a `fails_with` case) occur during the execution of the action.
  (Previously, `#run!` would only raise if any of the initialization params were invalid.)

### Added
- Add `::new!` and `::run!` class methods for actions

## v0.14.2 (2021-01-26)
### Dependencies
- Bump `release_assistant` to `0.1.1.alpha`

## v0.14.1 (2021-01-26)
### Internal
- Move CI from Travis to GitHub Actions
- Ensure in PR CI runs that the current version contains "alpha", that there's no git diff (e.g. due
  to failing to run `bundle` after updating the version), and that there is an "Unreleased" section
  in `CHANGELOG.md`
- Use `release_assistant` gem to manage the release process

## v0.14.0 (2021-01-21)
### Added
- Add Rails generator (e.g. `bin/rails g runger_actions:action Users::Create`)

## v0.13.3 (2020-07-02)
### Internal
- Source Rubocop rules/config from `runger_style` gem

## v0.13.2 (2020-06-24)
### Dependencies
- Bump `shaped` from 0.6.4 to 0.7.0

## v0.13.1 (2020-06-22)
### Docs
- List some alternatives
- Add detail about the project status/context

## v0.13.0 (2020-06-22)
### Dependencies
- Bump `shaped` from 0.6.3 to 0.6.4

## v0.12.0 (2020-06-22)
### Changed
- Source `shaped` from RubyGems

### Docs
- Add more badges to README.md (Dependabot; GitHub tag/version)

## v0.11.0 (2020-06-21)
### Fixed
- Only check for promised return values if the action is successful

## v0.10.2 (2020-06-20)
### Docs
- Add Travis build status badge to README.md

## v0.10.1 (2020-06-20)
### Docs
- Add example of controller code using an action
- Add a table of contents to README.md
- Simplify README.md action example by removing check for NEXMO_API_KEY
- Illustrate `returns` in README.md example
- Add more detailed documentation/examples to README.md

## 0.10.0 (2020-06-19)
### Added
- Validate (at the time of assignment to the `result`) the "shape" of all `returns`ed result values

### Changed
- Tweaked the wording/formatting of some validation failure error messages.

## v0.9.0 (2020-06-19)
### Dependencies
- Bump `shaped` from 0.5.8 to 0.6.0

## v0.8.1 (2020-06-19)
### Dependencies
- Bump `shaped` from 0.5.0 to 0.5.8

## v0.8.0 (2020-06-19)
### Added
- Bump `shaped` from 0.4.0 to 0.5.0, which adds support for a new `Shaped::Shape::Callable` shape
  description, so you can now do something like this:

```rb
class ProcessOrder < ApplicationAction
  # allow ordering only 2, 4, or 6 widgets
  requires :number_of_widgets, ->(num) { num.is_a?(Integer) && (2..6).cover?(num) && num.even? }
  # [...]
end
```

## v0.7.0 (2020-06-18)
### Added
- Bump `shaped` from 0.3.2 to 0.4.0, which adds support for ActiveModel-style validations of
  `Shaped::Shape::Class` shapes. So now you can do something like this:

```rb
class ProcessOrder < ApplicationAction
  requires :number_of_widgets, Integer, numericality: { greater_than: 0, less_than: 1_000 }
  # [...]
end
```

## v0.6.1 (2020-06-18)
### Maintenance
- Add test coverage reporting (via `codecov` and `simplecov`)

### Tests
- Add test for `Result#success?`

## v0.6.0 (2020-06-18)
### Breaking changes
- Update `shaped` (which is used for param validation) from version 0.2.1 to 0.3.0, which has
  breaking changes. For more details, see the [`shaped`
  changelog](https://github.com/davidrunger/shaped/blob/master/CHANGELOG.md#030---2020-06-18).
- For `requires`, _all_ type/shape descriptions (i.e. arguments `[1..]`) are now passed through the
  `Shaped::Shape(...)` constructor method. (In most cases, this change will not have any effect,
  because in most cases the type/shape description was a single class, and this change has no effect
  in that case.)

## 0.5.1 - 2020-06-16
### Docs
- Mention in README.md that `shaped` needs to be installed explicitly/manually as a dependency in the user's own
  `Gemfile`.

## 0.5.0 - 2020-06-16
### Added
- Use [`shaped`](https://github.com/davidrunger/shaped/) gem to describe the shape of Hahes and
  Arrays

## 0.4.0 - 2020-06-16
### Added
- Raise an `RungerActions::MissingResultValue` error if a promised return value (as declared via the
  `returns` class method on the action) has not been set by the action's `#execute` method.

## 0.3.1 - 2020-06-16
### Fixed
- Don't raise an error when running an action that doesn't have any `requires` / input params

## 0.3.0 - 2020-06-15
### Added
- Add `RungerActions::Base#run!` method that will raise `RungerActions::InvalidParam` if there are
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
- Initial release of RungerActions! Organize and validate the business logic of your Rails
  application with this combined form object / command object.
