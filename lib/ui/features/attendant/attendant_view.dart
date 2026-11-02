import 'package:flutter/material.dart';
import 'package:minha_cantina_app/ui/core/app_theme.dart';
import 'package:minha_cantina_app/ui/core/formatters.dart';
import 'package:minha_cantina_app/ui/features/attendant/attendant_view_model.dart';

class AttendantView extends StatefulWidget {
  final AttendantViewModel viewModel;

  const AttendantView({super.key, required this.viewModel});

  @override
  State<AttendantView> createState() => _AttendantViewState();
}

class _AttendantViewState extends State<AttendantView> {
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final order = widget.viewModel.inspectedOrder;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Balcão de Entrega'),
            actions: [
              IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: () {
                  _otpController.clear();
                  widget.viewModel.clearInspection();
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAttendantHeader(),
                const SizedBox(height: 20),
                _buildOtpInputCard(context),
                const SizedBox(height: 24),
                if (widget.viewModel.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  )
                else if (widget.viewModel.errorMessage != null)
                  _buildErrorBanner(widget.viewModel.errorMessage!)
                else if (widget.viewModel.successMessage != null)
                  _buildSuccessBanner(widget.viewModel.successMessage!)
                else if (order != null)
                  _buildOrderDetailsCard(context, order),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendantHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.badge_outlined, color: AppTheme.primaryLight),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Operadora: Rosa António',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Posto de Atendimento e Entrega de Refeições',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpInputCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Validação de Código OTP',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Digite o código de 6 dígitos dito pelo cliente ou lido do QR Code.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              hintText: '000000',
              counterText: '',
              prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppTheme.accent),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: AppTheme.primaryLight),
                onPressed: () {
                  widget.viewModel.lookupOrderByOtp(_otpController.text);
                },
              ),
            ),
            onSubmitted: (val) => widget.viewModel.lookupOrderByOtp(val),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => widget.viewModel.lookupOrderByOtp(_otpController.text),
              icon: const Icon(Icons.search),
              label: const Text('Verificar Reserva'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard(BuildContext context, dynamic order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reserva #${order.orderId}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'RESERVADO',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppTheme.textSecondary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Cliente: ${order.customerName}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time, color: AppTheme.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Limite de Recolha: ${Formatters.formatTime(order.pickupDeadline)}',
                style: const TextStyle(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Divider(color: AppTheme.surfaceLight, height: 28),
          const Text(
            'Pratos / Itens a Entregar:',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...order.items.map<Widget>((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.quantity}x',
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.productName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final success = await widget.viewModel.confirmPickup(_otpController.text);
                if (success) {
                  _otpController.clear();
                }
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Confirmar Entrega da Refeição'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.primaryLight, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Refeição Entregue!',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
