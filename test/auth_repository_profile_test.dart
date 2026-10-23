import 'package:auto/core/api/api_client.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _ProfileClient extends ApiClient {
  _ProfileClient(this.response);
  final Map<String, dynamic> response;

  @override
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? params}) async => response;
}

void main() {
  const profile = {
    'id': 1,
    'name': 'Responsable',
    'email': 'responsable@example.test',
    'role': 'manager',
  };

  for (final wrapped in [false, true]) {
    test('le profil personnel ${wrapped ? 'enveloppé' : 'plat'} restaure la session', () async {
      final repository = AuthRepository(_ProfileClient(wrapped ? {'data': profile} : profile));

      final user = await repository.getMe();

      expect(user.id, 1);
      expect(user.role, 'manager');
      expect(user.name, 'Responsable');
    });
  }
}
