import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/library_location.dart';
import '../../services/osm_map_html.dart';
import '../../theme/theme.dart';

/// Map screen (mirrors `app/(tabs)/more/map.js`): an embedded
/// Leaflet/OpenStreetMap WebView centered on the library. The popup's
/// "Open in Google Maps" link posts a message back through the
/// `ReactNativeWebView` JavaScript channel, which this screen listens for
/// to hand off to the native Google Maps app/browser.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final html = buildOsmMapHtml(
      latitude: libraryLocation.latitude,
      longitude: libraryLocation.longitude,
      title: libraryLocation.name,
    );
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'ReactNativeWebView',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'open-google-maps') {
            launchUrl(
              Uri.parse(googleMapsUrl(libraryLocation)),
              mode: LaunchMode.externalApplication,
            );
          }
        },
      )
      ..loadHtmlString(html);
  }

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    return Container(
      color: colors.background.primary,
      child: WebViewWidget(controller: _controller),
    );
  }
}
