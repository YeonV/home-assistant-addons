### Option: `services`

*   **Type**: `list`
*   **Required**: Yes
*   **Description**: A list of service advertisement rules. Each rule defines a set of Home Assistant entities to advertise and how to advertise them.

    Each item in the `services` list is an object with the following keys:

    *   **`name`** (`string`, required): A user-friendly name for this advertising rule (e.g., "WLED Devices", "ESPHome Sensors"). Used primarily for logging.
    *   **`enabled`** (`boolean`, optional, default: `true`): Set to `false` to temporarily disable this specific rule.
    *   **`entities`** (`list`, required): A list of specific Home Assistant `entity_id` strings that this rule should process and advertise. Example: `["sensor.wled_1_ip", "sensor.wled_2_ip"]`.
    *   **`service_type`** (`string`, required): The mDNS service type to advertise (e.g., `"_wled._tcp"`, `"_esphomelib._tcp"`).
    *   **`service_port`** (`integer`, required): The network port number associated with the service (e.g., `80` for WLED HTTP). Must be between 1 and 65535.
    *   **`ip_source`** (`string`, optional, default: `"attribute"`): Where to find the IP address for the entity. Options:
        *   `"attribute"`: Look in an attribute specified by `ip_attribute`.
        *   `"state"`: Use the entity's main state value as the IP address.
    *   **`ip_attribute`** (`string`, optional): Required **only** if `ip_source` is `"attribute"`. The name of the entity attribute containing the IP address.
    *   **`name_source`** (`string`, optional, default: `"attribute"`): Where to find the name to use for the mDNS advertisement. Options:
        *   `"attribute"`: Look in an attribute specified by `name_attribute` (defaults to `friendly_name`).
        *   `"entity_id"`: Use the entity's ID as the advertised name.
    *   **`name_attribute`** (`string`, optional, default: `"friendly_name"`): Required **only** if `name_source` is `"attribute"`. The name of the entity attribute to use for the advertised name. If this attribute is missing, the `entity_id` will be used as a fallback.
    *   **`filter_by_state`** (`string`, optional): If set, entities whose state exactly matches this string will be filtered out (or kept, see `filter_by_state_inverse`). Example: `"unavailable"`.
    *   **`filter_by_state_inverse`** (`boolean`, optional, default: `false`): If `true`, the `filter_by_state` logic is inverted: entities whose state **does not** match `filter_by_state` are kept, and those that *do* match are filtered out. Set this to `true` when `filter_by_state` is `"unavailable"` to process only available entities.
    *   **`txt_records`** (`list`, optional): *[Future implementation]* Define additional TXT records.

## Example Configuration

```yaml
# /config/options.yaml (or configure via UI)
interface: eth0
update_interval: 300
log_level: debug # Keep debug during testing
services:
  - name: "WLED Devices (from IP Sensors)"
    enabled: true
    entities: # List ALL your specific IP sensor entity IDs here
      - sensor.24v_2m_ip_2
      - sensor.kitchen_sink_ip
      - sensor.rgbw_60_01_ip
      - sensor.tv_wz_ip
      - sensor.yz_duo_1_ip
      # Add all other relevant sensor IDs...
    service_type: "_wled._tcp"
    service_port: 80
    ip_source: "state" # IMPORTANT: Get IP from sensor's state
    name_source: "attribute" # Get name from sensor's attribute
    name_attribute: "friendly_name" # Use the sensor's friendly name
    filter_by_state: "unavailable" # Filter out sensors that are unavailable
    filter_by_state_inverse: true # Keep sensors whose state IS NOT "unavailable"