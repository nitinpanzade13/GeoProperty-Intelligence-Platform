import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/providers/service_providers.dart';
import '../../core/models/survey_model.dart';
import '../../core/models/property_model.dart';
import '../../core/utils/result.dart';
import '../../core/routing/routes.dart';
import '../../core/constants/defaults.dart';
import 'widgets/search_dropdown.dart';

class PropertySearchScreen extends ConsumerStatefulWidget {
  const PropertySearchScreen({super.key});

  @override
  ConsumerState<PropertySearchScreen> createState() =>
      _PropertySearchScreenState();
}

class _PropertySearchScreenState extends ConsumerState<PropertySearchScreen> {
  // Selections
  String? _selectedDistrictCode;
  String? _selectedDistrictName;
  String? _selectedTalukaCode;
  String? _selectedTalukaName;
  String? _selectedVillageCode;
  String? _selectedVillageName;
  String? _selectedSurveyNumber;
  String? _resolvedGisCode;

  // Dropdown Lists
  List<DropdownItem<String>> _districtItems = [];
  List<DropdownItem<String>> _talukaItems = [];
  List<DropdownItem<String>> _villageItems = [];
  List<DropdownItem<String>> _surveyItems = [];

  // Loading States
  bool _isLoadingDistricts = false;
  bool _isLoadingTalukas = false;
  bool _isLoadingVillages = false;
  bool _isLoadingSurveys = false;
  bool _isSubmitting = false;

  final TextEditingController _surveyTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDistricts();
  }

  @override
  void dispose() {
    _surveyTextController.dispose();
    super.dispose();
  }

  Future<void> _loadDistricts() async {
    setState(() => _isLoadingDistricts = true);
    final repo = ref.read(villageRepositoryProvider);
    final result = await repo.getDistricts();

    if (result is Success<List<dynamic>>) {
      final items = result.data.map((item) {
        final map = item as Map<String, dynamic>;

        final code = map['district_code']?.toString() ?? '2701';
        final name = map['district_name']?.toString() ?? Defaults.district;
        return DropdownItem<String>(value: code, label: name);
      }).toList();

      if (mounted) {
        setState(() {
          _districtItems = items;
          _isLoadingDistricts = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingDistricts = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load districts. Tap retry.')),
        );
      }
    }
  }

  Future<void> _loadTalukas(String districtCode) async {
    setState(() => _isLoadingTalukas = true);
    final repo = ref.read(villageRepositoryProvider);
    final result = await repo.getTalukas(districtCode);

    if (result is Success<List<dynamic>>) {
      final items = result.data.map((item) {
        final map = item as Map<String, dynamic>;

        final code = map['taluka_code']?.toString() ?? '${districtCode}01';
        final name = map['taluka_name']?.toString() ?? Defaults.taluka;
        return DropdownItem<String>(value: code, label: name);
      }).toList();

      if (mounted) {
        setState(() {
          _talukaItems = items;
          _isLoadingTalukas = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingTalukas = false);
      }
    }
  }

  Future<void> _loadVillages(String districtCode, String talukaCode) async {
    setState(() => _isLoadingVillages = true);
    final repo = ref.read(villageRepositoryProvider);
    final result = await repo.getVillages(districtCode, talukaCode);

    if (result is Success<List<dynamic>>) {
      final items = result.data.map((item) {
        final map = item as Map<String, dynamic>;

        final code = map['village_code']?.toString() ?? '52001';
        final name = map['village_name']?.toString() ?? Defaults.village;
        return DropdownItem<String>(value: code, label: name);
      }).toList();

      if (mounted) {
        setState(() {
          _villageItems = items;
          _isLoadingVillages = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingVillages = false);
      }
    }
  }

  Future<void> _loadSurveys(
      String districtCode, String talukaCode, String villageCode) async {
    setState(() => _isLoadingSurveys = true);
    final villageRepo = ref.read(villageRepositoryProvider);
    final surveyRepo = ref.read(surveyRepositoryProvider);

    final gisRes =
        await villageRepo.resolveGisCode(districtCode, talukaCode, villageCode);
    final gisCode = gisRes is Success<String>
        ? gisRes.data
        : 'MH-$districtCode-$talukaCode-$villageCode';
    _resolvedGisCode = gisCode;

    final surveyRes = await surveyRepo.getSurveys(gisCode: gisCode);
    if (surveyRes is Success<List<SurveyModel>>) {
      final items = surveyRes.data.map((s) {
        final label = s.subdivisionNumber != null
            ? '${s.surveyNumber}/${s.subdivisionNumber}'
            : s.surveyNumber;
        return DropdownItem<String>(value: s.surveyNumber, label: label);
      }).toList();

      if (mounted) {
        setState(() {
          _surveyItems = items;
          _isLoadingSurveys = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingSurveys = false);
      }
    }
  }

  void _onDistrictChanged(String? code) {
    if (code == null) return;
    final selectedItem =
        _districtItems.firstWhere((item) => item.value == code);
    setState(() {
      _selectedDistrictCode = code;
      _selectedDistrictName = selectedItem.label;
      _selectedTalukaCode = null;
      _selectedTalukaName = null;
      _selectedVillageCode = null;
      _selectedVillageName = null;
      _selectedSurveyNumber = null;
      _talukaItems = [];
      _villageItems = [];
      _surveyItems = [];
      _surveyTextController.clear();
    });
    _loadTalukas(code);
  }

  void _onTalukaChanged(String? code) {
    if (code == null || _selectedDistrictCode == null) return;
    final selectedItem = _talukaItems.firstWhere((item) => item.value == code);
    setState(() {
      _selectedTalukaCode = code;
      _selectedTalukaName = selectedItem.label;
      _selectedVillageCode = null;
      _selectedVillageName = null;
      _selectedSurveyNumber = null;
      _villageItems = [];
      _surveyItems = [];
      _surveyTextController.clear();
    });
    _loadVillages(_selectedDistrictCode!, code);
  }

  void _onVillageChanged(String? code) {
    if (code == null ||
        _selectedDistrictCode == null ||
        _selectedTalukaCode == null) {
      return;
    }
    final selectedItem = _villageItems.firstWhere((item) => item.value == code);
    setState(() {
      _selectedVillageCode = code;
      _selectedVillageName = selectedItem.label;
      _selectedSurveyNumber = null;
      _surveyItems = [];
      _surveyTextController.clear();
    });
    _loadSurveys(_selectedDistrictCode!, _selectedTalukaCode!, code);
  }

  void _onSurveyChanged(String? number) {
    setState(() {
      _selectedSurveyNumber = number;
      if (number != null) {
        _surveyTextController.text = number;
      }
    });
  }

  void _openVillageMapImmediate() {
    if (_selectedVillageCode == null) return;
    final gisCode = _resolvedGisCode ?? Defaults.gisCode;
    context.push(
      Routes.map,
      extra: {
        'gisCode': gisCode,
        'villageName': _selectedVillageName,
        'district': _selectedDistrictName,
        'taluka': _selectedTalukaName,
      },
    );
  }

  Future<void> _onViewProperty() async {
    final surveyNum =
        _selectedSurveyNumber ?? _surveyTextController.text.trim();
    if (surveyNum.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select or enter a valid Survey Number.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final propertyRepo = ref.read(propertyRepositoryProvider);
    final gisCode = _resolvedGisCode ?? Defaults.gisCode;

    final result = await propertyRepo.getPropertyDetails('${Defaults.surveyIdPrefix}$surveyNum',
        gisCode: gisCode, surveyNumber: surveyNum);

    if (mounted) {
      setState(() => _isSubmitting = false);
    }

    if (result is Success<PropertyModel>) {
      final prop = result.data;
      if (mounted) {
        context.push(
          Routes.propertySearchDetails,
          extra: {
            'property': prop,
            'district': _selectedDistrictName ?? Defaults.district,
            'taluka': _selectedTalukaName ?? Defaults.taluka,
            'village': _selectedVillageName ?? Defaults.village,
            'surveyNumber': surveyNum,
            'gisCode': gisCode,
          },
        );
      }
    } else if (result is Failure<PropertyModel>) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading property: ${result.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canSubmit = _selectedDistrictCode != null &&
        _selectedTalukaCode != null &&
        _selectedVillageCode != null &&
        (_selectedSurveyNumber != null ||
            _surveyTextController.text.trim().isNotEmpty) &&
        !_isSubmitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Land Record'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Description Card
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.search_outlined,
                          color: AppColors.primary, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Select Administrative Hierarchy',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Select District, Taluka, Village, and Survey Number to fetch official land record details from BhuNaksha GIS services.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Dropdowns Form Container
            GlassCard(
              child: Column(
                children: [
                  // 1. District Selector
                  SearchDropdown<String>(
                    label: '1. District',
                    icon: Icons.map_rounded,
                    value: _selectedDistrictCode,
                    items: _districtItems,
                    isLoading: _isLoadingDistricts,
                    isEnabled: !_isLoadingDistricts,
                    hintText: 'Select District (e.g. Pune)',
                    onChanged: _onDistrictChanged,
                  ),
                  const SizedBox(height: 16),

                  // 2. Taluka Selector
                  SearchDropdown<String>(
                    label: '2. Taluka',
                    icon: Icons.location_city_rounded,
                    value: _selectedTalukaCode,
                    items: _talukaItems,
                    isLoading: _isLoadingTalukas,
                    isEnabled:
                        _selectedDistrictCode != null && !_isLoadingTalukas,
                    hintText: 'Select Taluka (e.g. Haveli)',
                    onChanged: _onTalukaChanged,
                  ),
                  const SizedBox(height: 16),

                  // 3. Village Selector
                  SearchDropdown<String>(
                    label: '3. Village',
                    icon: Icons.holiday_village_rounded,
                    value: _selectedVillageCode,
                    items: _villageItems,
                    isLoading: _isLoadingVillages,
                    isEnabled:
                        _selectedTalukaCode != null && !_isLoadingVillages,
                    hintText: 'Select Village (e.g. Shivajinagar)',
                    onChanged: _onVillageChanged,
                  ),

                  // TASK 2: Immediate Village WMS Map Button as soon as Village is selected
                  if (_selectedVillageCode != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _openVillageMapImmediate,
                      icon: const Icon(Icons.map_rounded, color: AppColors.secondary),
                      label: Text(
                        'View ${_selectedVillageName ?? "Village"} Map (WMS)',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.secondary, width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // 4. Survey Number Dropdown or TextField
                  if (_surveyItems.isNotEmpty)
                    SearchDropdown<String>(
                      label: '4. Survey Number',
                      icon: Icons.tag_rounded,
                      value: _selectedSurveyNumber,
                      items: _surveyItems,
                      isLoading: _isLoadingSurveys,
                      isEnabled:
                          _selectedVillageCode != null && !_isLoadingSurveys,
                      hintText: 'Select Survey Number',
                      onChanged: _onSurveyChanged,
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.tag_rounded,
                              size: 18,
                              color: _selectedVillageCode != null
                                  ? AppColors.primary
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '4. Survey Number',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _surveyTextController,
                          enabled: _selectedVillageCode != null,
                          decoration: InputDecoration(
                            hintText: 'Enter Survey Number (e.g. 142)',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            CustomButton(
              text: _isSubmitting
                  ? 'Fetching Property Details...'
                  : 'View Property',
              icon: Icons.arrow_forward_rounded,
              isLoading: _isSubmitting,
              onPressed: canSubmit ? _onViewProperty : () {},
            ),
          ],
        ),
      ),
    );
  }
}
