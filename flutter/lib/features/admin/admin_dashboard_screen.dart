import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'admin_api_service.dart';
import 'models/admin_dashboard_models.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminApiService _adminApi = GetIt.instance<AdminApiService>();

  AdminDashboardSummary? _summary;
  List<AdminDistrictOverview> _districts = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _adminApi.getDashboardSummary(),
        _adminApi.getDistrictOverview(),
      ]);

      if (!mounted) return;

      setState(() {
        _summary = results[0] as AdminDashboardSummary;
        _districts = results[1] as List<AdminDistrictOverview>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () {
              _adminApi.logout();

              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load dashboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadDashboard,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_summary == null) {
      return const Center(
        child: Text('No dashboard data available'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Overview',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildSummaryGrid(),
          const SizedBox(height: 32),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'District Overview',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${_districts.length} districts',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDistrictList(),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid() {
    final summary = _summary!;

    final cards = [
      _SummaryItem(
        title: 'Districts',
        value: summary.districts,
        icon: Icons.map,
      ),
      _SummaryItem(
        title: 'Talukas',
        value: summary.talukas,
        icon: Icons.location_city,
      ),
      _SummaryItem(
        title: 'Villages',
        value: summary.villages,
        icon: Icons.holiday_village,
      ),
      _SummaryItem(
        title: 'Properties',
        value: summary.properties,
        icon: Icons.home_work,
      ),
      _SummaryItem(
        title: 'Owners',
        value: summary.owners,
        icon: Icons.people,
      ),
      _SummaryItem(
        title: 'Village Maps',
        value: summary.villageMaps,
        icon: Icons.layers,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 3
            : constraints.maxWidth >= 600
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.4,
          ),
          itemBuilder: (context, index) {
            return _SummaryCard(item: cards[index]);
          },
        );
      },
    );
  }

  Widget _buildDistrictList() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < _districts.length; i++) ...[
            _DistrictRow(
              district: _districts[i],
            ),
            if (i != _districts.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _SummaryItem {
  final String title;
  final int value;
  final IconData icon;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryItem item;

  const _SummaryCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.value.toString(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistrictRow extends StatelessWidget {
  final AdminDistrictOverview district;

  const _DistrictRow({
    required this.district,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = district.isSynced
        ? Colors.green
        : district.isPartiallySynced
            ? Colors.orange
            : Colors.grey;

    final statusText = district.isSynced
        ? 'Synced'
        : district.isPartiallySynced
            ? 'Partially Synced'
            : 'Not Synced';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Text(
              district.districtCode,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              district.districtName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${district.talukaCount}',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '${district.villageCount}',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '${district.mapCount}',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
