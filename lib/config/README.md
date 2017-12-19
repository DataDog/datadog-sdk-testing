# Skeleton Integration

## Overview

Get metrics from skeleton service in real time to:

* Visualize and monitor skeleton states
* Be notified about skeleton failovers and events.

## Setup
### Installation

Install the `dd-check-skeleton` package manually or with your favorite configuration manager

### Configuration

Edit the `skeleton.yaml` file to point to your server and port, set the masters to monitor

### Validation

When you run `datadog-agent info` you should see something like the following:

    Checks
    ======

        skeleton
        -----------
          - instance #0 [OK]
          - Collected 39 metrics, 0 events & 7 service checks

## Compatibility

The skeleton check is compatible with all major platforms

## Data Collected
### Metrics

See [metadata.csv](https://github.com/DataDog/datadog-sdk-testing/blob/master/lib/config/metadata.csv) for a list of metrics provided by this integration.

### Events
The skeleton check includes the following event at this time.

* skeleton event 1
* skeleton event foo

### Service Checks
This skeleton check tags all service checks it collects with:

  * `nameserver:<nameserver_in_yaml>`
  * `resolved_hostname:<hostname_in_yaml>`
  
`skeleton.can_resolve`:
Returns CRITICAL if the Agent fails to resolve the request, otherwise returns UP.

## Troubleshooting
Need help? Contact [Datadog Support](http://docs.datadoghq.com/help/).

## Further Reading
Learn more about infrastructure monitoring and all our integrations on [our blog](https://www.datadoghq.com/blog/)
