import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/banner.dart';
import '../../models/category.dart';
import '../../models/flash_sale.dart';
import '../../models/product.dart';
import '../../providers/core_providers.dart';

final bannersProvider = FutureProvider.autoDispose<List<AppBanner>>((ref) {
  return ref.watch(bannerServiceProvider).banners();
});

// Phase 1: homepage only surfaces Food and Beverages' sub-categories.
// Other root categories will be added back in a later phase.
final rootCategoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  final all = await ref.watch(catalogServiceProvider).categories();
  final foodCategory = all.firstWhere(
    (c) => c.parentId == null && c.slug == 'foods-beverages',
    orElse: () => throw StateError('Foods & Beverages category not found'),
  );

  return all
      .where((c) => c.parentId == foodCategory.id)
      .map((c) => c.icon != null && c.icon!.isNotEmpty ? c : c.copyWith(icon: foodCategory.icon))
      .toList();
});

final bestSellersProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  return ref.watch(catalogServiceProvider).bestSellers();
});

final flashSaleProvider = FutureProvider.autoDispose<FlashSaleSchedule>((ref) {
  return ref.watch(catalogServiceProvider).flashSale();
});
