import 'package:flutter/foundation.dart';
import '../models/pet.dart';
import '../services/api_service.dart';

class PetProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Pet> _allPets = [];
  List<Pet> _myPets = [];
  List<Pet> _adoptedPets = [];
  Pet? _selectedPet;
  bool _isLoading = false;
  String? _error;

  List<Pet> get allPets => _allPets;
  List<Pet> get myPets => _myPets;
  List<Pet> get adoptedPets => _adoptedPets;
  Pet? get selectedPet => _selectedPet;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Pet> get availablePets => _allPets.where((pet) => 
    pet.status == 'available' && pet.isActive
  ).toList();
  
  List<Pet> getAvailablePetsBySpecies(String species) {
    return availablePets.where((pet) => pet.species.toLowerCase() == species.toLowerCase()).toList();
  }

  List<Pet> getAdoptedPetsByUser(String userId) {
    print('PetProvider - getAdoptedPetsByUser called with userId: $userId');
    print('PetProvider - Total pets in _allPets: ${_allPets.length}');
    
    final adopted = _allPets.where((pet) => 
      pet.status == 'adopted' && pet.isActive
    ).toList();
    
    print('PetProvider - Found ${adopted.length} adopted pets');
    for (var pet in adopted) {
      print('PetProvider - Adopted pet: ${pet.name}, originalOwner: ${pet.originalOwnerId}, adoptedBy: ${pet.adoptedBy}, status: ${pet.status}');
    }
    
    return adopted;
  }

  Future<void> loadAllPets() async {
    _setLoading(true);
    _clearError();

    try {
      _allPets = await _apiService.getAllPets();
      print('PetProvider - loadAllPets: received ${_allPets.length} pets');
      for (var pet in _allPets) {
        print('PetProvider - All Pet: ${pet.name}, status: ${pet.status}, ownerId: ${pet.ownerId}, originalOwnerId: ${pet.originalOwnerId}, adoptedBy: ${pet.adoptedBy}');
      }
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('PetProvider - loadAllPets error: $e');
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
    }
  }

  Future<void> loadAdoptedPets(String userId) async {
    _adoptedPets = getAdoptedPetsByUser(userId);
    notifyListeners();
  }

  Future<void> loadMyPets() async {
    _setLoading(true);
    _clearError();

    try {
      _myPets = await _apiService.getMyPets();
      print('PetProvider - loadMyPets: received ${_myPets.length} pets');
      for (var pet in _myPets) {
        print('PetProvider - Pet: ${pet.name}, status: ${pet.status}, ownerId: ${pet.ownerId}, originalOwnerId: ${pet.originalOwnerId}, adoptedBy: ${pet.adoptedBy}');
      }
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('PetProvider - loadMyPets error: $e');
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
    }
  }

  Future<void> loadPetById(String id) async {
    _setLoading(true);
    _clearError();

    try {
      _selectedPet = await _apiService.getPetById(id);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
    }
  }

  Future<bool> registerPet({
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
    _setLoading(true);
    _clearError();

    try {
      final newPet = await _apiService.registerPet(
        name: name,
        species: species,
        breed: breed,
        size: size,
        age: age,
        gender: gender,
        description: description,
        images: images,
        status: status,
        vaccinations: vaccinations,
        isNeutered: isNeutered,
        location: location,
      );
      
      _myPets.add(newPet);
      
      if (_allPets.isNotEmpty) {
        _allPets.add(newPet);
      }
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updatePet(String id, Map<String, dynamic> updates) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedPet = await _apiService.updatePet(id, updates);
      
      final myPetIndex = _myPets.indexWhere((pet) => pet.id == id);
      if (myPetIndex != -1) {
        _myPets[myPetIndex] = updatedPet;
      }
      
      final allPetIndex = _allPets.indexWhere((pet) => pet.id == id);
      if (allPetIndex != -1) {
        _allPets[allPetIndex] = updatedPet;
      }
      
      if (_selectedPet?.id == id) {
        _selectedPet = updatedPet;
      }
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deletePet(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _apiService.deletePet(id);
      
      _myPets.removeWhere((pet) => pet.id == id);
      
      _allPets.removeWhere((pet) => pet.id == id);
      
      if (_selectedPet?.id == id) {
        _selectedPet = null;
      }
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  void setSelectedPet(Pet? pet) {
    _selectedPet = pet;
    notifyListeners();
  }

  void clearSelectedPet() {
    _selectedPet = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  List<Pet> searchPets(String query) {
    if (query.isEmpty) return availablePets;
    
    query = query.toLowerCase();
    return availablePets.where((pet) {
      return pet.name.toLowerCase().contains(query) ||
             pet.species.toLowerCase().contains(query) ||
             (pet.breed?.toLowerCase().contains(query) ?? false) ||
             pet.location.toLowerCase().contains(query);
    }).toList();
  }
} 