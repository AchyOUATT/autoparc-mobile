import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/garage_repository.dart';
import '../../data/models/vin_decode_result.dart';

// ── State ────────────────────────────────────────────────────────────────────

/// État du décodage VIN dans le formulaire "Ajouter au garage".
class VinDecodeState {
  final AsyncValue<VinDecodeResult?> result;

  const VinDecodeState({this.result = const AsyncData(null)});

  bool get isLoading => result is AsyncLoading;
  bool get hasResult  => result.valueOrNull != null;

  VinDecodeState copyWith({AsyncValue<VinDecodeResult?>? result}) =>
      VinDecodeState(result: result ?? this.result);
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class VinDecodeNotifier extends Notifier<VinDecodeState> {
  GarageRepository get _repo => ref.read(garageRepositoryProvider);

  @override
  VinDecodeState build() => const VinDecodeState();

  /// Lance le décodage. Ignore si le VIN fait moins de 17 chars.
  Future<void> decode(String vin) async {
    final cleaned = vin.trim().toUpperCase();
    if (cleaned.length != 17) return;

    state = state.copyWith(result: const AsyncLoading());

    state = state.copyWith(
      result: await AsyncValue.guard(() => _repo.decodeVin(cleaned)),
    );
  }

  /// Réinitialise (ex. : quand l'utilisateur vide le champ VIN).
  void reset() => state = const VinDecodeState();
}

// ── Provider ─────────────────────────────────────────────────────────────────

/// Provider local au formulaire — ne pas exposer globalement (état éphémère).
final vinDecodeProvider =
    NotifierProvider<VinDecodeNotifier, VinDecodeState>(
  VinDecodeNotifier.new,
);
