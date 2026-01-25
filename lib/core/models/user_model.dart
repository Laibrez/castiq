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
  final String? category;
  
  // Model specific
  final List<String>? portfolio;
  final Map<String, dynamic>? stats;
  final List<String>? categories;
  final int? age;
  final String? availability;
  final double? rating;
  final int? reviewCount;
  final String? portfolioVideo;
  final List<String>? portfolioImages;
  final String? zCardUrl;
  final bool? willingToTravel;

  final String? proofOfAddressUrl;
  final String? phone;
  final List<Map<String, dynamic>>? socialMedia;

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
    this.category,
    this.portfolio,
    this.stats,
    this.categories,
    this.age,
    this.availability,
    this.rating,
    this.reviewCount,
    this.portfolioVideo,
    this.portfolioImages,
    this.zCardUrl,
    this.willingToTravel, // Added

    this.proofOfAddressUrl,
    this.phone,
    this.socialMedia,
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
      category: data['category'],
      portfolio: data['portfolio'] != null ? List<String>.from(data['portfolio']) : null,
      stats: data['stats'] ?? data['measurements'], // Support both keys
      categories: data['categories'] != null ? List<String>.from(data['categories'] as List) : null,
      age: data['age'],
      availability: data['availability'],
      rating: (data['rating'] as num?)?.toDouble(),
      reviewCount: data['reviewCount'],
      portfolioVideo: data['portfolioVideo'],
      portfolioImages: data['portfolioImages'] != null ? List<String>.from(data['portfolioImages']) : null,
      zCardUrl: data['zCardUrl'],
      willingToTravel: data['willingToTravel'] ?? data['willTravel'], // Support legacy key if any
      proofOfAddressUrl: data['proofOfAddressUrl'],
      phone: data['phone'],
      socialMedia: data['socialMedia'] != null 
          ? List<Map<String, dynamic>>.from(data['socialMedia']) 
          : null,
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
      'category': category,
      'portfolio': portfolio,
      'stats': stats,
      'categories': categories,
      'age': age,
      'availability': availability,
      'rating': rating,
      'reviewCount': reviewCount,
      'portfolioVideo': portfolioVideo,
      'portfolioImages': portfolioImages,
      'zCardUrl': zCardUrl,
      'willingToTravel': willingToTravel,
      'proofOfAddressUrl': proofOfAddressUrl,
      'phone': phone,
      'socialMedia': socialMedia,
      'companyName': companyName,
      'industry': industry,
      'website': website,
    };
  }
}
