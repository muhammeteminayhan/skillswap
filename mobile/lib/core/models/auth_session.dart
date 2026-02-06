class AuthSession {
  const AuthSession({
    required this.userId,
    required this.name,
    required this.email,
  });

  final int userId;
  final String name;
  final String email;
}
