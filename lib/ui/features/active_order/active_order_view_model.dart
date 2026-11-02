import 'dart:async';
import 'package:flutter/material.dart';
import 'package:minha_cantina_app/data/models/order.dart';
import 'package:minha_cantina_app/data/services/api_service.dart';

class ActiveOrderViewModel extends ChangeNotifier {
  final ApiService apiService;
  Timer? _countdownTimer;

  ActiveOrderViewModel({required this.apiService});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ActiveOrderModel? _activeOrder;
  ActiveOrderModel? get activeOrder => _activeOrder;

  int _remainingSeconds = 0;
  int get remainingSeconds => _remainingSeconds;

  bool get hasActiveOrder => _activeOrder != null && _remainingSeconds > 0;

  Future<void> loadActiveOrder() async {
    _isLoading = true;
    notifyListeners();

    try {
      _activeOrder = await apiService.fetchActiveOrder();
      if (_activeOrder != null) {
        final diff = _activeOrder!.pickupDeadline.difference(DateTime.now()).inSeconds;
        _remainingSeconds = diff > 0 ? diff : 0;
        _startTimer();
      } else {
        _remainingSeconds = 0;
        _stopTimer();
      }
    } catch (_) {
      _activeOrder = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startTimer() {
    _stopTimer();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _stopTimer();
        loadActiveOrder();
      }
    });
  }

  void _stopTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
