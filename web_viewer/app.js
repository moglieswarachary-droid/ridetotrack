document.addEventListener("DOMContentLoaded", () => {
  // Extract share token from URL path: /live/{share_token}
  const pathParts = window.location.pathname.split("/").filter(Boolean);
  const shareToken = pathParts[pathParts.length - 1];

  let map;
  let bikeMarker;
  let routePolyline;
  let autoFollow = true;
  let ws;
  let timerInterval;
  let rideStartTime = null;

  // DOM elements
  const bikeTitleEl = document.getElementById("bike-title");
  const connectionStatusEl = document.getElementById("connection-status");
  const connectionChipEl = document.getElementById("connection-chip");
  const currentSpeedEl = document.getElementById("current-speed");
  const speedBarEl = document.getElementById("speed-bar");
  const totalDistanceEl = document.getElementById("total-distance");
  const rideDurationEl = document.getElementById("ride-duration");
  const batteryLevelEl = document.getElementById("battery-level");
  const lastUpdateEl = document.getElementById("last-update");
  const btnRecenter = document.getElementById("btn-recenter");
  const btnToggleFollow = document.getElementById("btn-toggle-follow");

  // Initialize Map
  function initMap() {
    map = L.map("live-map", {
      zoomControl: false,
      attributionControl: false
    }).setView([12.9716, 77.5946], 15);

    L.control.zoom({ position: "topleft" }).addTo(map);

    // Dark Map Tiles (CartoDB Dark Matter)
    L.tileLayer("https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}{r}.png", {
      maxZoom: 19,
      subdomains: "abcd",
    }).addTo(map);

    // Polyline for Route
    routePolyline = L.polyline([], {
      color: "#00E5FF",
      weight: 5,
      opacity: 0.85,
      lineJoin: "round"
    }).addTo(map);

    // Custom Glowing Motorcycle Marker
    const bikeIcon = L.divIcon({
      className: "bike-custom-icon",
      html: `
        <div style="
          width: 28px;
          height: 28px;
          border-radius: 50%;
          background: #00E5FF;
          border: 3px solid #FFFFFF;
          box-shadow: 0 0 15px #00E5FF, 0 0 25px rgba(0,229,255,0.6);
          display: flex;
          align-items: center;
          justify-content: center;
        ">
          <div style="width: 8px; height: 8px; border-radius: 50%; background: #0A0D14;"></div>
        </div>
      `,
      iconSize: [28, 28],
      iconAnchor: [14, 14]
    });

    bikeMarker = L.marker([12.9716, 77.5946], { icon: bikeIcon }).addTo(map);
  }

  // Update Telemetry Display
  function updateTelemetry(data) {
    if (data.bike_name) {
      const model = data.bike_model ? ` • ${data.bike_model}` : "";
      bikeTitleEl.innerText = `${data.bike_manufacturer || ""} ${data.bike_name}${model}`.trim();
    }

    const speed = Math.round(data.last_speed_kmh || data.speed_kmh || 0);
    currentSpeedEl.innerText = speed;
    const speedPct = Math.min(100, Math.round((speed / 160) * 100));
    speedBarEl.style.width = `${speedPct}%`;

    if (data.distance_km !== undefined) {
      totalDistanceEl.innerHTML = `${data.distance_km.toFixed(1)} <small>km</small>`;
    }

    if (data.last_battery_pct !== undefined && data.last_battery_pct !== null) {
      batteryLevelEl.innerText = `${data.last_battery_pct}%`;
    } else if (data.battery_pct !== undefined && data.battery_pct !== null) {
      batteryLevelEl.innerText = `${data.battery_pct}%`;
    }

    if (data.started_at && !rideStartTime) {
      rideStartTime = new Date(data.started_at);
      startDurationTimer();
    }

    lastUpdateEl.innerText = new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" });

    // Update coordinates & route
    const lat = data.last_latitude || data.latitude;
    const lng = data.last_longitude || data.longitude;

    if (lat && lng) {
      const newLatLng = [lat, lng];
      bikeMarker.setLatLng(newLatLng);
      routePolyline.addLatLng(newLatLng);

      if (autoFollow) {
        map.panTo(newLatLng, { animate: true, duration: 1.0 });
      }
    }
  }

  function startDurationTimer() {
    if (timerInterval) clearInterval(timerInterval);
    timerInterval = setInterval(() => {
      if (!rideStartTime) return;
      const now = new Date();
      const diffSec = Math.max(0, Math.floor((now - rideStartTime) / 1000));
      const hours = String(Math.floor(diffSec / 3600)).padStart(2, "0");
      const minutes = String(Math.floor((diffSec % 3600) / 60)).padStart(2, "0");
      const seconds = String(diffSec % 60).padStart(2, "0");
      rideDurationEl.innerText = `${hours}:${minutes}:${seconds}`;
    }, 1000);
  }

  // Fetch initial telemetry state via REST
  async function loadInitialState() {
    try {
      const response = await fetch(`/api/v1/shares/view/${shareToken}`);
      if (!response.ok) {
        connectionStatusEl.innerText = "Link Expired";
        connectionChipEl.className = "status-chip offline";
        bikeTitleEl.innerText = "This live tracking link is inactive or expired.";
        return;
      }

      const data = await response.json();
      if (!data.is_active || data.is_expired) {
        connectionStatusEl.innerText = "Ride Ended";
        connectionChipEl.className = "status-chip offline";
        bikeTitleEl.innerText = `${data.bike_name} • Ride Concluded`;
      } else {
        connectionStatusEl.innerText = "Live";
        connectionChipEl.className = "status-chip online";
      }

      // Populate full existing route
      if (data.route_points && data.route_points.length > 0) {
        const latLngs = data.route_points.map(p => [p.lat, p.lng]);
        routePolyline.setLatLngs(latLngs);
        const lastPt = latLngs[latLngs.length - 1];
        bikeMarker.setLatLng(lastPt);
        map.setView(lastPt, 16);
      }

      updateTelemetry(data);
      connectWebSocket();
    } catch (err) {
      console.error("Failed to load live state:", err);
      connectionStatusEl.innerText = "Offline";
      connectionChipEl.className = "status-chip offline";
    }
  }

  // Connect to Live WebSocket Channel
  function connectWebSocket() {
    const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
    const wsUrl = `${protocol}//${window.location.host}/api/v1/ws/live/${shareToken}`;

    ws = new WebSocket(wsUrl);

    ws.onopen = () => {
      connectionStatusEl.innerText = "Live";
      connectionChipEl.className = "status-chip online";
    };

    ws.onmessage = (event) => {
      try {
        const msg = JSON.parse(event.data);
        if (msg.type === "LOCATION_UPDATE" && msg.data) {
          updateTelemetry(msg.data);
        } else if (msg.type === "SESSION_STOPPED") {
          connectionStatusEl.innerText = "Ride Finished";
          connectionChipEl.className = "status-chip offline";
        }
      } catch (e) {
        console.error("Error parsing WS message:", e);
      }
    };

    ws.onclose = () => {
      connectionStatusEl.innerText = "Reconnecting";
      connectionChipEl.className = "status-chip";
      // Retry in 4 seconds
      setTimeout(connectWebSocket, 4000);
    };
  }

  // Controls Event Listeners
  btnRecenter.addEventListener("click", () => {
    const pos = bikeMarker.getLatLng();
    map.setView(pos, 16, { animate: true });
  });

  btnToggleFollow.addEventListener("click", () => {
    autoFollow = !autoFollow;
    btnToggleFollow.classList.toggle("active", autoFollow);
  });

  btnToggleFollow.classList.add("active");

  initMap();
  loadInitialState();
});
