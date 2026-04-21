import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tedu_qrcode/providers/menu_provider.dart';
import 'package:tedu_qrcode/widgets/menu_day_card.dart';

/// Full-screen view of the weekly cafeteria menu.
/// Accessible from the sidebar. Shows one tab per available day,
/// with today's tab pre-selected.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebuildTabController();
  }

  void _rebuildTabController() {
    final provider = context.read<MenuProvider>();
    final count = provider.menus.length;
    if (count == 0) return;

    _tabController?.dispose();
    _tabController = TabController(
      length: count,
      vsync: this,
      initialIndex: provider.todayIndex,
    );
    setState(() {});
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MenuProvider>();
    final colors = Theme.of(context).colorScheme;

    // Rebuild tab controller when menu data arrives
    if (provider.hasData &&
        (_tabController == null ||
            _tabController!.length != provider.menus.length)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _rebuildTabController();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Günün Menüsü'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
            onPressed: provider.isLoading
                ? null
                : () => context.read<MenuProvider>().refresh(),
          ),
        ],
        bottom: provider.hasData && _tabController != null
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: provider.menus.map((m) {
                  final isToday = m.isToday;
                  return Tab(
                    child: Text(
                      m.shortDay,
                      style: TextStyle(
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? colors.primary : null,
                      ),
                    ),
                  );
                }).toList(),
              )
            : null,
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(MenuProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Menü yükleniyor…'),
          ],
        ),
      );
    }

    if (provider.errorMessage != null && !provider.hasData) {
      return _ErrorState(message: provider.errorMessage!);
    }

    if (!provider.hasData) {
      return const _EmptyState();
    }

    return TabBarView(
      controller: _tabController,
      children: provider.menus.map((menu) {
        return RefreshIndicator(
          onRefresh: () => context.read<MenuProvider>().refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              MenuDayCard(menu: menu),
              // If there was an error but we have stale data, show a notice
              if (provider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _StaleDataBanner(message: provider.errorMessage!),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 72, color: colors.outlineVariant),
            const SizedBox(height: 20),
            Text(
              'Menü Yüklenemedi',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.read<MenuProvider>().refresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu_outlined,
                size: 72, color: colors.outlineVariant),
            const SizedBox(height: 20),
            Text(
              'Menü Bulunamadı',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              'Bu hafta için menü bilgisi mevcut değil.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.read<MenuProvider>().refresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Yenile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaleDataBanner extends StatelessWidget {
  final String message;
  const _StaleDataBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colors.onErrorContainer, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
