import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/app_localizations.dart';
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
    final l10n = context.l10n;
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
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.editProfile,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _field(l10n.mosqueName, nameController),
                  _field(l10n.fullName, imamNameController),
                  _field(l10n.imamPhone, imamPhoneController,
                      keyboardType: TextInputType.phone),
                  _field(l10n.city, cityController),
                  _field(l10n.address, addressController),
                  _field(l10n.about, descController, maxLines: 4),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.cancel),
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
                                'contactPhone': imamPhoneController.text.trim(),
                                'city': cityController.text.trim(),
                                'address': addressController.text.trim(),
                                'description': descController.text.trim(),
                              });
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.profileSaved),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${l10n.error}: $e'),
                                  ),
                                );
                              }
                            }
                          },
                          child: Text(l10n.saveChanges),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
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
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _mosqueRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '${l10n.error}: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F766E)),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text(l10n.mosqueDataNotFound));
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
                                Colors.black.withValues(alpha: 0.05),
                                Colors.black.withValues(alpha: 0.55),
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
                                            Colors.white.withValues(alpha: 0.9),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: TextButton.icon(
                        onPressed: () => _openEditSheet(mosque),
                        icon: const Icon(Icons.edit_rounded,
                            color: Colors.white, size: 18),
                        label: Text(
                          l10n.edit,
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.18),
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
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: const Color(0xFF0F766E),
                      unselectedLabelColor: const Color(0xFF6B7280),
                      indicatorColor: const Color(0xFF0F766E),
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 4),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      tabs: [
                        Tab(text: l10n.about),
                        Tab(text: l10n.posts),
                        Tab(text: l10n.prayerTimes),
                        Tab(text: l10n.location),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(mosque, l10n),
                _buildPostsTab(l10n),
                _buildPrayerTimesTab(l10n),
                _buildLocationTab(mosque, l10n),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAboutTab(MosqueModel mosque, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoTile(
          Icons.person_rounded,
          l10n.fullName,
          mosque.imamName.isNotEmpty ? mosque.imamName : l10n.methodUnset,
        ),
        _infoTile(
          Icons.phone_rounded,
          l10n.contactPhone,
          mosque.imamPhone.isNotEmpty ? mosque.imamPhone : l10n.methodUnset,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.description,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mosque.description.isNotEmpty
                    ? mosque.description
                    : l10n.noDescriptionYet,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0F766E), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab(AppLocalizations l10n) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('mosqueId', isEqualTo: widget.mosqueId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 44, color: Colors.black38),
                  const SizedBox(height: 12),
                  Text(
                    '${l10n.error}: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF0F766E)),
          );
        }

        final docs = (snapshot.data?.docs ?? []).toList();
        // Sort posts descending by createdAt in memory to avoid missing composite index errors
        docs.sort((a, b) {
          final tA = a.data()['createdAt'];
          final tB = b.data()['createdAt'];
          final dateA = tA is Timestamp
              ? tA.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          final dateB = tB is Timestamp
              ? tB.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          return dateB.compareTo(dateA);
        });

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined,
                      size: 52, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    l10n.noPostsYetMosque,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final postData = docs[index].data();
            final text = postData['text'] as String? ?? '';
            final category = postData['category'] as String? ?? '';
            final mediaUrls = List<String>.from(postData['mediaUrls'] ?? []);
            final createdAt = postData['createdAt'] is Timestamp
                ? (postData['createdAt'] as Timestamp).toDate()
                : null;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Color(0xFF0F766E),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (text.isNotEmpty)
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  if (mediaUrls.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        mediaUrls.first,
                        height: 190,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                  if (createdAt != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 13, color: Colors.black38),
                        const SizedBox(width: 4),
                        Text(
                          '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black38),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPrayerTimesTab(AppLocalizations l10n) {
    final now = DateTime.now();
    final todayDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _mosqueRef.collection('prayerTimes').doc(todayDate).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '${l10n.error}: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF0F766E)),
          );
        }

        final data = snapshot.data?.data();
        final fajr =
            (data?['fajrOverride'] ?? data?['fajr'] ?? '--:--').toString();
        final dhuhr =
            (data?['dhuhrOverride'] ?? data?['dhuhr'] ?? '--:--').toString();
        final asr =
            (data?['asrOverride'] ?? data?['asr'] ?? '--:--').toString();
        final maghrib =
            (data?['maghribOverride'] ?? data?['maghrib'] ?? '--:--')
                .toString();
        final isha =
            (data?['ishaOverride'] ?? data?['isha'] ?? '--:--').toString();
        final jumua = data?['jumuaPrayerTime'] ?? data?['jumuaKhutbahTime'];

        final prayers = [
          (name: l10n.fajr, time: fajr, icon: Icons.wb_twilight_rounded),
          (name: l10n.dhuhr, time: dhuhr, icon: Icons.wb_sunny_rounded),
          (name: l10n.asr, time: asr, icon: Icons.sunny_snowing),
          (name: l10n.maghrib, time: maghrib, icon: Icons.nightlight_round),
          (name: l10n.isha, time: isha, icon: Icons.bedtime_rounded),
          if (jumua != null && jumua.toString().isNotEmpty)
            (
              name: l10n.jumuah,
              time: jumua.toString(),
              icon: Icons.mosque_rounded
            ),
        ];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      size: 18, color: Color(0xFF0F766E)),
                  const SizedBox(width: 8),
                  Text(
                    todayDate,
                    style: const TextStyle(
                      color: Color(0xFF0F766E),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    data != null ? l10n.prayerTimes : l10n.methodUnset,
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ...prayers.map((e) {
              final hasTime = e.time.isNotEmpty && e.time != '--:--';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(e.icon,
                          size: 18, color: const Color(0xFF0F766E)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      e.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      e.time,
                      style: TextStyle(
                        color: hasTime
                            ? const Color(0xFF0F766E)
                            : Colors.black38,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildLocationTab(MosqueModel mosque, AppLocalizations l10n) {
    final hasGeo = mosque.geopoint != null &&
        mosque.geopoint!.latitude != 0 &&
        mosque.geopoint!.longitude != 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (hasGeo)
          Container(
            height: 200,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.black.withValues(alpha: 0.08)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(
                    mosque.geopoint!.latitude,
                    mosque.geopoint!.longitude,
                  ),
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.manbar.manbarAlmasjid',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          mosque.geopoint!.latitude,
                          mosque.geopoint!.longitude,
                        ),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFF0F766E),
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            height: 180,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F3F1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(Icons.map_rounded,
                  size: 48, color: Color(0xFF0F766E)),
            ),
          ),
        _infoTile(
          Icons.location_city_rounded,
          l10n.city,
          mosque.city.isNotEmpty ? mosque.city : l10n.methodUnset,
        ),
        _infoTile(
          Icons.place_rounded,
          l10n.detailedAddress,
          mosque.address.isNotEmpty ? mosque.address : l10n.methodUnset,
        ),
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => true;
}
