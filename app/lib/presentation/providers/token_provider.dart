import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tokenProvider = FutureProvider<String?>((ref) async {
  final user = fb.FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  return await user.getIdToken();
});
