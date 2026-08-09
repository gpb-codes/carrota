import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({String? baseUrl})
      : baseUrl = baseUrl ?? defaultBaseUrl();

  final String baseUrl;

  static const _timeout = Duration(seconds: 6);

  static String defaultBaseUrl() {
    const fromEnv = String.fromEnvironment('API_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://localhost:4000';
    return 'http://192.168.1.33:4000';
  }

  Future<Map<String, dynamic>?> _get(String path) async {
    final res = await http
        .get(Uri.parse('$baseUrl$path'))
        .timeout(_timeout);
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<bool> _post(String path, [Map<String, dynamic>? body]) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(_timeout);
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  Future<bool> _put(String path, [Map<String, dynamic>? body]) async {
    final res = await http
        .put(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(_timeout);
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  Future<bool> _delete(String path) async {
    final res =
        await http.delete(Uri.parse('$baseUrl$path')).timeout(_timeout);
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  Future<bool> health() async {
    try {
      final res =
          await http.get(Uri.parse('$baseUrl/api/health')).timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchFeed() async {
    final data = await _get('/api/feed');
    final list = (data?['videos'] as List?) ?? const [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<bool> like(String videoId) async {
    try {
      return await _post('/api/videos/$videoId/like');
    } catch (_) {
      return false;
    }
  }

  Future<bool> save(String videoId) async {
    try {
      return await _post('/api/videos/$videoId/save');
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchComments(String videoId) async {
    final data = await _get('/api/videos/$videoId/comments');
    final list = (data?['comments'] as List?) ?? const [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<bool> addComment(String videoId, String text) async {
    try {
      return await _post('/api/videos/$videoId/comments', {'text': text});
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchCart() async {
    final data = await _get('/api/cart');
    final list = (data?['items'] as List?) ?? const [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<bool> addCartItem(String productId, {int qty = 1}) async {
    try {
      return await _post('/api/cart', {'productId': productId, 'qty': qty});
    } catch (_) {
      return false;
    }
  }

  Future<bool> setCartQty(String productId, int qty) async {
    try {
      return await _put('/api/cart/$productId', {'qty': qty});
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeCartItem(String productId) async {
    try {
      return await _delete('/api/cart/$productId');
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearCart() async {
    try {
      return await _delete('/api/cart');
    } catch (_) {
      return false;
    }
  }

  Future<String?> registerSale(Map<String, dynamic> sale) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/sales'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(sale),
          )
          .timeout(_timeout);
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final s = body['sale'] as Map<String, dynamic>?;
      return s?['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchSales() async {
    final data = await _get('/api/sales');
    return ((data?['sales'] as List?) ?? const []).cast<Map<String, dynamic>>();
  }

  Future<bool> deleteSale(String id) async {
    try {
      return await _delete('/api/sales/$id');
    } catch (_) {
      return false;
    }
  }

  // ---------- productos e inventario ----------

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final data = await _get('/api/products');
    return ((data?['products'] as List?) ?? const []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> fetchProduct(String id) async {
    final data = await _get('/api/products/$id');
    return data?['product'] as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>?> productByBarcode(String code) async {
    final data = await _get('/api/products/barcode/$code');
    return data?['product'] as Map<String, dynamic>?;
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> fields) async {
    try {
      return await _put('/api/products/$id', fields);
    } catch (_) {
      return false;
    }
  }

  Future<bool> adjustStock(String id, int delta) async {
    try {
      return await _post('/api/products/$id/stock', {'delta': delta});
    } catch (_) {
      return false;
    }
  }

  // ---------- entregas ----------

  Future<bool> registerDelivery(Map<String, dynamic> delivery) async {
    try {
      return await _post('/api/deliveries', delivery);
    } catch (_) {
      return false;
    }
  }

  // ---------- resumen / insights / compra / cierre / eventos ----------

  Future<Map<String, dynamic>?> fetchSummary() async {
    final data = await _get('/api/summary');
    return data?['summary'] as Map<String, dynamic>?;
  }

  Future<List<Map<String, dynamic>>> fetchInsights() async {
    final data = await _get('/api/insights');
    return ((data?['insights'] as List?) ?? const []).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchShopping() async {
    final data = await _get('/api/shopping');
    return ((data?['items'] as List?) ?? const []).cast<Map<String, dynamic>>();
  }

  Future<bool> registerClosing({String? note}) async {
    try {
      return await _post('/api/closing', note == null ? null : {'note': note});
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchEvents({String? type}) async {
    final data = await _get('/api/events${type == null ? '' : '?type=$type'}');
    return ((data?['events'] as List?) ?? const []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> fetchBusiness() async {
    final data = await _get('/api/business');
    return data?['business'] as Map<String, dynamic>?;
  }

  /// Pregunta al LLM real (POST /api/lumo). Devuelve null si no está
  /// disponible (sin key en el server, error, o red caída) y la app debe
  /// usar el parser local.
  Future<({bool power, String? reply})> lumo(
    String text, {
    List<Map<String, dynamic>> history = const [],
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/lumo'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text, 'history': history}),
          )
          .timeout(_timeout);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return (power: false, reply: null);
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final power = data['power'] as bool? ?? false;
      final reply = data['reply'] as String?;
      return (power: power, reply: power && reply != null ? reply : null);
    } catch (_) {
      return (power: false, reply: null);
    }
  }

  static bool isNetworkError(Object error) =>
      error is SocketException || error is http.ClientException;
}
