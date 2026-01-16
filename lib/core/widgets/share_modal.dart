import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ShareModal extends StatefulWidget {
  final String shareUrl;
  final String title;

  const ShareModal({
    super.key,
    required this.shareUrl,
    required this.title,
  });

  static void show(BuildContext context, {required String shareUrl, required String title}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ShareModal(shareUrl: shareUrl, title: title),
    );
  }

  @override
  State<ShareModal> createState() => _ShareModalState();
}

class _ShareModalState extends State<ShareModal> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSaving = false;

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.shareUrl));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _shareSystem() async {
    await Share.share(widget.shareUrl, subject: widget.title);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _saveQRCode() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving to gallery is not supported on web. Use system share or copy link.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final image = await _screenshotController.captureFromWidget(
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              QrImageView(
                data: widget.shareUrl,
                version: QrVersions.auto,
                size: 200.0,
                gapless: false,
              ),
            ],
          ),
        ),
      );

      final result = await ImageGallerySaver.saveImage(image, name: "qr_code_${DateTime.now().millisecondsSinceEpoch}");
      
      if (mounted) {
        if (result['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR Code saved to photos')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save: ${result['errorMessage']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving QR code: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Share ${widget.title}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildShareOption(
                icon: LucideIcons.copy,
                label: 'Copy Link',
                onTap: _copyLink,
              ),
              _buildShareOption(
                icon: LucideIcons.share2,
                label: 'System Share',
                onTap: _shareSystem,
              ),
              _buildShareOption(
                icon: LucideIcons.qrCode,
                label: 'Save QR',
                onTap: _saveQRCode,
                isLoading: _isSaving,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: widget.shareUrl,
              version: QrVersions.auto,
              size: 150.0,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Scan to view',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(icon, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
