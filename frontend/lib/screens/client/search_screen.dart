import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/feed_repository.dart';
import '../../data/neighborhoods.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_chip.dart';
import '../../widgets/bc_icon.dart';

const _propertyTypes = [
  ('studio', 'Studio'),
  ('appartement', 'Appartement'),
  ('chambre', 'Chambre'),
  ('villa', 'Villa'),
];

/// Recherche ciblée — quartier, budget FCFA, type, équipements.
/// Fidèle au wireframe Client (écran 3).
class SearchScreen extends StatefulWidget {
  final ValueChanged<FeedFilters> onSearch;

  const SearchScreen({super.key, required this.onSearch});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _amenityRepository = _AmenityRepository(ApiClient());
  late Future<List<AmenityItem>> _amenitiesFuture;

  String? _neighborhood;
  double _budgetMax = 150000;
  String? _propertyType;
  final Set<int> _selectedAmenities = {};

  @override
  void initState() {
    super.initState();
    _amenitiesFuture = _amenityRepository.list();
  }

  void _apply() {
    widget.onSearch(
      FeedFilters(
        neighborhood: _neighborhood,
        budgetMax: _budgetMax.round(),
        propertyType: _propertyType,
        amenityIds: _selectedAmenities.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rechercher',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2F0),
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  const BcIcon('search', size: 16, color: AppColors.sub),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Quartier à Yaoundé…',
                      ),
                      onChanged: (v) => setState(() => _neighborhood = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                BcChip(
                  label: kYaoundeAll,
                  selected: _neighborhood == null || _neighborhood!.isEmpty,
                  onTap: () => setState(() => _neighborhood = null),
                ),
                for (final n in kYaoundeNeighborhoods)
                  BcChip(
                    label: n,
                    selected: _neighborhood == n,
                    onTap: () => setState(() => _neighborhood = n),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'Budget max (FCFA)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            Slider(
              value: _budgetMax,
              min: 0,
              max: 500000,
              divisions: 50,
              activeColor: AppColors.green,
              label: '${_budgetMax.round()} F',
              onChanged: (v) => setState(() => _budgetMax = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '0 F',
                  style: TextStyle(color: AppColors.sub, fontSize: 11),
                ),
                Text(
                  '${_budgetMax.round()} F',
                  style: const TextStyle(
                    color: AppColors.greenDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Type de bien',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                BcChip(
                  label: 'Tous',
                  selected: _propertyType == null,
                  onTap: () => setState(() => _propertyType = null),
                ),
                for (final t in _propertyTypes)
                  BcChip(
                    label: t.$2,
                    selected: _propertyType == t.$1,
                    onTap: () => setState(() => _propertyType = t.$1),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Équipements',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<AmenityItem>>(
              future: _amenitiesFuture,
              builder: (context, snapshot) {
                final amenities = snapshot.data ?? [];
                if (amenities.isEmpty) return const SizedBox.shrink();
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final a in amenities)
                      BcChip(
                        label: a.name,
                        selected: _selectedAmenities.contains(a.id),
                        onTap: () => setState(() {
                          if (!_selectedAmenities.remove(a.id)) {
                            _selectedAmenities.add(a.id);
                          }
                        }),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            BcButton(
              label: 'Voir les logements',
              icon: 'search',
              onPressed: _apply,
            ),
          ],
        ),
      ),
    );
  }
}

class _AmenityRepository {
  final ApiClient _api;
  _AmenityRepository(this._api);

  Future<List<AmenityItem>> list() async {
    final data = await _api.get('/api/amenities/') as List;
    return data
        .map((e) => AmenityItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
