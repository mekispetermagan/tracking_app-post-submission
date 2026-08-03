class SupportedCountry {
  final int id;
  final String name;

  const SupportedCountry({required this.id, required this.name});
}

abstract final class SupportedCountries {
  static const uganda = SupportedCountry(id: 1, name: 'Uganda');
  static const values = [uganda];
  static const defaultCountry = uganda;

  static String? nameForId(int? id) {
    if (id == null) return null;
    for (final country in values) {
      if (country.id == id) return country.name;
    }
    return null;
  }
}
