import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/partner_repository.dart';

class PartnerSession {
  const PartnerSession({this.profile, this.loading = false, this.error, this.deniedStatus, this.reviewReason, this.restoreFailed = false});
  final PartnerProfile? profile;
  final bool loading;
  final String? error;
  final String? deniedStatus;
  final String? reviewReason;
  final bool restoreFailed;
}

final partnerSessionProvider = StateNotifierProvider<PartnerSessionNotifier, PartnerSession>((ref) =>
  PartnerSessionNotifier(ref.watch(partnerRepositoryProvider)));

class PartnerSessionNotifier extends StateNotifier<PartnerSession> {
  PartnerSessionNotifier(this._repository) : super(const PartnerSession(loading: true)) {
    restore();
  }
  final PartnerRepository _repository;

  Future<void> restore() async {
    state = PartnerSession(profile: state.profile, loading: true);
    try {
      final profile = await _repository.restore();
      if (mounted) state = PartnerSession(profile: profile);
    } on PartnerApiException catch (error) {
      if (mounted) state = PartnerSession(error: error.message, restoreFailed: !error.sessionRejected,
        deniedStatus: error.accountStatus, reviewReason: error.reviewReason);
    } catch (_) {
      if (mounted) state = const PartnerSession(error: 'Impossible de vérifier votre session. Réessayez.', restoreFailed: true);
    }
  }

  Future<void> _authenticate(Future<PartnerProfile> Function() action) async {
    state = const PartnerSession(loading: true);
    try {
      final profile = await action();
      if (mounted) state = PartnerSession(profile: profile);
    } on PartnerApiException catch (error) {
      if (mounted) state = PartnerSession(error: error.message, deniedStatus: error.accountStatus, reviewReason: error.reviewReason);
    } catch (_) {
      if (mounted) state = const PartnerSession(error: 'La connexion n’a pas abouti. Réessayez.');
    }
  }

  Future<void> login(String email, String password) => _authenticate(() => _repository.login(email, password));
  Future<void> register(Map<String, dynamic> fields) => _authenticate(() => _repository.register(fields));
  Future<void> refresh() async {
    if (state.profile == null) return restore();
    final previous = state.profile;
    state = PartnerSession(profile: previous, loading: true);
    try {
      final profile = await _repository.getMe();
      if (mounted) state = PartnerSession(profile: profile);
    } on PartnerApiException catch (error) {
      if (mounted) state = PartnerSession(profile: error.sessionRejected ? null : previous,
        error: error.message, deniedStatus: error.accountStatus, reviewReason: error.reviewReason);
    } catch (_) {
      if (mounted) state = PartnerSession(profile: previous, error: 'Actualisation impossible. Réessayez.');
    }
  }

  Future<void> logout() async {
    state = PartnerSession(profile: state.profile, loading: true);
    try { await _repository.logout(); } catch (_) { /* Local token is cleared even offline. */ }
    if (mounted) state = const PartnerSession();
  }
  void clearNotice() => state = const PartnerSession();
}
