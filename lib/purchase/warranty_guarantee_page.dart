import 'package:billingapp/Auth/api service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class WarrantyGuaranteePage extends StatefulWidget {
  const WarrantyGuaranteePage({super.key});

  @override
  State<WarrantyGuaranteePage> createState() => _WarrantyGuaranteePageState();
}

class _WarrantyEntry {
  final int id;
  int productId;
  final String type; // 'Warranty' or 'Guarantee'
  String productName;
  String productCode;
  String category;
  String brand;
  String variant;
  String warrantyType; // Manufacturer Warranty, Seller Warranty, Money Back Guarantee, etc.
  int periodValue;
  String periodUnit; // Months, Years, Days
  DateTime startDate;
  DateTime endDate;
  String status; // Active, Inactive, Expired
  String description;
  String createdOn;

  _WarrantyEntry({
    required this.id,
    this.productId = 0,
    required this.type,
    required this.productName,
    required this.productCode,
    required this.category,
    required this.brand,
    required this.variant,
    required this.warrantyType,
    required this.periodValue,
    required this.periodUnit,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.description,
    required this.createdOn,
  });

  String get periodDisplay => "$periodValue $periodUnit";

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'type': type,
    'productName': productName,
    'productCode': productCode,
    'category': category,
    'brand': brand,
    'variant': variant,
    'warrantyType': warrantyType,
    'periodValue': periodValue,
    'periodUnit': periodUnit,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'status': status,
    'description': description,
    'createdOn': createdOn,
  };

  factory _WarrantyEntry.fromJson(Map<String, dynamic> json) => _WarrantyEntry(
    id: json['id'] as int? ?? 0,
    productId: json['productId'] as int? ?? json['product_id'] as int? ?? 0,
    type: json['type'] as String? ?? 'Warranty',
    productName: json['productName'] as String? ?? '',
    productCode: json['productCode'] as String? ?? 'PRO-0001',
    category: json['category'] as String? ?? 'General',
    brand: json['brand'] as String? ?? 'Imported',
    variant: json['variant'] as String? ?? 'Standard',
    warrantyType: json['warrantyType'] as String? ?? 'Manufacturer Warranty',
    periodValue: json['periodValue'] as int? ?? 6,
    periodUnit: json['periodUnit'] as String? ?? 'Months',
    startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate']) ?? DateTime.now() : DateTime.now(),
    endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) ?? DateTime.now().add(const Duration(days: 180)) : DateTime.now().add(const Duration(days: 180)),
    status: json['status'] as String? ?? 'Active',
    description: json['description'] as String? ?? '',
    createdOn: json['createdOn'] as String? ?? '04/08/2026',
  );

  factory _WarrantyEntry.fromApi(Map<String, dynamic> json) {
    final rawStartDate = json['start_date']?.toString();
    final rawEndDate = json['end_date']?.toString();
    final rawCreatedAt = json['created_at']?.toString();

    DateTime sDate = DateTime.now();
    if (rawStartDate != null && rawStartDate.isNotEmpty) {
      sDate = DateTime.tryParse(rawStartDate) ?? sDate;
    }

    DateTime eDate = sDate.add(const Duration(days: 180));
    if (rawEndDate != null && rawEndDate.isNotEmpty) {
      eDate = DateTime.tryParse(rawEndDate) ?? eDate;
    }

    String createdOnStr = "04/08/2026";
    if (rawCreatedAt != null && rawCreatedAt.isNotEmpty) {
      try {
        final parsed = DateTime.tryParse(rawCreatedAt.replaceAll(" ", "T"));
        if (parsed != null) {
          createdOnStr = DateFormat('dd/MM/yyyy').format(parsed);
        } else {
          createdOnStr = rawCreatedAt;
        }
      } catch (_) {
        createdOnStr = rawCreatedAt;
      }
    } else if (rawStartDate != null) {
      try {
        final parsed = DateTime.tryParse(rawStartDate);
        if (parsed != null) {
          createdOnStr = DateFormat('dd/MM/yyyy').format(parsed);
        }
      } catch (_) {}
    }

    final periodVal = int.tryParse(
      json['warranty_period']?.toString() ??
      json['guarantee_period']?.toString() ??
      json['periodValue']?.toString() ??
      '1'
    ) ?? 1;

    final periodUnitStr = json['warranty_unit']?.toString() ??
      json['guarantee_unit']?.toString() ??
      json['periodUnit']?.toString() ??
      'Years';

    final isGuarantee = json['item_type']?.toString().toLowerCase() == 'guarantee' ||
        json.containsKey('guarantee_period') ||
        json.containsKey('guarantee_type');

    final wType = json['warranty_type']?.toString() ??
      json['guarantee_type']?.toString() ??
      json['warrantyType']?.toString() ??
      (isGuarantee ? 'Replacement Guarantee' : 'Manufacturer Warranty');

    return _WarrantyEntry(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      type: isGuarantee ? 'Guarantee' : (json['item_type']?.toString() ?? json['type']?.toString() ?? 'Warranty'),
      productName: json['product_name']?.toString() ?? json['productName']?.toString() ?? '',
      productCode: json['product_code']?.toString() ?? json['productCode']?.toString() ?? 'PRD-0000',
      category: json['category_name']?.toString() ?? json['category']?.toString() ?? 'General',
      brand: json['brand_name']?.toString() ?? json['brand']?.toString() ?? 'Imported',
      variant: json['variant_name']?.toString() ?? json['variant']?.toString() ?? 'Standard',
      warrantyType: wType,
      periodValue: periodVal,
      periodUnit: periodUnitStr,
      startDate: sDate,
      endDate: eDate,
      status: json['status']?.toString() ?? 'Active',
      description: json['description']?.toString() ?? '',
      createdOn: createdOnStr,
    );
  }
}

class _ProductItem {
  final int productId;
  final String productName;
  final String productCode;
  final String? brandName;
  final dynamic brandId;
  final String? categoryName;
  final List<String> variants;

  _ProductItem({
    required this.productId,
    required this.productName,
    required this.productCode,
    this.brandName,
    this.brandId,
    this.categoryName,
    required this.variants,
  });

  factory _ProductItem.fromJson(Map<String, dynamic> json) {
    final List<String> parsedVariants = [];
    if (json['variant_details'] is List) {
      for (var v in json['variant_details']) {
        if (v is Map && v['variant_name'] != null) {
          final vName = v['variant_name'].toString().trim();
          if (vName.isNotEmpty && !parsedVariants.contains(vName)) {
            parsedVariants.add(vName);
          }
        }
      }
    }

    return _ProductItem(
      productId: int.tryParse(json['product_id']?.toString() ?? json['id']?.toString() ?? '0') ?? 0,
      productName: json['product_name']?.toString() ?? '',
      productCode: json['product_code']?.toString() ?? '',
      brandName: json['brand_name']?.toString(),
      brandId: json['brand_id'],
      categoryName: json['category_name']?.toString(),
      variants: parsedVariants,
    );
  }
}

class _WarrantyGuaranteePageState extends State<WarrantyGuaranteePage> {
  final ScrollController _scrollController = ScrollController();

  // Tab: 0 = Warranty, 1 = Guarantee (Photos 3 & 4)
  int _selectedTab = 0;

  // Products from API (GET https://billing.srivagroups.in/api/products)
  static final List<_ProductItem> _defaultFallbackProducts = [
    _ProductItem(productId: 5137, productName: "Arduino Unos", productCode: "ARD-MOD-04174", variants: []),
    _ProductItem(productId: 5136, productName: "Tuscan Rechargeable Battery 700 Mah", productCode: "TUS-TG0-04173", variants: ["Variant #520"]),
    _ProductItem(productId: 5135, productName: "Thermal Printers", productCode: "THE-MOD-04172", variants: ["Variant #508"]),
    _ProductItem(productId: 5134, productName: "Dot Matrix Printers", productCode: "DOT-MOD-04171", variants: ["Variant #171"]),
    _ProductItem(productId: 5133, productName: "Laser Printers", productCode: "LAS-MOD-04170", variants: ["Variant #290"]),
    _ProductItem(productId: 5132, productName: "Inkjet Printers", productCode: "INK-MOD-04169", variants: ["Variant #253"]),
    _ProductItem(productId: 5131, productName: "Zebronics Wireless Keyboard And Mouse", productCode: "ZEB-ZEB-04168", variants: ["Variant #998"]),
    _ProductItem(productId: 5130, productName: "Laptop Hdd", productCode: "LAP-MOD-04167", variants: ["Variant #287"]),
    _ProductItem(productId: 5129, productName: "Laptop Battery", productCode: "LAP-MOD-04166", variants: ["Variant #286"]),
    _ProductItem(productId: 5128, productName: "Laptop Motherboard", productCode: "LAP-MOD-04165", variants: ["Variant #289"]),
    _ProductItem(productId: 5127, productName: "Auto-ranging Multimeter", productCode: "AUT-MOD-04164", variants: ["Variant #116"]),
    _ProductItem(productId: 5126, productName: "Clamp Multimeters", productCode: "CLA-MOD-04163", variants: ["Variant #141"]),
    _ProductItem(productId: 5125, productName: "Analog Multimeters", productCode: "ANA-MOD-04162", variants: ["Variant #94"]),
    _ProductItem(productId: 5124, productName: "International Adapter", productCode: "INT-MOD-04161", variants: ["Variant #255"]),
    _ProductItem(productId: 5123, productName: "Ups", productCode: "UPS-MOD-04160", variants: ["Variant #525"]),
    _ProductItem(productId: 5122, productName: "Knife", productCode: "KNI-MOD-04159", variants: ["Variant #275"]),
    _ProductItem(productId: 5121, productName: "Insulation Tape", productCode: "INS-MOD-04158", variants: ["Variant #254"]),
    _ProductItem(productId: 5120, productName: "Crimping Tools", productCode: "CRI-MOD-04157", variants: ["Variant #152"]),
    _ProductItem(productId: 5119, productName: "Electrical Switches", productCode: "ELE-MOD-04156", variants: ["Variant #176"]),
    _ProductItem(productId: 5118, productName: "Electricals Wires", productCode: "ELE-MOD-04155", variants: ["Variant #177"]),
    _ProductItem(productId: 5117, productName: "Screw Terminal Block 2 Pin Wire To Board Connector", productCode: "SCR-MOD-04154", variants: ["Variant #436"]),
    _ProductItem(productId: 5116, productName: "Ld Transformer", productCode: "LDT-24V-04153", variants: ["Variant #292"]),
    _ProductItem(productId: 5115, productName: "8 Inch Woofer Speaker 40w", productCode: "8IN-8IN-04152", variants: ["Variant #77"]),
    _ProductItem(productId: 5114, productName: "6 Inch Woofer Speaker", productCode: "6IN-6IN-04151", variants: ["Variant #75"]),
    _ProductItem(productId: 5113, productName: "Mid Bass Treble Pre Board", productCode: "MID-202-04150", variants: ["Variant #329"]),
    _ProductItem(productId: 5112, productName: "12v Surround Decoder Board", productCode: "12V-12V-04149", variants: ["Variant #79"]),
    _ProductItem(productId: 5111, productName: "Mini Prologic Board", productCode: "MIN-51P-04148", variants: ["Variant #339"]),
    _ProductItem(productId: 5110, productName: "Copper Coil Step Down Transformer", productCode: "COP-24V-04147", variants: ["Variant #144"]),
    _ProductItem(productId: 5109, productName: "Dual Output Step-down Transformer", productCode: "DUA-24V-04146", variants: ["Variant #175"]),
    _ProductItem(productId: 5108, productName: "Center-tapped Step-down Transformer", productCode: "CEN-12V-04145", variants: ["Variant #137"]),
    _ProductItem(productId: 5107, productName: "Step-down Power Transformer", productCode: "STE-24V-04144", variants: ["Variant #483"]),
    _ProductItem(productId: 5106, productName: "Video Inverter Transformer", productCode: "VID-24V-04143", variants: ["Variant #537"]),
    _ProductItem(productId: 5105, productName: "Audio Video Inverter Transformer", productCode: "AUD-12V-04142", variants: ["Variant #538"]),
    _ProductItem(productId: 5104, productName: "Acrylic Remote Kit Panel", productCode: "ACR-JAZ-04141", variants: ["Variant #89"]),
    _ProductItem(productId: 5103, productName: "5.1 Home Theatre Front Panel", productCode: "51H-MAT-04140", variants: ["Variant #73"]),
    _ProductItem(productId: 5102, productName: "Stk Stereo Audio Amplifier Board", productCode: "STK-STK-04139", variants: ["Variant #486"]),
    _ProductItem(productId: 5101, productName: "Audio Pre-amplifier Board", productCode: "AUD-BUS-04138", variants: ["Variant #113"]),
    _ProductItem(productId: 5100, productName: "Double Ic Audio Power Amplifier Board", productCode: "DOU-MOD-04137", variants: ["Variant #172"]),
    _ProductItem(productId: 5099, productName: "2 Channel Audio Gainer Board", productCode: "2CH-MOD-04136", variants: ["Variant #52"]),
    _ProductItem(productId: 5098, productName: "Subwoofer Preamplifier Board", productCode: "SUB-24V-04135", variants: ["Variant #488"]),
    _ProductItem(productId: 5097, productName: "Sma 8 Fet Inverter Board Deluxe", productCode: "SMA-MOD-04134", variants: ["Variant #465"]),
    _ProductItem(productId: 5096, productName: "Cowboy 5.1 Power Amplifier Board", productCode: "COW-TDA-04133", variants: ["Variant #145"]),
    _ProductItem(productId: 5095, productName: "Sma 4 Fet Hd Converter Board", productCode: "SMA-12V-04132", variants: ["Variant #464"]),
    _ProductItem(productId: 5094, productName: "Beatz Dc Converter Board Dual Supply", productCode: "BEA-12V-04131", variants: ["Variant #120"]),
    _ProductItem(productId: 5093, productName: "Beatz Dual Supply Converter Board", productCode: "BEA-24V-04130", variants: ["Variant #121"]),
    _ProductItem(productId: 5092, productName: "Creative Tda7297 Stereo Amplifier Board", productCode: "CRE-TDA-04129", variants: ["Variant #150"]),
    _ProductItem(productId: 5091, productName: "Creative 2.1 Power Amplifier Board", productCode: "CRE-131-04128", variants: ["Variant #146"]),
    _ProductItem(productId: 5090, productName: "Creative Audio Pre-amplifier Board", productCode: "CRE-51G-04127", variants: ["Variant #149"]),
    _ProductItem(productId: 5089, productName: "Creative 4440 Double Ic Stereo Amplifier Board", productCode: "CRE-444-04126", variants: ["Variant #148"]),
    _ProductItem(productId: 5088, productName: "Creative Transistor Mono Amplifier Board", productCode: "CRE-CRE-04125", variants: ["Variant #151"]),
    _ProductItem(productId: 2, productName: "fewwrfwefrwfr", productCode: "NEW-2", brandName: "Android TV", categoryName: "Basic Electronics Components", variants: []),
    _ProductItem(productId: 3, productName: "kammaa", productCode: "NEW-3", brandName: "Converter", categoryName: "Basic Electronics Components", variants: []),
    _ProductItem(productId: 4, productName: "s", productCode: "NEW-4", brandName: "Converter", categoryName: "Basic Electronics Components", variants: ["Variant #712"]),
  ];

  List<_ProductItem> _products = List.from(_defaultFallbackProducts);

  // Form Fields - initially null matching "Select Product...", "Select Product First..."
  int? _selectedProductId;
  _ProductItem? _selectedProduct;
  String _productCode = "";
  String _category = "";
  String? _selectedBrand;
  String? _selectedVariant;
  String _warrantyType = "Manufacturer Warranty";

  List<String> _availableBrands = ["Imported", "Samsung", "Apple", "Sony", "Standard", "No Brand"];
  List<String> _availableVariants = ["Standard"];
  
  final TextEditingController _periodValueController = TextEditingController(text: "1");
  String _periodUnit = "Years"; // Years, Months, Days

  DateTime _startDate = DateTime.now();
  late DateTime _endDate;

  String _status = "Active"; // Active, Inactive, Expired
  final TextEditingController _descController = TextEditingController();

  int? _editingId;
  bool _isLoading = false;

  // Search & Filter
  final TextEditingController _searchController = TextEditingController();

  // Pre-seeded entries matching API responses
  List<_WarrantyEntry> _entries = [
    _WarrantyEntry(
      id: 6,
      productId: 4200,
      type: "Warranty",
      productName: "Mono Male Plug to 2 RCA Female Jack Splitter Connector",
      productCode: "PRD-4200",
      category: "CCTV Cables & Connectors",
      brand: "Imported",
      variant: "Imported",
      warrantyType: "Manufacturer Warranty",
      periodValue: 6,
      periodUnit: "Months",
      startDate: DateTime(2026, 8, 4),
      endDate: DateTime(2027, 2, 4),
      status: "Expired",
      description: "",
      createdOn: "04/08/2026",
    ),
    _WarrantyEntry(
      id: 5,
      productId: 4200,
      type: "Warranty",
      productName: "Mono Male Plug to 2 RCA Female Jack Splitter Connector",
      productCode: "PRD-4200",
      category: "CCTV Cables & Connectors",
      brand: "Imported",
      variant: "Imported",
      warrantyType: "Manufacturer Warranty",
      periodValue: 6,
      periodUnit: "Months",
      startDate: DateTime(2026, 8, 4),
      endDate: DateTime(2027, 2, 4),
      status: "Active",
      description: "",
      createdOn: "04/08/2026",
    ),
    _WarrantyEntry(
      id: 1,
      productId: 432,
      type: "Warranty",
      productName: "HW-072 Reed Switch Module",
      productCode: "PRD-0432",
      category: "Sensor Modules",
      brand: "Imported",
      variant: "Import",
      warrantyType: "Extended Warranty",
      periodValue: 2,
      periodUnit: "Years",
      startDate: DateTime(2026, 8, 4),
      endDate: DateTime(2028, 8, 4),
      status: "Active",
      description: "",
      createdOn: "04/08/2026",
    ),
    _WarrantyEntry(
      id: 1,
      productId: 432,
      type: "Guarantee",
      productName: "HW-072 Reed Switch Module",
      productCode: "PRD-0432",
      category: "Sensor Modules",
      brand: "Imported",
      variant: "Import",
      warrantyType: "Replacement Guarantee",
      periodValue: 6,
      periodUnit: "Months",
      startDate: DateTime(2026, 8, 4),
      endDate: DateTime(2027, 2, 4),
      status: "Active",
      description: "100% replacement guarantee if module is non-functional upon installation.",
      createdOn: "04/08/2026",
    ),
  ];

  final List<String> _warrantyTypes = [
    "Manufacturer Warranty",
    "Seller Warranty",
    "Extended Warranty",
    "Replacement Warranty",
  ];

  final List<String> _guaranteeTypes = [
    "Money Back Guarantee",
    "Replacement Guarantee",
    "Satisfaction Guarantee",
    "Price Match Guarantee",
  ];

  @override
  void initState() {
    super.initState();
    _calculateEndDate();
    _loadSaved();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        ApiService.getStores(),
        ApiService.getNotifications(),
        ApiService.getUserPermissions(),
        ApiService.getNewProducts(),
        ApiService.getStocks(), // ✅ GET /api/stocks
        ApiService.getWVariantStocks(), // ✅ GET /api/w_variant/stock
        _fetchProducts(), // ✅ GET /api/products
        _fetchWarrantyList(), // ✅ GET /api/warranty
        _fetchGuaranteeList(), // ✅ GET /api/guarantee
      ]);
    } catch (e) {
      debugPrint("Error fetching initial warranty data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// ✅ GET PRODUCTS: Connects https://billing.srivagroups.in/api/products
  Future<void> _fetchProducts() async {
    try {
      final res = await ApiService.getAllProducts();
      List rawList = [];
      if (res['products'] is List) {
        rawList = res['products'];
      } else if (res['data'] is Map && res['data']['products'] is List) {
        rawList = res['data']['products'];
      } else if (res['data'] is List) {
        rawList = res['data'];
      }

      if (rawList.isNotEmpty) {
        final List<_ProductItem> loaded = [];
        final Set<String> brandSet = Set.from(_availableBrands);

        for (var item in rawList) {
          if (item is Map) {
            final p = _ProductItem.fromJson(Map<String, dynamic>.from(item));
            if (p.productName.isNotEmpty) {
              loaded.add(p);
              if (p.brandName != null && p.brandName!.trim().isNotEmpty) {
                brandSet.add(p.brandName!.trim());
              }
            }
          }
        }

        if (mounted && loaded.isNotEmpty) {
          setState(() {
            _products = loaded;
            _availableBrands = brandSet.toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching products in warranty page: $e");
    }
  }

  void _onProductSelected(int? productId) {
    setState(() {
      _selectedProductId = productId;
      if (productId == null) {
        _selectedProduct = null;
        _selectedBrand = null;
        _selectedVariant = null;
        _productCode = "";
        _category = "";
        _availableVariants = ["Standard"];
      } else {
        final prod = _products.firstWhere(
          (p) => p.productId == productId,
          orElse: () => _ProductItem(productId: productId, productName: "", productCode: "", variants: []),
        );
        _selectedProduct = prod;
        _productCode = prod.productCode;
        _category = (prod.categoryName != null && prod.categoryName!.isNotEmpty)
            ? prod.categoryName!
            : "General";

        // Brand
        if (prod.brandName != null && prod.brandName!.trim().isNotEmpty) {
          _selectedBrand = prod.brandName!.trim();
          if (!_availableBrands.contains(_selectedBrand!)) {
            _availableBrands.add(_selectedBrand!);
          }
        } else {
          _selectedBrand = "No Brand";
          if (!_availableBrands.contains("No Brand")) {
            _availableBrands.add("No Brand");
          }
        }

        // Variants
        if (prod.variants.isNotEmpty) {
          _availableVariants = List.from(prod.variants);
          _selectedVariant = prod.variants.first;
        } else {
          _availableVariants = ["Standard"];
          _selectedVariant = "Standard";
        }
      }
    });
  }

  Future<void> _fetchWarrantyList() async {
    try {
      final res = await ApiService.getWarrantyList();
      if (res['success'] == true && res['data'] is List) {
        final list = (res['data'] as List)
            .map((e) => _WarrantyEntry.fromApi(Map<String, dynamic>.from(e)))
            .toList();
        if (mounted) {
          setState(() {
            _entries.removeWhere((e) => e.type == "Warranty");
            _entries.insertAll(0, list);
          });
          _saveToStorage();
        }
      }
    } catch (e) {
      debugPrint("Error fetching warranty list: $e");
    }
  }

  Future<void> _fetchGuaranteeList() async {
    try {
      final res = await ApiService.getGuaranteeList();
      if (res['success'] == true && res['data'] is List) {
        final list = (res['data'] as List)
            .map((e) => _WarrantyEntry.fromApi(Map<String, dynamic>.from(e)))
            .toList();
        if (mounted) {
          setState(() {
            _entries.removeWhere((e) => e.type == "Guarantee");
            _entries.addAll(list);
          });
          _saveToStorage();
        }
      }
    } catch (e) {
      debugPrint("Error fetching guarantee list: $e");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _periodValueController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _calculateEndDate() {
    final val = int.tryParse(_periodValueController.text.trim()) ?? 1;
    if (_periodUnit == "Years") {
      _endDate = DateTime(_startDate.year + val, _startDate.month, _startDate.day);
    } else if (_periodUnit == "Months") {
      _endDate = DateTime(_startDate.year, _startDate.month + val, _startDate.day);
    } else {
      _endDate = _startDate.add(Duration(days: val));
    }
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString("saved_warranty_guarantee_entries");
      if (raw != null && raw.isNotEmpty) {
        final List decoded = jsonDecode(raw);
        setState(() {
          _entries = decoded.map((e) => _WarrantyEntry.fromJson(e)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = _entries.map((e) => e.toJson()).toList();
      await prefs.setString("saved_warranty_guarantee_entries", jsonEncode(listJson));
    } catch (_) {}
  }

  void _showNotification(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13))),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearForm() {
    setState(() {
      _editingId = null;
      _selectedProductId = null;
      _selectedProduct = null;
      _productCode = "";
      _category = "";
      _selectedBrand = null;
      _selectedVariant = null;
      _availableVariants = ["Standard"];
      _warrantyType = _selectedTab == 0 ? "Manufacturer Warranty" : "Money Back Guarantee";
      _periodValueController.text = "1";
      _periodUnit = "Years";
      _startDate = DateTime.now();
      _calculateEndDate();
      _status = "Active";
      _descController.clear();
    });
    _showNotification("Form cleared");
  }

  Future<void> _saveEntry() async {
    if (_selectedProduct == null && _selectedProductId == null) {
      _showNotification("Please select a product first", isError: true);
      return;
    }

    final val = int.tryParse(_periodValueController.text.trim()) ?? 1;
    final currentType = _selectedTab == 0 ? "Warranty" : "Guarantee";
    final prodName = _selectedProduct?.productName ?? "Unknown Product";
    final pId = _selectedProductId ?? _selectedProduct?.productId ?? 0;
    final brandVal = _selectedBrand ?? "No Brand";
    final variantVal = _selectedVariant ?? "Standard";
    final startDateStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(_endDate);

    final Map<String, dynamic> payload = {
      "product_id": pId,
      "product_code": _productCode,
      "product_name": prodName,
      "category_name": _category,
      "brand_name": brandVal,
      "variant_name": variantVal,
      "start_date": startDateStr,
      "end_date": endDateStr,
      "status": _status,
      "description": _descController.text.trim(),
    };

    if (_selectedTab == 0) {
      payload["warranty_type"] = _warrantyType;
      payload["warranty_period"] = val;
      payload["warranty_unit"] = _periodUnit;
    } else {
      payload["guarantee_type"] = _warrantyType;
      payload["guarantee_period"] = val;
      payload["guarantee_unit"] = _periodUnit;
    }

    setState(() => _isLoading = true);

    try {
      if (_editingId != null) {
        // PUT /api/warranty/{id} or PUT /api/guarantee/{id}
        final res = _selectedTab == 0
            ? await ApiService.updateWarranty(_editingId!, payload)
            : await ApiService.updateGuarantee(_editingId!, payload);

        final msg = res['message']?.toString() ?? "$currentType updated successfully";
        _showNotification(msg);

        // Update local list
        final idx = _entries.indexWhere((e) => e.id == _editingId);
        if (idx != -1) {
          setState(() {
            _entries[idx].productId = pId;
            _entries[idx].productName = prodName;
            _entries[idx].productCode = _productCode;
            _entries[idx].category = _category;
            _entries[idx].brand = brandVal;
            _entries[idx].variant = variantVal;
            _entries[idx].warrantyType = _warrantyType;
            _entries[idx].periodValue = val;
            _entries[idx].periodUnit = _periodUnit;
            _entries[idx].startDate = _startDate;
            _entries[idx].endDate = _endDate;
            _entries[idx].status = _status;
            _entries[idx].description = _descController.text.trim();
          });
        }
      } else {
        // POST /api/warranty or POST /api/guarantee
        final res = _selectedTab == 0
            ? await ApiService.createWarranty(payload)
            : await ApiService.createGuarantee(payload);

        final msg = res['message']?.toString() ?? "$currentType saved successfully";
        _showNotification(msg);

        int newId = _entries.isEmpty ? 1 : (_entries.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
        if (res['data'] is Map && res['data']['id'] != null) {
          newId = int.tryParse(res['data']['id'].toString()) ?? newId;
        }

        final entry = _WarrantyEntry(
          id: newId,
          productId: pId,
          type: currentType,
          productName: prodName,
          productCode: _productCode,
          category: _category,
          brand: brandVal,
          variant: variantVal,
          warrantyType: _warrantyType,
          periodValue: val,
          periodUnit: _periodUnit,
          startDate: _startDate,
          endDate: _endDate,
          status: _status,
          description: _descController.text.trim(),
          createdOn: DateFormat('dd/MM/yyyy').format(DateTime.now()),
        );

        setState(() {
          _entries.insert(0, entry);
        });
      }

      _saveToStorage();
      _clearForm();

      if (_selectedTab == 0) {
        _fetchWarrantyList();
      } else {
        _fetchGuaranteeList();
      }
    } catch (e) {
      debugPrint("Error saving $currentType: $e");
      _showNotification("Failed to save $currentType: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _editEntry(_WarrantyEntry entry) {
    setState(() {
      _editingId = entry.id;
      _selectedTab = entry.type == "Warranty" ? 0 : 1;

      // Find matching product by productId, name, or code
      final matchedProd = _products.firstWhere(
        (p) =>
            (entry.productId > 0 && p.productId == entry.productId) ||
            p.productName.toLowerCase() == entry.productName.toLowerCase() ||
            (p.productCode.isNotEmpty &&
                p.productCode.toLowerCase() == entry.productCode.toLowerCase()),
        orElse: () => _ProductItem(
          productId: entry.productId > 0 ? entry.productId : -1,
          productName: entry.productName,
          productCode: entry.productCode,
          brandName: entry.brand,
          categoryName: entry.category,
          variants: entry.variant.isNotEmpty ? [entry.variant] : ["Standard"],
        ),
      );

      if (!_products.any((p) => p.productId == matchedProd.productId)) {
        _products.add(matchedProd);
      }

      _selectedProductId = matchedProd.productId;
      _selectedProduct = matchedProd;
      _productCode = entry.productCode;
      _category = entry.category;

      if (entry.brand.isNotEmpty) {
        _selectedBrand = entry.brand;
        if (!_availableBrands.contains(entry.brand)) {
          _availableBrands.add(entry.brand);
        }
      } else {
        _selectedBrand = matchedProd.brandName ?? "No Brand";
      }

      _availableVariants = matchedProd.variants.isNotEmpty
          ? List.from(matchedProd.variants)
          : ["Standard"];
      if (entry.variant.isNotEmpty && !_availableVariants.contains(entry.variant)) {
        _availableVariants.add(entry.variant);
      }
      _selectedVariant =
          entry.variant.isNotEmpty ? entry.variant : _availableVariants.first;

      _warrantyType = entry.warrantyType;
      _periodValueController.text = entry.periodValue.toString();
      _periodUnit = entry.periodUnit;
      _startDate = entry.startDate;
      _endDate = entry.endDate;
      _status = entry.status;
      _descController.text = entry.description;
    });

    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    _showNotification("Editing entry for '${entry.productName}'");
  }

  void _deleteEntry(_WarrantyEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Entry", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text("Are you sure you want to delete this ${entry.type} entry?", style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                final res = entry.type == "Warranty"
                    ? await ApiService.deleteWarranty(entry.id)
                    : await ApiService.deleteGuarantee(entry.id);

                final msg = res['message']?.toString() ?? "${entry.type} deleted successfully";
                _showNotification(msg);

                setState(() {
                  _entries.removeWhere((e) => e.id == entry.id);
                });
                _saveToStorage();
              } catch (e) {
                debugPrint("Error deleting ${entry.type}: $e");
                _showNotification("Failed to delete ${entry.type}", isError: true);
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // Action -> View Dialog (Photo 5: Warranty Details (6))
  void _openViewDialog(_WarrantyEntry entry) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 580),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Color(0x2E000000), blurRadius: 30, offset: Offset(0, 15)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Shield Icon + Title + Close Button (Photo 5)
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: Color(0xFF4F46E5), size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "${entry.type} Details (${entry.id})",
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Grid matching Photo 5
                      _buildDetailRow("Product Name:", entry.productName, "Product Code:", entry.productCode),
                      const SizedBox(height: 14),
                      _buildDetailRow("Category:", entry.category, "Brand:", entry.brand),
                      const SizedBox(height: 14),
                      _buildDetailRow("${entry.type} Type:", entry.warrantyType, "Coverage Period:", entry.periodDisplay),
                      const SizedBox(height: 14),
                      _buildDetailRow("Start Date:", DateFormat('yyyy-MM-dd').format(entry.startDate), "End Date:", DateFormat('yyyy-MM-dd').format(entry.endDate)),
                      const SizedBox(height: 14),
                      
                      // Status & Created On
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Status:", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    entry.status,
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Created On:", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(
                                  "${DateFormat('yyyy-MM-dd').format(entry.startDate)} 18:00:08",
                                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1E293B), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (entry.description.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text("Terms / Claim Procedure:", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(entry.description, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155), height: 1.4)),
                        ),
                      ],

                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text("Close", style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569), fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label1, String val1, String label2, String val2) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label1, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text(val1, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF0F172A), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label2, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text(val2, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF0F172A), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Warranty & Guarantee Management",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16.5, color: const Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            tooltip: "Refresh Data",
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                  )
                : const Icon(Icons.refresh, color: Color(0xFF4F46E5)),
            onPressed: _isLoading ? null : _fetchInitialData,
          ),
          const SizedBox(width: 8),
        ],
        bottom: _isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Color(0xFFE2E8F0),
                  color: Color(0xFF4F46E5),
                ),
              )
            : null,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row with Title & Warranty/Guarantee Switcher (Photos 3 & 4)
                _buildHeaderRow(),
                const SizedBox(height: 20),

                // Form Card (New Warranty Entry / New Guarantee Entry)
                _buildFormCard(),
                const SizedBox(height: 28),

                // Lower Table Section
                _buildTableSection(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 650;
        final titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Warranty & Guarantee Management",
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Text(
              "Configure, manage and track warranty coverage and product guarantee terms",
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
            ),
          ],
        );

        final switcher = Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tabButton(0, "Warranty", Icons.shield_outlined, const Color(0xFF4F46E5)),
              const SizedBox(width: 4),
              _tabButton(1, "Guarantee", Icons.verified_outlined, const Color(0xFF10B981)),
            ],
          ),
        );

        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleSection,
              const SizedBox(height: 14),
              switcher,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleSection),
            const SizedBox(width: 16),
            switcher,
          ],
        );
      },
    );
  }

  Widget _tabButton(int index, String label, IconData icon, Color activeColor) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
          _warrantyType = index == 0 ? "Manufacturer Warranty" : "Money Back Guarantee";
        });
        if (index == 0) {
          _fetchWarrantyList();
        } else {
          _fetchGuaranteeList();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? activeColor : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? activeColor : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? activeColor : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Form Card (Photo 3: New Warranty Entry, Photo 4: New Guarantee Entry)
  Widget _buildFormCard() {
    final isWarranty = _selectedTab == 0;
    final primaryColor = isWarranty ? const Color(0xFF4F46E5) : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isWarranty ? Icons.shield_outlined : Icons.verified_outlined, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                isWarranty ? "New Warranty Entry" : "New Guarantee Entry",
                style: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Row 1: Product, Brand, Variant, Warranty/Guarantee Type
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 750;
              final productCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Product *", style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _selectedProductId,
                        hint: Text(
                          "Select Product...",
                          style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        isExpanded: true,
                        menuMaxHeight: 400,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                        style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF0F172A)),
                        items: _products.map((p) {
                          final label = p.productCode.isNotEmpty ? "${p.productName} (${p.productCode})" : p.productName;
                          return DropdownMenuItem<int?>(
                            value: p.productId,
                            child: Text(label, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (v) => _onProductSelected(v),
                      ),
                    ),
                  ),
                ],
              );

              final brandCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Brand *", style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _selectedProductId == null ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: _selectedProductId == null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Select Product First...",
                                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFFCBD5E1)),
                            ],
                          )
                        : DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _availableBrands.contains(_selectedBrand)
                                  ? _selectedBrand
                                  : (_availableBrands.isNotEmpty ? _availableBrands.first : null),
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF0F172A)),
                              items: _availableBrands
                                  .map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedBrand = v);
                              },
                            ),
                          ),
                  ),
                ],
              );

              final variantCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Variant *", style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _selectedProductId == null ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: _selectedProductId == null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Select Product First...",
                                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFFCBD5E1)),
                            ],
                          )
                        : DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _availableVariants.contains(_selectedVariant)
                                  ? _selectedVariant
                                  : (_availableVariants.isNotEmpty ? _availableVariants.first : null),
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF0F172A)),
                              items: _availableVariants
                                  .map((varItem) => DropdownMenuItem(value: varItem, child: Text(varItem, overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedVariant = v);
                              },
                            ),
                          ),
                  ),
                ],
              );

              final typeCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isWarranty ? "Warranty Type" : "Guarantee Type", style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: (isWarranty ? _warrantyTypes : _guaranteeTypes).contains(_warrantyType)
                            ? _warrantyType
                            : (isWarranty ? _warrantyTypes.first : _guaranteeTypes.first),
                        isExpanded: true,
                        style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF0F172A)),
                        items: (isWarranty ? _warrantyTypes : _guaranteeTypes).map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setState(() => _warrantyType = v!),
                      ),
                    ),
                  ),
                ],
              );

              if (isSmall) {
                return Column(
                  children: [
                    productCol,
                    const SizedBox(height: 12),
                    brandCol,
                    const SizedBox(height: 12),
                    variantCol,
                    const SizedBox(height: 12),
                    typeCol,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 2, child: productCol),
                  const SizedBox(width: 12),
                  Expanded(child: brandCol),
                  const SizedBox(width: 12),
                  Expanded(child: variantCol),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: typeCol),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Row 2: Period, Start Date, End Date (Auto Calculate), Status
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 750;

              final periodCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isWarranty ? "Warranty Period *" : "Guarantee Period *", style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: TextField(
                          controller: _periodValueController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            setState(() => _calculateEndDate());
                          },
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: _inputDecoration("1"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _periodUnit,
                              isExpanded: true,
                              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF0F172A)),
                              items: ["Years", "Months", "Days"].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _periodUnit = v;
                                    _calculateEndDate();
                                  });
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

              final startDateCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Start Date", style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime(2035));
                      if (picked != null) {
                        setState(() {
                          _startDate = picked;
                          _calculateEndDate();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('dd/MM/yyyy').format(_startDate), style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF0F172A))),
                          const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),
                ],
              );

              final endDateCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("End Date (Auto Calculate)", style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Text(DateFormat('dd/MM/yyyy').format(_endDate), style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  ),
                ],
              );

              final statusCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Status", style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _status,
                        isExpanded: true,
                        style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF0F172A)),
                        items: ["Active", "Inactive", "Expired"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                    ),
                  ),
                ],
              );

              if (isSmall) {
                return Column(
                  children: [
                    periodCol,
                    const SizedBox(height: 12),
                    startDateCol,
                    const SizedBox(height: 12),
                    endDateCol,
                    const SizedBox(height: 12),
                    statusCol,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 2, child: periodCol),
                  const SizedBox(width: 12),
                  Expanded(child: startDateCol),
                  const SizedBox(width: 12),
                  Expanded(child: endDateCol),
                  const SizedBox(width: 12),
                  Expanded(child: statusCol),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Row 3: Description / Terms
          Text("Description / Terms", style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
          const SizedBox(height: 6),
          TextField(
            controller: _descController,
            style: GoogleFonts.inter(fontSize: 13),
            decoration: _inputDecoration("Enter specific ${isWarranty ? 'warranty' : 'guarantee'} terms, terms of repair or claim procedure..."),
          ),
          const SizedBox(height: 20),

          // Buttons: Clear & Save (Photo 3: blue Save Warranty, Photo 4: green Save Guarantee)
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: _clearForm,
                  child: Text("Clear", style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569), fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: 1,
                  ),
                  onPressed: _isLoading ? null : _saveEntry,
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _editingId != null ? "Update ${isWarranty ? 'Warranty' : 'Guarantee'}" : "Save ${isWarranty ? 'Warranty' : 'Guarantee'}",
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
    );
  }

  // Lower Table Section (Photos 3 & 4)
  Widget _buildTableSection() {
    final isWarranty = _selectedTab == 0;
    final currentType = isWarranty ? "Warranty" : "Guarantee";
    final search = _searchController.text.trim().toLowerCase();

    final filtered = _entries.where((e) {
      if (e.type != currentType) return false;
      if (search.isNotEmpty && !e.productName.toLowerCase().contains(search) && !e.productCode.toLowerCase().contains(search)) return false;
      return true;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search & Action Buttons (Filter, Export Excel, Export PDF, Print)
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 700;
              final searchField = ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 200, maxWidth: 360),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() {}),
                  style: GoogleFonts.inter(fontSize: 12.5),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    hintText: "Search by Product Name, Code, or Warranty ID...",
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search, size: 17, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
              );

              final toolbarButtons = Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _actionChip(Icons.filter_list, "Filter"),
                  _actionChip(Icons.table_chart_outlined, "Export Excel"),
                  _actionChip(Icons.picture_as_pdf_outlined, "Export PDF"),
                  _actionChip(Icons.print_outlined, "Print"),
                ],
              );

              if (isSmall) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    searchField,
                    const SizedBox(height: 12),
                    toolbarButtons,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  searchField,
                  const SizedBox(width: 12),
                  toolbarButtons,
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // Data Table
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(36),
              alignment: Alignment.center,
              child: Text("No $currentType entries found", style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 800),
                child: DataTable(
                  horizontalMargin: 12,
                  columnSpacing: 20,
                  headingRowHeight: 42,
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: 64,
                  headingTextStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 0.5),
                  columns: const [
                    DataColumn(label: Text("S.NO")),
                    DataColumn(label: Text("PRODUCT NAME")),
                    DataColumn(label: Text("PERIOD")),
                    DataColumn(label: Text("STATUS")),
                    DataColumn(label: Text("CREATED DATE")),
                    DataColumn(label: Text("ACTIONS")),
                  ],
                  rows: List.generate(filtered.length, (index) {
                    final e = filtered[index];
                    return DataRow(
                      cells: [
                        // S.NO
                        DataCell(Text("${index + 1}", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)))),
                        // PRODUCT NAME
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(e.productName, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text("Code: ${e.productCode} | ${e.category}", style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                        // PERIOD
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(e.periodDisplay, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                              const SizedBox(height: 2),
                              Text(e.warrantyType, style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                        // STATUS
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Text(e.status, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A))),
                              ],
                            ),
                          ),
                        ),
                        // CREATED DATE
                        DataCell(Text(e.createdOn, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)))),
                        // ACTIONS (View -> Photo 5 Modal, Edit, Delete)
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // View Icon (Photo 5 Modal)
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, size: 17, color: Color(0xFF64748B)),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                tooltip: "View Details",
                                onPressed: () => _openViewDialog(e),
                              ),
                              const SizedBox(width: 8),
                              // Edit Icon
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 17, color: Color(0xFF64748B)),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                tooltip: "Edit Entry",
                                onPressed: () => _editEntry(e),
                              ),
                              const SizedBox(width: 8),
                              // Delete Icon
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 17, color: Color(0xFFEF4444)),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                tooltip: "Delete Entry",
                                onPressed: () => _deleteEntry(e),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
        ],
      ),
    );
  }
}

