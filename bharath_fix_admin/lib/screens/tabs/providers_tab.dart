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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  const SizedBox(height: 4),
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
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 800;
                  if (isDesktop) {
                    return _buildDesktopProvidersTable(filteredDocs);
                  } else {
                    return _buildMobileProvidersList(filteredDocs);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopProvidersTable(List filteredDocs) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEAEAEA)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F8FA)),
              dataRowMinHeight: 64,
              dataRowMaxHeight: 76,
              columns: [
                DataColumn(label: Text('Full Name', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Skill Category', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Mobile Phone', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
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
                final rating = data['rating']?.toString() ?? '4.9';
                final status = data['status'] as String? ?? 'Active';

                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF000062).withValues(alpha: 0.08),
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
                          Text(rating, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    DataCell(_buildStatusBadge(status)),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.badge_rounded, color: Color(0xFF000062), size: 20),
                            tooltip: 'Review KYC & Skill Profile',
                            onPressed: () => _showKycReviewDialog(id, data),
                          ),
                          IconButton(
                            icon: Icon(
                              status == 'Active' ? Icons.block_rounded : Icons.check_circle_rounded,
                              color: status == 'Active' ? Colors.redAccent : Colors.green,
                              size: 18,
                            ),
                            tooltip: status == 'Active' ? 'Deactivate Account' : 'Activate Account',
                            onPressed: () async {
                              final newStatus = status == 'Active' ? 'Inactive' : 'Active';
                              await _service.updateProviderStatus(id, newStatus);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Updated $name to $newStatus')),
                                );
                              }
                            },
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
  }

  Widget _buildMobileProvidersList(List filteredDocs) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: filteredDocs.length,
      itemBuilder: (context, index) {
        final doc = filteredDocs[index];
        final data = doc.data();
        final id = doc.id;
        final name = data['name'] as String? ?? '';
        final category = data['category'] as String? ?? 'Appliance Repair';
        final phone = data['phone'] as String? ?? '';
        final rating = data['rating']?.toString() ?? '4.9';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEAEAEA)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF000062).withValues(alpha: 0.08),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'P',
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF000062), fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF111111)))),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(rating, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('$category • $phone', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF757575))),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.badge_rounded, color: Color(0xFF000062), size: 20),
                onPressed: () => _showKycReviewDialog(id, data),
              ),
            ],
          ),
        );
      },
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
          final data = doc.data();
          final status = (data['status'] as String? ?? '').trim().toLowerCase();
          return status == 'pending_verification' || status == 'pending';
        }).toList();

        if (pendingDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_rounded, color: Colors.green, size: 48),
                const SizedBox(height: 12),
                Text('No Pending KYC Applications', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('All partner registrations are currently verified and active.', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: pendingDocs.length,
          itemBuilder: (context, index) {
            final doc = pendingDocs[index];
            final data = doc.data();
            final id = doc.id;
            final name = data['name'] ?? 'Partner';
            final phone = data['phone'] ?? 'N/A';
            final category = data['category'] ?? 'Appliance Specialist';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions_rounded, color: Colors.amber, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('$category • Phone: $phone', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade800)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showKycReviewDialog(id, data),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000062)),
                    child: const Text('Review KYC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
    Color bg = status == 'Active' ? Colors.green.shade50 : Colors.red.shade50;
    Color fg = status == 'Active' ? Colors.green.shade800 : Colors.red.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
