import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/firebase/auth_service.dart';
import '../core/firebase/firestore_service.dart';
import '../core/services/device_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Persistent device ID — stable across restarts, doesn't depend on Firebase Auth
final deviceIdProvider = FutureProvider<String>((ref) {
  return DeviceService.instance.getDeviceId();
});

final userModelProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final loggedInUser = authState.valueOrNull;

  // If user is signed in with Google/Email (not anonymous), use their Firebase UID
  if (loggedInUser != null && !loggedInUser.isAnonymous) {
    return ref.watch(firestoreServiceProvider).userStream(loggedInUser.uid);
  }

  // Otherwise use persistent device ID — works 100% via VPS, no Firebase Auth needed
  final deviceId = ref.watch(deviceIdProvider);
  return deviceId.when(
    data: (id) => ref.watch(firestoreServiceProvider).userStream(id),
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

final isPremiumProvider = Provider<bool>((ref) {
  final user = ref.watch(userModelProvider).valueOrNull;
  return user?.isPremium ?? false;
});

/// Watches live user stream and keeps FCM topics in sync with VIP status.
final fcmTopicSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<UserModel?>>(userModelProvider, (prev, next) {
    final prevVip = prev?.valueOrNull?.isPremium ?? false;
    final nextUser = next.valueOrNull;
    final nextVip = nextUser?.isPremium ?? false;
    if (prevVip == nextVip) return;
    final msg = FirebaseMessaging.instance;
    if (nextVip) {
      msg.subscribeToTopic('vip_users');
      msg.unsubscribeFromTopic('free_users');
    } else if (nextUser != null) {
      msg.subscribeToTopic('free_users');
      msg.unsubscribeFromTopic('vip_users');
    }
  });
});

final userNotifierProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
  return UserNotifier(
    ref.watch(authServiceProvider),
    ref.watch(firestoreServiceProvider),
  );
});

class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  UserNotifier(this._authService, this._firestoreService)
      : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((user) async {
      if (user == null) {
        state = const AsyncValue.data(null);
        _syncFcmTopics(null);
        return;
      }
      try {
        final userModel = await _firestoreService.getUser(user.uid);
        state = AsyncValue.data(userModel);
        _syncFcmTopics(userModel);
      } catch (e, st) {
        state = AsyncValue.error(e, st);
      }
    });
  }

  void _syncFcmTopics(UserModel? user) {
    final msg = FirebaseMessaging.instance;
    if (user == null) {
      msg.unsubscribeFromTopic('all_users');
      msg.unsubscribeFromTopic('vip_users');
      msg.unsubscribeFromTopic('free_users');
    } else {
      msg.subscribeToTopic('all_users');
      if (user.isPremium) {
        msg.subscribeToTopic('vip_users');
        msg.unsubscribeFromTopic('free_users');
      } else {
        msg.subscribeToTopic('free_users');
        msg.unsubscribeFromTopic('vip_users');
      }
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithGoogle();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithEmail(email, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signUpWithEmail(email, password, name);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> continueAsGuest() async {
    await _authService.signInAnonymously();
  }
}
