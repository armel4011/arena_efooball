/// Supported fiat currencies across the rollout.
///
/// V1.0 actives → [xaf], [xof], [usd]
/// V1.1 actives → + Anglo Africa
/// V1.2 actives → + Maghreb
///
/// `decimalDigits = 0` for currencies where users never see fractions
/// (CFA franc, Naira at retail level).
enum Currency {
  // V1.0 — Francophone Africa
  xaf(code: 'XAF', symbol: 'FCFA', name: 'Franc CFA (BEAC)', decimalDigits: 0),
  xof(code: 'XOF', symbol: 'CFA', name: 'Franc CFA (BCEAO)', decimalDigits: 0),
  usd(code: 'USD', symbol: r'$', name: 'US Dollar', decimalDigits: 2),

  // V1.1 — Anglophone Africa
  ngn(code: 'NGN', symbol: '₦', name: 'Nigerian Naira', decimalDigits: 0),
  ghs(code: 'GHS', symbol: 'GH₵', name: 'Ghanaian Cedi', decimalDigits: 2),
  kes(code: 'KES', symbol: 'KSh', name: 'Kenyan Shilling', decimalDigits: 0),
  zar(code: 'ZAR', symbol: 'R', name: 'South African Rand', decimalDigits: 2),
  rwf(code: 'RWF', symbol: 'RF', name: 'Rwandan Franc', decimalDigits: 0),
  ugx(code: 'UGX', symbol: 'USh', name: 'Ugandan Shilling', decimalDigits: 0),
  tzs(code: 'TZS', symbol: 'TSh', name: 'Tanzanian Shilling', decimalDigits: 0),

  // V1.2 — Maghreb
  mad(code: 'MAD', symbol: 'DH', name: 'Moroccan Dirham', decimalDigits: 2),
  dzd(code: 'DZD', symbol: 'DA', name: 'Algerian Dinar', decimalDigits: 2),
  tnd(code: 'TND', symbol: 'DT', name: 'Tunisian Dinar', decimalDigits: 3),
  egp(code: 'EGP', symbol: 'E£', name: 'Egyptian Pound', decimalDigits: 2);

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.decimalDigits,
  });

  final String code;
  final String symbol;
  final String name;
  final int decimalDigits;

  static Currency fromCode(String code) {
    final upper = code.toUpperCase();
    return Currency.values.firstWhere(
      (c) => c.code == upper,
      orElse: () => Currency.usd,
    );
  }
}
