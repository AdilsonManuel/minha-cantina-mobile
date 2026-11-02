import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minha_cantina_app/ui/core/app_theme.dart';
import 'package:minha_cantina_app/ui/core/formatters.dart';
import 'package:minha_cantina_app/data/models/wallet.dart';
import 'package:minha_cantina_app/ui/features/wallet/wallet_view_model.dart';

class WalletView extends StatelessWidget {
  final WalletViewModel viewModel;

  const WalletView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final balance = viewModel.wallet?.balance ?? 0.0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Carteira Digital'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: viewModel.loadWalletData,
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: viewModel.loadWalletData,
            color: AppTheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceCard(context, balance),
                  const SizedBox(height: 24),
                  _buildQuickActionButtons(context),
                  const SizedBox(height: 28),
                  const Text(
                    'Extrato de Movimentos (Livro-Razão)',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Rastreabilidade total: cada débito, recarga ou estorno é auditado.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  _buildTransactionsList(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard(BuildContext context, double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF047857), Color(0xFF065F46), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo Disponível',
                style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  'AOA / Kz',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            Formatters.formatKz(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Icon(Icons.shield_outlined, color: Color(0xFFA7F3D0), size: 16),
              SizedBox(width: 6),
              Text(
                'Protegido com Optimistic Locking & Ledger Audit',
                style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showTopupModal(context),
            icon: const Icon(Icons.add_card_rounded),
            label: const Text('Carregar Saldo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(BuildContext context) {
    if (viewModel.transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Sem transações registadas.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: viewModel.transactions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final tx = viewModel.transactions[index];
        return _buildTransactionTile(tx);
      },
    );
  }

  Widget _buildTransactionTile(WalletTransactionModel tx) {
    final isDebit = tx.type == 'DEBIT_ORDER';
    final isRefund = tx.type == 'CREDIT_REFUND';

    Color iconColor;
    IconData iconData;
    String sign;

    if (isDebit) {
      iconColor = AppTheme.error;
      iconData = Icons.arrow_downward_rounded;
      sign = '-';
    } else if (isRefund) {
      iconColor = AppTheme.accent;
      iconData = Icons.replay_rounded;
      sign = '+';
    } else {
      iconColor = AppTheme.primaryLight;
      iconData = Icons.arrow_upward_rounded;
      sign = '+';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${Formatters.formatDateTime(tx.createdAt)} • Saldo: ${Formatters.formatKz(tx.balanceBefore)} → ${Formatters.formatKz(tx.balanceAfter)}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '$sign${Formatters.formatKz(tx.amount)}',
            style: TextStyle(
              color: isDebit ? AppTheme.textPrimary : iconColor,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  void _showTopupModal(BuildContext context) {
    double selectedAmount = 5000.0;
    String selectedMethod = 'MULTICAIXA_EXPRESS';
    final amountController = TextEditingController(text: '5000');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Carregar Carteira',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Escolha o montante e o método de pagamento local em Angola.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Opções rápidas de montante
                  Wrap(
                    spacing: 8,
                    children: [1000.0, 2500.0, 5000.0, 10000.0].map((val) {
                      final isSel = selectedAmount == val;
                      return ChoiceChip(
                        label: Text(Formatters.formatKz(val)),
                        selected: isSel,
                        onSelected: (_) {
                          setModalState(() {
                            selectedAmount = val;
                            amountController.text = val.toInt().toString();
                          });
                        },
                        selectedColor: AppTheme.primary,
                        backgroundColor: AppTheme.surfaceLight,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : AppTheme.textSecondary,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Seletor de Método de Pagamento
                  const Text('Método de Pagamento:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedMethod,
                    dropdownColor: AppTheme.surface,
                    decoration: const InputDecoration(),
                    items: const [
                      DropdownMenuItem(
                        value: 'MULTICAIXA_EXPRESS',
                        child: Text('Multicaixa Express (Transferência)', style: TextStyle(color: AppTheme.textPrimary)),
                      ),
                      DropdownMenuItem(
                        value: 'BANK_TRANSFER_IBAN',
                        child: Text('Transferência Bancária / BAI Directo', style: TextStyle(color: AppTheme.textPrimary)),
                      ),
                      DropdownMenuItem(
                        value: 'BANK_DEPOSIT',
                        child: Text('Depósito em Conta / Balcão', style: TextStyle(color: AppTheme.textPrimary)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedMethod = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Exibição do IBAN da Cantina
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.surfaceLight),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('IBAN da Cantina (BAI):', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                            SizedBox(height: 2),
                            Text(
                              'AO06.0040.0000.1234.5678.9012.3',
                              style: TextStyle(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: AppTheme.primaryLight, size: 18),
                          onPressed: () {
                            Clipboard.setData(const ClipboardData(text: 'AO06004000001234567890123'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('IBAN copiado!'), duration: Duration(seconds: 1)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botão de Submissão
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final topup = await viewModel.submitTopupRequest(
                          amount: selectedAmount,
                          paymentMethod: selectedMethod,
                          proofUrl: 'https://storage.minhacantina.ao/proofs/comprovativo_simulado.pdf',
                        );
                        if (topup != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.primary,
                              content: Text(
                                'Solicitação de ${Formatters.formatKz(topup.amount)} enviada para aprovação do administrador!',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Enviar Comprovativo e Solicitar'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
