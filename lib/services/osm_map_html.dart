/// Builds a self-contained Leaflet/OpenStreetMap HTML page for use inside a
/// WebView. The marker's popup contains an "Open in Google Maps" link;
/// tapping it posts a message back to Flutter via a `ReactNativeWebView`
/// JavaScriptChannel (registered by the Map screen) so the deep link opens
/// in the native Google Maps app/browser rather than inside the WebView.
String buildOsmMapHtml({
  required double latitude,
  required double longitude,
  required String title,
}) {
  return """<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <style>
      html, body, #map { height: 100%; margin: 0; padding: 0; }
      .popup-button {
        display: inline-block;
        margin-top: 6px;
        padding: 6px 12px;
        background: #1D4ED8; /* Base 700 — brand blue */
        color: #fff;
        border-radius: 999px;
        font-family: -apple-system, sans-serif;
        font-size: 13px;
        text-decoration: none;
      }
      .popup-title {
        font-family: -apple-system, sans-serif;
        font-size: 14px;
        font-weight: 600;
        margin-bottom: 4px;
        display: block;
      }
    </style>
  </head>
  <body>
    <div id="map"></div>
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script>
      var map = L.map('map', { zoomControl: true }).setView([$latitude, $longitude], 16);
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap contributors'
      }).addTo(map);

      var marker = L.marker([$latitude, $longitude]).addTo(map);
      var popupHtml = '<span class="popup-title">$title</span>' +
        '<a class="popup-button" href="#" onclick="window.ReactNativeWebView.postMessage(\\'open-google-maps\\'); return false;">Open in Google Maps</a>';
      marker.bindPopup(popupHtml).openPopup();
    </script>
  </body>
</html>""";
}
