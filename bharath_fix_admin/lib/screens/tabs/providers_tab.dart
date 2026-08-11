// lib/screens/tabs/providers_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_service.dart';

class ProvidersTab extends StatefulWidget {
  const ProvidersTab({super.key});

  @override
  State<ProvidersTab> createState() => _ProvidersTabState();
}

class _ProvidersTabState extends State<ProvidersTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _service = FirebaseService();
  String _searchQuery = '';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedCategory = 'Electrician';
  String _selectedStatus = 'Pending';

  final List<String> _categories = [
    'Electrician', 'AC Repair', 'Cleaning', 'Painting',
    'Salon', 'Plumber', 'Carpenter', 'Pest Control'
  ];

  final List<String> _statuses = ['Pending', 'Active', 'Inactive'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showKycReviewDialog(String docId, Map<String, dynamic> data) {
    final kyc = data['kyc'] as Map<String, dynamic>? ?? {};
    final bank = data['bankDetails'] as Map<String, dynamic>? ?? {};
    final skills = (data['skills'] as List<dynamic>?) ?? [];
    final name = data['name'] ?? 'Partner';
    final email = data['email'] ?? 'N/A';
    final phone = data['phone'] ?? 'N/A';
    final radius = data['operatingRadiusKm'] ?? 15;
    final exp = data['experience'] ?? data['experienceYears'] ?? 3;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Review Partner KYC & Skills', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoSection('Personal & Contact Info', [
                  'Full Name: $name',
                  'Email Address: $email',
                  'Phone Number: $phone',
                  'Experience: $exp years',
                  'Operating Radius: $radius km',
                ]),
                const SizedBox(height: 16),
                _buildInfoSection('Identity Verification (KYC)', [
                  'Aadhaar Number: ${kyc['aadhaarNumber'] ?? 'N/A'}',
                  'PAN Number: ${kyc['panNumber'] ?? 'N/A'}',
                ]),
                const SizedBox(height: 16),
                _buildInfoSection('Bank Payout Information', [
                  'Bank Name: ${bank['bankName'] ?? 'N/A'}',
                  'Account Holder: ${bank['accountHolder'] ?? 'N/A'}',
                  'Account Number: ${bank['accountNumber'] ?? bank['accountNo'] ?? 'N/A'}',
                  'IFSC Code: ${bank['ifscCode'] ?? bank['ifsc'] ?? 'N/A'}',
                ]),
                const SizedBox(height: 16),
                Text('Certified Appliance Skills:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: skills.map((skill) => Chip(label: Text(skill.toString(), style: const TextStyle(fontSize: 12)))).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _service.updateProviderStatus(docId, 'Active');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Partner $name Approved & Activated!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000062)),
              child: Text('Approve & Activate Partner', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoSection(String header, List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(header, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF000062), fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        for (var line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(line, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF555555), fontSize: 13)),
          ),
      ],
    );
  }

  void _showAddProviderDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('Onboard New Provider', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold)),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Full Name', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'e.g. Ramesh Kumar',
                          hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9E9E9E)),
                          filled: true,
                          fillColor: const Color(0xFFF7F8FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      Text('Phone Number', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneController,
                        style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'e.g. 9876543210',
                          hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9E9E9E)),
                          filled: true,
                          fillColor: const Color(0xFFF7F8FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Phone is required' : null,
                      ),
                      const SizedBox(height: 16),

                      Text('Skill Category', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(8)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            dropdownColor: Colors.white,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF111111)),
                            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 14),
                            items: _categories.map((cat) {
                              return DropdownMenuItem(value: cat, child: Text(cat));
                            }).toList(),
                            onChanged: (val) => setDialogState(() => _selectedCategory = val!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text('Approval Status', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(8)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            dropdownColor: Colors.white,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF111111)),
                            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 14),
                            items: _statuses.map((st) {
                              return DropdownMenuItem(value: st, child: Text(st));
                            }).toList(),
                            onChanged: (val) => setDialogState(() => _selectedStatus = val!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575))),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    
                    Navigator.pop(context);
                    await _service.addProvider(
                      name: _nameController.text.trim(),
                      phone: _phoneController.text.trim(),
                      category: _selectedCategory,
                      status: _selectedStatus,
                    );

                    _nameController.clear();
                    _phoneController.clear();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Onboarded Provider successfully!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000062)),
                  child: Text('Onboard', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Providers Directory & KYC',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF111111),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage technician status, review KYC (Aadhaar/PAN/Bank), and approve partner accounts.',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF757575),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddProviderDialog,
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                label: Text(
                  'Add Provider',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000062),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF000062),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF000062),
            indicatorWeight: 3,
            labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: "Active Service Directory"),
              Tab(text: "Pending KYC Approvals"),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActiveProvidersList(),
                _buildPendingKycList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveProvidersList() {
    return Column(
      children: [
        TextField(
          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search by provider name or skill category...',
            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9E9E9E)),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF757575)),
            filled: true,
            fillColor: const Color(0xFFF7F8FA),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF000062)),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
        const SizedBox(height: 20),

        Expanded(
          child: StreamBuilder(
            stream: _service.getProvidersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF000062)));
              }

              final docs = snapshot.data?.docs ?? [];
              final filteredDocs = docs.where((doc) {
                final data = doc.data();
                final name = (data['name'] as String? ?? '').toLowerCase();
                final category = (data['category'] as String? ?? '').toLowerCase();
                final status = (data['status'] as String? ?? '').trim().toLowerCase();

                return status != 'pending_verification' && status != 'pending' && (name.contains(_searchQuery) || category.contains(_searchQuery));
              }).toList();

              if (filteredDocs.isEmpty) {
                return Center(
                  child: Text(
                    'No active providers registered in directory.',
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575)),
                  ),
                );
              }

              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFEAEAEA)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F8FA)),
                        dataRowMinHeight: 64,
                        dataRowMaxHeight: 76,
                        columns: [
                          DataColumn(label: Text('Full Name', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Skill Category', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Telephone Phone', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Completed Jobs', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Rating', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Status', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Actions', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                        ],
                        rows: filteredDocs.map((doc) {
                          final data = doc.data();
                          final id = doc.id;
                          final name = data['name'] as String? ?? '';
                          final category = data['category'] as String? ?? 'Appliance Repair';
                          final phone = data['phone'] as String? ?? '';
                          final completedJobs = data['completedJobs'] as int? ?? 0;
                          final rating = data['rating']?.toString() ?? '5.0';
                          final status = data['status'] as String? ?? 'Active';

                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: const Color(0xFF000062).withOpacity(0.08),
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : 'P',
                                        style: GoogleFonts.plusJakartaSans(color: const Color(0xFF000062), fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(name, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              DataCell(Text(category, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 13))),
                              DataCell(Text(phone, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 13))),
                              DataCell(Text(completedJobs.toString(), style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 13))),
                              DataCell(
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(rating, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              DataCell(_buildStatusBadge(status)),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.description_outlined, color: Color(0xFF000062), size: 18),
                                      onPressed: () => _showKycReviewDialog(id, data),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                      onPressed: () => _confirmDeleteProvider(id, name),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPendingKycList() {
    return StreamBuilder(
      stream: _service.getProvidersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF000062)));
        }

        final docs = snapshot.data?.docs ?? [];
        final pendingDocs = docs.where((doc) {
          final st = (doc.data()['status'] ?? '').toString().trim().toLowerCase();
          return st == 'pending_verification' || st == 'pending';
        }).toList();

        if (pendingDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_user_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No Pending Partner Approvals', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('New technician registrations will appear here for KYC verification.', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: pendingDocs.length,
          itemBuilder: (context, index) {
            final doc = pendingDocs[index];
            final data = doc.data();
            final name = data['name'] ?? 'Partner';
            final email = data['email'] ?? 'N/A';
            final phone = data['phone'] ?? 'N/A';
            final skills = (data['skills'] as List<dynamic>?) ?? [];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                            child: const Text('KYC PENDING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text("Email: $email • Phone: $phone", style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text("Skills: ${skills.join(', ')}", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF000062), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showKycReviewDialog(doc.id, data),
                    icon: const Icon(Icons.find_in_page_outlined, color: Colors.white, size: 16),
                    label: const Text('Review & Approve KYC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000062)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bg;

    switch (status.toLowerCase()) {
      case 'active':
        color = const Color(0xFF34A853);
        bg = const Color(0xFF34A853).withOpacity(0.1);
        break;
      case 'inactive':
        color = Colors.redAccent;
        bg = Colors.redAccent.withOpacity(0.1);
        break;
      case 'pending':
      case 'pending_verification':
      default:
        color = const Color(0xFFFF9900);
        bg = const Color(0xFFFF9900).withOpacity(0.1);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _confirmDeleteProvider(String id, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Delete Provider Profile', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold)),
          content: Text(
            'Are you sure you want to delete "$name" from the providers directory?',
            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _service.deleteProvider(id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted provider $name.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: Text('Delete', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
