import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/accents.dart';

/// Confirm copy before opening a downloadable library guide (PDF).
const String kGuideDownloadMessage =
    'This action will open a PDF guide for download.';

/// Confirm copy before opening the VPN video tutorial on YouTube.
const String kGuideVideoRedirectMessage =
    'This action will redirect you to YouTube to watch the video tutorial.';

enum LibraryGuideAction { download, externalVideo }

/// One guide on the Guides & Documentation screen.
class LibraryGuideLink {
  final String title;
  final IconData icon;
  final AppAccent accent;
  final String url;
  final LibraryGuideAction action;

  const LibraryGuideLink({
    required this.title,
    required this.icon,
    required this.accent,
    required this.url,
    required this.action,
  });

  String get confirmMessage => switch (action) {
        LibraryGuideAction.download => kGuideDownloadMessage,
        LibraryGuideAction.externalVideo => kGuideVideoRedirectMessage,
      };
}

final List<LibraryGuideLink> libraryGuides = [
  const LibraryGuideLink(
    title: 'Library Handbook',
    icon: LucideIcons.download,
    accent: AppAccent.brand,
    url:
        'https://library.comsats.edu.pk/Images/Library%20Booklet%20design.pdf',
    action: LibraryGuideAction.download,
  ),
  const LibraryGuideLink(
    title: 'Turnitin Usage Guide',
    icon: LucideIcons.download,
    accent: AppAccent.error,
    url: 'https://library.comsats.edu.pk/Files/User%20Guide%20-%20Turnitin.pdf',
    action: LibraryGuideAction.download,
  ),
  const LibraryGuideLink(
    title: 'VPN User Guide',
    icon: LucideIcons.download,
    accent: AppAccent.success,
    url: 'https://library.comsats.edu.pk/Files/VPN%20User%20Guide.pdf',
    action: LibraryGuideAction.download,
  ),
  const LibraryGuideLink(
    title: 'Video Tutorial for VPN Configuration',
    icon: LucideIcons.external_link,
    accent: AppAccent.warning,
    url: 'https://www.youtube.com/watch?v=uE-aH82Chm8',
    action: LibraryGuideAction.externalVideo,
  ),
  const LibraryGuideLink(
    title: 'VPN User Guide for MacOS',
    icon: LucideIcons.download,
    accent: AppAccent.success,
    url:
        'https://library.comsats.edu.pk/Files/vpn%20user%20guide%20for%20MAC%20users.pdf',
    action: LibraryGuideAction.download,
  ),
  const LibraryGuideLink(
    title: 'VPN User Guide for Windows 8',
    icon: LucideIcons.download,
    accent: AppAccent.success,
    url: 'https://library.comsats.edu.pk/Files/VPN_Window8_Guide.pdf',
    action: LibraryGuideAction.download,
  ),
  const LibraryGuideLink(
    title: 'VPN User Guide for Windows 7',
    icon: LucideIcons.download,
    accent: AppAccent.success,
    url: 'https://library.comsats.edu.pk/Files/VPN_Window7_Guide.pdf',
    action: LibraryGuideAction.download,
  ),
  const LibraryGuideLink(
    title: 'How to write PHD thesis',
    icon: LucideIcons.download,
    accent: AppAccent.brand,
    url:
        'https://library.comsats.edu.pk/Files/PhD_Thesis_guidelines_handbook.pdf',
    action: LibraryGuideAction.download,
  ),
  const LibraryGuideLink(
    title: 'Guidelines for Writing MS Thesis',
    icon: LucideIcons.download,
    accent: AppAccent.brand,
    url:
        'https://library.comsats.edu.pk/Files/MS_Thesis_guidelines_hanbook.pdf',
    action: LibraryGuideAction.download,
  ),
];
