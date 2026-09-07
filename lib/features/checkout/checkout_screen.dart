import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/cart.dart';
import '../../models/payment_method.dart';
import '../../models/shipping_method.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/address_picker.dart';
import 'checkout_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.group});

  final CartStoreGroup group;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _addressDetailController = TextEditingController();
  final _notesController = TextEditingController();

  AddressSelection _address = const AddressSelection();
  PaymentMethod? _paymentMethod;
  ShippingMethod? _shippingMethod;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _recipientNameController.text = user.name;
      _recipientPhoneController.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _addressDetailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onAddressChanged(AddressSelection selection) {
    final districtChanged = selection.district?.code != _address.district?.code;
    final villageChanged = selection.village?.code != _address.village?.code;

    setState(() {
      _address = selection;
      if (districtChanged || villageChanged) {
        _shippingMethod = null;
      }
    });
  }

  double get _total => widget.group.subtotal + (_shippingMethod?.displayFee ?? 0);

  bool get _canSubmit =>
      _paymentMethod != null &&
      _shippingMethod != null &&
      _address.isComplete &&
      _recipientNameController.text.trim().isNotEmpty &&
      _recipientPhoneController.text.trim().isNotEmpty &&
      _addressDetailController.text.trim().isNotEmpty;

  Future<void> _pickPaymentMethod() async {
    final methods = await ref.read(checkoutStorePaymentMethodsProvider(widget.group.store.slug).future);
    if (!mounted) return;
    final selected = await showModalBottomSheet<PaymentMethod>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PaymentMethodPickerSheet(methods: methods),
    );
    if (selected != null) setState(() => _paymentMethod = selected);
  }

  Future<void> _pickShippingMethod() async {
    final district = _address.district;
    if (district == null) return;

    final methods = await ref.read(checkoutStoreShippingMethodsProvider((
      storeSlug: widget.group.store.slug,
      districtCode: district.code,
      villageCode: _address.village?.code,
    )).future);
    if (!mounted) return;
    final selected = await showModalBottomSheet<ShippingMethod>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ShippingMethodPickerSheet(methods: methods),
    );
    if (selected != null) setState(() => _shippingMethod = selected);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final success = await ref.read(checkoutProvider.notifier).submit(
          storeId: widget.group.store.id,
          cartItemIds: widget.group.items.map((item) => item.id).toList(),
          paymentMethodId: _paymentMethod!.id,
          shippingMethodId: _shippingMethod!.id,
          recipientName: _recipientNameController.text.trim(),
          recipientPhone: _recipientPhoneController.text.trim(),
          provinceCode: _address.province!.code,
          cityCode: _address.city!.code,
          districtCode: _address.district!.code,
          villageCode: _address.village!.code,
          addressDetail: _addressDetailController.text.trim(),
          customerNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      final order = ref.read(checkoutProvider).order;
      if (order != null) {
        context.go('/orders/${order.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan berhasil dibuat.'), behavior: SnackBarBehavior.floating),
        );
      }
    } else {
      final error = ref.read(checkoutProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Gagal membuat pesanan.'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SectionCard(
            title: widget.group.store.name,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in widget.group.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.productName}${item.variantName != null ? ' (${item.variantName})' : ''} x${item.quantity}',
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(formatCurrency(item.lineTotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Alamat Pengiriman',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _recipientNameController,
                  decoration: const InputDecoration(labelText: 'Nama Penerima'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _recipientPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                AddressPicker(onChanged: _onAddressChanged),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressDetailController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Detail Alamat (Jalan, RT/RW, dll)'),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Metode Pembayaran',
            child: _PickerRow(
              label: _paymentMethod?.name ?? 'Pilih metode pembayaran',
              onTap: _pickPaymentMethod,
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Metode Pengiriman',
            child: _address.district == null
                ? const Text('Pilih alamat terlebih dahulu', style: TextStyle(color: AppColors.mutedForeground))
                : _PickerRow(
                    label: _shippingMethod != null
                        ? '${_shippingMethod!.name} · ${formatCurrency(_shippingMethod!.displayFee)}'
                        : 'Pilih metode pengiriman',
                    onTap: _pickShippingMethod,
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Catatan (opsional)',
            child: TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Tulis catatan untuk penjual'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
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
                      formatCurrency(_total),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _canSubmit && !checkoutState.submitting ? _submit : null,
                child: checkoutState.submitting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Buat Pesanan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
            const Icon(Icons.chevron_right, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodPickerSheet extends StatelessWidget {
  const _PaymentMethodPickerSheet({required this.methods});

  final List<PaymentMethod> methods;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (methods.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('Belum ada metode pembayaran.')),
            for (final method in methods)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(method.name),
                subtitle: method.type == 'bank_transfer' && method.bankName != null
                    ? Text(method.bankName!)
                    : (method.description != null ? Text(method.description!) : null),
                onTap: () => Navigator.of(context).pop(method),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShippingMethodPickerSheet extends StatelessWidget {
  const _ShippingMethodPickerSheet({required this.methods});

  final List<ShippingMethod> methods;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Metode Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (methods.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Tidak ada metode pengiriman yang tersedia untuk alamat ini.'),
              ),
            for (final method in methods)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    Expanded(child: Text(method.name)),
                    if (method.isTableRate)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Lokal', style: TextStyle(fontSize: 10, color: AppColors.accent)),
                      ),
                  ],
                ),
                subtitle: method.estimatedDeliveryTime != null ? Text(method.estimatedDeliveryTime!) : null,
                trailing: Text(formatCurrency(method.displayFee), style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.of(context).pop(method),
              ),
          ],
        ),
      ),
    );
  }
}
