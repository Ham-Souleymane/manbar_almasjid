import 'package:cloud_firestore/cloud_firestore.dart';

class ImamGroupModel {
  const ImamGroupModel({
    required this.id,
    required this.name,
    this.nameEn = '',
    required this.category,
    required this.description,
    this.iconName = 'menu_book',
    this.colorKey = 'emerald',
    this.membersCount = 0,
    this.memberIds = const [],
    this.createdBy,
    required this.createdAt,
    this.isPrivate = false,
    this.rules = const [],
    this.lastActivity,
    this.lastMessageText,
    this.lastMessageSender,
  });

  final String id;
  final String name;
  final String nameEn;
  final String category;
  final String description;
  final String iconName;
  final String colorKey;
  final int membersCount;
  final List<String> memberIds;
  final String? createdBy;
  final DateTime createdAt;
  final bool isPrivate;
  final List<String> rules;
  final DateTime? lastActivity;
  final String? lastMessageText;
  final String? lastMessageSender;

  bool isMember(String imamId) => memberIds.contains(imamId);

  factory ImamGroupModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawMembers = data['memberIds'];
    final membersList = rawMembers is List
        ? rawMembers.map((e) => e.toString()).toList()
        : <String>[];

    final rawRules = data['rules'];
    final rulesList = rawRules is List
        ? rawRules.map((e) => e.toString()).toList()
        : <String>[];

    return ImamGroupModel(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      nameEn: data['nameEn']?.toString() ?? '',
      category: data['category']?.toString() ?? 'عام',
      description: data['description']?.toString() ?? '',
      iconName: data['iconName']?.toString() ?? 'menu_book',
      colorKey: data['colorKey']?.toString() ?? 'emerald',
      membersCount: (data['membersCount'] as num?)?.toInt() ?? membersList.length,
      memberIds: membersList,
      createdBy: data['createdBy']?.toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPrivate: data['isPrivate'] == true,
      rules: rulesList,
      lastActivity: (data['lastActivity'] as Timestamp?)?.toDate(),
      lastMessageText: data['lastMessageText'] as String?,
      lastMessageSender: data['lastMessageSender'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'nameEn': nameEn,
      'category': category,
      'description': description,
      'iconName': iconName,
      'colorKey': colorKey,
      'membersCount': membersCount,
      'memberIds': memberIds,
      if (createdBy != null) 'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPrivate': isPrivate,
      'rules': rules,
      if (lastActivity != null) 'lastActivity': Timestamp.fromDate(lastActivity!),
      if (lastMessageText != null) 'lastMessageText': lastMessageText,
      if (lastMessageSender != null) 'lastMessageSender': lastMessageSender,
    };
  }

  ImamGroupModel copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? category,
    String? description,
    String? iconName,
    String? colorKey,
    int? membersCount,
    List<String>? memberIds,
    String? createdBy,
    DateTime? createdAt,
    bool? isPrivate,
    List<String>? rules,
    DateTime? lastActivity,
    String? lastMessageText,
    String? lastMessageSender,
  }) {
    return ImamGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      category: category ?? this.category,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorKey: colorKey ?? this.colorKey,
      membersCount: membersCount ?? this.membersCount,
      memberIds: memberIds ?? this.memberIds,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isPrivate: isPrivate ?? this.isPrivate,
      rules: rules ?? this.rules,
      lastActivity: lastActivity ?? this.lastActivity,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
    );
  }
}
