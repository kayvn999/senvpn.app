import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/server_model.dart';
import '../../providers/locale_provider.dart';
import '../../providers/server_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/vpn_provider.dart';

// ── Tunable limits ──────────────────────────────────────────────────────────
const int kFreeCountriesMax = 100;     // max countries shown in free tab
const int kFreeServersPerCountry = 10; // max servers per country (free users)

class ServersScreen extends ConsumerStatefulWidget {
  const ServersScreen({super.key});

  @override
  ConsumerState<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends ConsumerState<ServersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Re-fetch on open — backend handles VPNGate toggle and filtering.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(serversProvider);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serversAsync = ref.watch(serversProvider);
    final allServers = serversAsync.valueOrNull ?? [];
    final isLoading = serversAsync.isLoading;
    final isPremium = ref.watch(isPremiumProvider);
    final s = ref.watch(l10nProvider);

    final freeServers = allServers.where((s) => s.isFree).toList();
    final vipServers = allServers.where((s) => s.isVip).toList();

    // Group both by country
    final freeGroups = _groupByCountry(freeServers, kFreeCountriesMax);
    final vipGroups  = _groupByCountry(vipServers, 999);

    // Filter by search
    final filteredGroups = _searchQuery.isEmpty
        ? freeGroups
        : freeGroups
            .where((g) =>
                g.country.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    final filteredVipGroups = _searchQuery.isEmpty
        ? vipGroups
        : vipGroups
            .where((g) =>
                g.country.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            _Header(
              totalFree: freeServers.length,
              totalVip: vipServers.length,
              searchQuery: _searchQuery,
              onSearch: (v) => setState(() => _searchQuery = v),
              title: s.chooseServer,
              searchHint: s.searchCountry,
            ),

            if (isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                color: Color(0xFF6366F1),
              ),

            const SizedBox(height: 12),

            // ── Tabs ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF6B7280),
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                  padding: const EdgeInsets.all(4),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(s.freeTab),
                          const SizedBox(width: 5),
                          _CountBadge(count: filteredGroups.length),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(s.vipTab),
                          const SizedBox(width: 5),
                          _CountBadge(count: filteredVipGroups.length),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Content ─────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Free — grouped by country
                  _CountryGroupList(
                    groups: filteredGroups,
                    isPremium: isPremium,
                  ),

                  // VIP — grouped by country (same UI as free)
                  isPremium
                      ? _CountryGroupList(
                          groups: filteredVipGroups,
                          isPremium: true,
                        )
                      : _VipLockedBanner(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Groups servers by country, sorted by best ping, limited to [maxCountries].
  List<_CountryGroup> _groupByCountry(
      List<ServerModel> servers, int maxCountries) {
    final map = <String, List<ServerModel>>{};
    for (final s in servers) {
      map.putIfAbsent(s.countryCode, () => []).add(s);
    }
    // Sort servers within each group by ping
    for (final list in map.values) {
      list.sort((a, b) => a.ping.compareTo(b.ping));
    }
    final groups = map.entries
        .map((e) => _CountryGroup(
              countryCode: e.key,
              country: e.value.first.country,
              flag: e.value.first.flag,
              servers: e.value,
              bestPing: e.value.first.ping,
            ))
        .toList()
      ..sort((a, b) => a.bestPing.compareTo(b.bestPing));

    return groups.take(maxCountries).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Country Group data class
// ─────────────────────────────────────────────────────────────────────────────
class _CountryGroup {
  final String countryCode;
  final String country;
  final String flag;
  final List<ServerModel> servers;
  final int bestPing;

  const _CountryGroup({
    required this.countryCode,
    required this.country,
    required this.flag,
    required this.servers,
    required this.bestPing,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatefulWidget {
  final int totalFree;
  final int totalVip;
  final String searchQuery;
  final ValueChanged<String> onSearch;
  final String title;
  final String searchHint;

  const _Header({
    required this.totalFree,
    required this.totalVip,
    required this.searchQuery,
    required this.onSearch,
    required this.title,
    required this.searchHint,
  });

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _ctrl,
              onChanged: widget.onSearch,
              style: const TextStyle(color: Color(0xFF111827), fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF9CA3AF), size: 20),
                suffixIcon: widget.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: Color(0xFF9CA3AF), size: 18),
                        onPressed: () {
                          _ctrl.clear();
                          widget.onSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Country Group List (Free tab)
// ─────────────────────────────────────────────────────────────────────────────
class _CountryGroupList extends ConsumerWidget {
  final List<_CountryGroup> groups;
  final bool isPremium;

  const _CountryGroupList({required this.groups, required this.isPremium});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (groups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public_off_rounded, color: Color(0xFF9CA3AF), size: 52),
            SizedBox(height: 12),
            Text('Không tìm thấy quốc gia',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final group = groups[i];
        final displayCount =
            isPremium ? group.servers.length : group.servers.length.clamp(0, kFreeServersPerCountry);
        return _CountryTile(
          group: group,
          displayCount: displayCount,
          onTap: () => _openCountrySheet(context, ref, group, isPremium),
        )
            .animate(delay: Duration(milliseconds: i * 40))
            .fadeIn(duration: 250.ms)
            .slideX(begin: 0.04, end: 0);
      },
    );
  }

  void _openCountrySheet(
      BuildContext context, WidgetRef ref, _CountryGroup group, bool isPremium) {
    final servers = isPremium
        ? group.servers
        : group.servers.take(kFreeServersPerCountry).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CountryServersSheet(
        group: group,
        servers: servers,
        isPremium: isPremium,
        ref: ref,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Country Tile
// ─────────────────────────────────────────────────────────────────────────────
class _CountryTile extends StatelessWidget {
  final _CountryGroup group;
  final int displayCount;
  final VoidCallback onTap;

  const _CountryTile({
    required this.group,
    required this.displayCount,
    required this.onTap,
  });

  Color get _pingColor {
    if (group.bestPing < 50) return const Color(0xFF10B981);
    if (group.bestPing < 150) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Flag
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(group.flag,
                    style: const TextStyle(fontSize: 28)),
              ),
            ),

            const SizedBox(width: 14),

            // Country info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.country,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _pingColor,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${group.bestPing} ms',
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$displayCount server',
                          style: const TextStyle(
                            color: Color(0xFF6366F1),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF), size: 22),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Country Servers Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _CountryServersSheet extends StatelessWidget {
  final _CountryGroup group;
  final List<ServerModel> servers;
  final bool isPremium;
  final WidgetRef ref;

  const _CountryServersSheet({
    required this.group,
    required this.servers,
    required this.isPremium,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final selectedServer = ref.watch(selectedServerProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Sheet header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Text(group.flag,
                    style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.country,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${servers.length} server khả dụng',
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (!isPremium && group.servers.length > kFreeServersPerCountry)
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/vip');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '+ VIP',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // Server list
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              itemCount: servers.length,
              shrinkWrap: true,
              itemBuilder: (context, i) {
                final server = servers[i];
                final isSelected = selectedServer?.id == server.id;
                return _ServerRow(
                  server: server,
                  isSelected: isSelected,
                  onTap: () async {
                    final vpnNotifier = ref.read(vpnNotifierProvider.notifier);
                    final vpnState = ref.read(vpnNotifierProvider);
                    ref.read(selectedServerProvider.notifier).state = server;
                    Navigator.pop(context);
                    context.pop();
                    // Auto-reconnect if currently connected
                    if (vpnState.isConnected || vpnState.isConnecting) {
                      await vpnNotifier.disconnect();
                      await Future.delayed(const Duration(milliseconds: 800));
                      await vpnNotifier.connect(server);
                    }
                  },
                ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideY(begin: 0.05);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Server Row (inside bottom sheet)
// ─────────────────────────────────────────────────────────────────────────────
class _ServerRow extends StatelessWidget {
  final ServerModel server;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServerRow({
    required this.server,
    required this.isSelected,
    required this.onTap,
  });

  Color get _pingColor {
    if (server.ping < 50) return const Color(0xFF10B981);
    if (server.ping < 150) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Ping indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: _pingColor),
            ),
            const SizedBox(width: 10),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    server.name,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text('${server.ping} ms',
                          style: const TextStyle(
                              color: Color(0xFF6B7280), fontSize: 12)),
                      const SizedBox(width: 10),
                      // Load bar
                      Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (server.load / 100).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: server.load < 50
                                  ? const Color(0xFF10B981)
                                  : server.load < 80
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text('${server.load}%',
                          style: const TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),

            if (isSelected)
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 15),
              )
            else
              _SpeedBadge(speedMbps: server.speedMbps),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Speed Badge
// ─────────────────────────────────────────────────────────────────────────────
class _SpeedBadge extends StatelessWidget {
  final double speedMbps;
  const _SpeedBadge({required this.speedMbps});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    if (speedMbps >= 500) {
      label = '⚡ Siêu nhanh';
      color = const Color(0xFF10B981);
    } else if (speedMbps >= 100) {
      label = '🚀 Nhanh';
      color = const Color(0xFF6366F1);
    } else if (speedMbps >= 10) {
      label = '👍 Ổn định';
      color = const Color(0xFF0EA5E9);
    } else {
      label = '🐢 Chậm';
      color = const Color(0xFFF59E0B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Count Badge (in tab)
// ─────────────────────────────────────────────────────────────────────────────
class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _VipLockedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'Server VIP',
            style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 22,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nâng cấp để truy cập server cao cấp\ntốc độ cao, ping thấp, ổn định',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => context.push('/vip'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Text(
                'Nâng cấp VIP ngay',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
