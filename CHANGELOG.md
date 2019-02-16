# posh-cargo Release History

## 0.1.2 - 2019-02-16

- Fixed a problem where completion for built-in subcommands did not work properly. (#1)
- Fixed an issue where invisible errors accumulate on completion. (#2)

Thanks @GNQG for your contribution.

- Update required PowerShell version to 4.1.0
  - Modules that require earlier version than 4.1.0 cannot be published to PowerShell Gallary.

## 0.1.1 - 2017-08-23

- Fix typos of '--tests' option
- Add autocompletion for the '--explain' option
- Add '--no-fail-fast' option for 'bench' command
  - See: <https://github.com/rust-lang/cargo/pull/4248>

## 0.1.0 - 2017-08-02

- First release
