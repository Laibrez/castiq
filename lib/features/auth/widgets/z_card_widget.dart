import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ZCardWidget extends StatefulWidget {
  final List<dynamic> allImages; // Uint8List or String (URL)
  final String name;
  final String category;
  final String location;
  final bool willingToTravel;
  final Map<String, dynamic> stats; // Height, Bust, Waist, Hips, Shoe
  final ValueChanged<List<dynamic>> onZCardImagesChanged;
  final bool isEditable;

  const ZCardWidget({
    super.key,
    required this.allImages,
    required this.name,
    required this.category,
    required this.location,
    required this.willingToTravel,
    required this.stats,
    required this.onZCardImagesChanged,
    this.isEditable = true,
  });

  @override
  State<ZCardWidget> createState() => _ZCardWidgetState();
}

class _ZCardWidgetState extends State<ZCardWidget> {
  late List<dynamic> _selectedImages;

  @override
  void initState() {
    super.initState();
    _populateSelectedImages();
  }
  
  @override
  void didUpdateWidget(ZCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.allImages != oldWidget.allImages) {
      _populateSelectedImages();
    }
  }

  void _populateSelectedImages() {
    _selectedImages = [];
    if (widget.allImages.isNotEmpty) {
      for (int i = 0; i < 4; i++) {
        if (i < widget.allImages.length) {
          _selectedImages.add(widget.allImages[i]);
        }
      }
    }
    // Fire initial change so parent has defaults if needed? No, let parent handle.
  }

  void _replaceImage(int slotIndex) {
    if (!widget.isEditable) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Image',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  itemCount: widget.allImages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final image = widget.allImages[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (slotIndex < _selectedImages.length) {
                            _selectedImages[slotIndex] = image;
                          } else {
                            if (_selectedImages.length < 4) {
                                _selectedImages.add(image);
                            }
                          }
                        });
                        widget.onZCardImagesChanged(_selectedImages);
                        Navigator.pop(context);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImageWidget(image),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageWidget(dynamic image, {BoxFit fit = BoxFit.cover}) {
    if (image is Uint8List) {
      return Image.memory(image, fit: fit);
    } else if (image is String) {
      return Image.network(image, fit: fit);
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2), // Print-style corner
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 2x2 Grid
          AspectRatio(
            aspectRatio: 4 / 5, // Typical Card ratio roughly
            child: Row(
              children: [
                // Left Column
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildImageSlot(0)),
                      const SizedBox(height: 2),
                      Expanded(child: _buildImageSlot(2)),
                    ],
                  ),
                ),
                const SizedBox(width: 2), // Grid gutter
                // Right Column
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildImageSlot(1)),
                      const SizedBox(height: 2),
                      Expanded(child: _buildImageSlot(3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Info Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.name.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Didot', // Or serif fallback
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.willingToTravel ? 'TRAVEL: YES' : 'LOCAL ONLY',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${widget.category} • ${widget.location}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.black, height: 1),
                const SizedBox(height: 12),
                
                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat('HEIGHT', widget.stats['Height'] ?? '-'),
                    _buildStat('BUST', widget.stats['Bust'] ?? '-'),
                    _buildStat('WAIST', widget.stats['Waist'] ?? '-'),
                    _buildStat('HIPS', widget.stats['Hips'] ?? '-'),
                    _buildStat('SHOE', widget.stats['Shoe'] ?? '-'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSlot(int index) {
    Uint8List? image;
    if (index < _selectedImages.length) {
      image = _selectedImages[index];
    }

    return GestureDetector(
      onTap: () => _replaceImage(index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: const Color(0xFFF5F5F5),
            child: image != null
                ? _buildImageWidget(image, fit: BoxFit.cover)
                : const Center(
                    child: Icon(LucideIcons.image, color: Colors.grey),
                  ),
          ),
          // Edit Overlay Hint
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.edit2, size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
