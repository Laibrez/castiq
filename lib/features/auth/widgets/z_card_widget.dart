import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // Structured slots definition
  final List<String> _slotNames = ['HEADSHOT', 'FULL BODY', 'EDITORIAL', 'COMMERCIAL'];

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
    _selectedImages = List.filled(4, null); // Ensure 4 slots
    if (widget.allImages.isNotEmpty) {
      for (int i = 0; i < 4; i++) {
        if (i < widget.allImages.length) {
          _selectedImages[i] = widget.allImages[i];
        }
      }
    }
  }

  void _replaceImage(int slotIndex) {
    if (!widget.isEditable) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)), // Sharp editorial corners
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECT ${_slotNames[slotIndex]}',
                style: GoogleFonts.didactGothic(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Recommended: 2000px height minimal. Clean, professional lighting.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  itemCount: widget.allImages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8, // Portrait preview
                  ),
                  itemBuilder: (context, index) {
                    final image = widget.allImages[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImages[slotIndex] = image;
                        });
                        // Filter out nulls for the callback to maintain list integrity if needed,
                        // but actually we want to keep slots fixed.
                        // The parent expects a list. If we want structured, we might need to change how we store it.
                        // For now, let's just pass the list as is, assuming index 0 is headshot etc.
                        widget.onZCardImagesChanged(_selectedImages);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
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
      return Image.memory(image, fit: fit, alignment: Alignment.topCenter);
    } else if (image is String) {
      return Image.network(image, fit: fit, alignment: Alignment.topCenter);
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    // Layout builder to determine clean grid based on width
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 600;
        
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFFBFBFB), // Off-white editorial background
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.name.toUpperCase(),
                      style: GoogleFonts.didactGothic(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 4.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.category.toUpperCase()} • ${widget.location.toUpperCase()}',
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: 10,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // GRID
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 4 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8, // 4:5 Ratio
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) => _buildSlotContainer(index),
                ),
              ),

              const SizedBox(height: 32),

              // FOOTER STATS
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    const Divider(color: Colors.black, thickness: 1),
                    const SizedBox(height: 16),
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
      },
    );
  }

  Widget _buildSlotContainer(int index) {
    dynamic image = _selectedImages[index];

    return GestureDetector(
      onTap: () => _replaceImage(index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                border: Border.all(color: Colors.transparent),
              ),
              child: image != null
                  ? _buildImageWidget(image, fit: BoxFit.cover)
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(LucideIcons.camera, color: Colors.grey[400], size: 24),
                        // Optional subtle silhouette could go here
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _slotNames[index],
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.black,
                ),
              ),
              if (widget.isEditable)
                const Icon(LucideIcons.edit2, size: 10, color: Colors.black),
            ],
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
          style: GoogleFonts.inter(
            color: Colors.grey[600],
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toUpperCase(),
          style: GoogleFonts.didactGothic(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

