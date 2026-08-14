import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/api_client.dart';
import '../../data/listing_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_chip.dart';
import '../../widgets/bc_icon.dart';
import '../../widgets/bc_mobile_frame.dart';
import '../../widgets/bc_sticky_bar.dart';

const _propertyTypes = [
  ('studio', 'Studio'),
  ('appartement', 'Appartement'),
  ('chambre', 'Chambre'),
  ('villa', 'Villa'),
];

/// Formulaire de publication — fidèle à la vue « Mobile · Publier un bien »
/// du dossier de conception (section 8, Bailleur).
class PublishListingScreen extends StatefulWidget {
  const PublishListingScreen({super.key});

  @override
  State<PublishListingScreen> createState() => _PublishListingScreenState();
}

class _PublishListingScreenState extends State<PublishListingScreen> {
  final _listingRepository = ListingRepository(ApiClient());
  final _picker = ImagePicker();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _termsController = TextEditingController();
  final _whatsappController = TextEditingController(text: '+237');

  String _propertyType = _propertyTypes.first.$1;
  final List<(XFile file, Uint8List bytes)> _pickedMedia = [];
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _neighborhoodController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _termsController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _pickedMedia.add((file, bytes)));
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty ||
        _neighborhoodController.text.trim().isEmpty) {
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
      final listing = await _listingRepository.create(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        neighborhood: _neighborhoodController.text.trim(),
        propertyType: _propertyType,
        rentAmount: rent,
        depositAmount: int.tryParse(_depositController.text.trim()) ?? 0,
        terms: _termsController.text.trim(),
        whatsappNumber: _whatsappController.text.trim(),
      );

      for (final (file, bytes) in _pickedMedia) {
        await _listingRepository.uploadMedia(
          listingId: listing.id,
          mediaType: 'photo',
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
    return BcMobileFrame(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          icon: const BcIcon('back', size: 18),
                        ),
                        const Text(
                          'Nouveau bien',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      '1/1',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.sub,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: _pickMedia,
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          height: 122,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: AppColors.green,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                            color: AppColors.greenLight,
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                BcIcon(
                                  'images',
                                  size: 28,
                                  color: AppColors.greenDark,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Ajouter vidéo 60 s + photos',
                                  style: TextStyle(
                                    color: AppColors.greenDark,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_pickedMedia.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 52,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _pickedMedia.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) => ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                _pickedMedia[index].$2,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _label('Titre & type'),
                      _textField(
                        _titleController,
                        hint: 'Studio meublé · Yaoundé',
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final type in _propertyTypes)
                            BcChip(
                              label: type.$2,
                              selected: _propertyType == type.$1,
                              onTap: () =>
                                  setState(() => _propertyType = type.$1),
                            ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      _textField(
                        _descriptionController,
                        hint: 'Description du bien',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      _label('Localisation'),
                      _textField(
                        _neighborhoodController,
                        hint: 'Quartier (ex. Bastos)',
                        icon: 'pin',
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Expanded(
                            child: _textField(
                              _rentController,
                              hint: 'Loyer /mois',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _textField(
                              _depositController,
                              hint: 'Caution',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      _textField(
                        _whatsappController,
                        hint: 'WhatsApp de contact (+237)',
                        icon: 'phone',
                      ),
                      const SizedBox(height: 14),
                      _label('Modalités'),
                      _textField(
                        _termsController,
                        hint: 'Conditions, durée du bail, avance exigée…',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              BcStickyBar(
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    icon: const BcIcon('check', size: 17, color: Colors.white),
                    label: Text(
                      _submitting
                          ? 'Publication...'
                          : 'Publier — soumis à validation',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
    ),
  );

  Widget _textField(
    TextEditingController controller, {
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
        hintText: hint,
        prefixIcon: icon != null
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: BcIcon(icon, size: 16, color: AppColors.sub),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: const Color(0xFFEEF2F0),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.line),
        ),
      ),
    );
  }
}
