import 'package:flutter/material.dart';
import 'package:minha_cantina_app/data/models/wallet.dart';
import 'package:minha_cantina_app/data/models/topup.dart';
import 'package:minha_cantina_app/data/services/api_service.dart';

class WalletViewModel extends ChangeNotifier {
  final ApiService apiService;

  WalletViewModel({required this.apiService});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  WalletModel? _wallet;
  WalletModel? get wallet => _wallet;

  List<WalletTransactionModel> _transactions = [];
  List<WalletTransactionModel> get transactions => _transactions;

  Future<void> loadWalletData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _wallet = await apiService.fetchWallet();
      _transactions = await apiService.fetchTransactions();
    } catch (e) {
      _errorMessage = 'Erro ao carregar carteira: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TopupModel?> submitTopupRequest({
    required double amount,
    required String paymentMethod,
    required String proofUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final topup = await apiService.requestTopup(
        amount: amount,
        paymentMethod: paymentMethod,
        proofUrl: proofUrl,
      );
      await loadWalletData();
      return topup;
    } catch (e) {
      _errorMessage = 'Falha ao solicitar carregamento: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
