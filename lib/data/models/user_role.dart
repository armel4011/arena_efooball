/// User role as stored in the `profiles.role` column.
///
/// - [player]      → joueur lambda (app User)
/// - [admin]       → admin (app Admin uniquement)
/// - [superAdmin]  → super-admin (généré uniquement par invitation)
enum UserRole {
  player('player'),
  admin('admin'),
  superAdmin('super_admin');

  const UserRole(this.value);

  final String value;

  static UserRole fromValue(String? value) {
    return UserRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => UserRole.player,
    );
  }
}
