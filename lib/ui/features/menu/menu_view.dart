import 'package:flutter/material.dart';
import 'package:minha_cantina_app/ui/core/app_theme.dart';
import 'package:minha_cantina_app/ui/core/formatters.dart';
import 'package:minha_cantina_app/data/models/product.dart';
import 'package:minha_cantina_app/ui/features/menu/menu_view_model.dart';

class MenuView extends StatelessWidget {
  final MenuViewModel viewModel;
  final VoidCallback onOrderCreated;

  const MenuView({
    super.key,
    required this.viewModel,
    required this.onOrderCreated,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: viewModel.loadProducts,
            color: AppTheme.primary,
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(context),
                _buildCategoryFilter(),
                if (viewModel.isLoading && viewModel.products.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                  )
                else if (viewModel.errorMessage != null && viewModel.products.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                          const SizedBox(height: 12),
                          Text(viewModel.errorMessage!, style: const TextStyle(color: AppTheme.textSecondary)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: viewModel.loadProducts,
                            child: const Text('Tentar Novamente'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  _buildProductsGrid(context),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          bottomSheet: viewModel.cartCount > 0 ? _buildCartBar(context) : null,
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: false,
      expandedHeight: 100,
      backgroundColor: AppTheme.background,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Minha Cantina',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            Text(
              'Reserve a sua refeição e levante sem filas',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 52,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          scrollDirection: Axis.horizontal,
          itemCount: viewModel.categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final cat = viewModel.categories[index];
            final isSelected = viewModel.selectedCategory == cat;
            return ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) => viewModel.selectCategory(cat),
              selectedColor: AppTheme.primary,
              backgroundColor: AppTheme.surface,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.primary : AppTheme.surfaceLight,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductsGrid(BuildContext context) {
    final products = viewModel.filteredProducts;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = products[index];
            return _buildProductCard(context, product);
          },
          childCount: products.length,
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final inCart = viewModel.cartItems.any((i) => i.product.id == product.id);
    final quantityInCart = inCart
        ? viewModel.cartItems.firstWhere((i) => i.product.id == product.id).quantity
        : 0;
    final isOutOfStock = product.stockQuantity <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do Produto
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 90,
                height: 90,
                color: AppTheme.surfaceLight,
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.fastfood_rounded,
                          color: AppTheme.primaryLight,
                          size: 36,
                        ),
                      )
                    : const Icon(
                        Icons.fastfood_rounded,
                        color: AppTheme.primaryLight,
                        size: 36,
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Informações
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.category,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Badge de Stock
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOutOfStock
                              ? AppTheme.error.withValues(alpha: 0.15)
                              : AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isOutOfStock ? 'Esgotado' : '${product.stockQuantity} unids.',
                          style: TextStyle(
                            color: isOutOfStock ? AppTheme.error : AppTheme.primaryLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Preço e Botão Adicionar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Formatters.formatKz(product.price),
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (isOutOfStock)
                        const SizedBox()
                      else if (quantityInCart > 0)
                        Row(
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.remove_circle_outline, color: AppTheme.textSecondary),
                              onPressed: () => viewModel.removeFromCart(product.id),
                            ),
                            Text(
                              '$quantityInCart',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.add_circle, color: AppTheme.primary),
                              onPressed: () => viewModel.addToCart(product),
                            ),
                          ],
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => viewModel.addToCart(product),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Pedir'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${viewModel.cartCount} item(s) selecionado(s)',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                Text(
                  Formatters.formatKz(viewModel.cartTotal),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _showCheckoutModal(context),
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('Confirmar Reserva'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckoutModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                'Resumo da Reserva',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'O valor será debitado da sua carteira e será gerado o seu código OTP de recolha presencial.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const Divider(color: AppTheme.surfaceLight, height: 24),
              ...viewModel.cartItems.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.quantity}x ${item.product.name}',
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        ),
                        Text(
                          Formatters.formatKz(item.subtotal),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  )),
              const Divider(color: AppTheme.surfaceLight, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total a Pagar:',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    Formatters.formatKz(viewModel.cartTotal),
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final order = await viewModel.checkoutReservation();
                    if (order != null) {
                      onOrderCreated();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.primary,
                            content: Text(
                              'Reserva criada com sucesso! Código OTP: ${order.otpCode}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }
                    } else if (viewModel.errorMessage != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppTheme.error,
                          content: Text(viewModel.errorMessage!),
                        ),
                      );
                    }
                  },
                  child: const Text('Confirmar e Gerar OTP'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
