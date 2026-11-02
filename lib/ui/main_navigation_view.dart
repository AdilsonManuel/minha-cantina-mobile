import 'package:flutter/material.dart';
import 'package:minha_cantina_app/ui/core/app_theme.dart';
import 'package:minha_cantina_app/data/services/api_service.dart';
import 'package:minha_cantina_app/ui/features/menu/menu_view.dart';
import 'package:minha_cantina_app/ui/features/menu/menu_view_model.dart';
import 'package:minha_cantina_app/ui/features/active_order/active_order_view.dart';
import 'package:minha_cantina_app/ui/features/active_order/active_order_view_model.dart';
import 'package:minha_cantina_app/ui/features/wallet/wallet_view.dart';
import 'package:minha_cantina_app/ui/features/wallet/wallet_view_model.dart';
import 'package:minha_cantina_app/ui/features/attendant/attendant_view.dart';
import 'package:minha_cantina_app/ui/features/attendant/attendant_view_model.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _currentIndex = 0;
  final ApiService _apiService = ApiService();
  bool _isBackendOnline = false;

  late final MenuViewModel _menuViewModel;
  late final ActiveOrderViewModel _activeOrderViewModel;
  late final WalletViewModel _walletViewModel;
  late final AttendantViewModel _attendantViewModel;

  @override
  void initState() {
    super.initState();
    _menuViewModel = MenuViewModel(apiService: _apiService);
    _activeOrderViewModel = ActiveOrderViewModel(apiService: _apiService);
    _walletViewModel = WalletViewModel(apiService: _apiService);
    _attendantViewModel = AttendantViewModel(apiService: _apiService);

    _checkConnection();
    _menuViewModel.loadProducts();
    _activeOrderViewModel.loadActiveOrder();
    _walletViewModel.loadWalletData();
  }

  Future<void> _checkConnection() async {
    final online = await _apiService.checkHealth();
    if (mounted) {
      setState(() => _isBackendOnline = online);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      MenuView(
        viewModel: _menuViewModel,
        onOrderCreated: () {
          setState(() => _currentIndex = 1);
          _activeOrderViewModel.loadActiveOrder();
          _walletViewModel.loadWalletData();
        },
      ),
      ActiveOrderView(
        viewModel: _activeOrderViewModel,
        onGoToMenu: () => setState(() => _currentIndex = 0),
      ),
      WalletView(viewModel: _walletViewModel),
      AttendantView(viewModel: _attendantViewModel),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _isBackendOnline ? AppTheme.primaryLight : AppTheme.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _isBackendOnline ? 'Online (Render / API)' : 'Modo Demonstração',
              style: TextStyle(
                color: _isBackendOnline ? AppTheme.primaryLight : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet_rounded, size: 20),
            tooltip: 'Configurar URL do Backend',
            onPressed: _showServerConfigDialog,
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() => _currentIndex = idx);
          if (idx == 0) _menuViewModel.loadProducts();
          if (idx == 1) _activeOrderViewModel.loadActiveOrder();
          if (idx == 2) _walletViewModel.loadWalletData();
        },
        backgroundColor: AppTheme.surface,
        indicatorColor: AppTheme.primary.withValues(alpha: 0.25),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: AppTheme.primaryLight),
            label: 'Cantina',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag, color: AppTheme.primaryLight),
            label: 'Reserva',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet, color: AppTheme.primaryLight),
            label: 'Carteira',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale, color: AppTheme.primaryLight),
            label: 'Balcão',
          ),
        ],
      ),
    );
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: _apiService.baseUrl);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Conexão com o Backend', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Insira o endereço do servidor Spring Boot (Localhost ou Render):',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'https://sua-api.onrender.com',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Local (8080)'),
                    onPressed: () => controller.text = 'http://localhost:8080',
                  ),
                  ActionChip(
                    label: const Text('Emulador (10.0.2.2)'),
                    onPressed: () => controller.text = 'http://10.0.2.2:8080',
                  ),
                  ActionChip(
                    label: const Text('Render (Cloud)'),
                    onPressed: () => controller.text = 'https://minha-cantina-api.onrender.com',
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUrl = controller.text.trim();
                _apiService.updateBaseUrl(newUrl);
                Navigator.pop(dialogCtx);
                await _checkConnection();
                _menuViewModel.loadProducts();
                _walletViewModel.loadWalletData();
                _activeOrderViewModel.loadActiveOrder();
              },
              child: const Text('Salvar e Conectar'),
            ),
          ],
        );
      },
    );
  }
}
