/// The signed-in student, as the library knows them.
///
/// Distinct from `AppUser` (the Firebase identity) and `ProfileData` (what the
/// More tab renders): this is the library-side record — the card you present at
/// the desk. Koha calls it a borrower.
///
/// No `fromJson` yet, deliberately. `CatalogItem` has one because
/// `RestCatalogRepository` parses documented endpoints; there is no patron
/// endpoint on the API contract, so a factory now would be inventing a wire
/// format. It arrives with `RestPatronRepository`, once the shape is known.
class Patron {
  final String name;

  /// The number printed on the library card. Koha's `cardnumber`, which at
  /// this university is the student's registration number.
  final String barcode;

  final String email;

  /// The branch the patron belongs to, and where holds default to for pickup.
  final String homeLibrary;

  const Patron({
    required this.name,
    required this.barcode,
    required this.email,
    required this.homeLibrary,
  });
}
