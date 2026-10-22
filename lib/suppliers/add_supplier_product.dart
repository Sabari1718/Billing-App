part of 'Supplier Products.dart';

class AddSupplierProductScreen extends StatefulWidget {
  final String token;
  const AddSupplierProductScreen({super.key, required this.token});

  @override
  State<AddSupplierProductScreen> createState() => _AddSupplierProductScreenState();
}

class _AddSupplierProductScreenState extends State<AddSupplierProductScreen> with AddSupplierProductLogic {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Supplier-Product", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (isSaving)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(
              onPressed: saveSupplierProducts,
              child: const Text("SAVE", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMappingSection(),
            const SizedBox(height: 24),
            const Text("ADDED ITEMS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            _buildAddedItemsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMappingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("PRODUCT MAPPING", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildToggleBtn("PRODUCT"),
              const SizedBox(width: 12),
              _buildToggleBtn("CATEGORY"),
            ],
          ),
          const SizedBox(height: 20),
          _buildSearchField(),
          const SizedBox(height: 20),
          _buildVariantDropdown(),
          const SizedBox(height: 20),
          _buildInputRow("Supplier Product", supplierProductCtrl, hint: "Enter supplier's product name/code"),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            bool isSmall = constraints.maxWidth < 500;
            return Column(
              children: [
                if (isSmall) ...[
                  _buildInputRow("Cost Price", costPriceCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  _buildDropdownRow("Stock Status", selectedStockStatus, ["In Stock", "Out of Stock", "Discontinued", "Order Based"], (val) => setState(() => selectedStockStatus = val)),
                ] else Row(
                  children: [
                    Expanded(child: _buildInputRow("Cost Price", costPriceCtrl, keyboardType: TextInputType.number)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDropdownRow("Stock Status", selectedStockStatus, ["In Stock", "Out of Stock", "Discontinued", "Order Based"], (val) => setState(() => selectedStockStatus = val))),
                  ],
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          _buildLeadTimeSection(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: addItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("ADD", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("LEAD TIME", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        Row(
          children: [
            // Same Day Button
            GestureDetector(
              onTap: () {
                setState(() {
                  isSameDay = !isSameDay;
                  if (isSameDay) {
                    leadDaysCtrl.text = "0";
                    selectedLeadType = "Day";
                  } else {
                    leadDaysCtrl.text = "1";
                  }
                });
                print("LEAD TIME TYPE => $selectedLeadType");
                print("LEAD DAYS => ${leadDaysCtrl.text}");
                print("SAME DAY => $isSameDay");
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSameDay ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSameDay ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  "Same Day",
                  style: TextStyle(
                    color: isSameDay ? Colors.white : const Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Number Input
            Expanded(
              flex: 2,
              child: TextField(
                controller: leadDaysCtrl,
                keyboardType: TextInputType.number,
                enabled: !isSameDay,
                onChanged: (val) {
                  print("LEAD TIME TYPE => $selectedLeadType");
                  print("LEAD DAYS => $val");
                  print("SAME DAY => $isSameDay");
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isSameDay ? const Color(0xFFF1F5F9).withOpacity(0.5) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Dropdown
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedLeadType,
                    isExpanded: true,
                    items: ["Day", "Week", "Month", "Year"].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                    onChanged: isSameDay ? null : (val) {
                      if (val != null) {
                        setState(() => selectedLeadType = val);
                        print("LEAD TIME TYPE => $selectedLeadType");
                        print("LEAD DAYS => ${leadDaysCtrl.text}");
                        print("SAME DAY => $isSameDay");
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownRow(String label, String? value, List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildToggleBtn(String type) {
    bool isSelected = mappingType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => mappingType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(type, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildVariantDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("VARIANT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              isExpanded: true,
              hint: Text(_isLoadingVariants ? "Loading variants..." : "Select Variant"),
              value: selectedVariant,
              items: variants.map((v) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: v,
                  child: Text(v['name'] ?? 'N/A'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => selectedVariant = val);
                console.log("SELECTED VARIANT => \${val?['id']} - \${val?['name']}");
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Search \$mappingType", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        TextField(
          controller: searchCtrl,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: "Enter name...",
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: selectedItem != null ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0))),
          ),
        ),
        if (isSearching) const LinearProgressIndicator(),
        if (searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: searchResults.length,
              itemBuilder: (context, idx) {
                final item = searchResults[idx];
                return ListTile(
                  title: Text(item['name'] ?? item['product_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(item['code'] ?? item['sku'] ?? ''),
                  onTap: () {
                    setState(() {
                      selectedItem = item;
                      searchCtrl.text = item['name'] ?? item['product_name'] ?? 'Unknown';
                      searchResults = [];
                    });
                  },
                );
              },
            ),
          )
        else if (searchCtrl.text.isNotEmpty && !isSearching && searchResults.isEmpty && selectedItem == null)
          const Padding(padding: EdgeInsets.all(12), child: Text("No products found", style: TextStyle(color: Colors.grey))),
      ],
    );
  }

  Widget _buildInputRow(String label, TextEditingController ctrl, {TextInputType keyboardType = TextInputType.text, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAddedItemsList() {
    if (addedItems.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.add_shopping_cart_outlined, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text("No products mapped yet", style: TextStyle(color: Colors.grey.shade400)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: addedItems.length,
      itemBuilder: (context, index) {
        final item = addedItems[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF4F46E5), size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text("Variant: \${item['variant_name']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          Text("Supplier Ref: \${item['supplier_product']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => removeItem(index), icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _itemSummaryItem("COST PRICE", "₹\${item['cost_price']}"),
                    _itemSummaryItem("STOCK", item['stock_status']),
                    _itemSummaryItem("LEAD TIME", "\${item['lead_days']} Days"),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _itemSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
      ],
    );
  }
}
