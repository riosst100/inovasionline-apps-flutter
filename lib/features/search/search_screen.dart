import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/product.dart';
import '../../models/store.dart';
import '../../providers/core_providers.dart';
import '../../widgets/product_grid.dart';
import '../../widgets/skeleton.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Product> _products = [];
  List<Store> _stores = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _products = [];
        _stores = [];
        _searched = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query.trim()));
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final result = await ref.read(searchServiceProvider).search(query);
      if (!mounted) return;
      setState(() {
        _products = result.products;
        _stores = result.stores;
        _searched = true;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Cari produk atau toko...',
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
        ),
      ),
      body: _loading
          ? const ProductGridSkeleton()
          : !_searched
              ? const Center(child: Text('Ketik untuk mencari produk atau toko.'))
              : (_products.isEmpty && _stores.isEmpty)
                  ? const Center(child: Text('Tidak ada hasil ditemukan.'))
                  : ListView(
                      children: [
                        if (_stores.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Toko', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          ..._stores.map(
                            (store) => ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFF3F4F6),
                                backgroundImage: store.logoUrl != null ? NetworkImage(store.logoUrl!) : null,
                                child: store.logoUrl == null ? const Icon(Icons.storefront_outlined) : null,
                              ),
                              title: Text(store.name),
                              subtitle: Text(store.city ?? ''),
                            ),
                          ),
                          const Divider(),
                        ],
                        if (_products.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          ProductGrid(
                            products: _products,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            onProductTap: (product) => context.push('/products/${product.slug}'),
                          ),
                        ],
                      ],
                    ),
    );
  }
}
