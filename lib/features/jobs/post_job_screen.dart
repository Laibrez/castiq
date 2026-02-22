import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/core/services/job_service.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/models/job_model.dart';
import 'package:intl/intl.dart';

const _categories = [
  'Editorial',
  'Commercial',
  'Runway',
  'E-commerce',
  'Catalog',
  'Fitness',
  'Lifestyle',
  'Beauty',
  'Plus Size',
  'Promotional',
];

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _bringItemsController = TextEditingController();

  String? _selectedCategory;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _modelsNeeded = 1;
  bool _isSubmitting = false;

  bool get _isGroupJob => _modelsNeeded > 1;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _requirementsController.dispose();
    _bringItemsController.dispose();
    super.dispose();
  }

  void _adjustModelsNeeded(int delta) {
    setState(() {
      _modelsNeeded = (_modelsNeeded + delta).clamp(1, 20);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.gold,
              onPrimary: AppTheme.black,
              surface: AppTheme.white,
              onSurface: AppTheme.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.gold,
              onPrimary: AppTheme.black,
              surface: AppTheme.white,
              onSurface: AppTheme.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Select';
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final m = time.minute.toString().padLeft(2, '0');
    final p = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  int _parseBudget(String value) => int.tryParse(value) ?? 0;

  Future<void> _handleSubmit(String status) async {
    if (status == 'active') {
      if (_titleController.text.isEmpty ||
          _selectedCategory == null ||
          _locationController.text.isEmpty ||
          _selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields before posting.')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final authService = AuthService();
      final user = authService.currentUser;
      if (user == null) throw Exception('Not logged in');

      final budgetMin = int.tryParse(_budgetMinController.text) ?? 0;

      final jobModel = JobModel(
        id: '',
        brandId: user.uid,
        brandName: user.displayName ?? 'Brand',
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        date: _selectedDate ?? DateTime.now(),
        rate: budgetMin.toDouble(),
        requirements: _requirementsController.text.isNotEmpty
            ? _requirementsController.text.split('\n').where((r) => r.trim().isNotEmpty).toList()
            : [],
        status: status == 'active' ? 'open' : 'draft',
        createdAt: DateTime.now(),
      );

      await JobService().createJob(jobModel);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'active'
                ? 'Your job "${_titleController.text}" is now live!'
                : 'Draft saved. You can publish it anytime.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Post a Job',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Basic Information ──
            _SectionCard(
              title: 'Basic Information',
              children: [
                _buildLabel('Job Title', required: true),
                const SizedBox(height: 8),
                _buildTextField(_titleController, 'e.g., Summer Collection Photoshoot'),
                const SizedBox(height: 20),

                _buildLabel('Category', required: true),
                const SizedBox(height: 8),
                _buildCategoryDropdown(),
                const SizedBox(height: 20),

                _buildLabel('Description'),
                const SizedBox(height: 8),
                _buildTextField(_descriptionController, 'Describe the job, what you\'re looking for...', maxLines: 3),
              ],
            ),
            const SizedBox(height: 16),

            // ── Models Needed ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isGroupJob ? AppTheme.gold.withOpacity(0.04) : AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isGroupJob ? AppTheme.gold.withOpacity(0.25) : const Color(0xFFE8E4DE),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.users, size: 16, color: AppTheme.grey),
                      const SizedBox(width: 8),
                      Text('Models Needed', style: _sectionTitleStyle()),
                      const Spacer(),
                      if (_isGroupJob)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.gold.withOpacity(0.25)),
                          ),
                          child: Text(
                            'Group Booking',
                            style: GoogleFonts.montserrat(
                              fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.gold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _counterButton(LucideIcons.minus, () => _adjustModelsNeeded(-1), _modelsNeeded <= 1),
                      const SizedBox(width: 24),
                      Column(
                        children: [
                          Text(
                            '$_modelsNeeded',
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.black,
                            ),
                          ),
                          Text(
                            _modelsNeeded == 1 ? 'model' : 'models',
                            style: GoogleFonts.montserrat(fontSize: 13, color: AppTheme.grey),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      _counterButton(LucideIcons.plus, () => _adjustModelsNeeded(1), _modelsNeeded >= 20),
                    ],
                  ),

                  if (_isGroupJob) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.cream,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.info, size: 16, color: AppTheme.gold),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Group Booking Benefits:',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.black,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...[
                                  'Send contracts to all models at once',
                                  'Group chat with entire team',
                                  'Unified payment processing',
                                  'Track all check-ins in one place',
                                ].map((b) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('•  ', style: GoogleFonts.montserrat(fontSize: 12, color: AppTheme.grey)),
                                      Expanded(
                                        child: Text(b, style: GoogleFonts.montserrat(fontSize: 12, color: AppTheme.grey, height: 1.4)),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Location & Schedule ──
            _SectionCard(
              icon: LucideIcons.mapPin,
              title: 'Location & Schedule',
              children: [
                _buildLabel('Location', required: true),
                const SizedBox(height: 8),
                _buildTextField(_locationController, 'e.g., 123 Studio Ave, New York, NY'),
                const SizedBox(height: 20),

                _buildLabel('Date', required: true),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE0DCD5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 16, color: AppTheme.grey),
                        const SizedBox(width: 10),
                        Text(
                          _selectedDate != null
                              ? DateFormat('MMMM d, yyyy').format(_selectedDate!)
                              : 'Select date',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: _selectedDate != null ? AppTheme.black : AppTheme.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Start Time'),
                          const SizedBox(height: 8),
                          _buildTimePicker(isStart: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('End Time'),
                          const SizedBox(height: 8),
                          _buildTimePicker(isStart: false),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Budget ──
            _SectionCard(
              icon: LucideIcons.dollarSign,
              title: 'Budget',
              trailing: _isGroupJob
                  ? Text('(per model)', style: GoogleFonts.montserrat(fontSize: 11, color: AppTheme.grey))
                  : null,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Minimum (\$)'),
                          const SizedBox(height: 8),
                          _buildTextField(_budgetMinController, '500', keyboardType: TextInputType.number),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Maximum (\$)'),
                          const SizedBox(height: 8),
                          _buildTextField(_budgetMaxController, '800', keyboardType: TextInputType.number),
                        ],
                      ),
                    ),
                  ],
                ),

                if (_isGroupJob && _budgetMinController.text.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.cream,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text.rich(
                      TextSpan(
                        text: 'Total budget for $_modelsNeeded models: ',
                        style: GoogleFonts.montserrat(fontSize: 13, color: AppTheme.grey),
                        children: [
                          TextSpan(
                            text: _totalBudgetLabel(),
                            style: GoogleFonts.montserrat(
                              fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // ── Additional Details ──
            _SectionCard(
              title: 'Additional Details',
              children: [
                _buildLabel('Requirements'),
                const SizedBox(height: 8),
                _buildTextField(_requirementsController, 'Height, experience level, specific look...', maxLines: 2),
                const SizedBox(height: 20),

                _buildLabel('What to Bring'),
                const SizedBox(height: 8),
                _buildTextField(_bringItemsController, 'Neutral undergarments, heels, portfolio...', maxLines: 2),
              ],
            ),
            const SizedBox(height: 16),

            // ── Group Booking Summary ──
            if (_isGroupJob) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Group Booking Summary',
                      style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.black),
                    ),
                    const SizedBox(height: 16),
                    _summaryRow('Models needed', '$_modelsNeeded'),
                    _summaryRow('Per-model budget', _perModelBudgetLabel()),
                    _summaryRow('Total budget', _totalBudgetLabel()),
                    _summaryRow('Platform fee (10%)', _platformFeeLabel()),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Divider(color: Color(0xFFE8E4DE)),
            const SizedBox(height: 16),

            // ── Buttons ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => _handleSubmit('draft'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: const BorderSide(color: Color(0xFFE0DCD5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Save as Draft',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: AppTheme.black),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _handleSubmit('active'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: AppTheme.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      _isSubmitting ? 'Posting...' : 'Post Job',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _buildLabel(String text, {bool required = false}) {
    return Text(
      required ? '$text *' : text,
      style: GoogleFonts.montserrat(
        fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.black,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.montserrat(fontSize: 14, color: AppTheme.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(fontSize: 14, color: const Color(0xFFAAAAAA)),
        filled: true,
        fillColor: AppTheme.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0DCD5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0DCD5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.gold, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0DCD5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          hint: Text('Select category', style: GoogleFonts.montserrat(fontSize: 14, color: const Color(0xFFAAAAAA))),
          isExpanded: true,
          icon: const Icon(LucideIcons.chevronDown, size: 18, color: AppTheme.grey),
          dropdownColor: AppTheme.white,
          style: GoogleFonts.montserrat(fontSize: 14, color: AppTheme.black),
          items: _categories.map((cat) {
            return DropdownMenuItem(value: cat.toLowerCase(), child: Text(cat));
          }).toList(),
          onChanged: (value) => setState(() => _selectedCategory = value),
        ),
      ),
    );
  }

  Widget _buildTimePicker({required bool isStart}) {
    final time = isStart ? _startTime : _endTime;
    return GestureDetector(
      onTap: () => _pickTime(isStart: isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0DCD5)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.clock, size: 16, color: AppTheme.grey),
            const SizedBox(width: 10),
            Text(
              _formatTime(time),
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: time != null ? AppTheme.black : AppTheme.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterButton(IconData icon, VoidCallback onTap, bool disabled) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: disabled ? const Color(0xFFE8E4DE) : const Color(0xFFE0DCD5)),
        ),
        child: Icon(icon, size: 18, color: disabled ? const Color(0xFFCCCCCC) : AppTheme.black),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.montserrat(fontSize: 13, color: AppTheme.grey)),
          Text(value, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.black)),
        ],
      ),
    );
  }

  TextStyle _sectionTitleStyle() => GoogleFonts.montserrat(
        fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.black,
      );

  String _perModelBudgetLabel() {
    final min = _budgetMinController.text;
    final max = _budgetMaxController.text;
    if (min.isEmpty) return 'Not set';
    return max.isNotEmpty ? '\$$min - \$$max' : '\$$min';
  }

  String _totalBudgetLabel() {
    final min = _parseBudget(_budgetMinController.text);
    final max = _parseBudget(_budgetMaxController.text);
    if (min == 0) return 'Not set';
    final totalMin = min * _modelsNeeded;
    final totalMax = max * _modelsNeeded;
    return totalMax > 0 ? '\$$totalMin - \$$totalMax' : '\$$totalMin';
  }

  String _platformFeeLabel() {
    final min = _parseBudget(_budgetMinController.text);
    if (min == 0) return 'Not set';
    return '~\$${(min * _modelsNeeded * 0.1).round()}';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    this.icon,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E4DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppTheme.grey),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.black,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
