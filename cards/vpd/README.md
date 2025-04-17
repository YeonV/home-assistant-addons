# VPD Table Card for Home Assistant

[![creator](https://img.shields.io/badge/CREATOR-Yeon-blue.svg?logo=github&logoColor=white)](https://github.com/YeonV) [![creator](https://img.shields.io/badge/A.K.A-Blade-darkred.svg?logo=github&logoColor=white)](https://github.com/YeonV)
[![GitHub Release][releases-shield]][releases]
[![License][license-shield]][license]

<!-- Optional: Add shields for HACS default, downloads, etc. if you track them -->

Display a Vapor Pressure Deficit (VPD) table directly in your Lovelace dashboards, highlighting the current conditions based on your temperature and humidity sensors. Ideal for monitoring environments like grow tents or greenhouses.

![image](https://github.com/user-attachments/assets/9f8e0b78-11cc-4d2e-be79-0ad5b682c09c)

**Features:**

*   Displays a clear VPD table based on standard calculations.
*   Highlights the current VPD zone based on real-time sensor data.
*   Highlights the closest matching temperature row and humidity column.
*   Automatically scrolls the table to keep the current zone visible.
*   Customizable colors for different VPD zones (Danger, Flowering, Vegging) via UI editor.
*   Configurable header text.
*   Configurable table maximum height.
*   Responsive layout.

---

## Installation

### Method 1: HACS (Home Assistant Community Store) - Recommended

1.  Ensure [HACS](https://hacs.xyz/) is installed and working.
2.  Navigate to HACS -> Frontend -> Click the three dots (⋮) top right -> **Custom Repositories**.
3.  Enter the following information:
    *   **URL:** `https://github.com/YeonV/home-assistant-addons`
    *   **Category:** `Lovelace`
4.  Click **Add**.
5.  Close the Custom Repositories dialog.
6.  The "VPD Table Card" should now appear in the HACS Frontend list (you might need to refresh). Click **Install**.
7.  Follow the prompts to install the card and reload Lovelace resources.

### Method 2: Manual Installation

1.  Download the `vpd-card.js` file from the latest [Release](https://github.com/YeonV/home-assistant-addons/releases).
2.  Place the downloaded file into your Home Assistant `config/www/` directory. If you place it in a subdirectory (e.g., `config/www/cards/`), adjust the resource URL accordingly.
3.  Add the resource reference to your Lovelace configuration:
    *   Go to **Configuration** -> **Dashboards** -> Click the **three dots (⋮)** top right -> **Resources**.
    *   Click **+ Add Resource**.
    *   **URL:** `/local/vpd-card.js` (or `/local/cards/vpd-card.js` if you used a subdirectory).
    *   **Resource Type:** `JavaScript Module`.
    *   Click **Create**.
4.  Refresh your browser.

---

## Configuration

Add the card to your Lovelace dashboard like any other card.

**UI Configuration:**

![image](https://github.com/user-attachments/assets/dec6537e-8150-408c-901c-14c6aa63f94d)


The card supports configuration through the Lovelace UI editor.

| Name          | Type    | Required | Description                                                                 | Default                  |
|---------------|---------|----------|-----------------------------------------------------------------------------|--------------------------|
| `type`        | string  | Yes      | `custom:vpd-card`                                                           |                          |
| `temperature` | string  | Yes      | Entity ID of your temperature sensor (expects °C).                          |                          |
| `humidity`    | string  | Yes      | Entity ID of your relative humidity sensor (expects %).                     |                          |
| `header`      | string  | No       | Text to display above the table.                                            | `""` (None)              |
| `max_height`  | string  | No       | Maximum height of the scrollable table container (e.g., `300px`, `40vh`).   | `300px`                  |
| `colors`      | object  | No       | Object to customize zone colors (see details below).                        | (Internal Defaults)      |

**Color Configuration (`colors` object):**

You can override the default colors for different zones and the highlight effect. Define colors using valid CSS color values (e.g., `#RRGGBB`, `rgb(...)`, `white`).

```yaml
type: custom:vpd-card
temperature: sensor.grow_tent_temperature
humidity: sensor.grow_tent_humidity
header: Grow Tent VPD
max_height: 400px
colors:
  danger:
    background: '#8B0000' # Dark Red
    color: 'white'
  midlateflower:
    background: '#DAA520' # Goldenrod
    color: 'black'
  earlyflowerlateveg:
    background: '#90EE90' # Light Green
    color: 'black'
  properearlyveg:
    background: '#228B22' # Forest Green
    color: 'white'
  highlight:
    color: 'orange'
