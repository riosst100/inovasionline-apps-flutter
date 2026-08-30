import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/cart.dart';
import 'cart_providers.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(cartProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cart = cartState.cart;

    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(cartProvider.notifier).load(),
        child: cartState.loading && cart == null
            ? const Center(child: CircularProgressIndicator())
            : cart == null || cart.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Icon(Icons.shopping_cart_outlined, size: 56, color: AppColors.mutedForeground),
                      SizedBox(height: 12),
                      Center(child: Text('Keranjang Anda kosong.', style: TextStyle(color: AppColors.mutedForeground))),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + MediaQuery.paddingOf(context).bottom + 88),
                    itemCount: cart.stores.length,
                    itemBuilder: (context, index) => _StoreGroupCard(group: cart.stores[index]),
                  ),
      ),
      bottomNavigationBar: cart != null && !cart.isEmpty
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Total', style: TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                          Text(
                            formatCurrency(cart.grandTotal),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Checkout'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _StoreGroupCard extends ConsumerWidget {
  const _StoreGroupCard({required this.group});

  final CartStoreGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.push('/stores/${group.store.slug}'),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.surface,
                    backgroundImage: group.store.logoUrl != null ? CachedNetworkImageProvider(group.store.logoUrl!) : null,
                    child: group.store.logoUrl == null
                        ? const Icon(Icons.storefront_outlined, size: 16, color: AppColors.foreground)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      group.store.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: AppColors.mutedForeground),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          for (final item in group.items) _CartItemTile(item: item),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Subtotal: ', style: TextStyle(fontSize: 12.5, color: AppColors.mutedForeground)),
                Text(
                  formatCurrency(group.subtotal),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  const _CartItemTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 56,
              height: 56,
              color: AppColors.surface,
              child: item.productImageUrl != null
                  ? CachedNetworkImage(imageUrl: item.productImageUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.image_outlined, color: AppColors.mutedForeground),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5)),
                if (item.variantName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(item.variantName!, style: const TextStyle(fontSize: 11.5, color: AppColors.mutedForeground)),
                  ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(item.unitPrice),
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => ref.read(cartProvider.notifier).removeItem(item.id),
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.mutedForeground),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 8),
              _QuantityStepper(item: item),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends ConsumerWidget {
  const _QuantityStepper({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            onTap: item.quantity > 1
                ? () => ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity - 1)
                : null,
          ),
          SizedBox(
            width: 28,
            child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
          ),
          _StepperButton(
            icon: Icons.add,
            onTap: item.quantity < item.stock
                ? () => ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 14, color: onTap == null ? AppColors.border : AppColors.foreground),
      ),
    );
  }
}
