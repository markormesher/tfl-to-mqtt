[![CircleCI](https://img.shields.io/circleci/build/github/markormesher/tfl-to-mqtt)](https://app.circleci.com/pipelines/github/markormesher/tfl-to-mqtt)
[![Releases on GHCR](https://img.shields.io/badge/releases-ghcr.io-green)](https://ghcr.io/markormesher/tfl-to-mqtt)

# TfL to MQTT

This project uses the Transport for London (TfL) API to publish line statuses and disruption details to MQTT. The API exposes other types of information that this project doesn't publish - PRs are welcome.

## Configuration

Configuration is via environment variables:

- `MQTT_CONNECTION_STRING` - MQTT connection string, including protocol, host and port (default: `mqtt://0.0.0.0:1883`).
- `MQTT_TOPIC_PREFIX` - topix prefix (default: `tfl`).
- `UPDATE_INTERVAL` - interval in seconds for updates; if this is <= 0 then the program will run once and exit (default: `0`).
- `TFL_APP_KEY` - your TfL app key, which you can sign up for [here](https://api-portal.tfl.gov.uk).
- `LINE_IDS` - comma-separated list of lines for which details should be published, e.g. `elizabeth,northern,central`.
- `GET_API_INFO` - set this to any non-empty value while you're setting up this tool to publish API metadata (see below) instead of line statsues.

## MQTT Topics

If `LINE_IDS` has been configured:

- `${prefix}/_meta/last_seen` - RFC3339 timestamp of when the program last ran.
- `${prefix}/state/lines/${line}/status_${i}/severity` - severity type for the `i`th status value of the given mode and line
- `${prefix}/state/lines/${line}/status_${i}/reason` - reason for the `i`th status value of the given mode and line (may be blank)
- `${prefix}/state/lines/${line}/status_${i}/disruption_category` - disruption type for the `i`th status value of the given mode and line (may be blank)
- `${prefix}/state/lines/${line}/status_${i}/disruption_description` - disruption description for the `i`th status value of the given mode and line (may be blank)

`i` will range from 1 to 5. Usually only status 1 will be populated and all others will be blank, but see the note below about multiple statuses.

If `GET_API_INFO` has been set:

- `${prefix}/state/api_info/modes/${mode}/lines` - comma-separated list of lines that exist for a given mode. Note that some modes have no lines.
- `${prefix}/state/api_info/modes/${mode}/severities` - comma-separated list of status severities that exist for a given mode. Note that some modes have no values.
- `${prefix}/state/api_info/disruption_categories` - comma-separated list of all disruption categories that exist.

## TfL API Quirks

- The TfL API is organised by _mode_ and _line_ (e.g. line "central" within mode "tube", or line "109" within mode "bus"), which is reflected in the `api_info` topics. However, line IDs are globally unique, so status information is requested and returned with only the line ID.
- Lines only have one status _most_ of the time, but in two cases they may have multiple:
  - Different sections of the same line can have separate statuses published for them.
  - TfL will sometimes publish two or tree almost-identical statuses for a line. This tool doesn't try to deduplicate them, so you will need to do that.
