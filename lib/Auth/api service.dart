import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:billingapp/bussinjessscreate/complete%20setup.dart';
import 'package:billingapp/bussinjessscreate/shop%20select.dart';
import 'package:billingapp/models/category%20grou0p.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';

class ApiService {
  static const String baseUrl = "https://billing.srivagroups.in/api";

  static void _logApiRequest(String name, String method, String url, {Map<String, dynamic>? payload}) {
    print("==================================================");
    print("[$name REQUEST]");
    print("=============");
    print("");
    print("METHOD => $method");
    print("URL => $url");
    if (payload != null) {
      print("");
      print("Payload =>");
      print(const JsonEncoder.withIndent('  ').convert(payload));
    }
    print("");
    print("==================================================");
  }

  static void _logApiResponse(String name, int statusCode, String body, {bool success = true}) {
    print("==================================================");
    print("[$name RESPONSE]");
    print("==============");
    print("");
    print("STATUS CODE => $statusCode");
    print("SUCCESS => ${success.toString().toUpperCase()}");
    print("");
    print("RESPONSE =>");
    print(body);
    print("");
    print("==================================================");
  }

  static void _logApiError(String name, String method, String url, dynamic error, StackTrace stackTrace) {
    print("==================================================");
    print("[API ERROR]");
    print("===========");
    print("");
    print("API => $name");
    print("METHOD => $method");
    print("URL => $url");
    print("");
    print("STATUS CODE => 500");
    print("SUCCESS => FALSE");
    print("");
    print("ERROR =>");
    print(error.toString());
    print("");
    print("STACKTRACE =>");
    print(stackTrace.toString());
    print("");
    print("==================================================");
  }

  /// ✅ HEADERS
  static Future<Map<String, String>> _getHeaders({bool auth = false}) async {
    final headers = {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "X-App-ID": "Product94674",
    };

    if (auth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("billing_auth_token") ?? prefs.getString("auth_token");

      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }
    }

    return headers;
  }


  /// ✅ HANDLE RESPONSE (🔥 IMPORTANT FIX)
  static Map<String, dynamic> _handleResponse(http.Response res) {
    try {
      final body = jsonDecode(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return body is Map<String, dynamic>
            ? body
            : {"data": body}; // handle list response
      } else {
        throw Exception(body.toString());
      }
    } catch (e) {
      throw Exception("API Error: ${res.body}");
    }
  }

  /// ✅ LOGIN
  static Future<Map<String, dynamic>> loginUser(Map data) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));

      final response = _handleResponse(res);

      if (response["token"] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", response["token"]);
      }

      return response;
    } on SocketException {
      throw Exception("No Internet Connection");
    } on TimeoutException {
      throw Exception("Request Timeout. Please check your connection.");
    } on http.ClientException {
      throw Exception("Network Error. Please check your internet.");
    } catch (e) {
      rethrow;
    }
  }

  /// ✅ BUSINESSES
  static Future<Map<String, dynamic>> getBusinesses() async {
    const url = "/businesses/my-businesses";
    try {
      _logApiRequest("GET BUSINESSES", "GET", url);
      final res = await http.get(
        Uri.parse("$baseUrl$url"),
        headers: await _getHeaders(auth: true),
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("GET BUSINESSES", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Get Businesses API", "GET", url, e, stackTrace);
      return {};
    }
  }

  /// ✅ SELECT BUSINESS
  static Future<Map<String, dynamic>> selectBusiness(Map data) async {
    const url = "/auth/select-business";
    try {
      _logApiRequest("SELECT BUSINESS", "POST", url);
      final res = await http.post(
        Uri.parse("$baseUrl$url"),
        headers: await _getHeaders(auth: true),
        body: jsonEncode(data),
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("SELECT BUSINESS", res.statusCode, res.body, success: success);

      final response = _handleResponse(res);

      if (response["data"] != null) {
        final prefs = await SharedPreferences.getInstance();
        final businessData = response["data"];

        if (businessData["token"] != null) {
          final tokenStr = businessData["token"].toString();
          await prefs.setString("auth_token", tokenStr);
          await prefs.setString("billing_auth_token", tokenStr);
          await prefs.setString("token", tokenStr);
        }

        final bId = businessData["business_id"] ?? data["business_id"];
        if (bId != null && bId.toString() != "null" && bId.toString().isNotEmpty) {
          final bIdStr = bId.toString();
          await prefs.setString("selected_business_id", bIdStr);
          await prefs.setString("business_id", bIdStr);
          try {
            await prefs.setInt("business_id_int", int.parse(bIdStr));
          } catch (_) {}
        }

        if (businessData["user_main_id"] != null) {
          await prefs.setString("user_main_id", businessData["user_main_id"].toString());
        }

        if (businessData["type"] != null) {
          await prefs.setString("business_type", businessData["type"].toString());
          await prefs.setString("role", businessData["type"].toString()); // Sync role for existing logic
        }
      }

      return response;
    } catch (e, stackTrace) {
      _logApiError("Select Business API", "POST", url, e, stackTrace);
      rethrow;
    }
  }

  /// ✅ GET PLATFORMS FOR BUSINESS
  static Future<Map<String, dynamic>> getPlatforms({required String businessId}) async {
    final url = "/platform?businessId=$businessId";
    try {
      _logApiRequest("GET PLATFORMS", "GET", url);
      final res = await http.get(
        Uri.parse("$baseUrl$url"),
        headers: await _getHeaders(auth: true),
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("GET PLATFORMS", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Get Platforms API", "GET", url, e, stackTrace);
      return {};
    }
  }

  /// ✅ GET SALES BILLS
  static Future<Map<String, dynamic>> getSalesBills() async {
    const url = "/sales/bills";
    try {
      _logApiRequest("GET SALES BILLS", "GET", url);
      final res = await http.get(
        Uri.parse("$baseUrl$url"),
        headers: await _getHeaders(auth: true),
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("GET SALES BILLS", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Get Sales Bills API", "GET", url, e, stackTrace);
      return {};
    }
  }

  /// ✅ CATEGORY GROUPS
  Future<List<CategoryGroup>> fetchCategoryGroups() async {
    try {
      final headers = await _getHeaders(auth: true);

      final response = await http.get(
        Uri.parse("$baseUrl/categories"),
        headers: headers,
      );

      final res = _handleResponse(response);
      AppLogger.info("Category groups fetched successfully");

      if (res['success'] == true) {
        final data = res['data'];

        if (data is Map<String, dynamic>) {
          final categoryGroups = data['category_groups'];

          if (categoryGroups is List) {
            return categoryGroups
                .map((e) => CategoryGroup.fromJson(e))
                .toList();
          }
        }
      }

      return [];
    } catch (e) {
      AppLogger.error("fetchCategoryGroups error", e);
      return [];
    }
  }

  /// ✅ PRODUCTS
  static Future<Map<String, dynamic>> getProducts({
    required int categoryGroupId,
    required int businessId,
  }) async {
    final url =
        "/GroupCatgeorybrandallProductList?category_group_id=$categoryGroupId&business_id=$businessId";
    
    _logApiRequest("PRODUCTS", "GET", url);

    try {
      final res = await http.get(
        Uri.parse("$baseUrl$url"),
        headers: await _getHeaders(auth: true),
      );

      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("PRODUCTS", res.statusCode, res.body, success: success);

      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Products API", "GET", url, e, stackTrace);
      return {};
    }
  }

  /// ✅ SEND DEVICE INFO
  static Future<void> sendDeviceInfo(Map<String, dynamic> payload) async {
    final url = "$baseUrl/device-info"; // Adjust if user gives actual endpoint
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(auth: true),
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        AppLogger.success("Device info sent successfully");
      } else {
        AppLogger.error("Failed to send device info: ${res.statusCode}");
      }
    } catch (e) {
      AppLogger.error("Error sending device info", e);
    }
  }

  /// ✅ BRANDS
  /// ✅ BRANDS
  static Future<Map<String, dynamic>> getBrands({
    required dynamic categoryGroupId,
    String? type, // ✅ optional
  }) async {

    final url =
        "$baseUrl/GroupCatgeorybrandallProductList/categories-brands?category_group_id=$categoryGroupId";

    final res = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(auth: true),
    );

    final response = _handleResponse(res);

    /// 🔥 ONLY FILTER IF TYPE PROVIDED
    if (type != null) {
      response['data'] = _filterBrands(response['data'], type);
    }

    return response;
  }
  /// 🔥👇 INGA THAN PASTE PANNU (getBrands keezha)
  static List<Map<String, dynamic>> _filterBrands(List data, String type) {
    final Map<int, Map<String, dynamic>> unique = {};

    for (var group in data) {
      for (var primary in (group['primary_categories'] ?? [])) {

        if (type == "primary") {
          for (var brand in (primary['brands'] ?? [])) {
            if (brand['id'] != null) {
              unique[brand['id']] = {
                "id": brand['id'],
                "name": brand['name'] ?? "No Name"
              };
            }
          }
        }

        if (type == "secondary") {
          for (var secondary in (primary['secondary_categories'] ?? [])) {
            for (var brand in (secondary['brands'] ?? [])) {
              if (brand['id'] != null) {
                unique[brand['id']] = {
                  "id": brand['id'],
                  "name": brand['name'] ?? "No Name"
                };
              }
            }
          }
        }
      }
    }

    return unique.values.toList();
  }

  /// ✅ FIXED BRAND EXTRACTION (🔥 NO CRASH)
  static List<Map<String, dynamic>> extractBrands(
      Map<String, dynamic> response,
      String type,
      ) {
    final Map<int, Map<String, dynamic>> unique = {};
    final data = response['data'] ?? [];

    if (data is List) {
      for (var group in data) {
        for (var primary in (group['primary_categories'] ?? [])) {

          if (type == "primary") {
            for (var brand in (primary['brands'] ?? [])) {
              if (brand['id'] != null) {
                unique[brand['id']] = {
                  "id": brand['id'],
                  "name": brand['name'] ?? "No Name"
                };
              }
            }
          }

          if (type == "secondary") {
            for (var secondary in (primary['secondary_categories'] ?? [])) {
              for (var brand in (secondary['brands'] ?? [])) {
                if (brand['id'] != null) {
                  unique[brand['id']] = {
                    "id": brand['id'],
                    "name": brand['name'] ?? "No Name"
                  };
                }
              }
            }
          }
        }
      }
    }

    return unique.values.toList();
  }

  /// ✅ STORAGE TYPES
  static Future<List<Map<String, dynamic>>> getStorageTypes() async {
    final res = await http.get(
      Uri.parse("$baseUrl/storage/types"),
      headers: await _getHeaders(auth: true),
    );

    final response = _handleResponse(res);

    if (response['data'] != null) {
      return List<Map<String, dynamic>>.from(response['data']);
    } else {
      return List<Map<String, dynamic>>.from(response as Iterable<dynamic>);
    }
  }

  /// ✅ SHOP TYPES (FINAL WORKING)
  static Future<List<ShopType>> getShopTypes() async {
    final res = await http.get(
      Uri.parse("$baseUrl/setup/shop-types"),
      headers: await _getHeaders(auth: true),
    );

    final response = _handleResponse(res);

    try {
      final data = response['data'] ?? response;

      if (data is List) {
        return data.map<ShopType>((e) {
          return ShopType.fromJson(e);
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      AppLogger.error("ShopTypes Parse Error", e);
      return [];
    }
  }

  Future<List<ModuleItem>> fetchModules() async {
    try {
      final headers = await _getHeaders(auth: true);

      final response = await http.get(
        Uri.parse("$baseUrl/businessModules/modules/1/items"),
        headers: headers,
      );

      final res = _handleResponse(response);

      final data = res['data'] ?? res;

      if (data is List) {
        return data
            .map<ModuleItem>((e) => ModuleItem.fromJson(e))
            .toList();
      }

      return [];
    } catch (e) {
      AppLogger.error("fetchModules ERROR", e);
      return [];
    }
  }

  Future<bool> saveSelectedModules(Set<int> moduleIds) async {
    try {
      final headers = await _getHeaders(auth: true);

      final prefs = await SharedPreferences.getInstance();
      final rawBizId = prefs.get("business_id");
      final businessId = rawBizId != null ? int.tryParse(rawBizId.toString()) : null;

      if (businessId == null) {
        AppLogger.warning("saveSelectedModules: Business ID is null");
        return false;
      }

      for (int id in moduleIds) {
        final response = await http.post(
          Uri.parse("$baseUrl/businessModules/modules"),
          headers: headers,
          body: jsonEncode({
            "module_id": id,              // ✅ SINGLE
            "business_id": businessId,    // ✅ REQUIRED
          }),
        );

        AppLogger.api("POST", "$baseUrl/businessModules/modules", response.statusCode);

        if (response.statusCode != 200 && response.statusCode != 201) {
          return false;
        }
      }

      return true;
    } catch (e) {
      AppLogger.error("saveSelectedModules ERROR", e);
      return false;
    }
  }


  Future<bool> saveFullSetup({
    required List<int> shopTypeIds,
    required List<int> moduleIds,
    required List<int> categoryGroupIds,
    required List<int> categoryIds,
    required List<int> brandIds,
  }) async {
    try {
      final headers = await _getHeaders(auth: true);

      final prefs = await SharedPreferences.getInstance();
      final rawBizId = prefs.get("business_id");
      final businessId = rawBizId != null ? int.tryParse(rawBizId.toString()) : null;

      if (businessId == null) {
        AppLogger.warning("saveFullSetup: Business ID is null");
        return false;
      }

      final body = {
        "business_id": businessId,
        "shop_type_ids": shopTypeIds,
        "module_ids": moduleIds,
        "category_group_ids": categoryGroupIds,
        "category_ids": categoryIds,
        "brand_ids": brandIds,
      };

      final response = await http.post(
        Uri.parse("$baseUrl/setup/full"),
        headers: headers,
        body: jsonEncode(body),
      );

      AppLogger.api("POST", "$baseUrl/setup/full", response.statusCode);

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        return false;
      }

      final decoded = jsonDecode(response.body);

      return decoded["success"] == true;
    } catch (e) {
      AppLogger.error("saveFullSetup ERROR", e);
      return false;
    }
  }

  Future<List<ModuleItem>> getAllModules() async {
    try {
      final headers = await _getHeaders(auth: true);

      final res = await http.get(
        Uri.parse("$baseUrl/businessModules/modules/1/items"),
        headers: headers,
      );

      final decoded = jsonDecode(res.body);

      final list = decoded['data'] ?? [];

      return list
          .map<ModuleItem>((e) => ModuleItem.fromJson(e))
          .toList();
    } catch (e) {
      AppLogger.error("getAllModules ERROR", e);
      return [];
    }
  }

  Future<Map<String, dynamic>?> getFullSetup() async {
    try {
      final headers = await _getHeaders(auth: true);

      final res = await http.get(
        Uri.parse("$baseUrl/setup/setup"),
        headers: headers,
      );

      AppLogger.api("GET", "$baseUrl/setup/setup", res.statusCode);

      if (res.statusCode != 200) return null;

      final decoded = jsonDecode(res.body);

      if (decoded is Map<String, dynamic> &&
          decoded["success"] == true) {
        return decoded['data'];
      }

      return null;
    } catch (e) {
      AppLogger.error("getFullSetup ERROR", e);
      return null;
    }
  }

  static Future<bool> postRaw({
    required String url,
    required Map<String, dynamic> body,
  }) async {
    try {
      final headers = await _getHeaders(auth: true);

      final res = await http.post(
        Uri.parse("$baseUrl$url"),
        headers: headers,
        body: jsonEncode(body),
      );

      AppLogger.api("POST", "$baseUrl$url", res.statusCode);

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      AppLogger.error("postRaw ERROR", e);
      return false;
    }
  }

  static Future<bool> saveProductAllocation({
    required int categoryGroupId,
    required int categoryId,
    required int brandId,
    required int productId,
    required String productName,
    required int minQty,
    required int maxQty,
  }) async {
    const url = "/productAllocation";
    try {
      final headers = await _getHeaders(auth: true);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.get("selected_business_id") ?? prefs.get("business_id") ?? "52";
      final int setupId = raw is int ? raw : int.tryParse(raw.toString()) ?? 52;
      final storeIdStr = prefs.getString("selected_store_id") ?? prefs.get("store_id")?.toString() ?? "38";
      final int storeId = int.tryParse(storeIdStr) ?? 38;

      final body = {
        "setup_id": setupId,
        "business_id": setupId,
        "store_id": storeId,
        "category_group_id": categoryGroupId,
        "category_id": categoryId,
        "brand_id": brandId,
        "products": [
          {
            "product_id": productId,
            "product_name": productName,
            "min_sale_qty": minQty,
            "max_sale_qty": maxQty
          }
        ]
      };

      _logApiRequest("SAVE", "POST", url, payload: body);

      final res = await http.post(
        Uri.parse("$baseUrl$url"),
        headers: headers,
        body: jsonEncode(body),
      );

      final success = res.statusCode == 200 || res.statusCode == 201;
      _logApiResponse("SAVE", res.statusCode, res.body, success: success);

      return success;
    } catch (e, stackTrace) {
      _logApiError("Save Allocation API", "POST", url, e, stackTrace);
      return false;
    }
  }

  static Future<bool> updateProductAllocation({
    required int id,
    required int categoryGroupId,
    required int categoryId,
    required int brandId,
    required String productName,
    required int minQty,
    required int maxQty,
  }) async {
    final url = "/productAllocation/$id";
    try {
      final headers = await _getHeaders(auth: true);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.get("selected_business_id") ?? prefs.get("business_id") ?? "52";
      final int setupId = raw is int ? raw : int.tryParse(raw.toString()) ?? 52;
      final storeIdStr = prefs.getString("selected_store_id") ?? prefs.get("store_id")?.toString() ?? "38";
      final int storeId = int.tryParse(storeIdStr) ?? 38;

      final body = {
        "allocation_id": id,
        "setup_id": setupId,
        "business_id": setupId,
        "store_id": storeId,
        "category_group_id": categoryGroupId,
        "category_id": categoryId,
        "brand_id": brandId,
        "min_sale_qty": minQty,
        "max_sale_qty": maxQty,
      };

      _logApiRequest("UPDATE", "PUT", url, payload: body);

      final res = await http.put(
        Uri.parse("$baseUrl$url"),
        headers: headers,
        body: jsonEncode(body),
      );

      final success = res.statusCode == 200 || res.statusCode == 201;
      _logApiResponse("UPDATE", res.statusCode, res.body, success: success);

      return success;
    } catch (e, stackTrace) {
      _logApiError("Update Allocation API", "PUT", url, e, stackTrace);
      return false;
    }
  }

  static Future<bool> deleteProductAllocation(int id) async {
    final url = "/productAllocation/$id";
    try {
      _logApiRequest("DELETE", "DELETE", url);
      final headers = await _getHeaders(auth: true);
      final res = await http.delete(
        Uri.parse("$baseUrl$url"),
        headers: headers,
      );
      
      final success = res.statusCode == 200 || res.statusCode == 204;
      _logApiResponse("DELETE", res.statusCode, res.body, success: success);

      return success;
    } catch (e, stackTrace) {
      _logApiError("Delete Allocation API", "DELETE", url, e, stackTrace);
      return false;
    }
  }

  static Future<List<dynamic>> getAllocations() async {
    const url = "/productAllocation";
    try {
      _logApiRequest("ALLOCATION LIST", "GET", url);
      final headers = await _getHeaders(auth: true);
      final res = await http.get(
        Uri.parse("$baseUrl$url"),
        headers: headers,
      );
      
      final success = res.statusCode == 200;
      _logApiResponse("ALLOCATION LIST", res.statusCode, res.body, success: success);

      if (success) {
        final decoded = jsonDecode(res.body);
        return decoded['data'] ?? [];
      }
      return [];
    } catch (e, stackTrace) {
      _logApiError("Allocation List API", "GET", url, e, stackTrace);
      return [];
    }
  }
  
  static Future<List<CategoryGroup>> getCategoryGroups() async {
    const url = "/businesscategorygroup";
    try {
      _logApiRequest("CATEGORY GROUPS", "GET", url);
      final headers = await _getHeaders(auth: true);

      final res = await http.get(
        Uri.parse("$baseUrl$url"),
        headers: headers,
      );

      final success = res.statusCode == 200;
      _logApiResponse("CATEGORY GROUPS", res.statusCode, res.body, success: success);

      final response = _handleResponse(res);

      if (response['success'] == true) {
        final list = response['data']['category_groups'] ?? [];
        if (list is List) {
          return list.map<CategoryGroup>((e) {
            return CategoryGroup(
              id: e['id'] ?? 0,
              name: e['name'] ?? '',
            );
          }).toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      _logApiError("Category Groups API", "GET", url, e, stackTrace);
      return [];
    }
  }

  /// 🔥 CATEGORY + BRAND RAW DATA
  static Future<Map<String, dynamic>> getBrandsAndCategories({
    required dynamic categoryGroupId,
  }) async {
    final url =
        "$baseUrl/GroupCatgeorybrandallProductList/categories-brands?category_group_id=$categoryGroupId";

    final res = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(auth: true),
    );

    return _handleResponse(res);
  }

  /// 🔥 EXTRACT CATEGORY LIST (PRIMARY / SECONDARY)
  static List<Map<String, dynamic>> extractCategoryItems(
      List data,
      String type,
      ) {
    final Map<int, Map<String, dynamic>> unique = {};

    for (var group in data) {
      for (var primary in (group['primary_categories'] ?? [])) {

        if (type == "primary") {
          if (primary['id'] != null) {
            unique[primary['id']] = {
              "id": primary['id'],
              "name": primary['name'] ?? "No Name",
            };
          }
        }

        if (type == "secondary") {
          for (var sec in (primary['secondary_categories'] ?? [])) {
            if (sec['id'] != null) {
              unique[sec['id']] = {
                "id": sec['id'],
                "name": sec['name'] ?? "No Name",
              };
            }
          }
        }
      }
    }

    return unique.values.toList();
  }

  /// 🔥 EXTRACT BRANDS BASED ON CATEGORY
  static List<Map<String, dynamic>> extractBrandsByCategory({
    required List data,
    required String type,
    required int categoryId,
  }) {
    final Map<int, Map<String, dynamic>> unique = {};

    for (var group in data) {
      for (var primary in (group['primary_categories'] ?? [])) {

        if (type == "primary" && primary['id'] == categoryId) {
          for (var brand in (primary['brands'] ?? [])) {
            if (brand['id'] != null) {
              unique[brand['id']] = {
                "id": brand['id'],
                "name": brand['name'] ?? "No Name",
              };
            }
          }
        }

        if (type == "secondary") {
          for (var sec in (primary['secondary_categories'] ?? [])) {
            if (sec['id'] == categoryId) {
              for (var brand in (sec['brands'] ?? [])) {
                if (brand['id'] != null) {
                  unique[brand['id']] = {
                    "id": brand['id'],
                    "name": brand['name'] ?? "No Name",
                  };
                }
              }
            }
          }
        }
      }
    }

    return unique.values.toList();
  }


  static Future<Map<String, dynamic>> getCategoryBrands({
    required int categoryGroupId,
  }) async {
    final url =
        "/GroupCatgeorybrandallProductList/categories-brands?category_group_id=$categoryGroupId";

    try {
      _logApiRequest("CATEGORY BRANDS", "GET", url);
      final res = await http.get(
        Uri.parse("$baseUrl$url"),
        headers: await _getHeaders(auth: true),
      );

      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("CATEGORY BRANDS", res.statusCode, res.body, success: success);

      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Category Brands API", "GET", url, e, stackTrace);
      return {};
    }
  }

  static Future<Map<String, dynamic>> getBrandProducts({
    required int categoryId,
    required int brandId,
  }) async {
    final url =
        "/GroupCatgeorybrandallProductList/brand-products/$categoryId/$brandId";

    try {
      _logApiRequest("BRAND PRODUCTS", "GET", url);
      final res = await http.get(
        Uri.parse("$baseUrl$url"),
        headers: await _getHeaders(auth: true),
      );

      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("BRAND PRODUCTS", res.statusCode, res.body, success: success);

      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Brand Products API", "GET", url, e, stackTrace);
      return {};
    }
  }

  static Future<bool> verifyPin(String pin) async {
    const url = "/pin-auth";
    final body = {"pin": pin};
    try {
      _logApiRequest("PIN AUTH", "POST", url, payload: body);
      final headers = await _getHeaders(auth: true);
      final res = await http.post(
        Uri.parse("$baseUrl$url"),
        headers: headers,
        body: jsonEncode(body),
      );

      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("PIN AUTH", res.statusCode, res.body, success: success);

      if (success) {
        final decoded = jsonDecode(res.body);
        return decoded["success"] == true ||
            decoded["status"] == "success" ||
            decoded["status"] == true ||
            decoded["authenticated"] == true;
      }
      return false;
    } catch (e, stackTrace) {
      _logApiError("Pin Auth API", "POST", url, e, stackTrace);
      return false;
    }
  }

  static Future<Map<String, dynamic>> getEmployeeCountData() async {
    const url = "/employee-count-data";
    try {
      _logApiRequest("EMPLOYEE COUNT DATA", "GET", url);
      final headers = await _getHeaders(auth: true);
      final res = await http.get(
        Uri.parse("$baseUrl$url"),
        headers: headers,
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("EMPLOYEE COUNT DATA", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Employee Count Data API", "GET", url, e, stackTrace);
      return {};
    }
  }

  static Future<Map<String, dynamic>> getModulePageMapping() async {
    const url = "/admin/module-page-mapping";
    try {
      _logApiRequest("MODULE PAGE MAPPING", "GET", url);
      final headers = await _getHeaders(auth: true);
      final res = await http.get(
        Uri.parse("$baseUrl$url"),
        headers: headers,
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("MODULE PAGE MAPPING", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Module Page Mapping API", "GET", url, e, stackTrace);
      return {};
    }
  }

  static Future<Map<String, dynamic>> createEmployee(Map<String, dynamic> data) async {
    const url = "/admin/employee-create";
    try {
      _logApiRequest("EMPLOYEE CREATE", "POST", url, payload: data);
      final headers = await _getHeaders(auth: true);
      final res = await http.post(
        Uri.parse("$baseUrl$url"),
        headers: headers,
        body: jsonEncode(data),
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("EMPLOYEE CREATE", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Employee Create API", "POST", url, e, stackTrace);
      return {};
    }
  }

  static Future<Map<String, dynamic>> createTeam(Map<String, dynamic> data) async {
    const url = "/admin/team-create";
    try {
      _logApiRequest("TEAM CREATE", "POST", url, payload: data);
      final headers = await _getHeaders(auth: true);
      final res = await http.post(
        Uri.parse("$baseUrl$url"),
        headers: headers,
        body: jsonEncode(data),
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("TEAM CREATE", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Team Create API", "POST", url, e, stackTrace);
      return {};
    }
  }

  static Future<Map<String, dynamic>> getAccessManagement() async {
    const url = "/manage/access-management";
    try {
      _logApiRequest("ACCESS MANAGEMENT", "GET", url);
      final headers = await _getHeaders(auth: true);
      final res = await http.get(
        Uri.parse("$baseUrl$url"),
        headers: headers,
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("ACCESS MANAGEMENT", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Access Management API", "GET", url, e, stackTrace);
      return {};
    }
  }

  static Future<Map<String, dynamic>> getEmployees() async {
    const url = "/admin/employee-create";
    try {
      _logApiRequest("GET EMPLOYEES", "GET", url);
      final headers = await _getHeaders(auth: true);
      final res = await http.get(
        Uri.parse("$baseUrl$url"),
        headers: headers,
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("GET EMPLOYEES", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Get Employees API", "GET", url, e, stackTrace);
      return {};
    }
  }

  static Future<Map<String, dynamic>> getRoles() async {
    const url = "/admin/role-create";
    try {
      _logApiRequest("GET ROLES", "GET", url);
      final headers = await _getHeaders(auth: true);
      final res = await http.get(
        Uri.parse("$baseUrl$url"),
        headers: headers,
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("GET ROLES", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Get Roles API", "GET", url, e, stackTrace);
      return {};
    }
  }

  static Future<Map<String, dynamic>> getTeams() async {
    const url = "/admin/team-create";
    try {
      _logApiRequest("GET TEAMS", "GET", url);
      final headers = await _getHeaders(auth: true);
      final res = await http.get(
        Uri.parse("$baseUrl$url"),
        headers: headers,
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("GET TEAMS", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Get Teams API", "GET", url, e, stackTrace);
      return {};
    }
  }


  static Future<Map<String, dynamic>> createRole(Map<String, dynamic> data) async {
    const url = "/admin/role-create";
    try {
      _logApiRequest("CREATE ROLE", "POST", url, payload: data);
      final headers = await _getHeaders(auth: true);
      final res = await http.post(
        Uri.parse("$baseUrl$url"),
        headers: headers,
        body: jsonEncode(data),
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("CREATE ROLE", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Create Role API", "POST", url, e, stackTrace);
      return {};
    }
  }

  static Future<Map<String, dynamic>> updateRole(int id, Map<String, dynamic> data) async {
    final url = "/admin/role-create/$id";
    try {
      _logApiRequest("UPDATE ROLE", "PUT", url, payload: data);
      final headers = await _getHeaders(auth: true);
      final res = await http.put(
        Uri.parse("$baseUrl$url"),
        headers: headers,
        body: jsonEncode(data),
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("UPDATE ROLE", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Update Role API", "PUT", url, e, stackTrace);
      return {};
    }
  }

  static Future<bool> deleteRole(int id) async {
    final url = "/admin/role-create/$id";
    try {
      _logApiRequest("DELETE ROLE", "DELETE", url);
      final headers = await _getHeaders(auth: true);
      final res = await http.delete(
        Uri.parse("$baseUrl$url"),
        headers: headers,
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("DELETE ROLE", res.statusCode, res.body, success: success);
      return success;
    } catch (e, stackTrace) {
      _logApiError("Delete Role API", "DELETE", url, e, stackTrace);
      return false;
    }
  }
  static Future<dynamic> getJobApproved() async {
    const url = "https://user.jobes24x7.com/api/job-approved";
    try {
      _logApiRequest("GET JOB APPROVED", "GET", url);
      final res = await http.get(Uri.parse(url));
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("GET JOB APPROVED", res.statusCode, res.body, success: success);
      if (success) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e, stackTrace) {
      _logApiError("Get Job Approved API", "GET", url, e, stackTrace);
      return null;
    }
  }

  static Future<Map<String, dynamic>> updateEmployee(int id, Map<String, dynamic> data) async {
    final url = "/admin/employee-create/$id";
    try {
      _logApiRequest("UPDATE EMPLOYEE", "PUT", url, payload: data);
      final headers = await _getHeaders(auth: true);
      final res = await http.put(
        Uri.parse("$baseUrl$url"),
        headers: headers,
        body: jsonEncode(data),
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("UPDATE EMPLOYEE", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Update Employee API", "PUT", url, e, stackTrace);
      return {};
    }
  }

  static Future<bool> deleteEmployee(int id) async {
    final url = "/admin/employee-create/$id";
    try {
      _logApiRequest("DELETE EMPLOYEE", "DELETE", url);
      final headers = await _getHeaders(auth: true);
      final res = await http.delete(
        Uri.parse("$baseUrl$url"),
        headers: headers,
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("DELETE EMPLOYEE", res.statusCode, res.body, success: success);
      return success;
    } catch (e, stackTrace) {
      _logApiError("Delete Employee API", "DELETE", url, e, stackTrace);
      return false;
    }
  }

  static Future<Map<String, dynamic>> viewProductByBarcode(String barcode) async {
    final url = "https://srivagroups.in/api/products/view/$barcode?json=true";
    try {
      _logApiRequest("VIEW PRODUCT BY BARCODE", "GET", url);
      final res = await http.get(Uri.parse(url));
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("VIEW PRODUCT BY BARCODE", res.statusCode, res.body, success: success);
      if (success) {
        return jsonDecode(res.body);
      }
      return {};
    } catch (e, stackTrace) {
      _logApiError("View Product By Barcode API", "GET", url, e, stackTrace);
      return {};
    }
  }

  static Future<Map<String, dynamic>> setTeamRole(Map<String, dynamic> data) async {
    const url = "/admin/team-role-set";
    try {
      _logApiRequest("SET TEAM ROLE", "POST", url, payload: data);
      final headers = await _getHeaders(auth: true);
      final res = await http.post(
        Uri.parse("$baseUrl$url"),
        headers: headers,
        body: jsonEncode(data),
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("SET TEAM ROLE", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Set Team Role API", "POST", url, e, stackTrace);
      return {};
    }
  }

  static Future<Map<String, dynamic>> getProjects() async {
    const url = "/admin/project-create";
    try {
      _logApiRequest("GET PROJECTS", "GET", url);
      final headers = await _getHeaders(auth: true);
      final res = await http.get(Uri.parse("$baseUrl$url"), headers: headers);
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("GET PROJECTS", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Get Projects API", "GET", url, e, stackTrace);
      return {};
    }
  }

  static Future<Map<String, dynamic>> createProject(Map<String, dynamic> data) async {
    const url = "/admin/project-create";
    try {
      _logApiRequest("CREATE PROJECT", "POST", url, payload: data);
      final headers = await _getHeaders(auth: true);
      final res = await http.post(Uri.parse("$baseUrl$url"), headers: headers, body: jsonEncode(data));
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("CREATE PROJECT", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Create Project API", "POST", url, e, stackTrace);
      return {};
    }
  }

  static Future<Map<String, dynamic>> allocateTeamProject(Map<String, dynamic> data) async {
    const url = "/admin/project-allocation/team";
    try {
      _logApiRequest("ALLOCATE TEAM PROJECT", "POST", url, payload: data);
      final headers = await _getHeaders(auth: true);
      final res = await http.post(Uri.parse("$baseUrl$url"), headers: headers, body: jsonEncode(data));
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("ALLOCATE TEAM PROJECT", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Allocate Team Project API", "POST", url, e, stackTrace);
      return {};
    }
  }

  static Future<Map<String, dynamic>> allocateIndividualProject(Map<String, dynamic> data) async {
    const url = "/admin/project-allocation/individual";
    try {
      _logApiRequest("ALLOCATE INDIVIDUAL PROJECT", "POST", url, payload: data);
      final headers = await _getHeaders(auth: true);
      final res = await http.post(Uri.parse("$baseUrl$url"), headers: headers, body: jsonEncode(data));
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("ALLOCATE INDIVIDUAL PROJECT", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Allocate Individual Project API", "POST", url, e, stackTrace);
      return {};
    }
  }

  static Future<Map<String, dynamic>> getTeamAllocations() async {
    const url = "/admin/project-allocation/team";
    try {
      _logApiRequest("GET TEAM ALLOCATIONS", "GET", url);
      final headers = await _getHeaders(auth: true);
      final res = await http.get(Uri.parse("$baseUrl$url"), headers: headers);
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("GET TEAM ALLOCATIONS", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Get Team Allocations API", "GET", url, e, stackTrace);
      return {};
    }
  }

  static Future<Map<String, dynamic>> getIndividualAllocations() async {
    const url = "/admin/project-allocation/individual";
    try {
      _logApiRequest("GET INDIVIDUAL ALLOCATIONS", "GET", url);
      final headers = await _getHeaders(auth: true);
      final res = await http.get(Uri.parse("$baseUrl$url"), headers: headers);
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("GET INDIVIDUAL ALLOCATIONS", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Get Individual Allocations API", "GET", url, e, stackTrace);
      return {};
    }
  }

  static Future<Map<String, dynamic>> getRaw({required String url}) async {
    try {
      _logApiRequest("GET RAW", "GET", url);
      final headers = await _getHeaders(auth: true);
      final res = await http.get(Uri.parse("$baseUrl$url"), headers: headers);
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("GET RAW", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Get Raw API", "GET", url, e, stackTrace);
      return {};
    }
  }

  static Future<Map<String, dynamic>> getPinAuths() async {
    const url = "/pin-auth";
    try {
      _logApiRequest("GET PIN AUTHS", "GET", url);
      final headers = await _getHeaders(auth: true);
      final res = await http.get(
        Uri.parse("$baseUrl$url"),
        headers: headers,
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("GET PIN AUTHS", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Get Pin Auths API", "GET", url, e, stackTrace);
      return {};
    }
  }

  static Future<Map<String, dynamic>> createPinAuth(Map<String, dynamic> data) async {
    const url = "/pin-auth/manage";
    try {
      _logApiRequest("CREATE PIN AUTH", "POST", url, payload: data);
      final headers = await _getHeaders(auth: true);
      final res = await http.post(
        Uri.parse("$baseUrl$url"),
        headers: headers,
        body: jsonEncode(data),
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("CREATE PIN AUTH", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Create Pin Auth API", "POST", url, e, stackTrace);
      return {};
    }
  }

  static Future<Map<String, dynamic>> updatePinAuth(int id, Map<String, dynamic> data) async {
    final url = "/pin-auth/$id";
    try {
      _logApiRequest("UPDATE PIN AUTH", "PUT", url, payload: data);
      final headers = await _getHeaders(auth: true);
      final res = await http.put(
        Uri.parse("$baseUrl$url"),
        headers: headers,
        body: jsonEncode(data),
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("UPDATE PIN AUTH", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Update Pin Auth API", "PUT", url, e, stackTrace);
      return {};
    }
  }

  static Future<bool> deletePinAuth(int id) async {
    final url = "/pin-auth/$id";
    try {
      _logApiRequest("DELETE PIN AUTH", "DELETE", url);
      final headers = await _getHeaders(auth: true);
      final res = await http.delete(
        Uri.parse("$baseUrl$url"),
        headers: headers,
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("DELETE PIN AUTH", res.statusCode, res.body, success: success);
      return success;
    } catch (e, stackTrace) {
      _logApiError("Delete Pin Auth API", "DELETE", url, e, stackTrace);
      return false;
    }
  }

  static Future<Map<String, dynamic>> getNotifications() async {
    const url = "/notifications";
    try {
      _logApiRequest("GET NOTIFICATIONS", "GET", url);
      final res = await http.get(
        Uri.parse("$baseUrl$url"),
        headers: await _getHeaders(auth: true),
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("GET NOTIFICATIONS", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Get Notifications API", "GET", url, e, stackTrace);
      return {};
    }
  }

  static Future<Map<String, dynamic>> getUserPermissions() async {
    const url = "/user/permissions";
    try {
      _logApiRequest("GET USER PERMISSIONS", "GET", url);
      final res = await http.get(
        Uri.parse("$baseUrl$url"),
        headers: await _getHeaders(auth: true),
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("GET USER PERMISSIONS", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Get User Permissions API", "GET", url, e, stackTrace);
      return {};
    }
  }

  static Future<Map<String, dynamic>> clearAllNotifications() async {
    const url = "/notifications/clear-all";
    try {
      _logApiRequest("CLEAR ALL NOTIFICATIONS", "DELETE", url);
      final res = await http.delete(
        Uri.parse("$baseUrl$url"),
        headers: await _getHeaders(auth: true),
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("CLEAR ALL NOTIFICATIONS", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Clear All Notifications API", "DELETE", url, e, stackTrace);
      return {};
    }
  }

  /// ✅ GET STORES
  /// Request: GET https://billing.srivagroups.in/api/store?business_id=52&businessId=52&platform_id=1&platformId=1
  static Future<Map<String, dynamic>> getStores({
    String? businessId,
    String? platformId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final bId = businessId ??
        prefs.getString("selected_business_id") ??
        prefs.get("business_id")?.toString() ??
        "52";
    final pId = platformId ??
        prefs.getString("selected_platform_id") ??
        prefs.get("platform_id")?.toString() ??
        "1";

    final url =
        "/store?business_id=$bId&businessId=$bId&platform_id=$pId&platformId=$pId";

    try {
      _logApiRequest("GET STORES", "GET", url);
      final res = await http.get(
        Uri.parse("$baseUrl$url"),
        headers: await _getHeaders(auth: true),
      );

      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("GET STORES", res.statusCode, res.body, success: success);

      final response = _handleResponse(res);

      if (response["success"] == true &&
          response["data"] is List &&
          (response["data"] as List).isNotEmpty) {
        final firstStore = response["data"][0];
        if (firstStore["store_id"] != null) {
          await prefs.setString(
              "selected_store_id", firstStore["store_id"].toString());
          await prefs.setInt(
              "store_id", int.tryParse(firstStore["store_id"].toString()) ?? 0);
        }
        if (firstStore["store_name"] != null) {
          await prefs.setString(
              "selected_store_name", firstStore["store_name"].toString());
        }
      }

      return response;
    } catch (e, stackTrace) {
      _logApiError("Get Stores API", "GET", url, e, stackTrace);
      return {};
    }
  }

  /// ✅ GET PRODUCT ENTRY STORE SETUP
  /// Request: GET https://billing.srivagroups.in/api/product-entry/store-setup?userId=4995251182&businessId=52&platformId=1&storeId=38
  static Future<Map<String, dynamic>> getProductEntryStoreSetup({
    String? userId,
    String? businessId,
    String? platformId,
    String? storeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final uId = userId ??
        prefs.getString("user_main_id") ??
        prefs.getString("user_id") ??
        prefs.get("user_id")?.toString() ??
        "4995251182";
    final bId = businessId ??
        prefs.getString("selected_business_id") ??
        prefs.get("business_id")?.toString() ??
        "52";
    final pId = platformId ??
        prefs.getString("selected_platform_id") ??
        prefs.get("platform_id")?.toString() ??
        "1";
    final sId = storeId ??
        prefs.getString("selected_store_id") ??
        prefs.get("store_id")?.toString() ??
        "38";

    final url =
        "/product-entry/store-setup?userId=$uId&businessId=$bId&platformId=$pId&storeId=$sId";

    try {
      _logApiRequest("GET PRODUCT ENTRY STORE SETUP", "GET", url);
      final res = await http.get(
        Uri.parse("$baseUrl$url"),
        headers: await _getHeaders(auth: true),
      );

      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("GET PRODUCT ENTRY STORE SETUP", res.statusCode, res.body, success: success);

      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Get Product Entry Store Setup API", "GET", url, e, stackTrace);
      return {};
    }
  }

  /// ✅ GET STORE SETUP (Backward-compatible alias)
  static Future<Map<String, dynamic>> getStoreSetup({
    String? userId,
    String? businessId,
    String? platformId,
    String? storeId,
  }) async {
    return getProductEntryStoreSetup(
      userId: userId,
      businessId: businessId,
      platformId: platformId,
      storeId: storeId,
    );
  }

  /// ✅ GET CATEGORY LIST
  /// Request: GET https://srivagroups.in/api/category/list
  static Future<Map<String, dynamic>> getCategoryList() async {
    const srivaUrl = "https://srivagroups.in/api/category/list";
    try {
      _logApiRequest("GET CATEGORY LIST", "GET", srivaUrl);
      final headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "X-App-ID": "Product94674",
      };
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("billing_auth_token") ?? prefs.getString("auth_token");
        if (token != null && token.isNotEmpty) {
          headers["Authorization"] = token.startsWith("Bearer ") ? token : "Bearer $token";
        }
      } catch (_) {}

      final res = await http.get(
        Uri.parse(srivaUrl),
        headers: headers,
      ).timeout(const Duration(seconds: 12));

      debugPrint("getCategoryList [${res.statusCode}]: ${res.body.length} chars");
      if (res.statusCode >= 200 && res.statusCode < 300) {
        _logApiResponse("GET CATEGORY LIST (srivagroups.in)", res.statusCode, res.body, success: true);
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is List) return {"success": true, "data": decoded};
      }
    } catch (e) {
      debugPrint("Direct srivagroups.in getCategoryList failed: $e");
    }

    // Direct fallback with minimal headers
    try {
      final res = await http.get(
        Uri.parse(srivaUrl),
        headers: {
          "Accept": "application/json",
          "X-App-ID": "Product94674",
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is List) return {"success": true, "data": decoded};
      }
    } catch (e) {
      debugPrint("getCategoryList fallback error: $e");
    }

    return {};
  }

  /// ✅ GET PRODUCTS BY BRAND ID
  /// Request: GET https://billing.srivagroups.in/api/products/{brandId}
  static Future<Map<String, dynamic>> getProductsByBrandId(dynamic brandId) async {
    final url = "https://billing.srivagroups.in/api/products/$brandId";
    try {
      _logApiRequest("GET PRODUCTS BY BRAND ID", "GET", url);
      final headers = await _getHeaders(auth: true);
      headers["X-App-ID"] = "Product94674";
      final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));
      debugPrint("getProductsByBrandId [$url] [${res.statusCode}]: ${res.body.length} chars");
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is List) return {"success": true, "products": decoded};
      }
    } catch (e) {
      debugPrint("getProductsByBrandId error: $e");
    }
    return {};
  }

  /// ✅ GET BRANDS BY CATEGORY
  /// Request: GET https://srivagroups.in/api/brand/{categoryId}?userId=...&businessId=...&platformId=...&storeId=...
  static Future<Map<String, dynamic>> getBrandsByCategory({
    required dynamic categoryId,
    String? userId,
    String? businessId,
    String? platformId,
    String? storeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final effectiveUserId = userId ?? prefs.getString("userId") ?? prefs.getString("user_id") ?? "4995251182";
    final effectiveBusinessId = businessId ?? prefs.getString("selected_business_id") ?? prefs.getString("businessId") ?? "52";
    final effectivePlatformId = platformId ?? prefs.getString("selected_platform_id") ?? prefs.getString("platformId") ?? "1";
    final effectiveStoreId = storeId ?? prefs.getString("selected_store_id") ?? prefs.getString("storeId") ?? "38";

    final query = "userId=$effectiveUserId&businessId=$effectiveBusinessId&platformId=$effectivePlatformId&storeId=$effectiveStoreId";
    final srivaUrl = "https://srivagroups.in/api/brand/$categoryId?$query";
    final billingUrl = "$baseUrl/brand/$categoryId?$query";

    final headers = await _getHeaders(auth: true);
    headers["X-App-ID"] = "Product94674";

    try {
      _logApiRequest("GET BRANDS BY CATEGORY", "GET", srivaUrl);
      final res = await http.get(Uri.parse(srivaUrl), headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        _logApiResponse("GET BRANDS BY CATEGORY", res.statusCode, res.body, success: true);
        return _handleResponse(res);
      }
    } catch (e) {
      debugPrint("srivagroups getBrandsByCategory failed, trying billing: $e");
    }

    try {
      _logApiRequest("GET BRANDS BY CATEGORY (billing fallback)", "GET", billingUrl);
      final res = await http.get(Uri.parse(billingUrl), headers: headers).timeout(const Duration(seconds: 10));
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("GET BRANDS BY CATEGORY (billing fallback)", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Get Brands By Category API", "GET", billingUrl, e, stackTrace);
      return {};
    }
  }

  /// ✅ GET PRODUCTS BY BRAND AND CATEGORY
  /// Request: GET https://srivagroups.in/api/products?brand_id={brandId}&category_id={categoryId}&userId=...
  static Future<Map<String, dynamic>> getProductsByBrandAndCategory({
    required dynamic brandId,
    dynamic categoryId,
    String? userId,
    String? businessId,
    String? platformId,
    String? storeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final effectiveUserId = userId ?? prefs.getString("userId") ?? prefs.getString("user_id") ?? "4995251182";
    final effectiveBusinessId = businessId ?? prefs.getString("selected_business_id") ?? prefs.getString("businessId") ?? "52";
    final effectivePlatformId = platformId ?? prefs.getString("selected_platform_id") ?? prefs.getString("platformId") ?? "1";
    final effectiveStoreId = storeId ?? prefs.getString("selected_store_id") ?? prefs.getString("storeId") ?? "38";

    final catParam = categoryId != null ? "&category_id=$categoryId" : "";
    final query = "brand_id=$brandId$catParam&userId=$effectiveUserId&businessId=$effectiveBusinessId&platformId=$effectivePlatformId&storeId=$effectiveStoreId";
    final srivaUrl = "https://srivagroups.in/api/products?$query";
    final billingUrl = "$baseUrl/products?$query";

    final headers = await _getHeaders(auth: true);
    headers["X-App-ID"] = "Product94674";

    try {
      _logApiRequest("GET PRODUCTS BY BRAND & CATEGORY", "GET", srivaUrl);
      final res = await http.get(Uri.parse(srivaUrl), headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        _logApiResponse("GET PRODUCTS BY BRAND & CATEGORY", res.statusCode, res.body, success: true);
        return _handleResponse(res);
      }
    } catch (e) {
      debugPrint("srivagroups getProductsByBrandAndCategory failed, trying billing: $e");
    }

    try {
      _logApiRequest("GET PRODUCTS BY BRAND & CATEGORY (billing fallback)", "GET", billingUrl);
      final res = await http.get(Uri.parse(billingUrl), headers: headers).timeout(const Duration(seconds: 10));
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("GET PRODUCTS BY BRAND & CATEGORY (billing fallback)", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Get Products By Brand API", "GET", billingUrl, e, stackTrace);
      return {};
    }
  }

  /// ✅ GET BRAND LIST
  /// Request: GET https://billing.srivagroups.in/api/brand/list
  static Future<Map<String, dynamic>> getBrandList() async {
    const url = "/brand/list";
    try {
      _logApiRequest("GET BRAND LIST", "GET", url);
      final res = await http.get(
        Uri.parse("$baseUrl$url"),
        headers: await _getHeaders(auth: true),
      );
      final success = res.statusCode >= 200 && res.statusCode < 300;
      _logApiResponse("GET BRAND LIST", res.statusCode, res.body, success: success);
      return _handleResponse(res);
    } catch (e, stackTrace) {
      _logApiError("Get Brand List API", "GET", url, e, stackTrace);
      return {};
    }
  }
}

