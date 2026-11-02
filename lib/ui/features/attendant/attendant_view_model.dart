import 'package:flutter/material.dart';
import 'package:minha_cantina_app/data/models/order.dart';
import 'package:minha_cantina_app/data/services/api_service.dart';

class AttendantViewModel extends ChangeNotifier {
  final ApiService apiService;

  AttendantViewModel({required this.apiService});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  OrderLookupModel? _inspectedOrder;
  OrderLookupModel? get inspectedOrder => _inspectedOrder;

  String? _successMessage;
  String? get successMessage => _successMessage;

  Future<void> lookupOrderByOtp(String otpCode) async {
    final cleanOtp = otpCode.trim();
    if (cleanOtp.length != 6) {
      _errorMessage = 'O código OTP deve ter exactamente 6 dígitos numéricos.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    _inspectedOrder = null;
    notifyListeners();

    try {
      _inspectedOrder = await apiService.lookupOrder(cleanOtp);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> confirmPickup(String otpCode) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final success = await apiService.pickupOrder(otpCode.trim());
      if (success) {
        _successMessage = 'Refeição entregue com sucesso!';
        _inspectedOrder = null;
        return true;
      } else {
        _errorMessage = 'Falha ao confirmar levantamento.';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearInspection() {
    _inspectedOrder = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
