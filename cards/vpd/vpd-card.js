// Hardcoded table data (ensure this is complete and correct for your needs)
const tableData = [
    { temp: "°C", "30%": "30%", "35%": "35%", "40%": "40%", "45%": "45%", "50%": "50%", "55%": "55%", "60%": "60%", "65%": "65%", "70%": "70%", "75%": "75%", "80%": "80%", "85%": "85%", "90%": "90%" },
    { temp: 15,"30%": { value: 1.19, class: "earlyflowerlateveg" }, "35%": { value: 1.11, class: "earlyflowerlateveg" }, "40%": { value: 1.02, class: "earlyflowerlateveg" }, "45%": { value: 0.94, class: "earlyflowerlateveg" }, "50%": { value: 0.85, class: "earlyflowerlateveg" }, "55%": { value: 0.77, class: "properearlyveg" }, "60%": { value: 0.68, class: "properearlyveg" }, "65%": { value: 0.60, class: "properearlyveg" }, "70%": { value: 0.51, class: "properearlyveg" }, "75%": { value: 0.43, class: "properearlyveg" }, "80%": { value: 0.34, class: "danger" }, "85%": { value: 0.26, class: "danger" }, "90%": { value: 0.17, class: "danger" }},
    { temp: 16,"30%": { value: 1.27, class: "midlateflower" }, "35%": { value: 1.18, class: "earlyflowerlateveg" }, "40%": { value: 1.09, class: "earlyflowerlateveg" }, "45%": { value: 1.00, class: "earlyflowerlateveg" }, "50%": { value: 0.91, class: "earlyflowerlateveg" }, "55%": { value: 0.82, class: "earlyflowerlateveg" }, "60%": { value: 0.73, class: "properearlyveg" }, "65%": { value: 0.64, class: "properearlyveg" }, "70%": { value: 0.55, class: "properearlyveg" }, "75%": { value: 0.45, class: "properearlyveg" }, "80%": { value: 0.36, class: "danger" }, "85%": { value: 0.27, class: "danger" }, "90%": { value: 0.18, class: "danger" }},
    { temp: 17,"30%": { value: 1.36, class: "midlateflower" }, "35%": { value: 1.26, class: "midlateflower" }, "40%": { value: 1.16, class: "earlyflowerlateveg" }, "45%": { value: 1.07, class: "earlyflowerlateveg" }, "50%": { value: 0.97, class: "earlyflowerlateveg" }, "55%": { value: 0.87, class: "earlyflowerlateveg" }, "60%": { value: 0.78, class: "properearlyveg" }, "65%": { value: 0.68, class: "properearlyveg" }, "70%": { value: 0.58, class: "properearlyveg" }, "75%": { value: 0.48, class: "properearlyveg" }, "80%": { value: 0.39, class: "danger" }, "85%": { value: 0.29, class: "danger" }, "90%": { value: 0.19, class: "danger" }},
    { temp: 18,"30%": { value: 1.44, class: "midlateflower" }, "35%": { value: 1.34, class: "midlateflower" }, "40%": { value: 1.24, class: "midlateflower" }, "45%": { value: 1.14, class: "midlateflower" }, "50%": { value: 1.03, class: "earlyflowerlateveg" }, "55%": { value: 0.93, class: "earlyflowerlateveg" }, "60%": { value: 0.83, class: "earlyflowerlateveg" }, "65%": { value: 0.72, class: "properearlyveg" }, "70%": { value: 0.62, class: "properearlyveg" }, "75%": { value: 0.52, class: "properearlyveg" }, "80%": { value: 0.41, class: "properearlyveg" }, "85%": { value: 0.31, class: "danger" }, "90%": { value: 0.21, class: "danger" }},
    { temp: 19,"30%": { value: 1.54, class: "midlateflower" }, "35%": { value: 1.43, class: "midlateflower" }, "40%": { value: 1.32, class: "midlateflower" }, "45%": { value: 1.21, class: "midlateflower" }, "50%": { value: 1.10, class: "earlyflowerlateveg" }, "55%": { value: 0.99, class: "earlyflowerlateveg" }, "60%": { value: 0.88, class: "earlyflowerlateveg" }, "65%": { value: 0.77, class: "properearlyveg" }, "70%": { value: 0.66, class: "properearlyveg" }, "75%": { value: 0.55, class: "properearlyveg" }, "80%": { value: 0.44, class: "properearlyveg" }, "85%": { value: 0.33, class: "danger" }, "90%": { value: 0.22, class: "danger" }},
    { temp: 20,"30%": { value: 1.64, class: "danger" }, "35%": { value: 1.52, class: "midlateflower" }, "40%": { value: 1.40, class: "midlateflower" }, "45%": { value: 1.29, class: "midlateflower" }, "50%": { value: 1.17, class: "earlyflowerlateveg" }, "55%": { value: 1.05, class: "earlyflowerlateveg" }, "60%": { value: 0.94, class: "earlyflowerlateveg" }, "65%": { value: 0.82, class: "earlyflowerlateveg" }, "70%": { value: 0.70, class: "properearlyveg" }, "75%": { value: 0.58, class: "properearlyveg" }, "80%": { value: 0.48, class: "properearlyveg" }, "85%": { value: 0.35, class: "danger" }, "90%": { value: 0.23, class: "danger" }},
    { temp: 21,"30%": { value: 1.74, class: "danger" }, "35%": { value: 1.62, class: "danger" }, "40%": { value: 1.49, class: "midlateflower" }, "45%": { value: 1.37, class: "midlateflower" }, "50%": { value: 1.24, class: "midlateflower" }, "55%": { value: 1.12, class: "earlyflowerlateveg" }, "60%": { value: 0.99, class: "earlyflowerlateveg" }, "65%": { value: 0.87, class: "earlyflowerlateveg" }, "70%": { value: 0.75, class: "properearlyveg" }, "75%": { value: 0.62, class: "properearlyveg" }, "80%": { value: 0.50, class: "properearlyveg" }, "85%": { value: 0.37, class: "danger" }, "90%": { value: 0.25, class: "danger" }},
    { temp: 22,"30%": { value: 1.85, class: "danger" }, "35%": { value: 1.72, class: "danger" }, "40%": { value: 1.59, class: "midlateflower" }, "45%": { value: 1.45, class: "midlateflower" }, "50%": { value: 1.32, class: "midlateflower" }, "55%": { value: 1.19, class: "earlyflowerlateveg" }, "60%": { value: 1.06, class: "earlyflowerlateveg" }, "65%": { value: 0.93, class: "earlyflowerlateveg" }, "70%": { value: 0.79, class: "properearlyveg" }, "75%": { value: 0.66, class: "properearlyveg" }, "80%": { value: 0.53, class: "properearlyveg" }, "85%": { value: 0.40, class: "danger" }, "90%": { value: 0.26, class: "danger" }},
    { temp: 23,"30%": { value: 1.97, class: "danger" }, "35%": { value: 1.83, class: "danger" }, "40%": { value: 1.69, class: "danger" }, "45%": { value: 1.55, class: "midlateflower" }, "50%": { value: 1.40, class: "midlateflower" }, "55%": { value: 1.26, class: "midlateflower" }, "60%": { value: 1.12, class: "earlyflowerlateveg" }, "65%": { value: 0.98, class: "earlyflowerlateveg" }, "70%": { value: 0.84, class: "earlyflowerlateveg" }, "75%": { value: 0.70, class: "properearlyveg" }, "80%": { value: 0.56, class: "properearlyveg" }, "85%": { value: 0.42, class: "properearlyveg" }, "90%": { value: 0.28, class: "danger" }},
    { temp: 24,"30%": { value: 2.09, class: "danger" }, "35%": { value: 1.94, class: "danger" }, "40%": { value: 1.79, class: "danger" }, "45%": { value: 1.64, class: "danger" }, "50%": { value: 1.49, class: "midlateflower" }, "55%": { value: 1.34, class: "midlateflower" }, "60%": { value: 1.19, class: "earlyflowerlateveg" }, "65%": { value: 1.04, class: "earlyflowerlateveg" }, "70%": { value: 0.90, class: "earlyflowerlateveg" }, "75%": { value: 0.75, class: "properearlyveg" }, "80%": { value: 0.60, class: "properearlyveg" }, "85%": { value: 0.45, class: "properearlyveg" }, "90%": { value: 0.30, class: "danger" }},
    { temp: 25,"30%": { value: 2.22, class: "danger" }, "35%": { value: 2.06, class: "danger" }, "40%": { value: 1.90, class: "danger" }, "45%": { value: 1.74, class: "danger" }, "50%": { value: 1.58, class: "midlateflower" }, "55%": { value: 1.43, class: "midlateflower" }, "60%": { value: 1.27, class: "midlateflower" }, "65%": { value: 1.11, class: "earlyflowerlateveg" }, "70%": { value: 0.95, class: "earlyflowerlateveg" }, "75%": { value: 0.79, class: "properearlyveg" }, "80%": { value: 0.63, class: "properearlyveg" }, "85%": { value: 0.48, class: "properearlyveg" }, "90%": { value: 0.32, class: "danger" }},
    { temp: 26,"30%": { value: 2.35, class: "danger" }, "35%": { value: 2.18, class: "danger" }, "40%": { value: 2.02, class: "danger" }, "45%": { value: 1.85, class: "danger" }, "50%": { value: 1.68, class: "danger" }, "55%": { value: 1.51, class: "midlateflower" }, "60%": { value: 1.34, class: "midlateflower" }, "65%": { value: 1.18, class: "earlyflowerlateveg" }, "70%": { value: 1.01, class: "earlyflowerlateveg" }, "75%": { value: 0.84, class: "earlyflowerlateveg" }, "80%": { value: 0.67, class: "properearlyveg" }, "85%": { value: 0.50, class: "properearlyveg" }, "90%": { value: 0.34, class: "danger" }},
    { temp: 27,"30%": { value: 2.50, class: "danger" }, "35%": { value: 2.32, class: "danger" }, "40%": { value: 2.14, class: "danger" }, "45%": { value: 1.96, class: "danger" }, "50%": { value: 1.78, class: "danger" }, "55%": { value: 1.60, class: "danger" }, "60%": { value: 1.43, class: "midlateflower" }, "65%": { value: 1.25, class: "midlateflower" }, "70%": { value: 1.07, class: "earlyflowerlateveg" }, "75%": { value: 0.89, class: "earlyflowerlateveg" }, "80%": { value: 0.71, class: "properearlyveg" }, "85%": { value: 0.53, class: "properearlyveg" }, "90%": { value: 0.36, class: "danger" }},
    { temp: 28,"30%": { value: 2.65, class: "danger" }, "35%": { value: 2.46, class: "danger" }, "40%": { value: 2.27, class: "danger" }, "45%": { value: 2.08, class: "danger" }, "50%": { value: 1.89, class: "danger" }, "55%": { value: 1.70, class: "danger" }, "60%": { value: 1.51, class: "midlateflower" }, "65%": { value: 1.32, class: "midlateflower" }, "70%": { value: 1.13, class: "earlyflowerlateveg" }, "75%": { value: 0.94, class: "earlyflowerlateveg" }, "80%": { value: 0.76, class: "properearlyveg" }, "85%": { value: 0.57, class: "properearlyveg" }, "90%": { value: 0.38, class: "danger" }},
    { temp: 29,"30%": { value: 2.80, class: "danger" }, "35%": { value: 2.60, class: "danger" }, "40%": { value: 2.40, class: "danger" }, "45%": { value: 2.20, class: "danger" }, "50%": { value: 2.00, class: "danger" }, "55%": { value: 1.80, class: "danger" }, "60%": { value: 1.60, class: "danger" }, "65%": { value: 1.40, class: "midlateflower" }, "70%": { value: 1.20, class: "midlateflower" }, "75%": { value: 1.00, class: "earlyflowerlateveg" }, "80%": { value: 0.80, class: "earlyflowerlateveg" }, "85%": { value: 0.60, class: "properearlyveg" }, "90%": { value: 0.40, class: "properearlyveg" }},
    { temp: 30,"30%": { value: 2.97, class: "danger" }, "35%": { value: 2.76, class: "danger" }, "40%": { value: 2.55, class: "danger" }, "45%": { value: 2.33, class: "danger" }, "50%": { value: 2.12, class: "danger" }, "55%": { value: 1.91, class: "danger" }, "60%": { value: 1.70, class: "danger" }, "65%": { value: 1.48, class: "midlateflower" }, "70%": { value: 1.27, class: "midlateflower" }, "75%": { value: 1.06, class: "earlyflowerlateveg" }, "80%": { value: 0.85, class: "earlyflowerlateveg" }, "85%": { value: 0.64, class: "properearlyveg" }, "90%": { value: 0.42, class: "properearlyveg" }},
    { temp: 31,"30%": { value: 3.14, class: "danger" }, "35%": { value: 2.92, class: "danger" }, "40%": { value: 2.70, class: "danger" }, "45%": { value: 2.47, class: "danger" }, "50%": { value: 2.25, class: "danger" }, "55%": { value: 2.02, class: "danger" }, "60%": { value: 1.80, class: "danger" }, "65%": { value: 1.57, class: "midlateflower" }, "70%": { value: 1.35, class: "midlateflower" }, "75%": { value: 1.12, class: "earlyflowerlateveg" }, "80%": { value: 0.90, class: "earlyflowerlateveg" }, "85%": { value: 0.67, class: "properearlyveg" }, "90%": { value: 0.45, class: "properearlyveg" }},
    { temp: 32,"30%": { value: 3.33, class: "danger" }, "35%": { value: 3.09, class: "danger" }, "40%": { value: 2.85, class: "danger" }, "45%": { value: 2.61, class: "danger" }, "50%": { value: 2.38, class: "danger" }, "55%": { value: 2.14, class: "danger" }, "60%": { value: 1.90, class: "danger" }, "65%": { value: 1.66, class: "danger" }, "70%": { value: 1.43, class: "midlateflower" }, "75%": { value: 1.19, class: "midlateflower" }, "80%": { value: 0.95, class: "earlyflowerlateveg" }, "85%": { value: 0.71, class: "properearlyveg" }, "90%": { value: 0.48, class: "properearlyveg" }},
    { temp: 33,"30%": { value: 3.52, class: "danger" }, "35%": { value: 3.27, class: "danger" }, "40%": { value: 3.02, class: "danger" }, "45%": { value: 2.77, class: "danger" }, "50%": { value: 2.51, class: "danger" }, "55%": { value: 2.26, class: "danger" }, "60%": { value: 2.01, class: "danger" }, "65%": { value: 1.76, class: "danger" }, "70%": { value: 1.51, class: "midlateflower" }, "75%": { value: 1.26, class: "midlateflower" }, "80%": { value: 1.01, class: "earlyflowerlateveg" }, "85%": { value: 0.75, class: "properearlyveg" }, "90%": { value: 0.50, class: "properearlyveg" }},
    { temp: 34,"30%": { value: 3.72, class: "danger" }, "35%": { value: 3.46, class: "danger" }, "40%": { value: 3.19, class: "danger" }, "45%": { value: 2.93, class: "danger" }, "50%": { value: 2.66, class: "danger" }, "55%": { value: 2.39, class: "danger" }, "60%": { value: 2.13, class: "danger" }, "65%": { value: 1.86, class: "danger" }, "70%": { value: 1.60, class: "midlateflower" }, "75%": { value: 1.33, class: "midlateflower" }, "80%": { value: 1.06, class: "earlyflowerlateveg" }, "85%": { value: 0.80, class: "properearlyveg" }, "90%": { value: 0.53, class: "properearlyveg" }},
    { temp: 35,"30%": { value: 3.94, class: "danger" }, "35%": { value: 3.65, class: "danger" }, "40%": { value: 3.37, class: "danger" }, "45%": { value: 3.09, class: "danger" }, "50%": { value: 2.81, class: "danger" }, "55%": { value: 2.53, class: "danger" }, "60%": { value: 2.25, class: "danger" }, "65%": { value: 1.97, class: "danger" }, "70%": { value: 1.69, class: "danger" }, "75%": { value: 1.41, class: "midlateflower" }, "80%": { value: 1.12, class: "earlyflowerlateveg" }, "85%": { value: 0.84, class: "earlyflowerlateveg" }, "90%": { value: 0.56, class: "properearlyveg" }},
];


// ======================================================================
// == VPD Card Element                                                 ==
// ======================================================================
class VpdCard extends HTMLElement {

    config;
    content;
    shadowRoot; // Explicitly declare shadowRoot

    setConfig(config) {
        if (!config.temperature || !config.humidity) { 
            throw new Error('Please define both temperature and humidity entities!');
        }
        // Store a deep copy to prevent mutations affecting original config object
        this.config = JSON.parse(JSON.stringify(config));

        // Apply custom colors if provided (and shadowRoot exists)
        if (this.shadowRoot) {
            this._applyStyles();
        }
    }

    _applyStyles() {
        if (!this.shadowRoot) return;

        // Use existing style element or create a new one
        let styleElement = this.shadowRoot.querySelector('style');
        if (!styleElement) {
            styleElement = document.createElement('style');
            this.shadowRoot.appendChild(styleElement); // Append early
        }

        // Define default styles and apply overrides from config
        styleElement.textContent = `
            :host {
                font-family: sans-serif;
                display: block;
                padding: 0px;
                margin: 0 auto;
                /* Default Colors as CSS Variables */
                --vpd-danger-bg: ${this.config.colors?.danger?.background || '#1c2814'};
                --vpd-danger-color: ${this.config.colors?.danger?.color || 'white'};
                --vpd-midlateflower-bg: ${this.config.colors?.midlateflower?.background || '#505e49'};
                --vpd-midlateflower-color: ${this.config.colors?.midlateflower?.color || 'white'};
                --vpd-earlyflowerlateveg-bg: ${this.config.colors?.earlyflowerlateveg?.background || '#406f1e'};
                --vpd-earlyflowerlateveg-color: ${this.config.colors?.earlyflowerlateveg?.color || 'white'};
                --vpd-properearlyveg-bg: ${this.config.colors?.properearlyveg?.background || '#5ea52b'};
                --vpd-properearlyveg-color: ${this.config.colors?.properearlyveg?.color || 'white'};
                --vpd-highlight-color: ${this.config.colors?.highlight?.color || '#ffff00'};
                --vpd-table-header-bg: #1c1c1c;
                --vpd-table-header-color: #aaa;
                --vpd-table-cell-bg: #1c1c1c;
                --vpd-table-cell-color: white;
                --vpd-table-border-color: #333;
            }

            ha-card {
                border-radius: var(--ha-card-border-radius, 4px);
                overflow: hidden;
            }

            .card-content {
                padding: 0;
            }

            #table-container {
                overflow: auto;
                max-height: ${this.config.max_height || '300px'}; /* Use config or default */
                position: relative;
            }

            table {
                width: 100%;
                border-collapse: collapse;
                table-layout: fixed;
            }

            th {
                position: sticky;
                top: 0;
                z-index: 1;
                background-color: var(--vpd-table-header-bg);
                border: 1px solid var(--vpd-table-border-color);
                padding: 8px;
                text-align: center;
                overflow: hidden;
                white-space: nowrap;
                color: var(--vpd-table-header-color);
                margin: 0;
                font-weight: bold;
            }
             th:first-child { /* Optional: Style first header cell */ }

            td {
                border: 1px solid var(--vpd-table-border-color);
                padding: 8px;
                text-align: center;
                overflow: hidden;
                white-space: nowrap;
                background-color: var(--vpd-table-cell-bg);
                color: var(--vpd-table-cell-color);
                margin: 0;
                min-width: 50px;
            }
             td:first-child { /* Optional: Style first column cells */
                 font-weight: bold;
             }

            /* Color Classes */
            .danger { background-color: var(--vpd-danger-bg); color: var(--vpd-danger-color); }
            .midlateflower { background-color: var(--vpd-midlateflower-bg); color: var(--vpd-midlateflower-color); }
            .earlyflowerlateveg { background-color: var(--vpd-earlyflowerlateveg-bg); color: var(--vpd-earlyflowerlateveg-color); }
            .properearlyveg { background-color: var(--vpd-properearlyveg-bg); color: var(--vpd-properearlyveg-color); }

            /* Highlighting */
            .highlighted {
                color: var(--vpd-highlight-color) !important;
                font-weight: bold;
                outline: 1px solid var(--vpd-highlight-color);
                outline-offset: -1px;
            }
            td.highlighted {
                 outline: 2px solid var(--vpd-highlight-color);
                 outline-offset: -2px;
            }

            #message-container {
                text-align: center;
                color: var(--error-color, red);
                min-height: 20px;
                padding: 5px 0;
            }
        `;
    }

    set hass(hass) {
        if (!this.config) return; // Don't do anything if config is not set

        const tempEntityId = this.config.temperature;
        const humidityEntityId = this.config.humidity;

        const tempState = hass.states[tempEntityId];
        const humidityState = hass.states[humidityEntityId];

        const temperatureValue = tempState ? parseFloat(tempState.state) : NaN;
        const humidityValue = humidityState ? parseFloat(humidityState.state) : NaN;

        // Initial DOM setup (only once)
        if (!this.content) {
            this.shadowRoot = this.attachShadow({ mode: 'open' });
            this._applyStyles(); // Apply styles after shadowRoot is created

            const card = document.createElement('ha-card');
            if (this.config.header) {
                card.header = this.config.header;
            }

            this.content = document.createElement('div');
            this.content.className = 'card-content';

            const tableContainer = document.createElement('div');
            tableContainer.id = 'table-container';
            this.content.appendChild(tableContainer);

            const messageContainer = document.createElement('div');
            messageContainer.id = 'message-container';
            this.content.appendChild(messageContainer);

            card.appendChild(this.content);
            this.shadowRoot.appendChild(card);

            // Build the table structure
            this.buildTable(tableContainer);
        } else {
             // If config changed (e.g., header), update relevant parts
             const card = this.shadowRoot.querySelector('ha-card');
             if (card && this.config.header !== card.header) {
                 card.header = this.config.header || ""; // Update or remove header
             }
             // Re-apply styles in case colors changed
             this._applyStyles();
        }


        // Update message and highlighting based on current states
        const messageContainer = this.shadowRoot.querySelector("#message-container");
        if (!messageContainer) return; // Exit if elements not ready

        messageContainer.textContent = ""; // Clear previous message

        if (isNaN(temperatureValue) || isNaN(humidityValue)) {
            let unavailable = [];
            if (isNaN(temperatureValue)) unavailable.push(`Temperature (${tempEntityId})`);
            if (isNaN(humidityValue)) unavailable.push(`Humidity (${humidityEntityId})`);
            messageContainer.textContent = `${unavailable.join(' and ')} unavailable or invalid.`;
            this.clearHighlighting();
        } else {
            this.highlightCell(temperatureValue, humidityValue);
        }
    }

    buildTable(container) {
        if (!tableData || tableData.length < 2) {
            container.innerHTML = "<p>Error: Table data is missing or invalid.</p>";
            return;
        }
        const table = document.createElement("table");
        const thead = document.createElement("thead");
        const tbody = document.createElement("tbody");

        // Build header row
        const headerData = tableData[0];
        const headerRow = thead.insertRow();
        for (const key in headerData) {
            if (Object.prototype.hasOwnProperty.call(headerData, key)) {
                const cell = document.createElement("th");
                cell.scope = "col";
                cell.textContent = headerData[key];
                headerRow.appendChild(cell);
            }
        }
        if (headerRow.cells[0]) headerRow.cells[0].scope = "col";

        table.appendChild(thead);

        // Build data rows
        for (let i = 1; i < tableData.length; i++) {
            const rowData = tableData[i];
            const row = tbody.insertRow();
            let firstCell = true;
            for (const key in rowData) {
                if (Object.prototype.hasOwnProperty.call(rowData, key)) {
                    const cell = row.insertCell();
                    if (firstCell) {
                        cell.textContent = rowData[key];
                        cell.scope = "row";
                        firstCell = false;
                    } else {
                        const cellData = rowData[key];
                        if (typeof cellData === 'object' && cellData !== null && 'value' in cellData) {
                            cell.textContent = parseFloat(cellData.value).toFixed(2);
                            if (cellData.class) {
                                cell.classList.add(cellData.class);
                            }
                        } else {
                            cell.textContent = String(cellData);
                        }
                    }
                }
            }
        }
        table.appendChild(tbody);
        container.innerHTML = ''; // Clear previous content
        container.appendChild(table);
    }

    clearHighlighting() {
         const table = this.shadowRoot?.querySelector("#table-container table");
         if (table) {
             table.querySelectorAll(".highlighted").forEach(cell => cell.classList.remove("highlighted"));
         }
    }

    highlightCell(temperature, humidity) {
        const tableContainer = this.shadowRoot?.querySelector("#table-container");
        const table = tableContainer?.querySelector("table");
        const messageContainer = this.shadowRoot?.querySelector("#message-container");

        if (!table || !messageContainer) {
             if (messageContainer) messageContainer.textContent = "Table not ready for highlighting.";
            return;
        }

        this.clearHighlighting();

        let closestTempRowIndex = -1;
        let closestHumidityColIndex = -1;
        let minTempDiff = Infinity;
        let minHumidityDiff = Infinity;

        // Find closest temperature row
        const dataRows = table.querySelectorAll("tbody tr");
        dataRows.forEach((row, index) => {
            const rowTemp = parseFloat(row.cells[0]?.textContent);
             if (!isNaN(rowTemp)) {
                const diff = Math.abs(rowTemp - temperature);
                if (diff < minTempDiff) {
                    minTempDiff = diff;
                    closestTempRowIndex = index;
                }
             }
        });

        // Find closest humidity column
        const headerCells = table.querySelectorAll("thead th");
        for (let i = 1; i < headerCells.length; i++) {
             const headerCell = headerCells[i];
             const headerHumidity = parseFloat(headerCell?.textContent);
             if (!isNaN(headerHumidity)) {
                const diff = Math.abs(headerHumidity - humidity);
                if (diff < minHumidityDiff) {
                    minHumidityDiff = diff;
                    closestHumidityColIndex = i;
                }
             }
        }

        if (closestTempRowIndex === -1 || closestHumidityColIndex === -1) {
            messageContainer.textContent = "Could not find matching row/column for current values.";
            return;
        }

        // Get elements to highlight
        const tempCell = dataRows[closestTempRowIndex]?.cells[0];
        const humidityCell = headerCells[closestHumidityColIndex];
        const intersectionCell = dataRows[closestTempRowIndex]?.cells[closestHumidityColIndex];

        if (tempCell) tempCell.classList.add("highlighted");
        if (humidityCell) humidityCell.classList.add("highlighted");
        if (intersectionCell) {
            intersectionCell.classList.add("highlighted");

            // Scroll to the highlighted cell
            const containerRect = tableContainer.getBoundingClientRect();
            const cellRect = intersectionCell.getBoundingClientRect();
            const desiredScrollTop = tableContainer.scrollTop + cellRect.top - containerRect.top - (tableContainer.clientHeight / 2) + (cellRect.height / 2);
            const desiredScrollLeft = tableContainer.scrollLeft + cellRect.left - containerRect.left - (tableContainer.clientWidth / 2) + (cellRect.width / 2);

            tableContainer.scrollTo({
                top: Math.max(0, desiredScrollTop), // Ensure scroll position isn't negative
                left: Math.max(0, desiredScrollLeft),
                behavior: "smooth"
            });
        } else {
             messageContainer.textContent = "Error highlighting intersection cell.";
        }
    }

    // --- Lovelace Card Interface Methods ---

    static getStubConfig() {
        return {
            type: "custom:vpd-card", // Important for HA to identify the card type
            temperature: "sensor.your_temperature_sensor",
            humidity: "sensor.your_humidity_sensor",
            header: "VPD Table",
            max_height: "300px",
            // colors: { // Example structure
            //     danger: { background: "#8B0000", color: "white" },
            //     highlight: { color: "#FFA500" }
            // }
        };
    }

    getCardSize() {
        // Estimate card size (adjust as needed)
        return 6;
    }

    getGridOptions() {
        // Grid options for Sections view (adjust as needed)
        return {
          rows: 6, columns: 12,
          min_rows: 3, max_rows: 14,
          min_columns: 6, max_columns: 24,
        };
    }

    // --- Static method for UI Editor ---
    static getConfigElement() {
        return document.createElement('vpd-card-editor');
    }
}

customElements.define('vpd-card', VpdCard);


// ======================================================================
// == VPD Card Editor Element                                          ==
// ======================================================================
class VpdCardEditor extends HTMLElement {

    _config;
    _hass;
    _elements = {
        inputs: {},
        pickers: {},
        colors: {}
    };
    _initialized = false;

    // Define the default hex colors used by the card itself
    // These will be used as fallbacks for the color pickers
    _defaultHexColors = {
        danger:            { background: '#1c2814', color: '#ffffff' }, // Using your original danger bg default
        midlateflower:     { background: '#505e49', color: '#ffffff' },
        earlyflowerlateveg:{ background: '#406f1e', color: '#ffffff' },
        properearlyveg:    { background: '#5ea52b', color: '#ffffff' },
        highlight:         { /* no background */   color: '#ffff00' }
    };


    setConfig(config) {
        this._config = JSON.parse(JSON.stringify(config));
        if (this._initialized) {
            this.loadEditorValues();
        }
    }

    set hass(hass) {
        this._hass = hass;
        if (this._initialized && this._elements.pickers) {
            Object.values(this._elements.pickers).forEach(picker => {
                if (picker) picker.hass = this._hass;
            });
        }
    }

    connectedCallback() {
        if (!this._initialized) {
            this.attachShadow({ mode: 'open' });
            this.renderEditor();
            this._initialized = true;
            this._storeElementReferences();
            this._attachInputListeners();
            this.loadEditorValues();
             if (this._hass) {
                 this.hass = this._hass;
             }
        }
    }

    renderEditor() {
        // Sets the initial HTML structure. Listeners and values are added/set later.
        this.shadowRoot.innerHTML = `
            <style>
                 :host { display: block; box-sizing: border-box; padding: 10px; }
                .form-group { margin-bottom: 16px; }
                ha-textfield, ha-entity-picker { display: block; /* Ensure they take block space */ }
                h4 { margin-top: 24px; margin-bottom: 8px; border-bottom: 1px solid var(--divider-color); padding-bottom: 5px; }

                /* Styles for Collapsible Section */
                 details { margin-top: 10px; }
                 summary {
                    cursor: pointer;
                    padding: 8px 0 8px 20px; /* Add padding for arrow */
                    font-weight: bold;
                    list-style: none; /* Remove default marker */
                    position: relative;
                    border-bottom: 1px solid var(--divider-color); /* Optional separator */
                    margin-bottom: 10px; /* Space below summary */
                 }
                 summary::before {
                     content: '▶'; /* Collapsed state */
                     position: absolute;
                     left: 0;
                     top: 8px; /* Adjust vertical position */
                     display: inline-block;
                     transition: transform 0.2s ease-in-out;
                     font-size: 0.8em; /* Make arrow slightly smaller */
                 }
                 details[open] summary::before {
                     transform: rotate(90deg); /* Expanded state */
                 }
                 /* Indent the content within details */
                 details > div.details-content {
                     padding-left: 10px; /* Indent content slightly */
                     border-left: 2px solid var(--divider-color); /* Optional left border */
                     margin-left: 5px; /* Align with summary padding */
                 }

                /* Styles for Color Input Groups */
                .color-group {
                    border-left: 3px solid var(--primary-color);
                    padding-left: 15px;
                    margin-bottom: 15px;
                 }
                .color-group label { display: block; margin-bottom: 4px; font-weight: bold; }

                /* Wrapper for side-by-side Bg/Fg sections */
                .color-inputs-wrapper {
                    display: flex;
                    flex-wrap: wrap; /* Allow wrapping on small screens */
                    gap: 15px; /* Space between Bg and Fg sections */
                    align-items: flex-start;
                 }

                 /* Container for one text+picker pair */
                .color-input-container {
                    display: flex;
                    gap: 8px; /* Space between text field and picker */
                    align-items: center;
                    margin-bottom: 0; /* Wrapper handles spacing */
                    flex: 1; /* Allow Bg/Fg containers to share space */
                    min-width: 180px; /* Prevent excessive shrinking */
                }
                 .color-input-container ha-textfield {
                     flex: 1; /* Text field takes up remaining space */
                     margin-bottom: 0;
                 }
                 .color-picker-input {
                     width: 35px;
                     height: 30px;
                     padding: 0 2px;
                     border: 1px solid var(--divider-color);
                     border-radius: 4px;
                     cursor: pointer;
                     background-color: transparent;
                 }
            </style>
            <div class="form-group">
                <ha-entity-picker
                    label="Temperature Sensor (Required)"
                    .hass="${this._hass || ''}"
                    configValue="temperature"
                    allow-custom-entity
                    id="temperature"
                ></ha-entity-picker>
            </div>
            <div class="form-group">
                <ha-entity-picker
                    label="Humidity Sensor (Required)"
                    .hass="${this._hass || ''}"
                    configValue="humidity"
                    allow-custom-entity
                    id="humidity"
                ></ha-entity-picker>
            </div>
            <div class="form-group">
                <ha-textfield
                    label="Header (Optional)"
                    configValue="header"
                    id="header"
                ></ha-textfield>
            </div>

            <details>
                <summary>Color Customization (Optional)</summary>
                <div class="details-content">
                    <p>Enter valid CSS colors or use the picker.</p>

                    ${this._renderColorGroupHTML('danger', 'Danger Zone')}
                    ${this._renderColorGroupHTML('midlateflower', 'Mid/Late Flower Zone')}
                    ${this._renderColorGroupHTML('earlyflowerlateveg', 'Early Flower / Late Veg Zone')}
                    ${this._renderColorGroupHTML('properearlyveg', 'Proper / Early Veg Zone')}
                    ${this._renderColorGroupHTML('highlight', 'Highlight', true)}
                 </div>
            </details>
        `;
    }

    _renderColorGroupHTML(groupKey, labelText, isHighlight = false) {
        // Renders structure for Background (if applicable) and Text Color sections
        // Get default values to use in placeholders
        const defaultGroupColors = this._defaultHexColors[groupKey] || {};
        const defaultBg = defaultGroupColors.background || '#000000';
        const defaultFg = defaultGroupColors.color || '#ffffff';

        return `
            <div class="color-group">
                <label>${labelText}</label>
                <div class="color-inputs-wrapper">
                    ${!isHighlight ? `
                    <div class="color-input-container">
                        <ha-textfield
                            label="Background"
                            data-color-group="${groupKey}"
                            data-color-key="background"
                            placeholder="Default (${defaultBg})"
                            id="${groupKey}_bg"
                        ></ha-textfield>
                        <input
                            type="color"
                            class="color-picker-input"
                            data-color-group="${groupKey}"
                            data-color-key="background"
                            id="${groupKey}_bg_picker"
                            title="Pick Background Color"
                         />
                    </div>
                    ` : ''}
                    <div class="color-input-container">
                        <ha-textfield
                            label="Text Color"
                            data-color-group="${groupKey}"
                            data-color-key="color"
                            placeholder="Default (${defaultFg})"
                            id="${groupKey}_color"
                        ></ha-textfield>
                        <input
                            type="color"
                            class="color-picker-input"
                            data-color-group="${groupKey}"
                            data-color-key="color"
                            id="${groupKey}_color_picker"
                            title="Pick Text Color"
                        />
                    </div>
                </div>
            </div>
        `;
    }

    _storeElementReferences() {
        // Finds and stores references to the input elements after renderEditor
        const root = this.shadowRoot;
        if (!root) return;

        this._elements.pickers.temperature = root.querySelector('#temperature');
        this._elements.pickers.humidity = root.querySelector('#humidity');
        this._elements.inputs.header = root.querySelector('#header');

        const colorGroups = ['danger', 'midlateflower', 'earlyflowerlateveg', 'properearlyveg', 'highlight'];
        this._elements.colors = {}; // Reset before populating
        colorGroups.forEach(group => {
            this._elements.colors[group] = {
                background: {
                    text: root.querySelector(`#${group}_bg`),
                    picker: root.querySelector(`#${group}_bg_picker`)
                },
                color: {
                    text: root.querySelector(`#${group}_color`),
                    picker: root.querySelector(`#${group}_color_picker`)
                }
            };
            if (!this._elements.colors[group].background.text) {
                delete this._elements.colors[group].background;
            }
        });
    }

    _attachInputListeners() {
        // Adds event listeners imperatively to the input elements
        if (!this._elements) return;

        // Entity Pickers
        if (this._elements.pickers.temperature) this._elements.pickers.temperature.addEventListener('value-changed', this._valueChanged.bind(this));
        if (this._elements.pickers.humidity) this._elements.pickers.humidity.addEventListener('value-changed', this._valueChanged.bind(this));

        // Header Input
        if (this._elements.inputs.header) this._elements.inputs.header.addEventListener('input', this._valueChanged.bind(this));

        // Color Inputs (Both Text and Picker)
        for (const group in this._elements.colors) {
            const groupData = this._elements.colors[group];
            if (groupData.background) {
                groupData.background.text?.addEventListener('input', this._colorChanged.bind(this));
                groupData.background.picker?.addEventListener('input', this._colorChanged.bind(this));
            }
            if (groupData.color) {
                 groupData.color.text?.addEventListener('input', this._colorChanged.bind(this));
                 groupData.color.picker?.addEventListener('input', this._colorChanged.bind(this));
            }
        }
    }

    // Helper to attempt conversion of various CSS color formats to #rrggbb hex
    _getHexForPicker(colorString) {
        if (!colorString) return null;
        const str = colorString.trim().toLowerCase();
        if (/^#[0-9a-f]{6}$/.test(str)) return str;
        if (/^#[0-9a-f]{3}$/.test(str)) return `#${str[1]}${str[1]}${str[2]}${str[2]}${str[3]}${str[3]}`;
        const nameMap = { white: '#ffffff', black: '#000000', red: '#ff0000', green: '#008000', blue: '#0000ff', yellow: '#ffff00', orange: '#ffa500', purple: '#800080', gray: '#808080', lightgray: '#d3d3d3', cyan: '#00ffff', magenta: '#ff00ff' };
        if (nameMap.hasOwnProperty(str)) return nameMap[str];
        const rgbMatch = str.match(/^rgba?\((\d+)\s*,\s*(\d+)\s*,\s*(\d+)(?:\s*,\s*[\d.]+)?\)$/);
        if (rgbMatch) { try { const r = parseInt(rgbMatch[1]), g = parseInt(rgbMatch[2]), b = parseInt(rgbMatch[3]); if (r >= 0 && r <= 255 && g >= 0 && g <= 255 && b >= 0 && b <= 255) return `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`; } catch (e) { return null; } }
        return null;
    }

    loadEditorValues() {
        // Sets the '.value' property of the stored elements based on the current _config
        if (!this._config || !this._initialized || !this.shadowRoot) return;
        // console.log("Loading editor values from:", this._config); // Uncomment for debugging

        // --- Pickers & Inputs ---
        if (this._elements.pickers.temperature) {
            this._elements.pickers.temperature.value = this._config.temperature || '';
            this._elements.pickers.temperature.hass = this._hass;
        }
        if (this._elements.pickers.humidity) {
            this._elements.pickers.humidity.value = this._config.humidity || '';
            this._elements.pickers.humidity.hass = this._hass;
        }
        if (this._elements.inputs.header) {
            this._elements.inputs.header.value = this._config.header || '';
        }

        // --- Colors ---
        for (const group in this._elements.colors) {
            const groupData = this._elements.colors[group];
            const defaultGroupColors = this._defaultHexColors[group] || {}; // Get defaults for this group

            if (groupData.background) {
                const bgColor = this._config.colors?.[group]?.background || ''; // Get value from config
                if(groupData.background.text) groupData.background.text.value = bgColor; // Set text field exactly
                if(groupData.background.picker) {
                    // Attempt conversion for picker, fallback to defined default hex
                    const defaultHex = defaultGroupColors.background || '#000000'; // Fallback if group/key missing in defaults
                    groupData.background.picker.value = this._getHexForPicker(bgColor) || defaultHex;
                }
            }
            if (groupData.color) {
                 const fgColor = this._config.colors?.[group]?.color || ''; // Get value from config
                 if(groupData.color.text) groupData.color.text.value = fgColor; // Set text field exactly
                 if(groupData.color.picker) {
                     // Attempt conversion for picker, fallback to defined default hex
                     const defaultHex = defaultGroupColors.color || '#ffffff'; // Fallback if group/key missing in defaults
                     groupData.color.picker.value = this._getHexForPicker(fgColor) || defaultHex;
                 }
            }
        }
    }

    _valueChanged(ev) {
        // Handles changes from entity pickers and the header text field
        if (!this._config || !this._initialized) return;
        const target = ev.target;
        const value = ev.detail?.value !== undefined ? ev.detail.value : target.value;
        const configKey = target.getAttribute('configValue');
        // console.log(`Value Changed: Key=${configKey}, Value=${value}, Target=${target.tagName}`); // Uncomment for debugging
        if (configKey) {
            if (value === "" || value === null || value === undefined) {
                if (configKey !== 'temperature' && configKey !== 'humidity') delete this._config[configKey];
                else this._config[configKey] = "";
            } else {
                this._config[configKey] = value;
            }
            this.fireConfigChanged();
        }
    }

     _colorChanged(ev) {
         // Handles changes from the color text fields and pickers
        if (!this._config || !this._initialized) return;
        const target = ev.target;
        const group = target.dataset.colorGroup;
        const key = target.dataset.colorKey;
        const value = target.value.trim();
        // console.log(`Color Changed: Group=${group}, Key=${key}, Value=${value}, Type=${target.type}`); // Uncomment for debugging
        if (!group || !key) return;

        // --- Update Config ---
        if (!this._config.colors) this._config.colors = {};
        if (!this._config.colors[group]) this._config.colors[group] = {};
        if (value) { this._config.colors[group][key] = value; }
        else {
            delete this._config.colors[group][key];
            if (Object.keys(this._config.colors[group]).length === 0) delete this._config.colors[group];
            if (Object.keys(this._config.colors).length === 0) delete this._config.colors;
        }

        // --- Synchronize Inputs ---
        const elements = this._elements.colors[group]?.[key];
        if (!elements) return;
        const defaultGroupColors = this._defaultHexColors[group] || {}; // Get defaults
        // Determine the correct default hex for this specific key (bg or color)
        const defaultHex = defaultGroupColors[key] || (key === 'color' ? '#ffffff' : '#000000');

        if (target.type === 'color') { // Picker changed -> update text field
            if (elements.text) elements.text.value = value; // Picker always gives hex
        } else { // Text field changed -> update picker
            if (elements.picker) {
                // Attempt conversion, fallback to specific default hex
                elements.picker.value = this._getHexForPicker(value) || defaultHex;
            }
        }

        this.fireConfigChanged();
    }

    fireConfigChanged() {
        // Creates a deep copy and dispatches the event HA listens for
        const newConfig = JSON.parse(JSON.stringify(this._config));
        // console.log("Firing config-changed with:", newConfig); // Uncomment for debugging
        const event = new CustomEvent("config-changed", {
            detail: { config: newConfig },
            bubbles: true,
            composed: true,
        });
        this.dispatchEvent(event);
    }
}

// Define the custom element for the editor, ensuring it's only defined once
if (!customElements.get('vpd-card-editor')) {
    customElements.define('vpd-card-editor', VpdCardEditor);
}

// ======================================================================
// == Card Registration                                                ==
// ======================================================================
window.customCards = window.customCards || [];
window.customCards.push({
    type: "vpd-card", // Should match customElements.define('vpd-card', ...)
    name: "VPD Table Card",
    description: "Displays a VPD table and highlights the current conditions based on temperature and humidity sensors.",
    preview: true, // Enable preview in card picker
    // documentationURL: "https://github.com/blade-/ha-vpd-chart"
});