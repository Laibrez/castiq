import 'package:cloud_firestore/cloud_firestore.dart';

class BrandApplication {
  final String id;
  final String userId;
  final String businessName;
  final String? legalEntityType;
  final String? registrationCountry;
  final String? registrationNumber;
  final String? streetAddress;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? taxId;
  final String? vatNumber;
  final String? website;
  final String? linkedin;
  final String? instagram;
  final String? representativeName;
  final String? representativeTitle;
  final String? representativePhone;
  final String? representativeEmail;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final bool? additionalInfoRequested;
  final String? additionalInfoMessage;

  BrandApplication({
    required this.id,
    required this.userId,
    required this.businessName,
    this.legalEntityType,
    this.registrationCountry,
    this.registrationNumber,
    this.streetAddress,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.taxId,
    this.vatNumber,
    this.website,
    this.linkedin,
    this.instagram,
    this.representativeName,
    this.representativeTitle,
    this.representativePhone,
    this.representativeEmail,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewNotes,
    this.additionalInfoRequested,
    this.additionalInfoMessage,
  });

  factory BrandApplication.fromFirestore(Map<String, dynamic> data, String id) {
    Timestamp? submittedTimestamp;
    if (data['submitted_at'] is Timestamp) {
      submittedTimestamp = data['submitted_at'] as Timestamp;
    } else if (data['submitted_at'] != null) {
      submittedTimestamp = data['submitted_at'];
    }

    Timestamp? reviewedTimestamp;
    if (data['reviewed_at'] is Timestamp) {
      reviewedTimestamp = data['reviewed_at'] as Timestamp;
    } else if (data['reviewed_at'] != null) {
      reviewedTimestamp = data['reviewed_at'];
    }
    
    return BrandApplication(
      id: id,
      userId: data['user_id'] ?? '',
      businessName: data['business_name'] ?? '',
      legalEntityType: data['legal_entity_type'],
      registrationCountry: data['registration_country'],
      registrationNumber: data['registration_number'],
      streetAddress: data['street_address'],
      city: data['city'],
      state: data['state'],
      postalCode: data['postal_code'],
      country: data['country'],
      taxId: data['tax_id'],
      vatNumber: data['vat_number'],
      website: data['website'],
      linkedin: data['linkedin'],
      instagram: data['instagram'],
      representativeName: data['representative_name'],
      representativeTitle: data['representative_title'],
      representativePhone: data['representative_phone'],
      representativeEmail: data['representative_email'],
      status: data['status'] ?? 'pending',
      submittedAt: submittedTimestamp?.toDate() ?? DateTime.now(),
      reviewedAt: reviewedTimestamp?.toDate(),
      reviewNotes: data['review_notes'],
      additionalInfoRequested: data['additional_info_requested'],
      additionalInfoMessage: data['additional_info_message'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'business_name': businessName,
      'legal_entity_type': legalEntityType,
      'registration_country': registrationCountry,
      'registration_number': registrationNumber,
      'street_address': streetAddress,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'tax_id': taxId,
      'vat_number': vatNumber,
      'website': website,
      'linkedin': linkedin,
      'instagram': instagram,
      'representative_name': representativeName,
      'representative_title': representativeTitle,
      'representative_phone': representativePhone,
      'representative_email': representativeEmail,
      'status': status,
      'submitted_at': Timestamp.fromDate(submittedAt),
      'reviewed_at': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'review_notes': reviewNotes,
      'additional_info_requested': additionalInfoRequested,
      'additional_info_message': additionalInfoMessage,
    };
  }
}
