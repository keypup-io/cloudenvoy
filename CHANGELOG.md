# Changelog

## [v0.5.0](https://github.com/keypup-io/cloudenvoy/tree/v0.5.0) (2022-03-11)

[Full Changelog](https://github.com/keypup-io/cloudenvoy/compare/v0.4.2...v0.5.0)

**Improvements:**
- Ruby 3: Rework method arguments to be compatible with Ruby 3
- Tests: Separate test environment for Ruby 2 and Ruby 3
- Tests: Do not load Rails by default and skip Rails-specific tests in non-Rails appraisals

## [v0.4.2](https://github.com/keypup-io/cloudenvoy/tree/v0.4.2) (2021-10-25)

[Full Changelog](https://github.com/keypup-io/cloudenvoy/compare/v0.4.1...v0.4.2)

**Bug fix:**
- Message processing: fix subscription parsing for topic names with dots.

## [v0.4.1](https://github.com/keypup-io/cloudenvoy/tree/v0.4.1) (2020-10-06)

[Full Changelog](https://github.com/keypup-io/cloudenvoy/compare/v0.4.0...v0.4.1)

**Bug fix:**
- Logging: log publisher and subscriber errors during execution
- Rake tasks: fix early return statement when publisher or subscriber list is empty

## [v0.4.0](https://github.com/keypup-io/cloudenvoy/tree/v0.4.0) (2020-10-05)

[Full Changelog](https://github.com/keypup-io/cloudenvoy/compare/v0.3.1...v0.4.0)

**Bug fix:**
- Logging: fix log processing with `semantic_logger` `v4.7.2`. Accept any args on block passed to the logger.

## [v0.3.1](https://github.com/keypup-io/cloudenvoy/tree/v0.3.1) (2020-10-05)

[Full Changelog](https://github.com/keypup-io/cloudenvoy/compare/v0.3.0...v0.3.1)

**Improvements:**
- Development: auto-create topics in development mode when registering subscriptions.

## [v0.3.0](https://github.com/keypup-io/cloudenvoy/tree/v0.3.0) (2020-09-26)

[Full Changelog](https://github.com/keypup-io/cloudenvoy/compare/v0.2.0...v0.3.0)

**Bug fix:**
- Subscriptions: fix creation. `v0.2.0` introduced a bug as part of support subscription options (e.g. `retain_acked`)

## [v0.2.0](https://github.com/keypup-io/cloudenvoy/tree/v0.2.0) (2020-09-22)

[Full Changelog](https://github.com/keypup-io/cloudenvoy/compare/v0.1.0...v0.2.0)

**Improvements:**
- Subscriptions: support creation options such as `retained_acked` and `deadline`

## [v0.1.0](https://github.com/keypup-io/cloudenvoy/tree/v0.1.0) (2020-09-16)
Initial release