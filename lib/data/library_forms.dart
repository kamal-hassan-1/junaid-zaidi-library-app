import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/accents.dart';

/// Confirm copy before opening an external (Google Forms, etc.) form.
const String kExternalFormRedirectMessage =
    'This action will redirect you to an external form.';

/// Confirm copy before opening a downloadable PDF form.
const String kFormDownloadMessage =
    'This action will open a PDF form for download.';

/// One library form — used on the Services tab and the More → Forms screen.
class LibraryFormLink {
  final String title;
  final String? subtitle;
  final IconData icon;
  final AppAccent accent;
  final String url;

  /// When true, [url] is a PDF (or similar) download rather than a web form.
  final bool isDownload;

  const LibraryFormLink({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.accent,
    required this.url,
    this.isDownload = false,
  });

  String get confirmMessage =>
      isDownload ? kFormDownloadMessage : kExternalFormRedirectMessage;
}

final List<LibraryFormLink> libraryForms = [
  const LibraryFormLink(
    title: 'Plagiarism Report',
    subtitle: 'Request a plagiarism check',
    icon: LucideIcons.file_search,
    accent: AppAccent.error,
    url: 'https://forms.gle/m2R5ytHW6ZMPMwKg7',
  ),
  const LibraryFormLink(
    title: 'Wi‑Fi Password Set / Reset',
    subtitle: 'Network access form',
    icon: LucideIcons.wifi,
    accent: AppAccent.brand,
    url:
        'https://docs.google.com/forms/d/e/1FAIpQLSeqIcDqFBoKu-fpSf2nqCcleYJqg1O5-nwizQ4SwSSIiwBWqw/viewform',
  ),
  const LibraryFormLink(
    title: 'Book(s) Purchase Request',
    subtitle: 'PDF request form',
    icon: LucideIcons.book_plus,
    accent: AppAccent.warning,
    url: 'https://library.comsats.edu.pk/Images/Purchase_Request_Form.pdf',
    isDownload: true,
  ),
  const LibraryFormLink(
    title: 'VPN Request',
    subtitle: 'Remote access form',
    icon: LucideIcons.shield,
    accent: AppAccent.success,
    url:
        'https://docs.google.com/forms/d/e/1FAIpQLSc8LcJfyYU32CSRg6dgEqRyEDLojJ0AmxC3knLhNHHr5L3ZOg/viewform',
  ),
  const LibraryFormLink(
    title: 'Library Membership Form',
    subtitle: 'Membership application',
    icon: LucideIcons.id_card,
    accent: AppAccent.brand,
    url:
        'https://docs.google.com/forms/d/e/1FAIpQLSegZ6Xab_X4UZ9mjq8C0Fu0KibFQ-Mt-b5cga3u0gEZWUUeaQ/viewform',
  ),
  const LibraryFormLink(
    title: 'SDI Inquiry Form',
    subtitle: 'PDF inquiry form',
    icon: LucideIcons.clipboard_list,
    accent: AppAccent.warning,
    url: 'https://library.comsats.edu.pk/files/SDI%20Inquiry%20Form.pdf',
    isDownload: true,
  ),
];
