import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/admin_repository.dart';
import '../../data/api_client.dart';
import '../../data/feed_repository.dart' show AmenityItem;
import '../../data/media_limits.dart';
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

/// Publication d'une annonce par l'admin (amorçage de la base) — écran web
/// plein format du back-office, mêmes champs que la publication annonceur
/// (`publish_listing_screen.dart`) plus le contact d'amorçage. Auto-publiée
/// côté serveur (voir AdminListingViewSet.perform_create).
class AdminPublishListingScreen extends StatefulWidget {
  const AdminPublishListingScreen({super.key});

  @override
  State<AdminPublishListingScreen> createState() =>
      _AdminPublishListingScreenState();
}

class _AdminPublishListingScreenState
    extends State<AdminPublishListingScreen> {
  final _repository = AdminRepository(ApiClient());
  final _picker = ImagePicker();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _termsController = TextEditingController();
  final _whatsappController = TextEditingController(text: '+237');
  final _seedNameController = TextEditingController();
  final _seedPhoneController = TextEditingController();

  String _propertyType = _propertyTypes.first.$1;
  String? _neighborhood;
  final Set<int> _selectedAmenities = {};
  late Future<List<AmenityItem>> _amenitiesFuture;
  final List<(XFile file, Uint8List bytes, String mediaType)> _pickedMedia =
      [];
  bool _submitting = false;

  bool get _hasVideo => _pickedMedia.any((m) => m.$3 == 'video');

  @override
  void initState() {
    super.initState();
    _amenitiesFuture = _repository.amenities();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _termsController.dispose();
    _whatsappController.dispose();
    _seedNameController.dispose();
    _seedPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    await _addMedia(file, 'photo');
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: kMaxVideoDuration,
    );
    if (file == null) return;
    await _addMedia(file, 'video');
  }

  Future<void> _addMedia(XFile file, String mediaType) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > kMaxMediaFileSizeBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fichier trop volumineux (max ${kMaxMediaFileSizeBytes ~/ (1024 * 1024)} Mo).',
          ),
        ),
      );
      return;
    }
    setState(() => _pickedMedia.add((file, bytes, mediaType)));
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _neighborhood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Titre et quartier sont obligatoires.')),
      );
      return;
    }
    final rent = int.tryParse(_rentController.text.trim());
    if (rent == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Loyer invalide.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final listing = await _repository.createListing(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        neighborhood: _neighborhood!,
        propertyType: _propertyType,
        rentAmount: rent,
        depositAmount: int.tryParse(_depositController.text.trim()) ?? 0,
        terms: _termsController.text.trim(),
        whatsappNumber: _whatsappController.text.trim(),
        amenityIds: _selectedAmenities.toList(),
        seedContactName: _seedNameController.text.trim(),
        seedContactPhone: _seedPhoneController.text.trim(),
      );

      for (final (file, bytes, mediaType) in _pickedMedia) {
        await _repository.uploadListingMedia(
          listingId: listing.id,
          mediaType: mediaType,
          bytes: bytes,
          filename: file.name,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(false),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: BcIcon('back', size: 19, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Publier une annonce',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 56, right: 24, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Annonce d\'amorçage — publiée immédiatement, sans validation.',
                  style: TextStyle(fontSize: 13, color: AppColors.sub),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionCard(
                          title: 'Média',
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _mediaPickButton(
                                    icon: 'images',
                                    label: 'Ajouter des photos',
                                    onTap: _pickPhoto,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _mediaPickButton(
                                    icon: 'video',
                                    label: _hasVideo
                                        ? 'Vidéo ajoutée'
                                        : 'Ajouter une vidéo (60 s max)',
                                    onTap: _hasVideo ? null : _pickVideo,
                                  ),
                                ),
                              ],
                            ),
                            if (_pickedMedia.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 56,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _pickedMedia.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, index) =>
                                      _mediaThumbnail(_pickedMedia[index]),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        _sectionCard(
                          title: 'Annonce',
                          children: [
                            _textField(
                              _titleController,
                              label: 'Titre',
                              hint: 'Studio meublé · Yaoundé',
                            ),
                            const SizedBox(height: 12),
                            _textField(
                              _descriptionController,
                              label: 'Description',
                              hint: 'Description du bien',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Type de bien',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.sub,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final type in _propertyTypes)
                                  BcChip(
                                    label: type.$2,
                                    selected: _propertyType == type.$1,
                                    onTap: () => setState(
                                      () => _propertyType = type.$1,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _sectionCard(
                          title: 'Localisation & loyer',
                          children: [
                            _neighborhoodSelect(),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _textField(
                                    _rentController,
                                    label: 'Loyer / mois (FCFA)',
                                    hint: '75000',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _textField(
                                    _depositController,
                                    label: 'Caution (FCFA)',
                                    hint: '0',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _textField(
                              _whatsappController,
                              label: 'WhatsApp de contact',
                              hint: '+237...',
                              icon: 'phone',
                            ),
                            const SizedBox(height: 12),
                            _textField(
                              _termsController,
                              label: 'Modalités',
                              hint: 'Conditions, durée du bail, avance exigée…',
                              maxLines: 3,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _sectionCard(
                          title: 'Équipements',
                          children: [_amenitiesSelect()],
                        ),
                        const SizedBox(height: 16),
                        _sectionCard(
                          title: 'Contact d\'amorçage',
                          subtitle:
                              'Annonceur pas encore inscrit — coordonnées internes, jamais affichées publiquement.',
                          children: [
                            _textField(
                              _seedNameController,
                              label: 'Nom du contact',
                              hint: 'Optionnel',
                              icon: 'user',
                            ),
                            const SizedBox(height: 12),
                            _textField(
                              _seedPhoneController,
                              label: 'Téléphone du contact',
                              hint: 'Optionnel',
                              icon: 'phone',
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        BcButton(
                          label: _submitting ? 'Publication...' : 'Publier',
                          icon: 'check',
                          expand: false,
                          onPressed: _submitting ? null : _submit,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.sub),
            ),
          ],
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _mediaPickButton({
    required String icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 88,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: enabled ? AppColors.green : AppColors.line,
            width: 2,
          ),
          color: enabled ? AppColors.greenLight : const Color(0xFFEEF2F0),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BcIcon(
                icon,
                size: 22,
                color: enabled ? AppColors.greenDark : AppColors.sub,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: enabled ? AppColors.greenDark : AppColors.sub,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mediaThumbnail((XFile file, Uint8List bytes, String mediaType) media) {
    final (_, bytes, mediaType) = media;
    if (mediaType == 'video') {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: BcIcon('video', size: 20, color: Colors.white),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.memory(bytes, width: 56, height: 56, fit: BoxFit.cover),
    );
  }

  Widget _textField(
    TextEditingController controller, {
    required String label,
    required String hint,
    String? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null
            ? Padding(
                padding: const EdgeInsets.all(13),
                child: BcIcon(icon, size: 16, color: AppColors.sub),
              )
            : null,
        filled: true,
        fillColor: AppColors.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.line),
        ),
      ),
    );
  }

  Widget _neighborhoodSelect() {
    return DropdownButtonFormField<String>(
      initialValue: _neighborhood,
      items: [
        for (final n in kYaoundeNeighborhoods)
          DropdownMenuItem(value: n, child: Text(n)),
      ],
      onChanged: (v) => setState(() => _neighborhood = v),
      decoration: InputDecoration(
        labelText: 'Quartier',
        filled: true,
        fillColor: AppColors.bg,
        prefixIcon: const Padding(
          padding: EdgeInsets.all(13),
          child: BcIcon('pin', size: 16, color: AppColors.sub),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.line),
        ),
      ),
    );
  }

  Widget _amenitiesSelect() {
    return FutureBuilder<List<AmenityItem>>(
      future: _amenitiesFuture,
      builder: (context, snapshot) {
        final amenities = snapshot.data ?? [];
        if (amenities.isEmpty) {
          return const Text(
            'Aucun équipement disponible.',
            style: TextStyle(fontSize: 12.5, color: AppColors.sub),
          );
        }
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
    );
  }
}
