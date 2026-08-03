/// Junaid Zaidi Library, COMSATS University Islamabad — Park Road, Islamabad.
/// Coordinates pinned directly on the actual library building via Google
/// Maps (not the general campus centroid, which was the previous bug).
class LibraryLocation {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  const LibraryLocation({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

const LibraryLocation libraryLocation = LibraryLocation(
  name: 'Junaid Zaidi Library, COMSATS University Islamabad',
  address: 'Park Road, Tarlai Kalan, Islamabad 45550, Pakistan',
  latitude: 33.649362,
  longitude: 73.154569,
);

String googleMapsUrl(LibraryLocation location) =>
    'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';