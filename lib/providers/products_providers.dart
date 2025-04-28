import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/products_model.dart';

final productListProvider = StateNotifierProvider<ProductListNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductListNotifier();
});

class ProductListNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  ProductListNotifier() : super(const AsyncValue.loading()) {
    fetchProducts();
  }

  List<Product> _allProducts = [];
  int _page = 1;
  bool _isFetching = false;

  Future<void> fetchProducts({bool loadMore = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      if (!loadMore) {
        state = const AsyncValue.loading();
      }
      final response = await http.get(Uri.parse('https://fakestoreapi.com/products'));
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        _allProducts = data.map((e) => Product.fromJson(e)).toList();
        state = AsyncValue.data(_allProducts.take(10 * _page).toList());
      } else {
        state = AsyncValue.error('Failed to load products', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isFetching = false;
    }
  }

  void loadMore() {
    _page++;
    state = AsyncValue.data(_allProducts.take(10 * _page).toList());
  }

  void search(String query) {
    final filtered = _allProducts
        .where((p) => p.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    state = AsyncValue.data(filtered.take(10 * _page).toList());
  }

  // Sort products by price (low to high)
  void sortByPriceLowToHigh() {
    final sorted = [..._allProducts]..sort((a, b) => a.price.compareTo(b.price));
    state = AsyncValue.data(sorted.take(10 * _page).toList());
  }

  // Sort products by price (high to low)
  void sortByPriceHighToLow() {
    final sorted = [..._allProducts]..sort((a, b) => b.price.compareTo(a.price));
    state = AsyncValue.data(sorted.take(10 * _page).toList());
  }

  // Sort products by rating
  void sortByRating() {
    final sorted = [..._allProducts]..sort((a, b) => b.rating.compareTo(a.rating));
    state = AsyncValue.data(sorted.take(10 * _page).toList());
  }

  // Toggle favorite status
  void toggleFavorite(int productId) {
    final productIndex = _allProducts.indexWhere((product) => product.id == productId);
    if (productIndex != -1) {
      _allProducts[productIndex].isFavorite = !_allProducts[productIndex].isFavorite;
      state = AsyncValue.data([..._allProducts]);
    }
  }
}
