import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/pet.dart';
import '../models/adoption.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000';
  
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  Future<void> _storeToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _clearToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  bool get isLoggedIn => _authToken != null;

  // =================== AUTH ENDPOINTS ===================

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String city,
    required String state,
    required String zipCode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'address': address,
        'city': city,
        'state': state,
        'zipCode': zipCode,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _storeToken(data['access_token']);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Registration failed');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _storeToken(data['access_token']);
      return data;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Login failed');
    }
  }

  Future<void> logout() async {
    await _clearToken();
  }

  // =================== USER ENDPOINTS ===================

  Future<User> getProfile() async {
    print('ApiService - Getting user profile...');
    final response = await http.get(
      Uri.parse('$baseUrl/users/profile'),
      headers: _headers,
    );

    print('ApiService - Profile response status: ${response.statusCode}');
    print('ApiService - Profile response body: ${response.body}');

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      print('ApiService - Parsed user data: $userData');
      return User.fromJson(userData);
    } else {
      throw Exception('Failed to get profile');
    }
  }

  Future<User> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? zipCode,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (address != null) body['address'] = address;
    if (city != null) body['city'] = city;
    if (state != null) body['state'] = state;
    if (zipCode != null) body['zipCode'] = zipCode;

    final response = await http.put(
      Uri.parse('$baseUrl/users/profile'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update profile');
    }
  }

  Future<void> deleteAccount() async {
    print('ApiService - Deleting account...');
    
    final response = await http.delete(
      Uri.parse('$baseUrl/users/profile'),
      headers: _headers,
    );

    print('ApiService - Delete account response status: ${response.statusCode}');
    print('ApiService - Delete account response body: ${response.body}');
    print('ApiService - Delete account response headers: ${response.headers}');

    if (response.statusCode != 204 && response.statusCode != 200) {
      String errorMessage = 'Failed to delete account';
      
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['message'] ?? 'Failed to delete account';
        print('ApiService - Delete account error: $errorMessage');
      } catch (parseError) {
        print('ApiService - Delete account parsing error: $parseError');
      }
      
      throw Exception(errorMessage);
    }
    
    print('ApiService - Account deleted successfully, status: ${response.statusCode}');
  }

  // =================== PET ENDPOINTS ===================

  Future<List<Pet>> getAllPets() async {
    print('ApiService - Getting all pets...');
    final response = await http.get(
      Uri.parse('$baseUrl/pets'),
      headers: _headers,
    );

    print('Get all pets response status: ${response.statusCode}');
    print('Get all pets response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print('Number of pets received: ${data.length}');
      
      try {
        final pets = data.map((pet) => Pet.fromJson(pet)).toList();
        print('Successfully parsed ${pets.length} pets');
        for (var pet in pets) {
          print('Pet: ${pet.name} - Status: ${pet.status} - Owner: ${pet.ownerId} - Active: ${pet.isActive ?? 'N/A'}');
        }
        return pets;
      } catch (e) {
        print('Error parsing pets: $e');
        rethrow;
      }
    } else {
      print('Failed to get pets - Status: ${response.statusCode}, Body: ${response.body}');
      throw Exception('Failed to get pets');
    }
  }

  Future<Pet> getPetById(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/pets/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Pet.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get pet');
    }
  }

  Future<List<Pet>> getMyPets() async {
    final response = await http.get(
      Uri.parse('$baseUrl/pets/my-pets'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((pet) => Pet.fromJson(pet)).toList();
    } else {
      throw Exception('Failed to get my pets');
    }
  }

  Future<Pet> registerPet({
    required String name,
    required String species,
    String? breed,
    required String size,
    required double age,
    required String gender,
    required String description,
    List<String>? images,
    required String status,
    List<String>? vaccinations,
    required bool isNeutered,
    required String location,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pets'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'species': _mapSpeciesToEnglish(species),
        'breed': breed,
        'size': _mapSizeToEnglish(size),
        'age': age,
        'gender': _mapGenderToEnglish(gender),
        'description': description,
        'images': images ?? [],
        'status': _mapStatusToEnglish(status),
        'vaccinations': vaccinations ?? [],
        'isNeutered': isNeutered,
        'location': location,
      }),
    );

    if (response.statusCode == 201) {
      return Pet.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to register pet');
    }
  }

  String _mapSpeciesToEnglish(String species) {
    switch (species) {
      case 'Cachorro':
        return 'dog';
      case 'Gato':
        return 'cat';
      case 'Outro':
        return 'other';
      default:
        return species.toLowerCase();
    }
  }

  String _mapSizeToEnglish(String size) {
    switch (size) {
      case 'Pequeno':
        return 'small';
      case 'Médio':
        return 'medium';
      case 'Grande':
        return 'large';
      default:
        return size.toLowerCase();
    }
  }

  String _mapGenderToEnglish(String gender) {
    switch (gender) {
      case 'Macho':
        return 'male';
      case 'Fêmea':
        return 'female';
      default:
        return gender.toLowerCase();
    }
  }

  String _mapStatusToEnglish(String status) {
    switch (status) {
      case 'Disponível':
        return 'available';
      case 'Em adoção':
      case 'Pendente':
        return 'pending';
      case 'Adotado':
        return 'adopted';
      default:
        return status.toLowerCase();
    }
  }

  Future<Pet> updatePet(String id, Map<String, dynamic> updates) async {
    final Map<String, dynamic> mappedUpdates = Map.from(updates);
    
    if (mappedUpdates.containsKey('species')) {
      mappedUpdates['species'] = _mapSpeciesToEnglish(mappedUpdates['species']);
    }
    if (mappedUpdates.containsKey('size')) {
      mappedUpdates['size'] = _mapSizeToEnglish(mappedUpdates['size']);
    }
    if (mappedUpdates.containsKey('gender')) {
      mappedUpdates['gender'] = _mapGenderToEnglish(mappedUpdates['gender']);
    }
    if (mappedUpdates.containsKey('status')) {
      mappedUpdates['status'] = _mapStatusToEnglish(mappedUpdates['status']);
    }

    final response = await http.put(
      Uri.parse('$baseUrl/pets/$id'),
      headers: _headers,
      body: jsonEncode(mappedUpdates),
    );

    if (response.statusCode == 200) {
      return Pet.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update pet');
    }
  }

  Future<void> deletePet(String id) async {
    print('ApiService - Deleting pet with ID: $id');
    
    final response = await http.delete(
      Uri.parse('$baseUrl/pets/$id'),
      headers: _headers,
    );

    print('ApiService - Delete pet response status: ${response.statusCode}');
    print('ApiService - Delete pet response body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 204) {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to delete pet';
        print('ApiService - Delete pet error: $errorMessage');
        throw Exception(errorMessage);
      } catch (e) {
        print('ApiService - Delete pet parsing error: $e');
        throw Exception('Failed to delete pet');
      }
    }
    
    print('ApiService - Pet deleted successfully');
  }

  // =================== ADOPTION ENDPOINTS ===================

  Future<List<Adoption>> getAllAdoptions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/adoptions'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((adoption) => Adoption.fromJson(adoption)).toList();
    } else {
      throw Exception('Failed to get adoptions');
    }
  }

  Future<Adoption> createAdoption({
    required String petId,
    required String ownerId,
    String? message,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/adoptions'),
      headers: _headers,
      body: jsonEncode({
        'petId': petId,
        'ownerId': ownerId,
        'message': message ?? '',
      }),
    );

    if (response.statusCode == 201) {
      return Adoption.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to create adoption application');
    }
  }

  Future<List<Adoption>> getMyApplications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/adoptions/my-applications'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((adoption) => Adoption.fromJson(adoption)).toList();
    } else {
      throw Exception('Failed to get my applications');
    }
  }

  Future<List<Adoption>> getMyPetsApplications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/adoptions/my-pets-applications'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((adoption) => Adoption.fromJson(adoption)).toList();
    } else {
      throw Exception('Failed to get applications for my pets');
    }
  }

  Future<Adoption> updateAdoptionStatus({
    required String adoptionId,
    required String status,
    String? ownerNotes,
  }) async {
    print('ApiService - Updating adoption status...');
    print('ApiService - Adoption ID: $adoptionId');
    print('ApiService - New status: $status');
    print('ApiService - Owner notes: $ownerNotes');
    
    final response = await http.patch(
      Uri.parse('$baseUrl/adoptions/$adoptionId'),
      headers: _headers,
      body: jsonEncode({
        'status': status,
        'ownerNotes': ownerNotes,
      }),
    );

    print('ApiService - Update adoption response status: ${response.statusCode}');
    print('ApiService - Update adoption response body: ${response.body}');

    if (response.statusCode == 200) {
      return Adoption.fromJson(jsonDecode(response.body));
    } else {
      String errorMessage = 'Failed to update adoption status';
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['message'] ?? 'Failed to update adoption status';
        print('ApiService - Update adoption error: $errorMessage');
      } catch (parseError) {
        print('ApiService - Update adoption parsing error: $parseError');
      }
      throw Exception(errorMessage);
    }
  }

  Future<void> deleteAdoption(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/adoptions/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete adoption');
    }
  }
} 