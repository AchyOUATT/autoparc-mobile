import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/endpoints.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(apiClientProvider)),
);

class StaffUser {
  final int id;
  final String name;
  final String email;
  final String role;

  const StaffUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory StaffUser.fromJson(Map<String, dynamic> json) => StaffUser(
    id:    json['id']    as int,
    name:  json['name']  as String,
    email: json['email'] as String,
    role:  json['role']  as String,
  );
}

class AuthRepository {
  final ApiClient _client;
  const AuthRepository(this._client);

  // ── Staff (Sanctum) ───────────────────────────────────────────────

  /// Authentifie un membre du staff, stocke le token Sanctum.
  Future<StaffUser> loginStaff(String email, String password) async {
    final json = await _client.post(Endpoints.login, data: {
      'email':    email,
      'password': password,
    });

    final token = json['token'] as String?;
    if (token == null) throw const ApiException(message: 'Token manquant dans la réponse.');

    await ApiClient.saveToken(token);

    return StaffUser.fromJson(json['user'] as Map<String, dynamic>);
  }

  /// Récupère le profil staff courant (vérifie aussi que le token est toujours valide).
  Future<StaffUser> getMe() async {
    final json = await _client.get(Endpoints.me);
    return StaffUser.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Déconnecte le staff : révoque le token côté serveur, le supprime localement.
  Future<void> logoutStaff() async {
    try {
      await _client.post(Endpoints.logout);
    } catch (_) {
      // On supprime le token local même si le serveur est injoignable.
    }
    await ApiClient.deleteToken();
  }

  // ── Client Firebase ───────────────────────────────────────────────

  /// Connexion Google (client mobile).
  Future<User> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    final result   = await FirebaseAuth.instance.signInWithProvider(provider);
    return result.user!;
  }

  /// Connexion email/password Firebase (client mobile).
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email:    email,
      password: password,
    );
    return cred.user!;
  }

  /// Inscription Firebase (nouveau client).
  Future<User> registerWithEmailAndPassword(String email, String password) async {
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email:    email,
      password: password,
    );
    return cred.user!;
  }

  /// Déconnecte le client Firebase.
  Future<void> signOutClient() => FirebaseAuth.instance.signOut();

  /// Stream de l'état Firebase Auth — émet à chaque changement de session.
  Stream<User?> get firebaseAuthStream => FirebaseAuth.instance.authStateChanges();
}
