import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'package:billingapp/theme.dart';

part 'sales_point_logic.dart';
part 'sales_point_widgets.dart';
part 'sales_point_dialogs.dart';

class StockItem {
  final String stockId;
  final String productId;
  final String variantId;
  final String variantTypeId;
  final String name;
  final String supplierName;
  final String category;
  final String brand;
  final String sku;
  final String barcode;
  final String variantLabel;
  final int qty;
  final int totalQty;
  final double sellingPrice;
  final double mrp;
  final String description;

  StockItem({
    required this.stockId,
    required this.productId,
    required this.variantId,
    required this.variantTypeId,
    required this.name,
    required this.supplierName,
    required this.category,
    required this.brand,
    required this.sku,
    required this.barcode,
    required this.variantLabel,
    required this.qty,
    required this.totalQty,
    required this.sellingPrice,
    required this.mrp,
    required this.description,
  });
}

class SalesPointPage extends StatefulWidget {
  const SalesPointPage({super.key});

  @override
  State<SalesPointPage> createState() => _SalesPointPageState();
}

class _SalesPointPageState extends State<SalesPointPage> {
  List<StockItem> allStocks = [];
  List<StockItem> filteredStocks = [];
  bool isLoading = true;
  String searchQuery = "";
  String? selectedCategory;
  String? selectedBrand;
  int itemsPerPage = 10;
  int currentPage = 1;

  int totalSelectedItems = 0;
  double totalSelectedAmount = 0.0;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchStocks();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final cats = allStocks.map((e) => e.category).where((e) => e.isNotEmpty).toSet().toList();
    cats.sort();
    return cats;
  }

  List<String> get _brands {
    final brs = allStocks.map((e) => e.brand).where((e) => e.isNotEmpty).toSet().toList();
    brs.sort();
    return brs;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final bool isMobile = screenWidth < 800;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderCard(),
                            const SizedBox(height: 16),
                            _buildSearchCard(isMobile),
                            const SizedBox(height: 16),
                            _buildFiltersCard(_categories, _brands, isMobile),
                            const SizedBox(height: 24),
                            
                            // Products Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.inventory_2, color: Colors.grey.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Available Products",
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "${filteredStocks.length} Results",
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            filteredStocks.isEmpty
                                ? _buildEmptyState()
                                : _buildProductsGrid(screenWidth, isMobile),
                                
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
