/// Junaid Zaidi Library, COMSATS University Islamabad — Park Road, Islamabad.
/// Coordinates sourced from public COMSATS/library location listings.
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
  latitude: 33.651592,
  longitude: 73.156456,
);

String googleMapsUrl(LibraryLocation location) =>
    'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
