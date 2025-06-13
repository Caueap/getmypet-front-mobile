import 'pet.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String? avatar;
  final List<Pet> pets;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    this.avatar,
    required this.pets,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  String get avatarUrl {
    if (avatar != null && avatar!.isNotEmpty) {
      if (avatar!.startsWith('http')) {
        return avatar!;
      }
      return 'http://10.0.2.2:3000$avatar';
    }
    return '';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    print('User.fromJson - Raw JSON: $json');
    
    try {
      print('User.fromJson - Parsing individual fields:');
      print('  - id: ${json['id'] ?? json['_id']}');
      print('  - name: ${json['name']}');
      print('  - email: ${json['email']}');
      print('  - phone: ${json['phone']}');
      print('  - address: ${json['address']}');
      print('  - city: ${json['city']}');
      print('  - state: ${json['state']}');
      print('  - zipCode: ${json['zipCode']}');
      print('  - avatar: ${json['avatar']} (type: ${json['avatar'].runtimeType})');
      
      final user = User(
        id: json['id'] ?? json['_id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        address: json['address'] ?? '',
        city: json['city'] ?? '',
        state: json['state'] ?? '',
        zipCode: json['zipCode'] ?? '',
        avatar: json['avatar'],
        pets: _parsePets(json['pets']),
        role: json['role'] ?? 'user',
        isActive: json['isActive'] ?? true,
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      );
      return user;
    } catch (e) {
     
      rethrow;
    }
  }


  static List<Pet> _parsePets(dynamic petsData) {
    if (petsData == null) return [];
    
    try {
      if (petsData is List) {
        return petsData.map((pet) => Pet.fromJson(pet)).toList();
      }
    } catch (e) {
      print('User._parsePets - Error parsing pets: $e');
    }
    
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'role': role,
      'isActive': isActive,
    };
  }
} 