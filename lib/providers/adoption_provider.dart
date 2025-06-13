import 'package:flutter/foundation.dart';
import '../models/adoption.dart';
import '../services/api_service.dart';

class AdoptionProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Adoption> _myApplications = [];
  List<Adoption> _receivedApplications = [];
  bool _isLoading = false;
  String? _error;

  List<Adoption> get myApplications => _myApplications;
  List<Adoption> get receivedApplications => _receivedApplications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMyApplications() async {
    _setLoading(true);
    _clearError();

    try {
      _myApplications = await _apiService.getMyApplications();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
    }
  }

  Future<void> loadReceivedApplications() async {
    _setLoading(true);
    _clearError();

    try {
      _receivedApplications = await _apiService.getMyPetsApplications();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
    }
  }

  Future<void> loadAllApplications() async {
    _setLoading(true);
    _clearError();

    try {
      final myApps = _apiService.getMyApplications();
      final receivedApps = _apiService.getMyPetsApplications();
      
      final results = await Future.wait([myApps, receivedApps]);
      
      _myApplications = results[0];
      _receivedApplications = results[1];
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
    }
  }

  Future<bool> createApplication(String petId, String ownerId, {String? message}) async {
    _setLoading(true);
    _clearError();

    try {
      final newApplication = await _apiService.createAdoption(
        petId: petId,
        ownerId: ownerId,
        message: message,
      );
      
      _myApplications.add(newApplication);
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateApplicationStatus(String applicationId, String status, {String? notes}) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedApplication = await _apiService.updateAdoptionStatus(
        adoptionId: applicationId,
        status: status,
        ownerNotes: notes,
      );
      
      final index = _receivedApplications.indexWhere((app) => app.id == applicationId);
      if (index != -1) {
        _receivedApplications[index] = updatedApplication;
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
} 