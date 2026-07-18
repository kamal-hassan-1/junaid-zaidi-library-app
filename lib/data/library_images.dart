/// Central registry of the library photography in assets/. Screens should
/// reference images via this file rather than hardcoding asset paths
/// directly, so there's a single place to update paths.
class LibraryImage {
  final String key;
  final String assetPath;
  final String caption;

  const LibraryImage({
    required this.key,
    required this.assetPath,
    required this.caption,
  });
}

final List<LibraryImage> libraryImages = [
  const LibraryImage(
    key: 'library-front-view',
    assetPath: 'assets/library-front-view.jpg',
    caption: 'Library front view',
  ),
  const LibraryImage(
    key: 'library-front-leftAngle-view',
    assetPath: 'assets/library-front-leftAngle-view.jpg',
    caption: 'Library, front-left angle',
  ),
  const LibraryImage(
    key: 'library-ground-floor',
    assetPath: 'assets/library-ground-floor.jpg',
    caption: 'Ground floor',
  ),
  const LibraryImage(
    key: 'library-firstFloor',
    assetPath: 'assets/library-firstFloor.jpg',
    caption: 'First floor',
  ),
  const LibraryImage(
    key: 'book-shelves',
    assetPath: 'assets/book-shelves.jpg',
    caption: 'Book shelves',
  ),
  const LibraryImage(
    key: 'book-shelves-front',
    assetPath: 'assets/book-shelves-front.jpg',
    caption: 'Book shelves, front view',
  ),
  const LibraryImage(
    key: 'magazine-shelf',
    assetPath: 'assets/magazine-shelf.jpg',
    caption: 'Magazine shelf',
  ),
  const LibraryImage(
    key: 'group-study-rooms',
    assetPath: 'assets/group-study-rooms.jpg',
    caption: 'Group study rooms',
  ),
  const LibraryImage(
    key: 'conference-room',
    assetPath: 'assets/conference-room.jpg',
    caption: 'Conference room',
  ),
  const LibraryImage(
    key: 'basement-conference-room',
    assetPath: 'assets/basement-conference-room.jpg',
    caption: 'Basement conference room',
  ),
  const LibraryImage(
    key: 'women-corner',
    assetPath: 'assets/women-corner.jpg',
    caption: "Women's corner",
  ),
  const LibraryImage(
    key: 'coffee-shop-1',
    assetPath: 'assets/coffee-shop-1.jpg',
    caption: 'Coffee shop',
  ),
  const LibraryImage(
    key: 'public-computer-section',
    assetPath: 'assets/public-computer-section.jpg',
    caption: 'Public computer section',
  ),
  const LibraryImage(
    key: 'public-computer-cubicles',
    assetPath: 'assets/public-computer-cubicles.jpg',
    caption: 'Public computer cubicles',
  ),
  const LibraryImage(
    key: 'front-desk',
    assetPath: 'assets/front-desk.jpg',
    caption: 'Front desk',
  ),
  const LibraryImage(
    key: 'library-drop-box',
    assetPath: 'assets/library-drop-box.jpg',
    caption: 'Book drop box',
  ),
  const LibraryImage(
    key: 'art-gallery-1',
    assetPath: 'assets/art-gallery-1.jpg',
    caption: 'Art gallery',
  ),
  const LibraryImage(
    key: 'art-gallery-2',
    assetPath: 'assets/art-gallery-2.jpg',
    caption: 'Art gallery',
  ),
  const LibraryImage(
    key: 'book-lending-software-opened-on-desktop',
    assetPath: 'assets/book-lending-software-opened-on-desktop.jpg',
    caption: 'Book lending desk',
  ),
];

const String logoImagePath = 'assets/logo.png';

/// Used as the Home screen's low-opacity background photo.
const String homeBackgroundImagePath = 'assets/library-front-view.jpg';
