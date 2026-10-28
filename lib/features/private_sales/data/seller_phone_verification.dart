import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerPhoneVerificationProvider = Provider<SellerPhoneVerification>(
  (_) => SellerPhoneVerification(),
);

/// Links the phone to the EXISTING client; it never signs in as another account.
class SellerPhoneVerification {
  String? get linkedPhone => FirebaseAuth.instance.currentUser?.phoneNumber;

  Future<void> send(
    String phone, {
    required void Function(String) codeSent,
    required void Function(String) verified,
    required void Function(String) failed,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Connectez-vous pour vérifier votre téléphone.');
    }
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        try {
          verified(await _link(user, credential));
        } catch (_) {
          failed('La vérification automatique a échoué. Utilisez le code SMS.');
        }
      },
      verificationFailed: (_) => failed(
        'Le SMS n’a pas pu être envoyé. Vérifiez le numéro et réessayez.',
      ),
      codeSent: (id, _) => codeSent(id),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<String> confirm(String id, String code) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Reconnectez-vous avant de vérifier le téléphone.');
    }
    return _link(
      user,
      PhoneAuthProvider.credential(verificationId: id, smsCode: code),
    );
  }

  Future<String> _link(User user, PhoneAuthCredential credential) async {
    if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
      throw StateError('Le compte a changé. Recommencez la vérification.');
    }
    if (user.phoneNumber == null) {
      await user.linkWithCredential(credential);
    } else {
      await user.updatePhoneNumber(credential);
    }
    await user.reload();
    final current = FirebaseAuth.instance.currentUser;
    if (current == null || current.uid != user.uid) {
      throw StateError('Session modifiée.');
    }
    await current.getIdToken(true);
    return current.phoneNumber ?? '';
  }
}
