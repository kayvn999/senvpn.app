import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../models/server_model.dart';
import '../../models/user_model.dart';
import '../constants/app_constants.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Users ───────────────────────────────────────────────────────────────

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _db.collection(AppConstants.colUsers).doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  Future<void> createUser(UserModel user) async {
    await _db.collection(AppConstants.colUsers).doc(user.uid).set(user.toMap());
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection(AppConstants.colUsers).doc(uid).update(data);
  }

  Stream<UserModel?> userStream(String uid) async* {
    UserModel fallback() => UserModel(
          uid: uid,
          email: '',
          displayName: 'Khách',
          createdAt: DateTime.now(),
        );

    // Initial fetch
    final first = await _getUserFromApi(uid);
    yield first ?? fallback();

    // Poll every 30s so VIP granted in admin reflects without restart
    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      final updated = await _getUserFromApi(uid);
      yield updated ?? fallback();
    }
  }

  Future<UserModel?> _getUserFromApi(String uid) async {
    try {
      final resp = await http
          .get(Uri.parse('https://lephap.io.vn/api/user/$uid'))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;
      final body = resp.body.trim();
      if (body == 'null' || body.isEmpty) return null;
      final data = jsonDecode(body);
      if (data == null) return null;
      return UserModel.fromApiMap(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> activatePremium(String uid, DateTime expiry) async {
    final ts = Timestamp.fromDate(expiry);
    await _db.collection(AppConstants.colUsers).doc(uid).update({
      'subscriptionStatus': 'vip',
      'tier': 'vip',
      'premiumExpiry': ts,
      'subscriptionExpiry': ts,
    });
  }

  Future<void> revokePremium(String uid) async {
    await _db.collection(AppConstants.colUsers).doc(uid).update({
      'subscriptionStatus': 'free',
      'tier': 'free',
      'premiumExpiry': null,
      'subscriptionExpiry': null,
    });
  }

  Future<void> updateDataUsage(String uid, int additionalMB) async {
    await _db.collection(AppConstants.colUsers).doc(uid).update({
      'usedDataTodayMB': FieldValue.increment(additionalMB),
    });
  }

  Future<void> resetDailyData(String uid) async {
    await _db.collection(AppConstants.colUsers).doc(uid).update({
      'usedDataTodayMB': 0,
    });
  }

  // ─── Servers ─────────────────────────────────────────────────────────────
  // Note: no orderBy in Firestore queries (requires composite index).
  // Sorting is done in-memory in server_provider.dart.

  Future<List<ServerModel>> getServers({bool freeOnly = false}) async {
    try {
      Query query = _db
          .collection(AppConstants.colServers)
          .where('isActive', isEqualTo: true);

      if (freeOnly) {
        query = query.where('isFree', isEqualTo: true);
      }

      final snapshot = await query.get();
      final servers = snapshot.docs
          .map((doc) => ServerModel.fromFirestore(doc))
          .where((s) => s.isActive)   // extra in-memory safety check
          .toList();
      servers.sort((a, b) => a.ping.compareTo(b.ping));
      return servers;
    } catch (_) {
      return [];
    }
  }

  Stream<List<ServerModel>> serversStream({bool freeOnly = false}) {
    Query query = _db
        .collection(AppConstants.colServers)
        .where('isActive', isEqualTo: true);

    if (freeOnly) {
      query = query.where('isFree', isEqualTo: true);
    }

    return query.snapshots().map((snap) {
      final servers = snap.docs
          .map((doc) => ServerModel.fromFirestore(doc))
          .where((s) => s.isActive)
          .toList();
      servers.sort((a, b) => a.ping.compareTo(b.ping));
      return servers;
    });
  }

  Future<ServerModel?> getBestServer(bool isPremium) async {
    try {
      Query query = _db
          .collection(AppConstants.colServers)
          .where('isActive', isEqualTo: true);

      if (!isPremium) {
        query = query.where('isFree', isEqualTo: true);
      }

      final snap = await query.get();
      final servers = snap.docs
          .map((doc) => ServerModel.fromFirestore(doc))
          .where((s) => s.isActive)
          .toList();
      if (servers.isEmpty) return null;
      servers.sort((a, b) => a.ping.compareTo(b.ping));
      return servers.first;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateServerStats(String serverId, Map<String, dynamic> stats) async {
    await _db
        .collection(AppConstants.colServers)
        .doc(serverId)
        .update(stats);
  }

  // ─── Connections ─────────────────────────────────────────────────────────

  Future<String?> logConnectionStart({
    required String uid,
    required String email,
    required String serverName,
    required String serverCountry,
  }) async {
    try {
      final ref = await _db.collection('connections').add({
        'uid': uid,
        'email': email,
        'serverName': serverName,
        'serverCountry': serverCountry,
        'connectedAt': Timestamp.now(),
      });
      return ref.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> logConnectionEnd(String logId, double dataMB) async {
    try {
      await _db.collection('connections').doc(logId).update({
        'disconnectedAt': Timestamp.now(),
        'dataMB': dataMB,
      });
    } catch (_) {}
  }

  // ─── App Version ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getAppVersion() async {
    try {
      final doc = await _db
          .collection(AppConstants.colAppConfig)
          .doc('app_version')
          .get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  // ─── App Config ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getAppConfig() async {
    try {
      final doc = await _db
          .collection(AppConstants.colAppConfig)
          .doc('free_settings')
          .get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  Stream<Map<String, dynamic>?> appConfigStream() {
    return _db
        .collection(AppConstants.colAppConfig)
        .doc('free_settings')
        .snapshots()
        .map((doc) => doc.data());
  }

  Future<List<Map<String, dynamic>>> getVipPlans() async {
    try {
      final resp = await http.get(Uri.parse('https://lephap.io.vn/api/plans'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return [];
      final list = jsonDecode(resp.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> initDefaultConfig() async {
    final ref = _db.collection(AppConstants.colAppConfig).doc('free_settings');
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'freeDataLimitMB': 500,
        'freeServersPerCountry': 3,
        'freeMaxConnections': 1,
        'allowedCountries': [],
        'blockedCountries': [],
        'maintenanceMode': false,
        'maintenanceMessage': '',
        'vpngateEnabled': true,
        'vpngateMaxServers': 300,
      });
    }
  }
}
