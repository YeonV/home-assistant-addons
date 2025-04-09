# mDNS Advertiser Add-on Documentation

This document describes the configuration options for the mDNS Advertiser Home Assistant add-on.

## Configuration

Configuration is done via the **Configuration** tab on the add-on page in the Home Assistant UI. Options are specified in YAML format.

### Option: `interface`

*   **Type**: `string`
*   **Required**: Yes
*   **Default**: `"eth0"`
*   **Description**: The network interface name on the Home Assistant host system onto which the mDNS service advertisements should be published. This should typically be the interface connected to your main network where discovery clients (like LedFx) reside. You can usually find interface names using the Home Assistant CLI (`ha network info`) or by inspecting system logs/network settings.

### Option: `update_interval`

*   **Type**: `integer`
*   **Required**: No
*   **Default**: `300`
*   **Description**: The interval, in seconds, at which the add-on queries the Home Assistant API for device states and republishes the mDNS advertisements. Minimum value is 60 seconds.

### Option: `log_level`

*   **Type**: `string`
*   **Required**: No
*   **Default**: `"info"`
*   **Description**: Sets the logging verbosity for the add-on. Valid options are: `trace`, `debug`, `info`, `notice`, `warning`, `error`, `fatal`.

### Option: `services`

*   **Type**: `list`
*   **Required**: Yes
*   **Description**: A list of service advertisement rules. Each rule defines a set of Home Assistant entities to advertise and how to advertise them. You must define at least one service rule.

    Each item in the `services` list is an object with the following keys:

    *   **`name`** (`string`, required): A user-friendly name for this advertising rule (e.g., "WLED Devices", "ESPHome Sensors"). Used primarily for logging.
    *   **`enabled`** (`boolean`, optional, default: `true`): Set to `false` to temporarily disable this specific rule without removing it.
    *   **Filtering Options** (Choose **one**):
        *   **`ha_integration`** (`string`, optional): Filter entities based on the integration that provides them. This relies on the entity having an `integration` attribute, which may not always be present or accurate. Example: `"wled"`.
        *   **`ha_domain`** (`string`, optional): Filter entities based on their domain (the part before the dot in the entity ID). Example: `"light"`, `"sensor"`.
        *   **`ha_entity_pattern`** (`string`, optional): Filter entities whose entity ID matches a simple prefix pattern. *Note: Currently implements basic prefix matching only.* Example: `"light.wled_"` would match `light.wled_living_room`.
    *   **`service_type`** (`string`, required): The mDNS service type to advertise (e.g., `"_wled._tcp"`, `"_esphomelib._tcp"`).
    *   **`service_port`** (`integer`, required): The network port number associated with the service (e.g., `80` for WLED HTTP, `6053` for ESPHome native API). Must be between 1 and 65535.
    *   **`ip_attribute`** (`string`, required): The name of the Home Assistant entity attribute that contains the IP address of the device. **This is crucial.** You need to inspect the entity's state in **Developer Tools -> States** to find the correct attribute name (common examples might be `ip_address`, `host`, `ip`).
    *   **`txt_records`** (`list`, optional): A list of additional key-value pairs to include in the mDNS TXT record. Each item in the list is an object:
        *   **`key`** (`string`, required): The key for the TXT record entry.
        *   **`attribute`** (`string`, required): The name of the Home Assistant entity attribute whose value should be used for this TXT record key.

## Example Configuration

```yaml
# /config/options.yaml (or configure via UI)
interface: eth0
update_interval: 300
log_level: info
services:
  - name: "WLED Devices"
    enabled: true
    # Using domain filter as it's often more reliable than integration attribute
    ha_domain: "light"
    # You could also use a pattern if needed:
    # ha_entity_pattern: "light.wled_"
    service_type: "_wled._tcp"
    service_port: 80
    ip_attribute: "ip_address" # Check Developer Tools -> States for your WLED entities!
  - name: "ESPHome Devices (Native API)"
    enabled: true
    ha_domain: "sensor" # Example: Assuming your primary ESPHome entity is a sensor
    # Use a more specific pattern if needed:
    # ha_entity_pattern: "sensor.esphome_device_"
    service_type: "_esphomelib._tcp"
    service_port: 6053
    ip_attribute: "ip_address" # Check Developer Tools -> States for your ESPHome entities!