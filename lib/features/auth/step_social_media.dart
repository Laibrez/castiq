
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class StepSocialMedia extends StatefulWidget {
  final VoidCallback nextStep;
  final List<Map<String, String>> socialLinks;
  final ValueChanged<List<Map<String, String>>> onLinksChanged;

  const StepSocialMedia({
    super.key,
    required this.nextStep,
    required this.socialLinks,
    required this.onLinksChanged,
  });

  @override
  State<StepSocialMedia> createState() => _StepSocialMediaState();
}

class _StepSocialMediaState extends State<StepSocialMedia> {
  final _linkController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  String _selectedPlatform = 'Instagram';
  
  final List<String> _platforms = ['Instagram', 'Facebook', 'TikTok', 'LinkedIn', 'YouTube', 'Twitter', 'Other'];

  void _addLink() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;
    
    // Construct URL if just username (optional, or just store username)
    // For now, let's assume input could be full link or username.
    String url = username;
    
    final newLinks = List<Map<String, String>>.from(widget.socialLinks);
    newLinks.add({'platform': _selectedPlatform, 'url': url});
    widget.onLinksChanged(newLinks);
    _usernameController.clear();
  }

  void _removeLink(int index) {
    final newLinks = List<Map<String, String>>.from(widget.socialLinks);
    newLinks.removeAt(index);
    widget.onLinksChanged(newLinks);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Online Influence', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          const Text('Share your social media profiles', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 32),
          
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPlatform,
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white),
                    items: _platforms.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setState(() => _selectedPlatform = val!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Username / Link',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addLink,
                icon: const Icon(LucideIcons.plusCircle, color: Color(0xFF6366F1)),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          if (widget.socialLinks.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: widget.socialLinks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return ListTile(
                    dense: true,
                    title: Text(item['platform']!, style: const TextStyle(color: Colors.white70)),
                    subtitle: Text(item['url']!, style: const TextStyle(color: Colors.white30), maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(LucideIcons.trash2, color: Colors.white24, size: 18),
                      onPressed: () => _removeLink(index),
                    ),
                  );
                }).toList(),
              ),
            ),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: widget.nextStep, child: const Text('Next')),
          ),
        ],
      ),
    );
  }
}
