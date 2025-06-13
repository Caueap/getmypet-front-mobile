import 'user.dart';
import 'pet.dart';

class Adoption {
  final String id;
  final String petId;
  final String applicantId;
  final String ownerId;
  final String status;
  final String? message;
  final String? ownerNotes;
  final User? applicant;
  final User? owner;
  final Pet? pet;
  final DateTime createdAt;
  final DateTime updatedAt;

  Adoption({
    required this.id,
    required this.petId,
    required this.applicantId,
    required this.ownerId,
    required this.status,
    this.message,
    this.ownerNotes,
    this.applicant,
    this.owner,
    this.pet,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Adoption.fromJson(Map<String, dynamic> json) {
    return Adoption(
      id: json['id'] ?? json['_id'] ?? '',
      petId: _extractId(json['petId']),
      applicantId: _extractId(json['applicantId']),
      ownerId: _extractId(json['ownerId']),
      status: json['status'] ?? 'pending',
      message: json['message'],
      ownerNotes: json['ownerNotes'],
      applicant: json['applicant'] != null 
          ? User.fromJson(json['applicant'])
          : (json['applicantId'] is Map<String, dynamic> 
              ? User.fromJson(json['applicantId']) 
              : null),
      owner: json['owner'] != null 
          ? User.fromJson(json['owner'])
          : (json['ownerId'] is Map<String, dynamic> 
              ? User.fromJson(json['ownerId']) 
              : null),
      pet: json['pet'] != null 
          ? Pet.fromJson(json['pet'])
          : (json['petId'] is Map<String, dynamic> 
              ? Pet.fromJson(json['petId']) 
              : null),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  static String _extractId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      return value['_id'] ?? value['id'] ?? '';
    }
    return '';
  }

  Map<String, dynamic> toJson() {
    return {
      'petId': petId,
      'message': message,
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isCompleted => status == 'completed';

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }
} 