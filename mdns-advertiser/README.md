# Home Assistant Add-on: mDNS Advertiser

[![GitHub Release][releases-shield]][releases]
[![License][license-shield]][license]
[![Contributor Covenant][coc-shield]][coc]

<!-- Shield Configuration -->
[releases-shield]: https://img.shields.io/github/release/YeonV/mdns-advertiser.svg?style=for-the-badge
[releases]: https://github.com/YeonV/home-assistant-addons/releases
[license-shield]: https://img.shields.io/github/license/YeonV/mdns-advertiser.svg?style=for-the-badge
[license]: https://github.com/YeonV/home-assistant-addons/blob/main/mdns-advertiser/LICENSE
[coc-shield]: https://img.shields.io/badge/Contributor%20Covenant-v2.1-ff69b4.svg?style=for-the-badge
[coc]: https://github.com/YeonV/home-assistant-addons/blob/main/mdns-advertiser/CODE_OF_CONDUCT.md


## About

This Home Assistant add-on selectively advertises services based on Home Assistant entity states via mDNS (also known as Zeroconf or Bonjour) onto a specific network interface.

Its primary use case is to enable device discovery across different network segments (subnets) **without** using a full mDNS reflector/repeater, thereby avoiding the broadcast "spam" of unsolicited announcements on the main network segment.

For example, you can keep your IoT devices (like WLED controllers) on a separate, isolated network, but still allow applications on your main network (like LedFx) to discover them via mDNS when they actively query for services.

## How it Works

1.  The add-on periodically queries the Home Assistant API to get the state and attributes of specified entities.
2.  It extracts relevant information, such as the device's friendly name and its IP address (from a configured attribute).
3.  It uses the `avahi-publish` command to advertise the corresponding mDNS service record (e.g., `_wled._tcp.local`) **only** on the network interface specified in the configuration (typically your main network interface).
4.  The underlying `avahi-daemon` on the host system then handles responding to mDNS queries received on that interface.

This effectively creates a controlled mDNS proxy advertisement, driven by Home Assistant's knowledge of the devices.

## Installation

1.  Navigate to your Home Assistant instance.
2.  Go to **Settings** -> **Add-ons** -> **Add-on Store**.
3.  Click the vertical ellipsis (⋮) button in the top right and select **Repositories**.
4.  Enter the URL of your addons repository (`https://github.com/YeonV/home-assistant-addons`) and click **Add**.
5.  Close the dialog. The "mDNS Advertiser" add-on should now appear in the store.
6.  Click on the "mDNS Advertiser" add-on card.
7.  Click **Install** and wait for the installation to complete.

## Configuration

Detailed configuration options are available in the **[DOCS.md](DOCS.md)** file.

At a minimum, you will need to:

1.  Configure the network `interface` on which to advertise (e.g., `eth0`).
2.  Define at least one `service` block, specifying:
    *   How to identify the relevant Home Assistant entities (e.g., by integration or domain).
    *   The mDNS `service_type` (e.g., `_wled._tcp`).
    *   The `service_port`.
    *   The Home Assistant entity `attribute` that contains the device's IP address (`ip_attribute`).

## Prerequisites

*   This add-on relies on the `avahi-daemon` service running on the host system (Home Assistant OS) or within the container's environment to handle the actual mDNS protocol interactions. This is typically present on HAOS.
*   Proper network configuration:
    *   If HA has interfaces on both networks (e.g., `eth0` on main, `wlan0` on IoT), HA needs direct access to the IoT devices.
    *   If HA is only on the main network, your router(s) must be configured with appropriate static routes so that devices on the main network (like your PC running LedFx) can reach the IP addresses being advertised (which belong to the IoT network).

## Limitations

*   This add-on only *advertises* services known to Home Assistant; it does not reflect arbitrary mDNS traffic.
*   Discovery relies on Home Assistant having the correct and current IP address for the target devices in the specified attribute. Static IPs or DHCP reservations for target devices are highly recommended.
*   It depends on the `avahi-publish` utility and the `avahi-daemon` service.

## Support

Got questions? You have several options to get them answered:

*   [Home Assistant Community Forum](https://community.home-assistant.io/)
*   [Home Assistant Discord Chat Server](https://discord.gg/home-assistant)
*   Open an issue on [GitHub](https://github.com/YeonV/home-assistant-addons/issues) (Please ensure the issue pertains to the add-on itself).

## Contributing

This is an active open-source project. We are always open to people contributing enhancements, new features, bug fixes, documentation improvements, or feedback. Please check the [CONTRIBUTING.md](CONTRIBUTING.md) file for details.

## License

MIT License

Copyright (c) [YeonV]