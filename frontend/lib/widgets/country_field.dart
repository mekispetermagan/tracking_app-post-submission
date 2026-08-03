import 'package:flutter/material.dart';

import '../config/supported_countries.dart';

class CountryField extends StatelessWidget {
  final SupportedCountry country;

  const CountryField({
    this.country = SupportedCountries.defaultCountry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: country.name,
      readOnly: true,
      decoration: const InputDecoration(suffixIcon: Icon(Icons.lock_outline)),
    );
  }
}
