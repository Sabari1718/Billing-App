import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';

part 'supplier_products_logic.dart';
part 'add_supplier_product.dart';
part 'add_supplier_product_logic.dart';

// Shim to support console.log/error
class _Console {
  void log(Object? message) => debugPrint(message?.toString());
  void error(Object? message) => debugPrint("ERROR: \${message?.toString()}");
}
final console = _Console();

class SupplierProductsPage extends StatefulWidget {
  final String token;

  const SupplierProductsPage({super.key, required this.token});

  @override
  State<SupplierProductsPage> createState() => _SupplierProductsPageState();
}

class _SupplierProductsPageState extends State<SupplierProductsPage> with SupplierProductsLogic {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchAndFilters(),
          Expanded(child: _buildProductList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Supplier Products",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Text(
            "Manage and map products to your suppliers efficiently.",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildTabButton("ALL"),
              const SizedBox(width: 8),
              _buildTabButton("PERSONAL"),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddSupplierProductScreen(token: widget.token))),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("ADD NEW PRODUCT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab) {
    bool isSelected = selectedTab == tab;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() => selectedTab = tab);
          fetchSupplierProducts();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade300),
        ),
        child: Text(
          tab,
          style: TextStyle(
            color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: "Search products...",
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: isSearching ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2))) : null,
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown("All Categories", ["All Categories"]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStockDropdown(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String value, List<String> items) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: (val) {},
      ),
    );
  }

  Widget _buildStockDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: selectedStock,
        isExpanded: true,
        underline: const SizedBox(),
        items: ["All Stock Levels", "In Stock", "Low Stock", "Out of Stock", "Order Based"]
            .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
            .toList(),
        onChanged: (val) {
          if (val != null) filterByStock(val);
        },
      ),
    );
  }

  Widget _buildProductList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text("No products found", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          ],
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 800) {
        return _buildDesktopTable();
      } else {
        return _buildMobileList();
      }
    });
  }

  Widget _buildMobileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final item = products[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(item['product_name']?.toString() ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    _buildStatusBadge(item['status']?.toString() ?? 'Pending'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(item['supplier_name']?.toString() ?? 'Unknown Supplier', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("UNIT PRICE", style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                        Text("₹\${item['unit_price']?.toString() ?? '0'}", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("DAYS", style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                        Text("\${item['days'] ?? '0'} Days", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
          columns: const [
            DataColumn(label: Text("PRODUCT NAME", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("SUPPLIER", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("UNIT PRICE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("STATUS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("DAYS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("ACTIONS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          ],
          rows: products.map((item) {
            return DataRow(cells: [
              DataCell(Text(item['product_name']?.toString() ?? 'N/A')),
              DataCell(Text(item['supplier_name']?.toString() ?? 'N/A')),
              DataCell(Text("₹\${item['unit_price']?.toString() ?? '0'}")),
              DataCell(_buildStatusBadge(item['status']?.toString() ?? 'Pending')),
              DataCell(Text("\${item['days'] ?? '0'} Days")),
              DataCell(Row(children: [IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () {}), IconButton(icon: const Icon(Icons.delete, size: 18), onPressed: () {})])),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    String s = status.toLowerCase();
    Color color = Colors.orange; // Default Pending
    
    if (s == "verified" || s == "in_stock" || s == "in stock") {
      color = Colors.green;
    } else if (s == "out_of_stock" || s == "out of stock") {
      color = Colors.red;
    } else if (s == "order_based" || s == "order based") {
      color = Colors.indigo;
    } else if (s == "discontinued") {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}