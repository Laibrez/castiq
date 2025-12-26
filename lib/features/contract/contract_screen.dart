import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ContractScreen extends StatefulWidget {
  const ContractScreen({super.key});

  @override
  State<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen> {
  bool _isSigned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Digital Contract',
          style: GoogleFonts.tinos(fontWeight: FontWeight.w600, fontStyle: FontStyle.italic),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Standard Model Release Agreement',
                    style: GoogleFonts.tinos(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'This Agreement is made between [Brand Name] ("Client") and [Model Name] ("Model").\n\n'
                    '1. SCOPE OF WORK\n'
                    'Model agrees to provide modeling services for Client on [Date] at [Location].\n\n'
                    '2. COMPENSATION\n'
                    'Client agrees to pay Model the sum of [Amount] for the services rendered.\n\n'
                    '3. USAGE RIGHTS\n'
                    'Client shall have the right to use the images for [Usage Details] for a period of [Duration].\n\n'
                    '4. CANCELLATION\n'
                    'Cancellations made less than 24 hours before the shoot will incur a fee of 50%.\n\n'
                    '5. GOVERNING LAW\n'
                    'This agreement shall be governed by the laws of [State/Country].',
                    style: GoogleFonts.tinos(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (_isSigned)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.green.withOpacity(0.1),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.checkCircle, color: Colors.green),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Signed by Jane Doe',
                                style: GoogleFonts.tinos(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                DateTime.now().toString().split('.')[0],
                                style: GoogleFonts.tinos(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(top: BorderSide(color: Colors.grey[900]!)),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSigned
                      ? null
                      : () {
                          setState(() {
                            _isSigned = true;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Contract Signed Successfully')),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSigned ? Colors.grey : Colors.white,
                  ),
                  child: Text(_isSigned ? 'Signed' : 'Sign Contract'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
