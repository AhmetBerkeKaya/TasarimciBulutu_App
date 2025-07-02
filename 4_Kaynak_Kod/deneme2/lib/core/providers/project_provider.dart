// lib/core/providers/project_provider.dart
import 'package:flutter/material.dart';

import '../../data/models/project_model.dart';
import '../services/api_service.dart';

class ProjectProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Project> _projects = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ProjectProvider() {
    fetchProjects(); // Provider oluşturulduğunda projeleri otomatik çek
  }

  Future<void> fetchProjects() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _projects = await _apiService.getProjects();
    } catch (e) {
      _errorMessage = "Projeler yüklenirken bir hata oluştu.";
    }

    _isLoading = false;
    notifyListeners();
  }
}