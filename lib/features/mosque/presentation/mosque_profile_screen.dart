import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/mosque_model.dart';

class MosqueProfileScreen extends StatefulWidget {
  final String mosqueId;

  const MosqueProfileScreen({super.key, required this.mosqueId});

  @override
  State<MosqueProfileScreen> createState() => _MosqueProfileScreenState();
}

class _MosqueProfileScreenState extends State<MosqueProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>> get _mosqueRef => FirebaseFirestore
      .instance
      .collection('mosques')
      .doc(widget.mosqueId);

  Future<void> _openEditSheet(MosqueModel mosque) async {
    final nameController = TextEditingController(text: mosque.name);
    final imamNameController = TextEditingController(text: mosque.imamName);
    final imamPhoneController = TextEditingController(text: mosque.imamPhone);
    final descController = TextEditingController(text: mosque.description);
    final cityController = TextEditingController(text: mosque.city);
    final addressController = TextEditingController(text: mosque.address);

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'تعديل الملف',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _field('اسم المسجد', nameController),
                    _field('اسم الإمام', imamNameController),
                    _field('رقم هاتف الإمام', imamPhoneController,
                        keyboardType: TextInputType.phone),
                    _field('المدينة', cityController),
                    _field('العنوان', addressController),
                    _field('عن المسجد', descController, maxLines: 4),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('إلغاء'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              try {
                                await _mosqueRef.update({
                                  'name': nameController.text.trim(),
                                  'imamName': imamNameController.text.trim(),
                                  'imamPhone': imamPhoneController.text.trim(),
                                  'city': cityController.text.trim(),
                                  'address': addressController.text.trim(),
                                  'description': descController.text.trim(),
                                });
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم تحديث الملف بنجاح'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('حدث خطأ أثناء الحفظ: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('حفظ التعديلات'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _field(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF4F6F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _mosqueRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.data!.exists) {
              return const Center(child: Text('لم يتم العثور على المسجد'));
            }

            final mosque =
                MosqueModel.fromMap(snapshot.data!.id, snapshot.data!.data()!);

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 220,
                    pinned: true,
                    backgroundColor: const Color(0xFF0F766E),
                    iconTheme: const IconThemeData(color: Colors.white),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          mosque.coverUrl.isNotEmpty
                              ? Image.network(mosque.coverUrl,
                                  fit: BoxFit.cover)
                              : Container(color: const Color(0xFF0F766E)),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.05),
                                  Colors.black.withOpacity(0.55),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            right: 16,
                            left: 16,
                            child: Row(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                    color: Colors.white,
                                  ),
                                  child: ClipOval(
                                    child: mosque.logoUrl.isNotEmpty
                                        ? Image.network(mosque.logoUrl,
                                            fit: BoxFit.cover)
                                        : const Icon(Icons.mosque_rounded,
                                            color: Color(0xFF0F766E),
                                            size: 32),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              mosque.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (mosque.isVerified) ...[
                                            const SizedBox(width: 4),
                                            const Icon(
                                                Icons.verified_rounded,
                                                color: Colors.white,
                                                size: 18),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        mosque.city.isNotEmpty
                                            ? mosque.city
                                            : mosque.address,
                                        style: TextStyle(
                                          color:
                                              Colors.white.withOpacity(0.9),
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 4),
                        child: TextButton.icon(
                          onPressed: () => _openEditSheet(mosque),
                          icon: const Icon(Icons.edit_rounded,
                              color: Colors.white, size: 18),
                          label: const Text(
                            'تعديل الملف',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF0F766E),
                        unselectedLabelColor: Colors.black54,
                        indicatorColor: const Color(0xFF0F766E),
                        tabs: const [
                          Tab(text: 'عن المسجد'),
                          Tab(text: 'المنشورات'),
                          Tab(text: 'أوقات الصلاة'),
                          Tab(text: 'الموقع'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildAboutTab(mosque),
                  _buildPostsTab(),
                  _buildPrayerTimesTab(),
                  _buildLocationTab(mosque),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAboutTab(MosqueModel mosque) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoTile(Icons.person_rounded, 'اسم الإمام',
            mosque.imamName.isNotEmpty ? mosque.imamName : 'غير محدد'),
        _infoTile(Icons.phone_rounded, 'رقم الهاتف',
            mosque.imamPhone.isNotEmpty ? mosque.imamPhone : 'غير محدد'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الوصف',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                mosque.description.isNotEmpty
                    ? mosque.description
                    : 'لا يوجد وصف بعد.',
                style: const TextStyle(
                  color: Colors.black54,
                  height: 1.6,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0F766E), size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.black45)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _mosqueRef
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('لا توجد منشورات بعد'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final post = docs[index].data();
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(post['title'] ?? ''),
            );
          },
        );
      },
    );
  }

  Widget _buildPrayerTimesTab() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _mosqueRef.collection('prayerTimes').doc('today').snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final prayers = {
          'الفجر': data?['fajr'],
          'الظهر': data?['dhuhr'],
          'العصر': data?['asr'],
          'المغرب': data?['maghrib'],
          'العشاء': data?['isha'],
        };
        return ListView(
          padding: const EdgeInsets.all(16),
          children: prayers.entries.map((e) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(e.value ?? '--:--',
                      style: const TextStyle(color: Color(0xFF0F766E))),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLocationTab(MosqueModel mosque) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFFE5F3F1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(Icons.map_rounded, size: 40, color: Color(0xFF0F766E)),
          ),
        ),
        const SizedBox(height: 12),
        _infoTile(Icons.location_city_rounded, 'المدينة',
            mosque.city.isNotEmpty ? mosque.city : 'غير محدد'),
        _infoTile(Icons.place_rounded, 'العنوان التفصيلي',
            mosque.address.isNotEmpty ? mosque.address : 'غير محدد'),
      ],
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
