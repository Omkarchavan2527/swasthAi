import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/i18n/app_translations.dart';
import '../../providers/family_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/sw_card.dart';

class BloodDonorsScreen extends ConsumerStatefulWidget {
  const BloodDonorsScreen({super.key});

  @override
  ConsumerState<BloodDonorsScreen> createState() => _BloodDonorsScreenState();
}

class _BloodDonorsScreenState extends ConsumerState<BloodDonorsScreen> {
  String _selectedBloodGroup = 'All';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _allDonors = [
    {
      'name': 'Rahul Sharma',
      'bloodGroup': 'O+',
      'distance': '1.8 km away',
      'location': 'MIDC, Baramati',
      'phone': '9822012345',
      'isAvailable': true,
      'donations': 4,
    },
    {
      'name': 'Amit Patil',
      'bloodGroup': 'B+',
      'distance': '2.4 km away',
      'location': 'Kasba, Baramati',
      'phone': '9822054321',
      'isAvailable': true,
      'donations': 6,
    },
    {
      'name': 'Sneha Deshmukh',
      'bloodGroup': 'A+',
      'distance': '3.1 km away',
      'location': 'Bhigwan Road',
      'phone': '9890123456',
      'isAvailable': true,
      'donations': 2,
    },
    {
      'name': 'Dr. Pravin Jagtap',
      'bloodGroup': 'AB+',
      'distance': '4.0 km away',
      'location': 'Civil Hospital Area',
      'phone': '9765432109',
      'isAvailable': true,
      'donations': 11,
    },
    {
      'name': 'Vikas Jadhav',
      'bloodGroup': 'O-',
      'distance': '5.2 km away',
      'location': 'Jalochi, Baramati',
      'phone': '9881234567',
      'isAvailable': true,
      'donations': 5,
    },
    {
      'name': 'Pooja Kadam',
      'bloodGroup': 'B-',
      'distance': '6.0 km away',
      'location': 'Indapur Road',
      'phone': '9922345678',
      'isAvailable': false,
      'donations': 3,
    },
    {
      'name': 'Sanjay More',
      'bloodGroup': 'A-',
      'distance': '7.5 km away',
      'location': 'Malegaon Colony',
      'phone': '9823456789',
      'isAvailable': true,
      'donations': 8,
    },
    {
      'name': 'Ganesh Shinde',
      'bloodGroup': 'AB-',
      'distance': '8.2 km away',
      'location': 'Daund Road',
      'phone': '9850123456',
      'isAvailable': true,
      'donations': 1,
    },
  ];

  Future<void> _callDonor(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot initiate call to $phone')),
        );
      }
    }
  }

  void _showRegisterDonorSheet(BuildContext context) {
    final activeMember = ref.read(activeMemberProvider);
    final nameController = TextEditingController(text: activeMember?.name ?? '');
    final phoneController = TextEditingController(text: activeMember?.phone ?? '');
    final cityController = TextEditingController(text: 'Baramati');
    String bloodGroup = activeMember?.bloodGroup ?? 'O+';
    if (!['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'].contains(bloodGroup)) {
      bloodGroup = 'O+';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.bloodtype, color: Color(0xFFBA1A1A), size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Register as Life Saver Donor',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person, color: Color(0xFF00685F)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: bloodGroup,
                decoration: InputDecoration(
                  labelText: 'Blood Group *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.water_drop, color: Color(0xFFBA1A1A)),
                ),
                items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                    .map((bg) => DropdownMenuItem(value: bg, child: Text(bg, style: const TextStyle(fontWeight: FontWeight.bold))))
                    .toList(),
                onChanged: (val) => setSheetState(() => bloodGroup = val ?? 'O+'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Contact Phone Number *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFF00685F)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cityController,
                decoration: InputDecoration(
                  labelText: 'City / Taluka',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.location_on, color: Color(0xFF00685F)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBA1A1A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();
                    if (name.isEmpty || phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill name and contact phone number')),
                      );
                      return;
                    }

                    final box = Hive.box('settings');
                    box.put('registered_donor_profile', {
                      'name': name,
                      'bloodGroup': bloodGroup,
                      'phone': phone,
                      'location': cityController.text.trim(),
                      'registeredAt': DateTime.now().toIso8601String(),
                      'isAvailable': true,
                    });

                    Navigator.pop(ctx);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎉 Thank you $name! You are now registered as an active $bloodGroup donor.'),
                        backgroundColor: const Color(0xFF00685F),
                      ),
                    );
                  },
                  child: const Text('Confirm Registration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            AppTranslations.tr(lang, 'bloodTitle'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF121C2A)),
          ),
          bottom: TabBar(
            indicatorColor: const Color(0xFF00685F),
            labelColor: const Color(0xFF00685F),
            unselectedLabelColor: const Color(0xFF64748B),
            tabs: [
              Tab(text: AppTranslations.tr(lang, 'findDonors')),
              Tab(text: AppTranslations.tr(lang, 'donateBlood')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFindDonorsTab(lang),
            _buildDonateTab(lang),
          ],
        ),
      ),
    );
  }

  Widget _buildFindDonorsTab(String lang) {
    final bloodGroups = ['All', 'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

    final filtered = _allDonors.where((d) {
      final matchesGroup = _selectedBloodGroup == 'All' || d['bloodGroup'] == _selectedBloodGroup;
      final matchesQuery = _searchQuery.isEmpty ||
          (d['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (d['location'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (d['bloodGroup'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesGroup && matchesQuery;
    }).toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Search donor name, area, or blood group...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: Icon(Icons.search, color: Color(0xFF00685F), size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // Blood Group Filter Chips
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: bloodGroups.length,
            itemBuilder: (context, index) {
              final bg = bloodGroups[index];
              final isSelected = _selectedBloodGroup == bg;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(bg),
                  selected: isSelected,
                  selectedColor: const Color(0xFF00685F),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                  ),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF00685F) : const Color(0xFFE2E8F0),
                  ),
                  onSelected: (val) => setState(() => _selectedBloodGroup = bg),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 6),

        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bloodtype_outlined, size: 56, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 10),
                      Text(
                        'No donors found for $_selectedBloodGroup',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final donor = filtered[index];
                    final isAvail = donor['isAvailable'] as bool;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SWCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFFBA1A1A),
                              child: Text(
                                donor['bloodGroup'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        donor['name'],
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF121C2A)),
                                      ),
                                      const SizedBox(width: 6),
                                      if (isAvail)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFCCFBF1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text('Available', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00685F))),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${donor['distance']} • ${donor['location']}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Donations: ${donor['donations']} times',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF00685F), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00685F),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.call, size: 14),
                              label: const Text('Call', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () => _callDonor(donor['phone']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDonateTab(String lang) {
    final box = Hive.box('settings');
    final myProfile = box.get('registered_donor_profile') as Map?;

    if (myProfile != null) {
      final isAvail = myProfile['isAvailable'] == true;
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SWCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFFBA1A1A),
                          child: Text(
                            myProfile['bloodGroup'] ?? 'O+',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              myProfile['name'] ?? 'Donor',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                            ),
                            const Text(
                              'Verified SwasthAI Donor',
                              style: TextStyle(fontSize: 12, color: Color(0xFF00685F), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18, color: Color(0xFF64748B)),
                      onPressed: () => _showRegisterDonorSheet(context),
                    ),
                  ],
                ),
                const Divider(height: 24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF00685F),
                  title: const Text('Available for Emergency Donation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    isAvail ? 'Nearby families can contact you for blood' : 'You are currently marked as resting/busy',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  value: isAvail,
                  onChanged: (val) {
                    final updated = Map<String, dynamic>.from(myProfile);
                    updated['isAvailable'] = val;
                    box.put('registered_donor_profile', updated);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Blood Donation Compatibility',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
          ),
          const SizedBox(height: 8),
          SWCard(
            child: Column(
              children: [
                _buildCompatibilityRow('O-', 'Universal Donor (Can give to ALL)'),
                const Divider(height: 16),
                _buildCompatibilityRow('O+', 'Can give to O+, A+, B+, AB+'),
                const Divider(height: 16),
                _buildCompatibilityRow('A+', 'Can give to A+, AB+'),
                const Divider(height: 16),
                _buildCompatibilityRow('B+', 'Can give to B+, AB+'),
                const Divider(height: 16),
                _buildCompatibilityRow('AB+', 'Universal Recipient (Can receive from ALL)'),
              ],
            ),
          ),
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFFEAEA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bloodtype, size: 64, color: Color(0xFFBA1A1A)),
            ),
            const SizedBox(height: 20),
            Text(
              AppTranslations.tr(lang, 'donateBlood'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'A single donation can save up to 3 lives. Join our community-driven blood donor directory in Baramati & Maharashtra.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), height: 1.5, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBA1A1A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.favorite, size: 18),
                label: Text(
                  AppTranslations.tr(lang, 'registerAsDonor'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: () => _showRegisterDonorSheet(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibilityRow(String group, String desc) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFBA1A1A),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(group, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(desc, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
        ),
      ],
    );
  }
}
