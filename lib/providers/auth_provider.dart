import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null && _apiService.isLoggedIn;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    await _apiService.init();
    if (_apiService.isLoggedIn) {
      await _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      print('AuthProvider - Loading user profile...');
      _currentUser = await _apiService.getProfile();
      print('AuthProvider - User profile loaded: ${_currentUser?.name}');
      notifyListeners();
    } catch (e) {
      print('AuthProvider - Error loading user profile: $e');
      await logout();
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.login(email: email, password: password);
      _currentUser = User.fromJson(response['user']);
      
      await _loadUserProfile();
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String city,
    required String state,
    required String zipCode,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        address: address,
        city: city,
        state: state,
        zipCode: zipCode,
      );
      _currentUser = User.fromJson(response['user']);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? zipCode,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _apiService.updateProfile(
        name: name,
        phone: phone,
        address: address,
        city: city,
        state: state,
        zipCode: zipCode,
      );
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<void> refreshProfile() async {
    try {
      _currentUser = await _apiService.getProfile();
      notifyListeners();
    } catch (e) {
      print('AuthProvider - Error refreshing profile: $e');
    }
  }

  Future<bool> deleteAccount() async {
    print('AuthProvider - Starting deleteAccount...');
    _setLoading(true);
    _clearError();

    try {
      print('AuthProvider - Calling API service deleteAccount...');
      await _apiService.deleteAccount();
      print('AuthProvider - API call succeeded, logging out...');
      await logout();
      print('AuthProvider - Logout completed');
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      print('AuthProvider - Error caught: $e');
      print('AuthProvider - Error type: ${e.runtimeType}');
      _setError(e.toString().replaceAll('Exception: ', ''));
      print('AuthProvider - Error set to: $_error');
      _setLoading(false);
      print('AuthProvider - Loading set to false');
      notifyListeners();
      print('AuthProvider - Notified listeners, returning false');
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