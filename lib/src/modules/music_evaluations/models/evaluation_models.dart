import 'package:cloud_firestore/cloud_firestore.dart';

class EvaluationCategoryModel {
  const EvaluationCategoryModel({
    required this.id,
    required this.name,
    required this.description,
    this.documentPath,
  });

  final String id;
  final String name;
  final String description;
  final String? documentPath;

  factory EvaluationCategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EvaluationCategoryModel(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      documentPath: data['documentPath']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    if (documentPath != null) 'documentPath': documentPath,
  };
}

class EvaluationFormModel {
  const EvaluationFormModel({
    required this.id,
    required this.title,
    required this.musicId,
    required this.musicTitle,
    required this.categoryId,
    required this.createdAt,
    this.allowedUserIds = const [],
    this.isOpen = true,
  });

  final String id;
  final String title;
  final String musicId;
  final String musicTitle;
  final String categoryId;
  final DateTime createdAt;
  final List<String> allowedUserIds;
  final bool isOpen;

  factory EvaluationFormModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EvaluationFormModel(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      musicId: data['musicId']?.toString() ?? '',
      musicTitle: data['musicTitle']?.toString() ?? '',
      categoryId: data['categoryId']?.toString() ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      allowedUserIds: (data['allowedUserIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isOpen: data['isOpen'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'musicId': musicId,
    'musicTitle': musicTitle,
    'categoryId': categoryId,
    'isOpen': isOpen,
    if (allowedUserIds.isNotEmpty) 'allowedUserIds': allowedUserIds,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

class EvaluationResponseModel {
  const EvaluationResponseModel({
    required this.id,
    required this.formId,
    required this.userId,
    required this.userName,
    required this.ratings,
    required this.createdAt,
    this.comment,
  });

  final String id;
  final String formId;
  final String userId;
  final String userName;
  final Map<String, int> ratings; // criteriaId → 1..5
  final DateTime createdAt;
  final String? comment;

  double get averageRating {
    if (ratings.isEmpty) return 0;
    return ratings.values.reduce((a, b) => a + b) / ratings.length;
  }

  factory EvaluationResponseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final ratingsMap = <String, int>{};
    final raw = data['ratings'] as Map<String, dynamic>? ?? {};
    raw.forEach((k, v) => ratingsMap[k] = (v as int?) ?? 0);

    return EvaluationResponseModel(
      id: doc.id,
      formId: data['formId']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? '',
      ratings: ratingsMap,
      comment: data['comment']?.toString(),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'formId': formId,
    'userId': userId,
    'userName': userName,
    'ratings': ratings,
    if (comment != null) 'comment': comment,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
