import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Clé globale du Scaffold shell.
/// Permet aux pages enfants (liste véhicules, pièces, accessoires)
/// d'ouvrir le drawer depuis leur propre AppBar.
final shellScaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>(
  (_) => GlobalKey<ScaffoldState>(),
);
