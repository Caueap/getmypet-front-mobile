import 'user.dart';

class Pet {
  final String id;
  final String name;
  final String species;
  final String? breed;
  final String size;
  final double age;
  final String gender;
  final String description;
  final List<String> images;
  final String status;
  final List<String> vaccinations;
  final bool isNeutered;
  final String location;
  final String ownerId;
  final User? owner;
  final String? originalOwnerId;
  final User? originalOwner;
  final String? adoptedBy;
  final User? adopter;
  final DateTime? adoptedAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Pet({
    required this.id,
    required this.name,
    required this.species,
    this.breed,
    required this.size,
    required this.age,
    required this.gender,
    required this.description,
    required this.images,
    required this.status,
    required this.vaccinations,
    required this.isNeutered,
    required this.location,
    required this.ownerId,
    this.owner,
    this.originalOwnerId,
    this.originalOwner,
    this.adoptedBy,
    this.adopter,
    this.adoptedAt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  List<String> get fullImageUrls {
    return images.map((imagePath) {
      if (imagePath.startsWith('http')) {
        return imagePath;
      }
      return 'http://10.0.2.2:3000$imagePath';
    }).toList();
  }

  String get genderInPortuguese {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Macho';
      case 'female':
        return 'Fêmea';
      default:
        return gender;
    }
  }

  String get sizeInPortuguese {
    switch (size.toLowerCase()) {
      case 'small':
        return 'Pequeno';
      case 'medium':
        return 'Médio';
      case 'large':
        return 'Grande';
      default:
        return size;
    }
  }

  String get statusInPortuguese {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Disponível';
      case 'pending':
        return 'Pendente';
      case 'adopted':
        return 'Adotado';
      default:
        return status;
    }
  }

  String get speciesInPortuguese {
    switch (species.toLowerCase()) {
      case 'dog':
        return 'Cachorro';
      case 'cat':
        return 'Gato';
      case 'other':
        return 'Outro';
      default:
        return species;
    }
  }

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      species: json['species'] ?? '',
      breed: json['breed'],
      size: json['size'] ?? '',
      age: (json['age'] ?? 0).toDouble(),
      gender: json['gender'] ?? '',
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      status: json['status'] ?? 'available',
      vaccinations: List<String>.from(json['vaccinations'] ?? []),
      isNeutered: json['isNeutered'] ?? false,
      location: json['location'] ?? '',
      ownerId: json['ownerId'] is String 
          ? json['ownerId'] 
          : (json['ownerId']?['_id'] ?? json['ownerId']?['id'] ?? ''),
      owner: json['ownerId'] is Map<String, dynamic> 
          ? User.fromJson(json['ownerId']) 
          : null,
      originalOwnerId: json['originalOwnerId'] is String 
          ? json['originalOwnerId'] 
          : (json['originalOwnerId']?['_id'] ?? json['originalOwnerId']?['id']),
      originalOwner: json['originalOwnerId'] is Map<String, dynamic> 
          ? User.fromJson(json['originalOwnerId']) 
          : null,
      adoptedBy: json['adoptedBy'] is String 
          ? json['adoptedBy'] 
          : (json['adoptedBy']?['_id'] ?? json['adoptedBy']?['id']),
      adopter: json['adoptedBy'] is Map<String, dynamic> 
          ? User.fromJson(json['adoptedBy']) 
          : null,
      adoptedAt: json['adoptedAt'] != null ? DateTime.parse(json['adoptedAt']) : null,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'species': species,
      'breed': breed,
      'size': size,
      'age': age,
      'gender': gender,
      'description': description,
      'images': images,
      'status': status,
      'vaccinations': vaccinations,
      'isNeutered': isNeutered,
      'location': location,
    };
  }
} 