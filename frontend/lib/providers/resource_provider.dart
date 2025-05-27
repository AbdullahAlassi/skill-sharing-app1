import 'package:flutter/foundation.dart';
import '../services/resource_service.dart';
import '../models/resource_model.dart';
import '../utils/api_response.dart';

class ResourceProvider with ChangeNotifier {
  final ResourceService _resourceService;
  List<Resource> _resources = [];
  bool _isLoading = false;
  String? _error;

  ResourceProvider(this._resourceService);

  List<Resource> get resources => _resources;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadResources() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _resourceService.getResources();
      if (response.success && response.data != null) {
        _resources = response.data!;
        _error = null;
      } else {
        _error = response.error ?? 'Failed to load resources';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createResource(
    String title,
    String description,
    String type,
    String url,
    String skillId,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _resourceService.createResource(
        title,
        description,
        type,
        url,
        skillId,
      );
      if (response.success && response.data != null) {
        _resources.add(response.data!);
        _error = null;
      } else {
        _error = response.error ?? 'Failed to create resource';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateResource(
    String id,
    String title,
    String description,
    String type,
    String url,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _resourceService.updateResource(
        id,
        title,
        description,
        type,
        url,
      );
      if (response.success && response.data != null) {
        final index = _resources.indexWhere((r) => r.id == id);
        if (index != -1) {
          _resources[index] = response.data!;
        }
        _error = null;
      } else {
        _error = response.error ?? 'Failed to update resource';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
