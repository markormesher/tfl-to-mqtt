[![CircleCI](https://img.shields.io/circleci/build/github/markormesher/tfl-to-mqtt)](https://app.circleci.com/pipelines/github/markormesher/tfl-to-mqtt)
[![Releases on GHCR](https://img.shields.io/badge/releases-ghcr.io-green)](https://ghcr.io/markormesher/tfl-to-mqtt)

# TfL to MQTT

This project uses the Transport for London (TfL) API to publish line statuses and disruption details to MQTT. The API exposes other types of information too - PRs to this tool are welcome.


## Configuration

:point_right: See this project's base library, [X to MQTT](https://github.com/markormesher/x-to-mqtt), for configuration reference.

The default update interval is 60 seconds, which is also the minimum interval that can be set to avoid spamming the upstream service. In addition to the base library configuration, the following values must be configured:

- `TFL_APP_KEY` - your TfL app key, which you can sign up for [here](https://api-portal.tfl.gov.uk). See the base library documentation for details on how to provide this as a secret file.
- `LINE_IDS` - comma-separated list of lines for which details should be published, e.g. `elizabeth,northern,central`. To make configuration easier all valid line IDs are published to MQTT under an `api_info` topic - see below.

Note: the TfL API is organised by mode and line (e.g. mode: tube, line: central) and the topics published by this tool reflect this. However, line IDs are unique across modes, so only the line IDs are needed in the configuration.

## MQTT Topics

Lines only have a single status _most_ of the time, but sometimes have more if there are multiple issues affecting them. Indexes below (`i`) start from zero.

- `${prefix}/state/modes/${mode}/lines/${line}/status_${i}/severity` - severity type for the `i`th status value of the given mode and line
- `${prefix}/state/modes/${mode}/lines/${line}/status_${i}/reason` - reason for the `i`th status value of the given mode and line (may be blank)
- `${prefix}/state/modes/${mode}/lines/${line}/status_${i}/disruption_category` - disruption type for the `i`th status value of the given mode and line (may be blank)
- `${prefix}/state/modes/${mode}/lines/${line}/status_${i}/disruption_description` - disruption description for the `i`th status value of the given mode and line (may be blank)

The topics below are published once at startup to provide info about the valid inputs to this tool and the possible outputs.

- `${prefix}/state/api_info/modes/${mode}/lines` - comma-separated list of lines that exist for a given mode. Note that some modes have no lines.
- `${prefix}/state/api_info/modes/${mode}/severities` - comma-separated list of status severities that exist for a given mode. Note that some modes have no values.
- `${prefix}/state/api_info/disruption_categories` - comma-separated list of all disruption categories that exist.

:point_right: See [X to MQTT](https://github.com/markormesher/x-to-mqtt) for other values published under the `${prefix}/_meta` topic, like the upstream service status.
