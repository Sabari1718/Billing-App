part of 'stock entry.dart';

extension _StockEntryPageStateDialogs on _StockEntryPageState {
  // --- SPECIFY VARIANT DETAILS POPUP ---
  void openVariantPopup() {
    if (variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("No variants available. Please wait for loading."),
      ));
      return;
    }

    final selectedProdObj = products.firstWhere(
      (e) => e['id'].toString() == selectedProduct,
      orElse: () => null,
    );
    final String prodName = selectedProdObj != null
        ? (selectedProdObj['product_name'] ?? selectedProdObj['name'] ?? 'Product')
        : 'Product';

    // Prefill controller values from variantTabData
    for (var v in variants) {
      int id = int.tryParse(v['id'].toString()) ?? 0;
      var data = variantTabData[id] ?? {'qty': '', 'buying': '', 'profit': '', 'selling': ''};
      qtyCtrls[id] ??= TextEditingController(text: data['qty'] ?? '');
      priceCtrls[id] ??= TextEditingController(text: data['buying'] ?? '');
      profitCtrls[id] ??= TextEditingController(text: data['profit'] ?? '');
    }

    int? expandedVariantId = variants.isNotEmpty ? (int.tryParse(variants.first['id'].toString()) ?? 0) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Recalculate totals dynamically
            int totalQty = 0;
            double totalValue = 0.0;
            for (var v in variants) {
              int id = int.tryParse(v['id'].toString()) ?? 0;
              int q = int.tryParse(qtyCtrls[id]?.text ?? '') ?? 0;
              double p = double.tryParse(priceCtrls[id]?.text ?? '') ?? 0.0;
              totalQty += q;
              totalValue += (q * p);
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.95,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Title Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_cart_outlined, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        const Text("Variant Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF), // soft blue tint
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.widgets_outlined, color: Color(0xFF2563EB), size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("PRODUCT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                      const SizedBox(height: 2),
                                      Text(
                                        prodName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text("MRP ₹499.00", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text("$totalQty", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                          const Text("TOTAL QTY", style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      Container(width: 1, height: 24, color: Colors.grey.shade200),
                                      const SizedBox(width: 8),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text("₹${totalValue.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                          const Text("TOTAL VALUE", style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Heading
                          const Text(
                            "SELECT VARIANT & ENTER DETAILS",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 12),

                          // Accordions
                          Column(
                            children: variants.map((v) {
                              int id = int.tryParse(v['id'].toString()) ?? 0;
                              bool isExpanded = expandedVariantId == id;

                              int qVal = int.tryParse(qtyCtrls[id]?.text ?? '') ?? 0;
                              double pVal = double.tryParse(priceCtrls[id]?.text ?? '') ?? 0.0;
                              double marginVal = double.tryParse(profitCtrls[id]?.text ?? '') ?? 0.0;

                              double purchaseVal = qVal * pVal;
                              double sellingPerQty = pVal + marginVal;
                              double totalSellingVal = qVal * sellingPerQty;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isExpanded ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setModalState(() {
                                          expandedVariantId = isExpanded ? null : id;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        child: Row(
                                          children: [
                                            Icon(
                                              (qVal > 0 && pVal > 0.0) ? Icons.check_circle : Icons.circle_outlined,
                                              color: (qVal > 0 && pVal > 0.0) ? Colors.green : Colors.grey.shade300,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  v['name'] ?? "Variant $id",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: isExpanded ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                                                  ),
                                                ),
                                                if (qtyCtrls[id]!.text.isNotEmpty || priceCtrls[id]!.text.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "Qty: ${qtyCtrls[id]!.text.isEmpty ? '0' : qtyCtrls[id]!.text}  Unit Price: ₹${priceCtrls[id]!.text.isEmpty ? '0.00' : priceCtrls[id]!.text}",
                                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const Spacer(),
                                            Icon(
                                              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                              color: isExpanded ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isExpanded) ...[
                                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // TOTAL QTY
                                            const Text("TOTAL QTY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                            const SizedBox(height: 6),
                                            TextField(
                                              controller: qtyCtrls[id],
                                              keyboardType: TextInputType.number,
                                              onChanged: (val) {
                                                setModalState(() {});
                                              },
                                              decoration: InputDecoration(
                                                hintText: "0",
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: BorderSide(color: qVal <= 0 ? Colors.red.shade300 : Colors.grey.shade300),
                                                ),
                                              ),
                                            ),
                                            if (qtyCtrls[id]!.text.isEmpty || qVal <= 0) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: const [
                                                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 12),
                                                  SizedBox(width: 4),
                                                  Text("Total Qty must be greater than 0", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w500)),
                                                ],
                                              ),
                                            ],
                                            const SizedBox(height: 16),

                                            // PER QTY PRICE
                                            const Text("PER QTY PRICE (₹)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                            const SizedBox(height: 6),
                                            TextField(
                                              controller: priceCtrls[id],
                                              keyboardType: TextInputType.number,
                                              onChanged: (val) {
                                                setModalState(() {});
                                              },
                                              decoration: InputDecoration(
                                                hintText: "0.00",
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: BorderSide(color: pVal <= 0.0 ? Colors.red.shade300 : Colors.grey.shade300),
                                                ),
                                              ),
                                            ),
                                            if (priceCtrls[id]!.text.isEmpty || pVal <= 0.0) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: const [
                                                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 12),
                                                  SizedBox(width: 4),
                                                  Text("Per Qty Price must be greater than 0", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w500)),
                                                ],
                                              ),
                                            ],
                                            const SizedBox(height: 16),

                                            // PURCHASE VALUE
                                            const Text("PURCHASE VALUE (₹)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                            const SizedBox(height: 6),
                                            TextField(
                                              controller: purchaseValueCtrls.putIfAbsent(id, () => TextEditingController())..text = purchaseVal.toStringAsFixed(2),
                                              readOnly: true,
                                              decoration: InputDecoration(
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                filled: true,
                                                fillColor: const Color(0xFFF1F5F9),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                            const SizedBox(height: 16),

                                            // PROFIT MARGIN
                                            const Text("PROFIT MARGIN (₹)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                            const SizedBox(height: 6),
                                            TextField(
                                              controller: profitCtrls[id],
                                              keyboardType: TextInputType.number,
                                              onChanged: (val) {
                                                setModalState(() {});
                                              },
                                              decoration: InputDecoration(
                                                hintText: "0.00",
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                            const SizedBox(height: 16),

                                            // SELLING PRICE PER QTY
                                            const Text("SELLING PRICE PER QTY (₹)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                            const SizedBox(height: 6),
                                            TextField(
                                              controller: sellingPerQtyCtrls.putIfAbsent(id, () => TextEditingController())..text = sellingPerQty.toStringAsFixed(2),
                                              readOnly: true,
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                              decoration: InputDecoration(
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                filled: true,
                                                fillColor: const Color(0xFFF1F5F9),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                            const SizedBox(height: 16),

                                            // TOTAL SELLING VALUE
                                            const Text("TOTAL SELLING VALUE (₹)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                            const SizedBox(height: 6),
                                            TextField(
                                              controller: totalSellingValCtrls.putIfAbsent(id, () => TextEditingController())..text = totalSellingVal.toStringAsFixed(2),
                                              readOnly: true,
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                              decoration: InputDecoration(
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                filled: true,
                                                fillColor: const Color(0xFFF8FAFC),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Confirm & Save Sticky Bar
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          for (var v in variants) {
                            int id = int.tryParse(v['id'].toString()) ?? 0;
                            final qText = qtyCtrls[id]?.text.trim() ?? '';
                            final pText = priceCtrls[id]?.text.trim() ?? '';
                            final profitText = profitCtrls[id]?.text.trim() ?? '';

                            double buy = double.tryParse(pText) ?? 0.0;
                            double margin = double.tryParse(profitText) ?? 0.0;
                            String sellStr = (buy + margin).toStringAsFixed(2);

                            variantTabData[id] = {
                              'qty': qText,
                              'buying': pText,
                              'profit': profitText,
                              'selling': sellStr,
                            };
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text("Confirm & Save", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- SPECIFY PRICE DETAILS POPUP (WITHOUT VARIANT MODE) ---
  void openPriceDetailsPopup() {
    variantTabData[0] ??= {'qty': '', 'buying': '', 'profit': '', 'selling': ''};

    // Prefill controllers for ID 0
    qtyCtrls[0] ??= TextEditingController(text: variantTabData[0]?['qty'] ?? qtyController.text);
    priceCtrls[0] ??= TextEditingController(text: variantTabData[0]?['buying'] ?? '');
    profitCtrls[0] ??= TextEditingController(text: variantTabData[0]?['profit'] ?? '');

    final selectedProdObj = products.firstWhere(
      (e) => e['id'].toString() == selectedProduct,
      orElse: () => null,
    );
    final String prodName = selectedProdObj != null
        ? (selectedProdObj['product_name'] ?? selectedProdObj['name'] ?? 'Product')
        : 'Product';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            int qVal = int.tryParse(qtyCtrls[0]?.text ?? '') ?? 0;
            double pVal = double.tryParse(priceCtrls[0]?.text ?? '') ?? 0.0;
            double marginVal = double.tryParse(profitCtrls[0]?.text ?? '') ?? 0.0;

            double purchaseVal = qVal * pVal;
            double sellingPerQty = pVal + marginVal;
            double totalSellingVal = qVal * sellingPerQty;

            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Title Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.currency_rupee, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        const Text("Price Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.widgets_outlined, color: Color(0xFF2563EB), size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("PRODUCT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                      const SizedBox(height: 2),
                                      Text(
                                        prodName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Form
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // TOTAL QTY
                                const Text("TOTAL QTY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: qtyCtrls[0],
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    setModalState(() {});
                                  },
                                  decoration: InputDecoration(
                                    hintText: "0",
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: qVal <= 0 ? Colors.red.shade300 : Colors.grey.shade300),
                                    ),
                                  ),
                                ),
                                if (qtyCtrls[0]!.text.isEmpty || qVal <= 0) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: const [
                                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 12),
                                      SizedBox(width: 4),
                                      Text("Total Qty must be greater than 0", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 16),

                                // PER QTY PRICE
                                const Text("PER QTY PRICE (₹)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: priceCtrls[0],
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    setModalState(() {});
                                  },
                                  decoration: InputDecoration(
                                    hintText: "0.00",
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: pVal <= 0.0 ? Colors.red.shade300 : Colors.grey.shade300),
                                    ),
                                  ),
                                ),
                                if (priceCtrls[0]!.text.isEmpty || pVal <= 0.0) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: const [
                                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 12),
                                      SizedBox(width: 4),
                                      Text("Per Qty Price must be greater than 0", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 16),

                                // PURCHASE VALUE
                                const Text("PURCHASE VALUE (₹)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: purchaseValueCtrls.putIfAbsent(0, () => TextEditingController())..text = purchaseVal.toStringAsFixed(2),
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    filled: true,
                                    fillColor: const Color(0xFFF1F5F9),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // PROFIT MARGIN
                                const Text("PROFIT MARGIN (₹)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: profitCtrls[0],
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    setModalState(() {});
                                  },
                                  decoration: InputDecoration(
                                    hintText: "0.00",
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // SELLING PRICE PER QTY
                                const Text("SELLING PRICE PER QTY (₹)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: sellingPerQtyCtrls.putIfAbsent(0, () => TextEditingController())..text = sellingPerQty.toStringAsFixed(2),
                                  readOnly: true,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    filled: true,
                                    fillColor: const Color(0xFFF1F5F9),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // TOTAL SELLING VALUE
                                const Text("TOTAL SELLING VALUE (₹)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: totalSellingValCtrls.putIfAbsent(0, () => TextEditingController())..text = totalSellingVal.toStringAsFixed(2),
                                  readOnly: true,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Confirm & Save Sticky Bar
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          variantTabData[0] = {
                            'qty': qtyCtrls[0]?.text.trim() ?? '',
                            'buying': priceCtrls[0]?.text.trim() ?? '',
                            'profit': profitCtrls[0]?.text.trim() ?? '',
                            'selling': sellingPerQty.toStringAsFixed(2),
                          };
                          // Sync main qtyController
                          qtyController.text = qtyCtrls[0]?.text.trim() ?? '';
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text("Confirm & Save", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoBox(String title, String value, {Color? color}) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
      ],
    );
  }

  void openStockPopup() {
    if (stockTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("No stock types available. Please wait for loading."),
      ));
      return;
    }

    final selectedProdObj = products.firstWhere(
      (e) => e['id'].toString() == selectedProduct,
      orElse: () => null,
    );
    final String prodName = selectedProdObj != null
        ? (selectedProdObj['product_name'] ?? selectedProdObj['name'] ?? 'Product')
        : 'Product';

    final List<Map<String, dynamic>> activeItems = [];
    if (withVariantMode) {
      for (var v in variants) {
        int id = int.tryParse(v['id'].toString()) ?? 0;
        int qty = int.tryParse(qtyCtrls[id]?.text ?? '') ?? 0;
        if (qty > 0) {
          activeItems.add({
            'id': id,
            'name': v['name'] ?? "Variant $id",
            'qty': qty,
          });
        }
      }
    } else {
      int qty = int.tryParse(qtyController.text) ?? 0;
      if (qty > 0) {
        activeItems.add({
          'id': 0,
          'name': prodName,
          'qty': qty,
        });
      }
    }

    if (activeItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please enter quantity in Variant/Price details first."),
      ));
      return;
    }

    final Map<int, Map<int, TextEditingController>> tempControllers = {};
    for (var item in activeItems) {
      int itemId = item['id'];
      tempControllers[itemId] = {};
      
      List<dynamic> existingDist = stockTabData[itemId] ?? [];
      for (var st in stockTypes) {
        int stId = int.tryParse(st['id'].toString()) ?? 0;
        var matching = existingDist.firstWhere((element) => int.tryParse(element['stock_type_id'].toString()) == stId, orElse: () => null);
        String qtyText = matching != null ? matching['qty'].toString() : '';
        tempControllers[itemId]![stId] = TextEditingController(text: qtyText);
      }
    }

    int? expandedItemId = activeItems.isNotEmpty ? activeItems.first['id'] : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.95,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        const Text("Stock Distribution", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "DISTRIBUTE QUANTITY TO STOCK TYPES",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 12),

                          Column(
                            children: activeItems.map((item) {
                              int itemId = item['id'];
                              int limitQty = item['qty'];
                              bool isExpanded = expandedItemId == itemId;

                              int distributedSum = 0;
                              tempControllers[itemId]?.forEach((stId, ctrl) {
                                distributedSum += int.tryParse(ctrl.text) ?? 0;
                              });

                              bool isValid = distributedSum == limitQty;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isExpanded ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setModalState(() {
                                          expandedItemId = isExpanded ? null : itemId;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isValid ? Icons.check_circle : Icons.circle_outlined,
                                              color: isValid ? Colors.green : Colors.orange,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['name'],
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: isExpanded ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "Allocated: $distributedSum / $limitQty",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: isValid ? Colors.green : Colors.orange,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                              color: isExpanded ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isExpanded) ...[
                                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: stockTypes.map((st) {
                                            int stId = int.tryParse(st['id'].toString()) ?? 0;
                                            String stName = st['name'] ?? "Stock Type";
                                            final ctrl = tempControllers[itemId]![stId]!;
                                            
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 12),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    flex: 3,
                                                    child: Text(
                                                      stName,
                                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    flex: 2,
                                                    child: SizedBox(
                                                      height: 40,
                                                      child: TextField(
                                                        controller: ctrl,
                                                        keyboardType: TextInputType.number,
                                                        onChanged: (val) {
                                                          setModalState(() {});
                                                        },
                                                        decoration: InputDecoration(
                                                          hintText: "0",
                                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          bool allValid = true;
                          for (var item in activeItems) {
                            int itemId = item['id'];
                            int limitQty = item['qty'];
                            int distributedSum = 0;
                            tempControllers[itemId]?.forEach((stId, ctrl) {
                              distributedSum += int.tryParse(ctrl.text) ?? 0;
                            });
                            if (distributedSum != limitQty) {
                              allValid = false;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text("Distribution for ${item['name']} must equal $limitQty"),
                                backgroundColor: Colors.redAccent,
                              ));
                              break;
                            }
                          }

                          if (allValid) {
                            setState(() {
                              for (var item in activeItems) {
                                int itemId = item['id'];
                                final List<Map<String, dynamic>> distList = [];
                                tempControllers[itemId]?.forEach((stId, ctrl) {
                                  int q = int.tryParse(ctrl.text) ?? 0;
                                  if (q > 0) {
                                    distList.add({
                                      "stock_type_id": stId,
                                      "qty": q,
                                    });
                                  }
                                });
                                stockTabData[itemId] = distList;
                              }
                            });
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text("Confirm & Save", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
