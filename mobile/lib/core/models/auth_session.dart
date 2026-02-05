class AuthSession {
  const AuthSession({
    required this.userId,
    required this.name,
    required this.email,
    required this.token,
  });

  final int userId;
  final String name;
  final String email;
  final String token;
}
