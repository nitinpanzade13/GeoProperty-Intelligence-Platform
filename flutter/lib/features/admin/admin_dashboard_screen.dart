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

  // ------------------------------------------------------------
  // Expanded hierarchy state
  // ------------------------------------------------------------

  final Set<String> _expandedDistricts = {};
  final Set<String> _expandedTalukas = {};

  // districtCode -> taluka list
  final Map<String, List<AdminTalukaOverview>> _talukas = {};

  // districtCode/talukaCode -> village list
  final Map<String, List<AdminVillageOverview>> _villages = {};

  final Set<String> _loadingTalukas = {};
  final Set<String> _loadingVillages = {};

  final Set<String> _syncingDistricts = {};
  final Set<String> _syncingTalukas = {};
  final Set<String> _syncingVillages = {};
  final Set<String> _syncingVillageMaps = {};

  // ------------------------------------------------------------
  // Lifecycle
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  // ------------------------------------------------------------
  // Dashboard
  // ------------------------------------------------------------

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

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

  // ------------------------------------------------------------
  // Load Talukas
  // ------------------------------------------------------------

  Future<void> _toggleDistrict(
    AdminDistrictOverview district,
  ) async {
    final districtCode = district.districtCode;

    if (_expandedDistricts.contains(districtCode)) {
      setState(() {
        _expandedDistricts.remove(districtCode);
      });
      return;
    }

    setState(() {
      _expandedDistricts.add(districtCode);
    });

    if (_talukas.containsKey(districtCode)) {
      return;
    }

    await _loadTalukas(districtCode);
  }

  Future<void> _loadTalukas(
    String districtCode,
  ) async {
    if (_loadingTalukas.contains(districtCode)) {
      return;
    }

    setState(() {
      _loadingTalukas.add(districtCode);
    });

    try {
      final result = await _adminApi.getTalukaOverview(
        districtCode: districtCode,
      );

      if (!mounted) return;

      setState(() {
        _talukas[districtCode] = result;
      });
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Failed to load talukas: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingTalukas.remove(districtCode);
        });
      }
    }
  }

  // ------------------------------------------------------------
  // Load Villages
  // ------------------------------------------------------------

  Future<void> _toggleTaluka({
    required String districtCode,
    required String talukaCode,
  }) async {
    final key = _talukaKey(
      districtCode,
      talukaCode,
    );

    if (_expandedTalukas.contains(key)) {
      setState(() {
        _expandedTalukas.remove(key);
      });
      return;
    }

    setState(() {
      _expandedTalukas.add(key);
    });

    if (_villages.containsKey(key)) {
      return;
    }

    await _loadVillages(
      districtCode: districtCode,
      talukaCode: talukaCode,
    );
  }

  Future<void> _loadVillages({
    required String districtCode,
    required String talukaCode,
  }) async {
    final key = _talukaKey(
      districtCode,
      talukaCode,
    );

    if (_loadingVillages.contains(key)) {
      return;
    }

    setState(() {
      _loadingVillages.add(key);
    });

    try {
      final result = await _adminApi.getVillageOverview(
        districtCode: districtCode,
        talukaCode: talukaCode,
      );

      if (!mounted) return;

      setState(() {
        _villages[key] = result;
      });
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Failed to load villages: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingVillages.remove(key);
        });
      }
    }
  }

  String _talukaKey(
    String districtCode,
    String talukaCode,
  ) {
    return '$districtCode/$talukaCode';
  }

  // ------------------------------------------------------------
  // Sync District
  // ------------------------------------------------------------

  Future<void> _syncDistrict(
    AdminDistrictOverview district,
  ) async {
    final districtCode = district.districtCode.trim();

    if (districtCode.isEmpty) {
      _showError(
        'District code is missing.',
      );
      return;
    }

    if (_syncingDistricts.contains(
      districtCode,
    )) {
      return;
    }

    final confirmed = await _confirmAction(
      title: 'Sync District',
      message: 'Sync the complete ${district.districtName} district?\n\n'
          'The synchronization will continue in the background.',
      confirmText: 'Start Sync',
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _syncingDistricts.add(
        districtCode,
      );
    });

    try {
      // ----------------------------------------------------------
      // START BACKEND JOB
      // ----------------------------------------------------------

      final startResponse = await _adminApi.syncDistrict(
        districtCode: districtCode,
      );

      debugPrint(
        'DISTRICT SYNC START RESPONSE: '
        '$startResponse',
      );

      if (!mounted) {
        return;
      }

      _showSuccess(
        '${district.districtName} synchronization started.',
      );

      // ----------------------------------------------------------
      // POLL STATUS
      // ----------------------------------------------------------

      while (mounted) {
        await Future.delayed(
          const Duration(seconds: 2),
        );

        if (!mounted) {
          return;
        }

        final statusResponse = await _adminApi.getDistrictSyncStatus(
          districtCode: districtCode,
        );

        debugPrint(
          'DISTRICT SYNC STATUS [$districtCode]: '
          '$statusResponse',
        );

        final status =
            (statusResponse['sync_status']?.toString().toLowerCase().trim()) ??
                'not_synced';

        final processed = int.tryParse(
              statusResponse['processed_villages']?.toString() ?? '0',
            ) ??
            0;

        final total = int.tryParse(
              statusResponse['total_villages']?.toString() ?? '0',
            ) ??
            0;

        final progress = statusResponse['progress_percent']?.toString() ?? '0';

        // --------------------------------------------------------
        // Update district status locally.
        // --------------------------------------------------------

        if (mounted) {
          setState(() {
            final index = _districts.indexWhere(
              (item) => item.districtCode == districtCode,
            );

            if (index != -1) {
              _districts[index] = _districts[index].copyWith(
                syncStatus: status,
              );
            }
          });
        }

        debugPrint(
          'DISTRICT PROGRESS: '
          '$processed/$total '
          '($progress%) '
          'status=$status',
        );

        // --------------------------------------------------------
        // FINISHED
        // --------------------------------------------------------

        if (status == 'synced') {
          if (!mounted) {
            return;
          }

          _showSuccess(
            '${district.districtName} '
            'synchronized successfully.',
          );

          break;
        }

        if (status == 'partially_synced') {
          if (!mounted) {
            return;
          }

          final failed = statusResponse['failed_villages']?.toString() ?? '0';

          _showError(
            '${district.districtName} partially synchronized. '
            'Failed villages: $failed',
          );

          break;
        }

        if (status == 'not_synced' &&
            statusResponse['sync_in_progress'] != true &&
            processed > 0) {
          if (!mounted) {
            return;
          }

          _showError(
            '${district.districtName} synchronization failed.',
          );

          break;
        }
      }

      // ----------------------------------------------------------
      // Refresh dashboard after completion
      // ----------------------------------------------------------

      if (!mounted) {
        return;
      }

      _talukas.remove(
        districtCode,
      );

      final keysToRemove = _villages.keys
          .where(
            (key) => key.startsWith(
              '$districtCode/',
            ),
          )
          .toList();

      for (final key in keysToRemove) {
        _villages.remove(key);
      }

      await _loadDashboard();

      if (!mounted) {
        return;
      }

      if (_expandedDistricts.contains(
        districtCode,
      )) {
        await _loadTalukas(
          districtCode,
        );
      }
    } catch (e) {
      debugPrint(
        'DISTRICT SYNC ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      _showError(
        'District synchronization failed: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _syncingDistricts.remove(
            districtCode,
          );
        });
      }
    }
  }
  // ------------------------------------------------------------
  // Sync Taluka
  // ------------------------------------------------------------

  Future<void> _syncTaluka({
    required String districtCode,
    required String talukaCode,
    required String talukaName,
  }) async {
    final cleanDistrictCode = districtCode.trim();
    final cleanTalukaCode = talukaCode.trim();
    final cleanTalukaName =
        talukaName.trim().isEmpty ? 'Taluka' : talukaName.trim();

    if (cleanDistrictCode.isEmpty || cleanTalukaCode.isEmpty) {
      _showError(
        'District code or taluka code is missing.',
      );
      return;
    }

    final key = _talukaKey(
      cleanDistrictCode,
      cleanTalukaCode,
    );

    if (_syncingTalukas.contains(key)) {
      return;
    }

    final confirmed = await _confirmAction(
      title: 'Sync Taluka',
      message: 'Sync all villages and related data for '
          '$cleanTalukaName?\n\n'
          'Taluka Code:\n$cleanTalukaCode',
      confirmText: 'Sync Taluka',
    );

    if (!confirmed) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _syncingTalukas.add(key);
    });

    try {
      await _adminApi.syncTaluka(
        districtCode: cleanDistrictCode,
        talukaCode: cleanTalukaCode,
      );

      if (!mounted) {
        return;
      }

      _showSuccess(
        '$cleanTalukaName synchronized successfully.',
      );

      // ----------------------------------------------------------
      // Clear cached villages for this taluka
      // ----------------------------------------------------------

      _villages.remove(key);

      // ----------------------------------------------------------
      // Refresh dashboard
      // ----------------------------------------------------------

      await _loadDashboard();

      if (!mounted) {
        return;
      }

      // ----------------------------------------------------------
      // Reload talukas if district is expanded
      // ----------------------------------------------------------

      if (_expandedDistricts.contains(cleanDistrictCode)) {
        await _loadTalukas(cleanDistrictCode);
      }

      // ----------------------------------------------------------
      // Reload villages if taluka is expanded
      // ----------------------------------------------------------

      if (_expandedTalukas.contains(key)) {
        await _loadVillages(
          districtCode: cleanDistrictCode,
          talukaCode: cleanTalukaCode,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        'Taluka synchronization failed: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _syncingTalukas.remove(key);
        });
      }
    }
  }

  // ------------------------------------------------------------
  // Sync Village
  // ------------------------------------------------------------

  Future<void> _syncVillage({
    required String districtCode,
    required String talukaCode,
    required AdminVillageOverview village,
  }) async {
    final gisCode = village.gisCode.trim();

    final villageName = village.villageName.trim().isEmpty
        ? 'Village'
        : village.villageName.trim();

    // ----------------------------------------------------------
    // VALIDATE GIS CODE
    // ----------------------------------------------------------

    if (gisCode.isEmpty) {
      _showError(
        'GIS code is missing for this village.',
      );
      return;
    }

    // ----------------------------------------------------------
    // PREVENT DUPLICATE SYNC
    // ----------------------------------------------------------

    if (_syncingVillages.contains(gisCode)) {
      return;
    }

    // ----------------------------------------------------------
    // CONFIRM ACTION
    // ----------------------------------------------------------

    final confirmed = await _confirmAction(
      title: 'Sync Village',
      message: 'Synchronize $villageName?\n\n'
          'GIS Code:\n$gisCode\n\n'
          'This will synchronize the village data '
          'from BhuNaksha into PostgreSQL.',
      confirmText: 'Sync Village',
    );

    if (!confirmed) {
      return;
    }

    if (!mounted) {
      return;
    }

    // ----------------------------------------------------------
    // START SYNC
    // ----------------------------------------------------------

    setState(() {
      _syncingVillages.add(gisCode);
    });

    try {
      await _adminApi.syncVillage(
        districtCode: districtCode,
        talukaCode: talukaCode,
        gisCode: gisCode,
      );

      if (!mounted) {
        return;
      }

      _showSuccess(
        '$villageName synchronized successfully.',
      );

      // --------------------------------------------------------
      // CLEAR CACHED VILLAGE OVERVIEW
      // --------------------------------------------------------

      final key = _talukaKey(
        districtCode,
        talukaCode,
      );

      _villages.remove(key);

      // --------------------------------------------------------
      // REFRESH DASHBOARD STATISTICS
      // --------------------------------------------------------

      await _loadDashboard();

      // --------------------------------------------------------
      // RELOAD VILLAGES IF TALUKA IS EXPANDED
      // --------------------------------------------------------

      if (!mounted) {
        return;
      }

      if (_expandedTalukas.contains(key)) {
        await _loadVillages(
          districtCode: districtCode,
          talukaCode: talukaCode,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        'Village synchronization failed: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _syncingVillages.remove(gisCode);
        });
      }
    }
  }

  // ------------------------------------------------------------
  // Sync Village Map
  // ------------------------------------------------------------

  Future<void> _syncVillageMap({
    required String districtCode,
    required String talukaCode,
    required AdminVillageOverview village,
  }) async {
    final gisCode = village.gisCode.trim();
    final villageName = village.villageName.trim().isEmpty
        ? 'Village'
        : village.villageName.trim();

    if (gisCode.isEmpty) {
      _showError(
        'GIS code is missing for this village.',
      );
      return;
    }

    if (_syncingVillageMaps.contains(gisCode)) {
      return;
    }

    final confirmed = await _confirmAction(
      title: 'Sync Village Map',
      message: 'Fetch the latest BhuNaksha map and property data for '
          '$villageName?\n\n'
          'GIS Code:\n$gisCode\n\n'
          'This will update PostgreSQL for normal users.',
      confirmText: 'Sync Map',
    );

    if (!confirmed) return;

    if (!mounted) return;

    setState(() {
      _syncingVillageMaps.add(gisCode);
    });

    try {
      await _adminApi.syncVillageMap(
        gisCode: gisCode,
      );

      if (!mounted) return;

      _showSuccess(
        '$villageName map synchronized successfully.',
      );

      final key = _talukaKey(
        districtCode,
        talukaCode,
      );

      _villages.remove(key);

      await _loadDashboard();

      if (_expandedTalukas.contains(key)) {
        await _loadVillages(
          districtCode: districtCode,
          talukaCode: talukaCode,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Village map synchronization failed: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _syncingVillageMaps.remove(gisCode);
        });
      }
    }
  }

  // ------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------

  String _stringValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return '';
  }

  int _intValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value is int) {
        return value;
      }

      if (value != null) {
        return int.tryParse(
              value.toString(),
            ) ??
            0;
      }
    }

    return 0;
  }

  String _syncStatus(
    Map<String, dynamic> data,
  ) {
    return _stringValue(
      data,
      [
        'sync_status',
        'syncStatus',
      ],
    ).toLowerCase();
  }

  Color _statusColor(
    String status,
  ) {
    switch (status) {
      case 'synced':
        return Colors.green;

      case 'partially_synced':
        return Colors.orange;

      case 'syncing':
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  String _statusText(
    String status,
  ) {
    switch (status) {
      case 'synced':
        return 'Synced';

      case 'partially_synced':
        return 'Partially Synced';

      case 'syncing':
        return 'Syncing';

      default:
        return 'Not Synced';
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showSuccess(
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
  }

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

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
        child: Text(
          'No dashboard data available',
        ),
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
          const SizedBox(height: 36),
          _buildHierarchyHeader(),
          const SizedBox(height: 16),
          _buildDistrictHierarchy(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // Summary
  // ------------------------------------------------------------

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
        final columns = constraints.maxWidth >= 1100
            ? 3
            : constraints.maxWidth >= 650
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
            childAspectRatio: 2.5,
          ),
          itemBuilder: (context, index) {
            return _SummaryCard(
              item: cards[index],
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // Hierarchy Header
  // ------------------------------------------------------------

  Widget _buildHierarchyHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Administrative Hierarchy',
            style: TextStyle(
              fontSize: 24,
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
    );
  }

  // ------------------------------------------------------------
  // District hierarchy
  // ------------------------------------------------------------

  Widget _buildDistrictHierarchy() {
    if (_districts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No districts available',
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final district in _districts) _buildDistrictCard(district),
      ],
    );
  }

  Widget _buildDistrictCard(
    AdminDistrictOverview district,
  ) {
    final districtCode = district.districtCode;

    final expanded = _expandedDistricts.contains(
      districtCode,
    );

    final loading = _loadingTalukas.contains(
      districtCode,
    );

    final syncing = _syncingDistricts.contains(
      districtCode,
    );

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: syncing
                ? null
                : () => _toggleDistrict(
                      district,
                    ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                    ),
                    child: Icon(
                      Icons.map,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              district.districtName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              districtCode,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Wrap(
                          spacing: 18,
                          runSpacing: 4,
                          children: [
                            _CountLabel(
                              icon: Icons.location_city,
                              label: '${district.talukaCount} Talukas',
                            ),
                            _CountLabel(
                              icon: Icons.holiday_village,
                              label: '${district.villageCount} Villages',
                            ),
                            _CountLabel(
                              icon: Icons.layers,
                              label: '${district.mapCount} Maps',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(
                    status: district.syncStatus,
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: syncing
                        ? null
                        : () => _syncDistrict(
                              district,
                            ),
                    icon: syncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.sync,
                            size: 18,
                          ),
                    label: Text(
                      syncing ? 'Syncing' : 'Sync',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else
              _buildTalukaList(
                districtCode,
              ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // Taluka list
  // ------------------------------------------------------------

  Widget _buildTalukaList(
    String districtCode,
  ) {
    final talukas = _talukas[districtCode];

    if (talukas == null || talukas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No taluka data available.',
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (int i = 0; i < talukas.length; i++) ...[
            _buildTalukaItem(
              districtCode: districtCode,
              taluka: talukas[i],
            ),
            if (i != talukas.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  Widget _buildTalukaItem({
    required String districtCode,
    required AdminTalukaOverview taluka,
  }) {
    final talukaCode = taluka.talukaCode;

    final talukaName = taluka.talukaName;

    final key = _talukaKey(
      districtCode,
      talukaCode,
    );

    final expanded = _expandedTalukas.contains(key);

    final loading = _loadingVillages.contains(key);

    final syncing = _syncingTalukas.contains(key);

    final villageCount = taluka.villageCount;

    final mapCount = taluka.mapCount;

    final status = taluka.syncStatus;

    return Column(
      children: [
        InkWell(
          onTap: syncing
              ? null
              : () => _toggleTaluka(
                    districtCode: districtCode,
                    talukaCode: talukaCode,
                  ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const SizedBox(width: 8),
                const Icon(
                  Icons.location_city,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        talukaName.isEmpty ? 'Taluka $talukaCode' : talukaName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        '$villageCount villages  •  '
                        '$mapCount maps',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (status.isNotEmpty)
                  _StatusChip(
                    status: status,
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: syncing
                      ? null
                      : () => _syncTaluka(
                            districtCode: districtCode,
                            talukaCode: talukaCode,
                            talukaName: talukaName,
                          ),
                  icon: syncing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.sync,
                          size: 16,
                        ),
                  label: Text(
                    syncing ? 'Syncing' : 'Sync',
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (expanded) ...[
          const Divider(height: 1),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )
          else
            _buildVillageList(
              districtCode: districtCode,
              talukaCode: talukaCode,
            ),
        ],
      ],
    );
  }

  // ------------------------------------------------------------
  // Village list
  // ------------------------------------------------------------

  Widget _buildVillageList({
    required String districtCode,
    required String talukaCode,
  }) {
    final key = _talukaKey(
      districtCode,
      talukaCode,
    );

    final villages = _villages[key];

    if (villages == null || villages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No village data available.',
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(
        40,
        0,
        20,
        20,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _buildVillageHeader(),
          for (int i = 0; i < villages.length; i++) ...[
            _buildVillageItem(
              districtCode: districtCode,
              talukaCode: talukaCode,
              village: villages[i],
            ),
            if (i != villages.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  Widget _buildVillageHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(10),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(width: 36),

          // -------------------------------------------------------
          // VILLAGE NAME
          // -------------------------------------------------------
          Expanded(
            flex: 3,
            child: Text(
              'Village',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // -------------------------------------------------------
          // GIS CODE
          // -------------------------------------------------------
          Expanded(
            flex: 2,
            child: Text(
              'GIS Code',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // -------------------------------------------------------
          // PROPERTY COUNT
          // -------------------------------------------------------
          Expanded(
            child: Text(
              'Properties',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // -------------------------------------------------------
          // OWNER COUNT
          // -------------------------------------------------------
          Expanded(
            child: Text(
              'Owners',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // -------------------------------------------------------
          // SURVEY COUNT
          // -------------------------------------------------------
          Expanded(
            child: Text(
              'Surveys',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // -------------------------------------------------------
          // STATUS + ACTION BUTTONS
          // -------------------------------------------------------
          SizedBox(
            width: 220,
            child: Text(
              'Status / Actions',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVillageItem({
    required String districtCode,
    required String talukaCode,
    required AdminVillageOverview village,
  }) {
    // ============================================================
    // DATA
    // ============================================================

    final rawGisCode = village.gisCode.trim();

    final villageName = village.villageName.trim().isEmpty
        ? 'Village'
        : village.villageName.trim();

    final displayGisCode = rawGisCode.isEmpty ? '-' : rawGisCode;

    final propertyCount = village.propertyCount;
    final ownerCount = village.ownerCount;
    final surveyCount = village.surveyCount;

    final status = village.syncStatus.trim();

    // ============================================================
    // SYNC STATES
    // ============================================================

    final syncingVillage =
        rawGisCode.isNotEmpty && _syncingVillages.contains(rawGisCode);

    // If your screen already has a separate set for map syncing,
    // this will use it.
    //
    // If _syncingVillageMaps does not exist in your screen yet,
    // see the small addition below this method.
    final syncingVillageMap =
        rawGisCode.isNotEmpty && _syncingVillageMaps.contains(rawGisCode);

    final anySyncing = syncingVillage || syncingVillageMap;

    // ============================================================
    // UI
    // ============================================================

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      child: Row(
        children: [
          // ========================================================
          // VILLAGE ICON
          // ========================================================

          const SizedBox(width: 22),

          const Icon(
            Icons.holiday_village,
            size: 20,
          ),

          const SizedBox(width: 14),

          // ========================================================
          // VILLAGE NAME
          // ========================================================

          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  villageName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (propertyCount > 0)
                  Text(
                    '$propertyCount properties',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),

          // ========================================================
          // GIS CODE
          // ========================================================

          Expanded(
            flex: 2,
            child: Text(
              displayGisCode,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          // ========================================================
          // PROPERTY COUNT
          // ========================================================

          Expanded(
            child: Text(
              propertyCount.toString(),
              textAlign: TextAlign.center,
            ),
          ),

          // ========================================================
          // OWNER COUNT
          // ========================================================

          Expanded(
            child: Text(
              ownerCount.toString(),
              textAlign: TextAlign.center,
            ),
          ),

          // ========================================================
          // SURVEY COUNT
          // ========================================================

          Expanded(
            child: Text(
              surveyCount.toString(),
              textAlign: TextAlign.center,
            ),
          ),

          // ========================================================
          // STATUS
          // ========================================================

          SizedBox(
            width: 110,
            child: status.isNotEmpty
                ? Center(
                    child: _StatusChip(
                      status: status,
                    ),
                  )
                : const SizedBox(),
          ),

          // ========================================================
          // SYNC VILLAGE
          // ========================================================

          SizedBox(
            width: 48,
            child: IconButton(
              tooltip: syncingVillage ? 'Syncing village...' : 'Sync village',
              onPressed: anySyncing || rawGisCode.isEmpty
                  ? null
                  : () => _syncVillage(
                        districtCode: districtCode,
                        talukaCode: talukaCode,
                        village: village,
                      ),
              icon: syncingVillage
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.sync,
                    ),
            ),
          ),

          // ========================================================
          // SYNC VILLAGE MAP
          // ========================================================

          SizedBox(
            width: 48,
            child: IconButton(
              tooltip: syncingVillageMap
                  ? 'Syncing village map...'
                  : 'Sync village map',
              onPressed: anySyncing || rawGisCode.isEmpty
                  ? null
                  : () => _syncVillageMap(
                        districtCode: districtCode,
                        talukaCode: talukaCode,
                        village: village,
                      ),
              icon: syncingVillageMap
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.map_outlined,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// SUMMARY MODELS FOR UI
// ==================================================================

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

// ==================================================================
// SUMMARY CARD
// ==================================================================

class _SummaryCard extends StatelessWidget {
  final _SummaryItem item;

  const _SummaryCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
              child: Icon(
                item.icon,
                color: colorScheme.onPrimaryContainer,
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

// ==================================================================
// COUNT LABEL
// ==================================================================

class _CountLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CountLabel({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// STATUS CHIP
// ==================================================================

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    final Color color;

    switch (normalized) {
      case 'synced':
        color = Colors.green;
        break;

      case 'partially_synced':
        color = Colors.orange;
        break;

      case 'syncing':
        color = Colors.blue;
        break;

      default:
        color = Colors.grey;
    }

    final String text;

    switch (normalized) {
      case 'synced':
        text = 'Synced';
        break;

      case 'partially_synced':
        text = 'Partially Synced';
        break;

      case 'syncing':
        text = 'Syncing';
        break;

      default:
        text = 'Not Synced';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
