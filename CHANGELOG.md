# Changelog

## v2.3.5 - 2026-05-28
- Fix for CVE-2026-47074 - lack of verification of SNS message signatures. This is a critical security vulnerability that could allow attackers to forge SNS messages and potentially compromise the integrity of your application. It is highly recommended to update to this version immediately to mitigate the risk of exploitation. Thank you to @PJUllrich and @maennchen for their assistance in identifying and addressing this issue.
- Increase minimum Elixir version to 1.15 and OTP to 26

## v2.3.4 - 2024-09-10
- Update use of `name` to `key` to support both AWS and Localstack

## v2.3.3 - 2023-06-26
- Add `publish_batch` functionality

## v2.3.2 - 2023-01-10
- Make `json_codec` setting optional, defaulting to Jason

## v2.3.1 - 2022-11-28
- Add support for CheckIfPhoneNumberIsOptedOut action
- Add "String.Array" data type support

## v2.3.0 - 2022-05-15
- Increase minimum Elixir verion to 1.10
- Update publish_opts type to support FIFO topics

## v2.2.0 - 2021-12-12
- Add CI, dependabot and auto-formatting
- Fix return type spec on `verify_message`
- Documentation fixes and updates
- Update supervisor child spec format
- Add attributes option for `create_topic`

## v2.1.0 - 2019-11-19
- Add subscription options [via @darksheik]
- Add FilterPolicy to subscription attributes

## v2.0.1 - 2018-10-16

## v2.0
- Major Project Split. Please see the main ExAws repository for previous changelogs.
