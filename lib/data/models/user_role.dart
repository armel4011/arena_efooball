/// User role as stored in the `profiles.role` column.
///
/// - [player]      → joueur lambda (app User)
/// - [admin]       → admin (app Admin uniquement)
/// - [superAdmin]  → super-admin (généré uniquement par invitation)
/// - [collector]   → agent collecteur de paiement (app Admin, périmètre RÉDUIT :
///                   valide uniquement les paiements de SON pays sous quota).
///                   N'est PAS un admin (isAdmin=false).
enum UserRole {
  player('player'),
  admin('admin'),
  superAdmin('super_admin'),
  collector('collector');

  const UserRole(this.value);

  final String value;

  static UserRole fromValue(String? value) {
    return UserRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => UserRole.player,
    );
  }
}
