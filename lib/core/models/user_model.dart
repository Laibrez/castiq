import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role;
  final String name;
  final String? profileImageUrl;
  final DateTime createdAt;
  final bool isVerified;
  final String? bio;
  final String? location;
  
  // Model specific
  final List<String>? portfolio;
  final Map<String, dynamic>? stats;
  
  // Brand specific
  final String? companyName;
  final String? industry;
  final String? website;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
    this.profileImageUrl,
    required this.createdAt,
    this.isVerified = false,
    this.bio,
    this.location,
    this.portfolio,
    this.stats,
    this.companyName,
    this.industry,
    this.website,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'model',
      name: data['name'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: data['isVerified'] ?? false,
      bio: data['bio'],
      location: data['location'],
      portfolio: data['portfolio'] != null ? List<String>.from(data['portfolio']) : null,
      stats: data['stats'],
      companyName: data['companyName'],
      industry: data['industry'],
      website: data['website'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'isVerified': isVerified,
      'bio': bio,
      'location': location,
      'portfolio': portfolio,
      'stats': stats,
      'companyName': companyName,
      'industry': industry,
      'website': website,
    };
  }
}
