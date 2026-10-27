part of 'add product.dart';

extension _ProductEntryPageStateWidgets on _ProductEntryPageState {
  Widget _buildScanSetupArea() {
    final bool isQR = !_isBarcodeMode;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title & QR/Barcode Toggle
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Text(
                "Product Scan Setup",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildScanTypeButton("QR Code", isQR),
                    _buildScanTypeButton("Barcode", !isQR),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Viewfinder & Input Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 550;

              final viewfinder = GestureDetector(
                onTap: _openCameraScanner,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0F19),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Red scan laser line
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(seconds: 2),
                          builder: (context, value, child) {
                            final offset = (value - 0.5).abs() * 2 * 70;
                            return Positioned(
                              top: 25 + offset,
                              left: 20,
                              right: 20,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.redAccent.withOpacity(0.8),
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Corner brackets
                        _cornerBracket(top: 12, left: 12, isTop: true, isLeft: true),
                        _cornerBracket(top: 12, right: 12, isTop: true, isLeft: false),
                        _cornerBracket(bottom: 12, left: 12, isTop: false, isLeft: true),
                        _cornerBracket(bottom: 12, right: 12, isTop: false, isLeft: false),

                        // Center Icon (QR Code or Barcode)
                        if (isQR)
                          const Center(
                            child: Icon(
                              Icons.qr_code_2_rounded,
                              size: 48,
                              color: Color(0xFF38BDF8),
                            ),
                          )
                        else
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                8,
                                (index) => Container(
                                  width: index % 2 == 0 ? 5 : 3,
                                  height: 44,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  color: const Color(0xFF38BDF8),
                                ),
                              ),
                            ),
                          ),

                        // Bottom status text
                        Positioned(
                          bottom: 12,
                          child: Text(
                            isQR ? "Detecting QR CODE..." : "Detecting BAR CODE...",
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              final inputArea = Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Scan/Type Code Manually",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (constraints.maxWidth < 360) ...[
                      SizedBox(
                        height: 40,
                        child: TextField(
                          controller: barcodeController,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: isQR ? "Enter QR Code..." : "Enter Barcode...",
                            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 38,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _triggerSimulateScan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Simulate Scan",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: TextField(
                                controller: barcodeController,
                                style: GoogleFonts.inter(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: isQR ? "Enter QR Code..." : "Enter Barcode...",
                                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: _triggerSimulateScan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                "Simulate Scan",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );

              if (isSmall) {
                return Column(
                  children: [
                    viewfinder,
                    const SizedBox(height: 12),
                    inputArea,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 4, child: viewfinder),
                  const SizedBox(width: 16),
                  Expanded(flex: 6, child: inputArea),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _cornerBracket({double? top, double? bottom, double? left, double? right, required bool isTop, required bool isLeft}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: Color(0xFF38BDF8), width: 2.5) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: Color(0xFF38BDF8), width: 2.5) : BorderSide.none,
            left: isLeft ? const BorderSide(color: Color(0xFF38BDF8), width: 2.5) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: Color(0xFF38BDF8), width: 2.5) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  void _openCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String query = "";
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = query.trim().isEmpty
                ? categoryItems
                : categoryItems.where((c) {
                    final name = (c['name']?.toString() ?? "").toLowerCase();
                    final code = (c['code']?.toString() ?? "").toLowerCase();
                    final parent = (c['parent_name']?.toString() ?? "").toLowerCase();
                    final q = query.trim().toLowerCase();
                    return name.contains(q) || code.contains(q) || parent.contains(q);
                  }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.category_outlined, color: Color(0xFF2563EB), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          "Select Category",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                          ),
                          child: Text(
                            "${filtered.length} categories",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      autofocus: false,
                      onChanged: (val) {
                        setModalState(() {
                          query = val;
                        });
                      },
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Search category (e.g. Adapter, Mobile, Sensor)...",
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB), size: 20),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setModalState(() {
                                    query = "";
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 16),
                  // Category List
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    "No categories found for \"$query\"",
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, index) => Divider(height: 1, color: Colors.grey.shade100),
                            itemBuilder: (context, index) {
                              final cat = filtered[index];
                              final int cId = cat['id'] as int;
                              final String cName = cat['name']?.toString() ?? "No Name";
                              final String cCode = cat['code']?.toString() ?? "";
                              final bool isPrimary = cat['is_primary'] == true;
                              final String parentName = (cat['parent_name'] ?? "").toString().trim();
                              final bool isSelected = selectedCategoryId == cId;

                              return Padding(
                                padding: EdgeInsets.only(left: isPrimary ? 0 : 20.0),
                                child: ListTile(
                                  dense: true,
                                  selected: isSelected,
                                  selectedTileColor: const Color(0xFFEFF6FF),
                                  leading: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : (isPrimary ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      isPrimary ? Icons.folder_outlined : Icons.subdirectory_arrow_right_rounded,
                                      size: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : (isPrimary ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          cName,
                                          style: GoogleFonts.inter(
                                            fontSize: isPrimary ? 13.5 : 13,
                                            fontWeight: isPrimary
                                                ? FontWeight.w700
                                                : (isSelected ? FontWeight.w600 : FontWeight.w500),
                                            color: isSelected
                                                ? const Color(0xFF2563EB)
                                                : (isPrimary ? const Color(0xFF0F172A) : const Color(0xFF334155)),
                                          ),
                                        ),
                                      ),
                                      if (isPrimary)
                                        Container(
                                          margin: const EdgeInsets.only(left: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFFBFDBFE)),
                                          ),
                                          child: Text(
                                            "Primary",
                                            style: GoogleFonts.inter(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF2563EB),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: (!isPrimary && parentName.isNotEmpty)
                                      ? Text(
                                          "Sub-category of $parentName",
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        )
                                      : (cCode.isNotEmpty
                                          ? Text(
                                              cCode,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: const Color(0xFF94A3B8),
                                              ),
                                            )
                                          : null),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 20)
                                      : const Icon(Icons.chevron_right, size: 18, color: Color(0xFFCBD5E1)),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    onCategorySelected(cId);
                                  },
                                ),
                              );
                            },
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

  Widget _buildDropdownsFormArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Store Information Card
        if (currentStore != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.storefront_outlined, color: Color(0xFF10B981), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            currentStore!['store_name']?.toString() ?? "Store",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (currentStore!['status'] == "Active")
                                  ? const Color(0xFFDCFCE7)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              currentStore!['status']?.toString() ?? "Active",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: (currentStore!['status'] == "Active")
                                      ? const Color(0xFF166534)
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFDBEAFE)),
                            ),
                            child: Text(
                              hierarchyMode.replaceAll('_', ' ').toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (currentStore!['address'] != null && currentStore!['address'].toString().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          currentStore!['address'].toString(),
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Permission Notice (if read-only)
        if (!canCreateProduct && !isOwner) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: Color(0xFFB45309), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Read-only mode: You do not have permission to add new products.",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF92400E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Row 1: CATEGORY, BRAND, PRODUCT (Matching Web Layout)
        LayoutBuilder(
          builder: (context, constraints) {
            final selectedCatObj = (selectedCategoryId != null)
                ? categoryItems.firstWhere((e) => e['id'] == selectedCategoryId, orElse: () => {})
                : null;
            final selectedCatName = selectedCatObj?['name']?.toString();

            final categoryField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "CATEGORY",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF475569),
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (selectedCategoryId != null)
                      InkWell(
                        onTap: clearCategory,
                        child: Text(
                          "clear category",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _openCategoryPicker,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedCategoryId != null ? const Color(0xFF2563EB) : Colors.grey.shade300,
                        width: selectedCategoryId != null ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedCatName ?? "Select Category",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: selectedCatName != null ? FontWeight.w600 : FontWeight.normal,
                              color: selectedCatName != null ? const Color(0xFF0F172A) : Colors.grey.shade400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (selectedCategoryId != null)
                          InkWell(
                            onTap: clearCategory,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.close, size: 16, color: Colors.grey),
                            ),
                          ),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            );

            final brandField = buildField(
              "BRAND",
              DropdownButtonFormField<int>(
                key: ValueKey("brand_${selectedCategoryId}_$selectedBrandId"),
                value: (selectedBrandId != null && brands.any((e) => e['id'] == selectedBrandId))
                    ? selectedBrandId
                    : null,
                isExpanded: true,
                decoration: _dropdownDecoration().copyWith(
                  suffixIcon: selectedBrandId != null
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                          onPressed: () => onBrandSelected(null),
                        )
                      : null,
                ),
                hint: Text(
                  selectedCategoryId == null
                      ? "Select Category First"
                      : (brands.isEmpty ? "No Brands Available" : "Select Brand"),
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
                ),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                items: brands.map((e) {
                  return DropdownMenuItem<int>(
                    value: e['id'] as int,
                    child: Text(
                      e['name']?.toString() ?? "No Name",
                      style: GoogleFonts.inter(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (selectedCategoryId == null || brands.isEmpty)
                    ? null
                    : onBrandSelected,
              ),
            );

            final productField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildField(
                  "PRODUCT",
                  DropdownButtonFormField<int>(
                    key: ValueKey("prod_${selectedBrandId}_$selectedProductId"),
                    value: (selectedProductId != null && products.any((e) => e['id'] == selectedProductId))
                        ? selectedProductId
                        : null,
                    isExpanded: true,
                    decoration: _dropdownDecoration().copyWith(
                      suffixIcon: selectedProductId != null
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  selectedProductId = null;
                                  selectedProductName = null;
                                  selectedProductMrp = null;
                                  selectedProductCode = null;
                                });
                              },
                            )
                          : null,
                    ),
                    hint: Text(
                      selectedBrandId == null
                          ? "Select Brand First"
                          : (products.isEmpty ? "No Products Available" : "Select Product"),
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    items: products.map((e) {
                      return DropdownMenuItem<int>(
                        value: e['id'] as int,
                        child: Text(
                          e['product_name']?.toString() ?? e['name']?.toString() ?? "No Product",
                          style: GoogleFonts.inter(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (selectedBrandId == null || products.isEmpty)
                        ? null
                        : (val) {
                            final p = products.firstWhere((e) => e['id'] == val, orElse: () => {});
                            setState(() {
                              selectedProductId = val;
                              selectedProductName = p['product_name'] ?? p['name'];
                              selectedProductMrp = p['mrp']?.toString();
                              selectedProductCode = p['code']?.toString();
                            });
                          },
                  ),
                ),
                if (selectedProductId != null &&
                    ((selectedProductMrp != null && selectedProductMrp!.isNotEmpty) ||
                     (selectedProductCode != null && selectedProductCode!.isNotEmpty))) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (selectedProductMrp != null && selectedProductMrp!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Text(
                            "MRP: ₹$selectedProductMrp",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF166534),
                            ),
                          ),
                        ),
                      if (selectedProductCode != null && selectedProductCode!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            "Code: $selectedProductCode",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            );

            if (constraints.maxWidth >= 700) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: categoryField),
                  const SizedBox(width: 16),
                  Expanded(child: brandField),
                  const SizedBox(width: 16),
                  Expanded(child: productField),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  categoryField,
                  const SizedBox(height: 16),
                  brandField,
                  const SizedBox(height: 16),
                  productField,
                ],
              );
            }
          },
        ),

        const SizedBox(height: 20),

        // Row 2: MIN QTY, MAX QTY
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 650;

            final minField = buildField(
              "MIN QTY",
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    if ((int.tryParse(minQtyController.text) ?? 0) > 0)
                      InkWell(
                        onTap: decrementMinQty,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.remove, size: 16, color: Color(0xFF64748B)),
                        ),
                      ),
                    Expanded(
                      child: TextFormField(
                        controller: minQtyController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter Minimum Quantity",
                          hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: incrementMinQty,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.add, size: 16, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            );

            final maxField = buildField(
              "MAX QTY",
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    if ((int.tryParse(maxQtyController.text) ?? 0) > 0)
                      InkWell(
                        onTap: decrementMaxQty,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.remove, size: 16, color: Color(0xFF64748B)),
                        ),
                      ),
                    Expanded(
                      child: TextFormField(
                        controller: maxQtyController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter Maximum Quantity",
                          hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: incrementMaxQty,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.add, size: 16, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            );

            if (isNarrow) {
              return Column(
                children: [
                  minField,
                  const SizedBox(height: 16),
                  maxField,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: minField),
                const SizedBox(width: 16),
                Expanded(child: maxField),
                const SizedBox(width: 16),
                const Expanded(child: SizedBox()), // spacer to match 3 cols alignment
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildModeButton(String text, bool isActive, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isScanMode = text == "Scanner";
          if (!_isScanMode) {
            _autofilledText = null;
            barcodeController.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? const Color(0xFF2563EB) : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isActive ? const Color(0xFF2563EB) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanTypeButton(String text, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isBarcodeMode = text == "Barcode";
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              text == "QR Code" ? Icons.qr_code_2 : Icons.bar_chart,
              size: 14,
              color: isActive ? const Color(0xFF0F172A) : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? const Color(0xFF0F172A) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildField(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF475569),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }
}
