import 'package:billingapp/Auth/api service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class TermsConditionsPage extends StatefulWidget {
  const TermsConditionsPage({super.key});

  @override
  State<TermsConditionsPage> createState() => _TermsConditionsPageState();
}

class _PolicyDoc {
  final int id;
  final String documentType; // 'Terms & Conditions' or 'Return Policy'
  String title;
  String content;
  bool isDefault;
  String status; // 'Active' or 'Inactive'
  final String updatedBy;
  String updatedDate;
  // Return policy specific fields
  int returnDays;
  String refundType;
  List<String> categories;
  List<String> brands;
  List<String> products;

  _PolicyDoc({
    required this.id,
    required this.documentType,
    required this.title,
    required this.content,
    required this.isDefault,
    required this.status,
    required this.updatedBy,
    required this.updatedDate,
    this.returnDays = 7,
    this.refundType = 'Exchange',
    this.categories = const ['Electronics'],
    this.brands = const ['Apple'],
    this.products = const ['iPhone 15'],
  });

  String get applicableSummary {
    List<String> parts = [];
    if (categories.isNotEmpty) parts.add("Cat: ${categories.join(', ')}");
    if (brands.isNotEmpty) parts.add("Brand: ${brands.join(', ')}");
    if (products.isNotEmpty) parts.add("Prod: ${products.join(', ')}");
    return parts.isEmpty ? "All items" : parts.join(" | ");
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'documentType': documentType,
    'title': title,
    'content': content,
    'isDefault': isDefault,
    'status': status,
    'updatedBy': updatedBy,
    'updatedDate': updatedDate,
    'returnDays': returnDays,
    'refundType': refundType,
    'categories': categories,
    'brands': brands,
    'products': products,
  };

  factory _PolicyDoc.fromJson(Map<String, dynamic> json) => _PolicyDoc(
    id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
    documentType: json['documentType'] as String? ?? 'Terms & Conditions',
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    isDefault: json['isDefault'] as bool? ?? false,
    status: json['status'] as String? ?? 'Active',
    updatedBy: json['updatedBy'] as String? ?? 'kalaivanissd@gmail.com',
    updatedDate: json['updatedDate'] as String? ?? '',
    returnDays: json['returnDays'] as int? ?? 7,
    refundType: json['refundType'] as String? ?? 'Exchange',
    categories: (json['categories'] as List?)?.map((e) => e.toString()).toList() ?? ['Electronics'],
    brands: (json['brands'] as List?)?.map((e) => e.toString()).toList() ?? ['Apple'],
    products: (json['products'] as List?)?.map((e) => e.toString()).toList() ?? ['iPhone 15'],
  );

  factory _PolicyDoc.fromApi(Map<String, dynamic> json) {
    final docType = json['document_type']?.toString() ??
        json['documentType']?.toString() ??
        'Terms & Conditions';
    final title = json['title']?.toString() ?? '';
    final content = json['content']?.toString() ?? '';

    final rawDefault = json['is_default'] ?? json['isDefault'];
    final isDefault = (rawDefault == true || rawDefault == 1 || rawDefault == '1' || rawDefault == 'true');

    final status = json['status']?.toString() ?? 'Active';
    final updatedBy = json['updated_by']?.toString() ??
        json['user_email']?.toString() ??
        json['updatedBy']?.toString() ??
        'kalaivanissd@gmail.com';

    // Parse date
    String updatedDate = '';
    final rawDate = json['updated_at'] ?? json['created_at'] ?? json['updatedDate'];
    if (rawDate != null) {
      try {
        final dt = DateTime.tryParse(rawDate.toString().replaceAll(' ', 'T'));
        if (dt != null) {
          updatedDate = DateFormat('MMM dd, yyyy').format(dt);
        } else {
          updatedDate = rawDate.toString();
        }
      } catch (_) {
        updatedDate = rawDate.toString();
      }
    }
    if (updatedDate.isEmpty) {
      updatedDate = DateFormat('MMM dd, yyyy').format(DateTime.now());
    }

    final returnDays = int.tryParse(json['return_days']?.toString() ?? json['returnDays']?.toString() ?? '7') ?? 7;
    final refundType = json['refund_type']?.toString() ?? json['refundType']?.toString() ?? 'Exchange';

    List<String> categories = [];
    List<String> brands = [];
    List<String> products = [];

    final rawApplicable = json['applicable_for'] ?? json['applicableFor'];
    if (rawApplicable is List) {
      for (var item in rawApplicable) {
        final str = item.toString().trim();
        if (str.toLowerCase().startsWith('category:')) {
          final val = str.substring(str.indexOf(':') + 1).trim();
          if (val.isNotEmpty && !categories.contains(val)) categories.add(val);
        } else if (str.toLowerCase().startsWith('brand:')) {
          final val = str.substring(str.indexOf(':') + 1).trim();
          if (val.isNotEmpty && !brands.contains(val)) brands.add(val);
        } else if (str.toLowerCase().startsWith('product:')) {
          final val = str.substring(str.indexOf(':') + 1).trim();
          if (val.isNotEmpty && !products.contains(val)) products.add(val);
        }
      }
    }

    if (categories.isEmpty && json['categories'] is List) {
      categories = (json['categories'] as List).map((e) => e.toString()).toList();
    }
    if (brands.isEmpty && json['brands'] is List) {
      brands = (json['brands'] as List).map((e) => e.toString()).toList();
    }
    if (products.isEmpty && json['products'] is List) {
      products = (json['products'] as List).map((e) => e.toString()).toList();
    }

    final id = int.tryParse(json['id']?.toString() ?? '0') ?? 0;

    return _PolicyDoc(
      id: id,
      documentType: docType,
      title: title,
      content: content,
      isDefault: isDefault,
      status: status,
      updatedBy: updatedBy,
      updatedDate: updatedDate,
      returnDays: returnDays,
      refundType: refundType,
      categories: categories.isEmpty ? ['Electronics'] : categories,
      brands: brands.isEmpty ? ['Apple'] : brands,
      products: products.isEmpty ? ['iPhone 15'] : products,
    );
  }
}

class _TermsConditionsPageState extends State<TermsConditionsPage> {
  final ScrollController _scrollController = ScrollController();

  // Active Tab: 0 = Terms & Conditions, 1 = Return Policy
  int _selectedTab = 0;

  // Terms & Conditions Form Controllers
  final TextEditingController _termsTitleController = TextEditingController(text: "General Terms & Conditions");
  final TextEditingController _termsContentController = TextEditingController(
    text: "1. Payment is due within 15 days of invoice date.\n"
          "2. Goods once sold cannot be taken back without valid return approval.\n"
          "3. Please inspect all items upon delivery for damage or shortage.",
  );
  bool _setAsDefaultTerms = true;

  // Return Policy Form Controllers (Photos 1 & 2)
  final TextEditingController _returnTitleController = TextEditingController(text: "Customer Return & Exchange Policy");
  final TextEditingController _returnDescController = TextEditingController(
    text: "Enter policy details, required conditions, receipt requirements...",
  );
  final TextEditingController _returnDaysController = TextEditingController(text: "7");
  String _selectedRefundType = "Exchange"; // Exchange, Replacement, Full Refund, Store Credit
  
  // Applicable For Sub-Tab: 0 = Category, 1 = Brand, 2 = Product
  int _applicableSubTab = 0;
  List<String> _selectedCategories = ["Electronics"];
  List<String> _selectedBrands = ["Apple"];
  List<String> _selectedProducts = ["iPhone 15"];

  final TextEditingController _customCategoryController = TextEditingController();
  final TextEditingController _customBrandController = TextEditingController();
  final TextEditingController _customProductController = TextEditingController();

  final List<String> _availableCategories = ["Electronics", "Mobile & Accessories", "Sensor Modules", "Cables & Connectors", "Appliances"];
  final List<String> _availableBrands = ["Apple", "Samsung", "Sony", "LG", "Xiaomi", "Imported"];
  final List<String> _availableProducts = ["iPhone 15", "Galaxy S24", "Mono Male Plug to 2 RCA", "HW-072 Reed Switch Module"];

  String _status = "Active"; // Active | Inactive
  int? _editingDocId;
  bool _isLoading = false;
  bool _isSaving = false;

  // Search & Filter
  final TextEditingController _searchController = TextEditingController();
  String _filterType = "All Types"; // All Types | Terms & Conditions | Return Policy
  String _filterStatus = "All Statuses"; // All Statuses | Active | Inactive

  // List of saved documents (Matching Photos 1, 2, 3, 4)
  List<_PolicyDoc> _documents = [
    _PolicyDoc(
      id: 2,
      documentType: "Return Policy",
      title: "Customer Return & Exchange Policy",
      content: "fhjytkl;xvkdsjgksjgwlktjwplokriofltr",
      isDefault: false,
      status: "Active",
      updatedBy: "kalaivanissd@gmail.com",
      updatedDate: "Aug 20, 2026",
      returnDays: 7,
      refundType: "Exchange",
      categories: ["Electronics", "Mobile & Accessories"],
      brands: ["Apple", "Samsung"],
      products: ["iPhone 15", "Galaxy S24"],
    ),
    _PolicyDoc(
      id: 1,
      documentType: "Terms & Conditions",
      title: "General Terms & Conditions",
      content: "1. Payment is due within 15 days of invoice date.\n"
               "2. Goods once sold cannot be taken back without valid return approval.\n"
               "3. Please inspect all items upon delivery for damage or shortage.",
      isDefault: true,
      status: "Active",
      updatedBy: "kalaivanissd@gmail.com",
      updatedDate: "Jul 30, 2026",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedDocs();
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
        _fetchTermsConditions(),
      ]);
    } catch (e) {
      debugPrint("Error fetching initial data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTermsConditions() async {
    try {
      final res = await ApiService.getTermsConditions(status: "All", documentType: "All");
      if (res['success'] == true && res['data'] is List) {
        final list = (res['data'] as List)
            .map((e) => _PolicyDoc.fromApi(Map<String, dynamic>.from(e)))
            .toList();
        if (mounted) {
          setState(() {
            _documents = list;
          });
          _saveDocsToStorage();
        }
      }
    } catch (e) {
      debugPrint("Error fetching terms conditions: $e");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _termsTitleController.dispose();
    _termsContentController.dispose();
    _returnTitleController.dispose();
    _returnDescController.dispose();
    _returnDaysController.dispose();
    _customCategoryController.dispose();
    _customBrandController.dispose();
    _customProductController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedDocs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString("saved_seller_policies_docs");
      if (raw != null && raw.isNotEmpty) {
        final List decoded = jsonDecode(raw);
        setState(() {
          _documents = decoded.map((e) => _PolicyDoc.fromJson(e)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _saveDocsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = _documents.map((e) => e.toJson()).toList();
      await prefs.setString("saved_seller_policies_docs", jsonEncode(listJson));
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

  void _resetForm() {
    setState(() {
      _editingDocId = null;
      if (_selectedTab == 0) {
        _termsTitleController.text = "General Terms & Conditions";
        _termsContentController.text = "1. Payment is due within 15 days of invoice date.\n"
                                       "2. Goods once sold cannot be taken back without valid return approval.\n"
                                       "3. Please inspect all items upon delivery for damage or shortage.";
        _setAsDefaultTerms = true;
      } else {
        _returnTitleController.text = "Customer Return & Exchange Policy";
        _returnDescController.text = "Enter policy details, required conditions, receipt requirements...";
        _returnDaysController.text = "7";
        _selectedRefundType = "Exchange";
        _selectedCategories = ["Electronics"];
        _selectedBrands = ["Apple"];
        _selectedProducts = ["iPhone 15"];
      }
      _status = "Active";
    });
    _showNotification("Form reset successfully");
  }

  Future<void> _saveDocument({bool isDraft = false}) async {
    final isTerms = _selectedTab == 0;
    final title = isTerms ? _termsTitleController.text.trim() : _returnTitleController.text.trim();
    final content = isTerms ? _termsContentController.text.trim() : _returnDescController.text.trim();

    if (title.isEmpty) {
      _showNotification("Please enter a title", isError: true);
      return;
    }
    if (content.isEmpty) {
      _showNotification("Please enter description / content", isError: true);
      return;
    }

    final docType = isTerms ? "Terms & Conditions" : "Return Policy";
    final returnDaysVal = int.tryParse(_returnDaysController.text.trim()) ?? 7;

    setState(() => _isSaving = true);

    final Map<String, dynamic> payload = {
      "documentType": docType,
      "document_type": docType,
      "title": title,
      "content": content,
      "status": _status,
    };

    if (isTerms) {
      payload["isDefault"] = _setAsDefaultTerms;
      payload["is_default"] = _setAsDefaultTerms;
    } else {
      payload["refundType"] = _selectedRefundType;
      payload["refund_type"] = _selectedRefundType;
      payload["returnDays"] = returnDaysVal;
      payload["return_days"] = returnDaysVal;

      List<String> applicableFor = [];
      for (var c in _selectedCategories) {
        applicableFor.add("Category: $c");
      }
      for (var b in _selectedBrands) {
        applicableFor.add("Brand: $b");
      }
      for (var p in _selectedProducts) {
        applicableFor.add("Product: $p");
      }
      payload["applicableFor"] = applicableFor;
      payload["applicable_for"] = applicableFor;
    }

    try {
      Map<String, dynamic> response;
      if (_editingDocId != null) {
        response = await ApiService.updateTermsConditions(_editingDocId!, payload);
      } else {
        response = await ApiService.createTermsConditions(payload);
      }

      if (response['success'] == true || response['status'] == true || response.containsKey('data')) {
        _showNotification(_editingDocId != null
            ? "$docType updated successfully!"
            : (isDraft ? "Draft saved successfully!" : "$docType saved successfully!"));
        setState(() {
          _editingDocId = null;
        });
        await _fetchTermsConditions();
      } else {
        final msg = response['message']?.toString() ?? "Failed to save $docType";
        _showNotification(msg, isError: true);
      }
    } catch (e) {
      _showNotification("Error saving $docType: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Edit Action: Switch to the correct tab and populate all fields
  void _editDoc(_PolicyDoc doc) {
    setState(() {
      _editingDocId = doc.id;
      _status = doc.status;

      if (doc.documentType == "Return Policy") {
        _selectedTab = 1;
        _returnTitleController.text = doc.title;
        _returnDescController.text = doc.content;
        _returnDaysController.text = doc.returnDays.toString();
        _selectedRefundType = doc.refundType;
        _selectedCategories = List.from(doc.categories);
        _selectedBrands = List.from(doc.brands);
        _selectedProducts = List.from(doc.products);
      } else {
        _selectedTab = 0;
        _termsTitleController.text = doc.title;
        _termsContentController.text = doc.content;
        _setAsDefaultTerms = doc.isDefault;
      }
    });

    // Scroll up smoothly to form
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    _showNotification("Editing '${doc.title}' in ${doc.documentType}");
  }

  void _deleteDoc(_PolicyDoc doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Document", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text("Are you sure you want to delete '${doc.title}'?", style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey)),
          ),
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
                final res = await ApiService.deleteTermsConditions(doc.id);
                if (res['success'] == true || res['status'] == true) {
                  _showNotification("Document deleted successfully");
                  await _fetchTermsConditions();
                } else {
                  final msg = res['message']?.toString() ?? "Failed to delete document";
                  _showNotification(msg, isError: true);
                }
              } catch (e) {
                _showNotification("Error deleting document: $e", isError: true);
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: Text("Delete", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Action -> View Dialog (Photo 4)
  void _openViewDialog(_PolicyDoc doc) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 620),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2E000000),
                  blurRadius: 30,
                  offset: Offset(0, 15),
                ),
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
                      // Header Row: Icon + Title + Close Button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            doc.documentType == "Return Policy" ? Icons.replay_rounded : Icons.description_outlined,
                            color: const Color(0xFF4F46E5),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              doc.title,
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
                      const SizedBox(height: 16),

                      // Badges Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Type Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: doc.documentType == "Return Policy" ? const Color(0xFFFEF3C7) : const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              doc.documentType,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: doc.documentType == "Return Policy" ? const Color(0xFFB45309) : const Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: doc.status == "Active" ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: doc.status == "Active" ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  doc.status,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: doc.status == "Active" ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Metadata Grid (RETURN WINDOW, REFUND TYPE, APPLICABLE FOR)
                      if (doc.documentType == "Return Policy") ...[
                        Wrap(
                          spacing: 16,
                          runSpacing: 14,
                          children: [
                            SizedBox(
                              width: 140,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "RETURN WINDOW:",
                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${doc.returnDays} Days",
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 140,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "REFUND TYPE:",
                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    doc.refundType,
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                                  ),
                                ],
                              ),
                            ),
                            ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 200),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "APPLICABLE FOR:",
                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    doc.applicableSummary,
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF334155), height: 1.35),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ] else ...[
                        Wrap(
                          spacing: 16,
                          runSpacing: 14,
                          children: [
                            SizedBox(
                              width: 140,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "DEFAULT STATUS:",
                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    doc.isDefault ? "Yes (Default Terms)" : "No",
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 140,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "UPDATED BY:",
                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    doc.updatedBy,
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF334155)),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 140,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "UPDATED DATE:",
                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    doc.updatedDate,
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Content & Terms Details (Photo 4)
                      Text(
                        "Content & Terms Details",
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: SelectableText(
                          doc.content,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF334155),
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Close Preview Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            "Close Preview",
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Terms & Conditions",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF0F172A)),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top Banner
                    _buildTopBanner(),
                    const SizedBox(height: 16),

                    // 2. Sub Tabs: Terms & Conditions | Return Policy
                    _buildSubTabs(),
                    const SizedBox(height: 20),

                    // 3. Two-Column Form & Live Invoice Preview (Responsive & Overflow-free)
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _selectedTab == 0 ? _buildTermsFormCard() : _buildReturnPolicyFormCard()),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: _buildLiveInvoicePreview()),
                        ],
                      )
                    else ...[
                      _selectedTab == 0 ? _buildTermsFormCard() : _buildReturnPolicyFormCard(),
                      const SizedBox(height: 24),
                      _buildLiveInvoicePreview(),
                    ],
                    const SizedBox(height: 20),

                    // 4. Action Buttons (Overflow-safe Wrap)
                    _buildActionButtons(),
                    const SizedBox(height: 32),

                    // 5. Saved Terms & Return Policy Documents Table
                    _buildSavedDocumentsSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 1. Top Banner
  Widget _buildTopBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x404F46E5),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0x2EFFFFFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Terms & Conditions & Return Policy",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Manage custom invoice terms, return window policies, and customer receipt legal disclaimers.",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xE0FFFFFF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Sub Tabs (Photo 1)
  Widget _buildSubTabs() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildTabPill(
          index: 0,
          label: "Terms & Conditions",
          icon: Icons.article_outlined,
        ),
        _buildTabPill(
          index: 1,
          label: "Return Policy",
          icon: Icons.replay_rounded,
        ),
      ],
    );
  }

  Widget _buildTabPill({required int index, required String label, required IconData icon}) {
    final isSelected = _selectedTab == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x334F46E5),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3A. Terms & Conditions Form Card
  Widget _buildTermsFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.article_outlined, color: Color(0xFF4F46E5), size: 20),
              const SizedBox(width: 8),
              Text(
                "Terms & Conditions",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // TERMS TITLE *
          Row(
            children: [
              Text(
                "TERMS TITLE",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              const Text("*", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _termsTitleController,
            onChanged: (v) => setState(() {}),
            style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF0F172A)),
            decoration: _inputDecoration("General Terms & Conditions"),
          ),
          const SizedBox(height: 18),

          // TERMS CONTENT *
          Row(
            children: [
              Text(
                "TERMS CONTENT",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              const Text("*", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),

          _buildRichEditor(_termsContentController),
          const SizedBox(height: 22),

          // Controls Row: SET AS DEFAULT TERMS & STATUS (Photo 2 & 5)
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 420;
              final defaultSwitchWidget = Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: _setAsDefaultTerms,
                      activeThumbColor: const Color(0xFF4F46E5),
                      activeTrackColor: const Color(0x664F46E5),
                      inactiveThumbColor: const Color(0xFF94A3B8),
                      inactiveTrackColor: const Color(0xFFE2E8F0),
                      onChanged: (val) {
                        setState(() {
                          _setAsDefaultTerms = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SET AS DEFAULT TERMS",
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "If enabled, automatically use these terms in all new sales invoices.",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final statusWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "STATUS",
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _statusPill("Active", isActive: _status == "Active"),
                        _statusPill("Inactive", isActive: _status == "Inactive"),
                      ],
                    ),
                  ),
                ],
              );

              if (isSmall) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    defaultSwitchWidget,
                    const SizedBox(height: 16),
                    statusWidget,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: defaultSwitchWidget),
                  const SizedBox(width: 14),
                  statusWidget,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // 3B. Return Policy Form Card (Photo 1 & Photo 2)
  Widget _buildReturnPolicyFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.replay_rounded, color: Color(0xFF4F46E5), size: 20),
              const SizedBox(width: 8),
              Text(
                "Return Policy",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // RETURN POLICY TITLE * (Photo 1)
          Row(
            children: [
              Text(
                "RETURN POLICY TITLE",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              const Text("*", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _returnTitleController,
            onChanged: (v) => setState(() {}),
            style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF0F172A)),
            decoration: _inputDecoration("Customer Return & Exchange Policy"),
          ),
          const SizedBox(height: 18),

          // RETURN POLICY DESCRIPTION * (Photo 1)
          Row(
            children: [
              Text(
                "RETURN POLICY DESCRIPTION",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              const Text("*", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          _buildRichEditor(_returnDescController),
          const SizedBox(height: 18),

          // RETURN DAYS (WINDOW) & REFUND TYPE (Photo 1)
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 450;
              final returnDaysField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("RETURN DAYS (WINDOW)", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _returnDaysController,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() {}),
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: _inputDecoration("7"),
                  ),
                  const SizedBox(height: 4),
                  Text("Days (0 = No returns)", style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
                ],
              );

              final refundTypeField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("REFUND TYPE", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRefundType,
                        isExpanded: true,
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B), fontWeight: FontWeight.w500),
                        items: ["Exchange", "Replacement", "Full Refund", "Store Credit"]
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedRefundType = v);
                        },
                      ),
                    ),
                  ),
                ],
              );

              if (isSmall) {
                return Column(
                  children: [
                    returnDaysField,
                    const SizedBox(height: 14),
                    refundTypeField,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: returnDaysField),
                  const SizedBox(width: 14),
                  Expanded(child: refundTypeField),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // RETURN APPLICABLE FOR Box (Photo 1 & Photo 2)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "RETURN APPLICABLE FOR",
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF475569), letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  "Define specific Categories, Brands, or Products eligible under this policy:",
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 12),

                // Sub-Tabs: Category (x) | Brand (x) | Product (x) (Photo 1)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildApplicablePill(0, "Category (${_selectedCategories.length})", Icons.folder_outlined),
                    _buildApplicablePill(1, "Brand (${_selectedBrands.length})", Icons.local_offer_outlined),
                    _buildApplicablePill(2, "Product (${_selectedProducts.length})", Icons.inventory_2_outlined),
                  ],
                ),
                const SizedBox(height: 14),

                // Dropdown + Custom Add Input
                if (_applicableSubTab == 0) _buildCategorySelector(),
                if (_applicableSubTab == 1) _buildBrandSelector(),
                if (_applicableSubTab == 2) _buildProductSelector(),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // STATUS segmented buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "STATUS",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _statusPill("Active", isActive: _status == "Active"),
                    _statusPill("Inactive", isActive: _status == "Inactive"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplicablePill(int index, String label, IconData icon) {
    final isSelected = _applicableSubTab == index;
    return InkWell(
      onTap: () => setState(() => _applicableSubTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF334155)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              hint: Text("-- Select Category --", style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8))),
              isExpanded: true,
              items: _availableCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.inter(fontSize: 12.5)))).toList(),
              onChanged: (val) {
                if (val != null && !_selectedCategories.contains(val)) {
                  setState(() => _selectedCategories.add(val));
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customCategoryController,
                style: GoogleFonts.inter(fontSize: 12.5),
                decoration: InputDecoration(
                  hintText: "Or type custom category...",
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onPressed: () {
                final txt = _customCategoryController.text.trim();
                if (txt.isNotEmpty && !_selectedCategories.contains(txt)) {
                  setState(() {
                    _selectedCategories.add(txt);
                    _customCategoryController.clear();
                  });
                }
              },
              child: const Text("+ Add", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Selected Categories Tags (Photo 1)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Selected Categories:", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
            if (_selectedCategories.isNotEmpty)
              InkWell(
                onTap: () => setState(() => _selectedCategories.clear()),
                child: Text("Clear All", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444))),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _selectedCategories.map((cat) {
            return _tagChip(cat, onRemove: () => setState(() => _selectedCategories.remove(cat)));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBrandSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              hint: Text("-- Select Brand --", style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8))),
              isExpanded: true,
              items: _availableBrands.map((b) => DropdownMenuItem(value: b, child: Text(b, style: GoogleFonts.inter(fontSize: 12.5)))).toList(),
              onChanged: (val) {
                if (val != null && !_selectedBrands.contains(val)) {
                  setState(() => _selectedBrands.add(val));
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customBrandController,
                style: GoogleFonts.inter(fontSize: 12.5),
                decoration: InputDecoration(
                  hintText: "Or type custom brand...",
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onPressed: () {
                final txt = _customBrandController.text.trim();
                if (txt.isNotEmpty && !_selectedBrands.contains(txt)) {
                  setState(() {
                    _selectedBrands.add(txt);
                    _customBrandController.clear();
                  });
                }
              },
              child: const Text("+ Add", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Selected Brands:", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
            if (_selectedBrands.isNotEmpty)
              InkWell(
                onTap: () => setState(() => _selectedBrands.clear()),
                child: Text("Clear All", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444))),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _selectedBrands.map((brand) {
            return _tagChip(brand, onRemove: () => setState(() => _selectedBrands.remove(brand)));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProductSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              hint: Text("-- Select Product --", style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8))),
              isExpanded: true,
              items: _availableProducts.map((p) => DropdownMenuItem(value: p, child: Text(p, style: GoogleFonts.inter(fontSize: 12.5)))).toList(),
              onChanged: (val) {
                if (val != null && !_selectedProducts.contains(val)) {
                  setState(() => _selectedProducts.add(val));
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customProductController,
                style: GoogleFonts.inter(fontSize: 12.5),
                decoration: InputDecoration(
                  hintText: "Or type custom product...",
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onPressed: () {
                final txt = _customProductController.text.trim();
                if (txt.isNotEmpty && !_selectedProducts.contains(txt)) {
                  setState(() {
                    _selectedProducts.add(txt);
                    _customProductController.clear();
                  });
                }
              },
              child: const Text("+ Add", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Selected Products:", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
            if (_selectedProducts.isNotEmpty)
              InkWell(
                onTap: () => setState(() => _selectedProducts.clear()),
                child: Text("Clear All", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444))),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _selectedProducts.map((p) {
            return _tagChip(p, onRemove: () => setState(() => _selectedProducts.remove(p)));
          }).toList(),
        ),
      ],
    );
  }

  Widget _tagChip(String label, {required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF4338CA))),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: Color(0xFF4338CA)),
          ),
        ],
      ),
    );
  }

  Widget _buildRichEditor(TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _toolbarButton("B", isBold: true, onTap: () => _insertFormatting(controller, "**", "**")),
                _toolbarButton("I", isItalic: true, onTap: () => _insertFormatting(controller, "*", "*")),
                _toolbarButton("U", isUnderline: true, onTap: () => _insertFormatting(controller, "__", "__")),
                const SizedBox(width: 4),
                _toolbarButton("H1", onTap: () => _insertPrefix(controller, "# ")),
                _toolbarButton("H2", onTap: () => _insertPrefix(controller, "## ")),
                const SizedBox(width: 4),
                _toolbarIconButton(Icons.format_list_bulleted, onTap: () => _insertPrefix(controller, "• ")),
                _toolbarIconButton(Icons.format_list_numbered, onTap: () => _insertPrefix(controller, "1. ")),
                _toolbarIconButton(Icons.format_quote, onTap: () => _insertPrefix(controller, "> ")),
                _toolbarIconButton(Icons.format_align_left, onTap: () {}),
                _toolbarIconButton(Icons.format_align_center, onTap: () {}),
                _toolbarIconButton(Icons.link, onTap: () => _insertFormatting(controller, "[", "](url)")),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: TextField(
              controller: controller,
              maxLines: 6,
              onChanged: (v) => setState(() {}),
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), height: 1.5),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: "Enter policy details...",
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
    );
  }

  Widget _toolbarButton(String label, {bool isBold = false, bool isItalic = false, bool isUnderline = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
            color: const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _toolbarIconButton(IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, size: 14, color: const Color(0xFF475569)),
      ),
    );
  }

  void _insertFormatting(TextEditingController controller, String prefix, String suffix) {
    final text = controller.text;
    final sel = controller.selection;
    if (sel.isValid && !sel.isCollapsed) {
      final selectedText = text.substring(sel.start, sel.end);
      final newText = text.replaceRange(sel.start, sel.end, "$prefix$selectedText$suffix");
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: sel.start + prefix.length + selectedText.length + suffix.length),
      );
    } else {
      final pos = sel.isValid ? sel.start : text.length;
      final newText = text.replaceRange(pos, pos, "$prefix$suffix");
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: pos + prefix.length),
      );
    }
    setState(() {});
  }

  void _insertPrefix(TextEditingController controller, String prefix) {
    final text = controller.text;
    final sel = controller.selection;
    final pos = sel.isValid ? sel.start : text.length;
    final newText = text.replaceRange(pos, pos, "\n$prefix");
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + prefix.length + 1),
    );
    setState(() {});
  }

  Widget _statusPill(String status, {required bool isActive}) {
    Color bg = Colors.transparent;
    Color fg = const Color(0xFF64748B);
    if (isActive) {
      if (status == "Active") {
        bg = const Color(0xFF10B981);
        fg = Colors.white;
      } else {
        bg = const Color(0xFFEF4444);
        fg = Colors.white;
      }
    }
    return InkWell(
      onTap: () => setState(() => _status = status),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          status,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }

  // 4. Live Invoice Preview (Photo 1 & Photo 2)
  Widget _buildLiveInvoicePreview() {
    final isTerms = _selectedTab == 0;
    final title = isTerms ? (_termsTitleController.text.trim().isEmpty ? "General Terms & Conditions" : _termsTitleController.text.trim())
                          : (_returnTitleController.text.trim().isEmpty ? "Customer Return & Exchange Policy" : _returnTitleController.text.trim());
    final content = isTerms ? _termsContentController.text.trim() : _returnDescController.text.trim();

    String applicableSummary = "";
    if (!isTerms) {
      List<String> parts = [];
      if (_selectedCategories.isNotEmpty) parts.add("Cat: ${_selectedCategories.join(', ')}");
      if (_selectedBrands.isNotEmpty) parts.add("Brand: ${_selectedBrands.join(', ')}");
      if (_selectedProducts.isNotEmpty) parts.add("Prod: ${_selectedProducts.join(', ')}");
      applicableSummary = parts.isEmpty ? "All items" : parts.join(" | ");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row: Sparkle + LIVE INVOICE PREVIEW badge
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, size: 13, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 5),
                  Text(
                    "LIVE INVOICE PREVIEW",
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4F46E5),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "Real-time simulation of customer receipt / PDF printout",
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Simulation Card (Photo 1 & Photo 2)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: BILLING & ERP | TAX INVOICE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "BILLING & ERP",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF475569),
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    "TAX INVOICE",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF475569),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 14),

              // Title Row
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Icon(isTerms ? Icons.description_outlined : Icons.replay_rounded, size: 16, color: const Color(0xFF1E293B)),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  // If Terms: Default Badge (removed when setAsDefaultTerms is false)
                  if (isTerms && _setAsDefaultTerms) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "Default",
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // If Return Policy: Return within X days & Type: Exchange (Photo 1)
              if (!isTerms) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "Return within ${_returnDaysController.text.trim()} days",
                        style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w700, color: const Color(0xFF4338CA)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "Type: $_selectedRefundType",
                        style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w700, color: const Color(0xFFB45309)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "For: $applicableSummary",
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B), fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 10),
              ],

              // Terms/Policy Content Display
              if (content.isNotEmpty)
                Text(
                  content,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF475569),
                    height: 1.55,
                  ),
                )
              else
                Text(
                  "No content provided yet.",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF94A3B8),
                  ),
                ),

              const SizedBox(height: 20),

              // Bottom footer: Thank you for your business!
              Center(
                child: Text(
                  "Thank you for your business!",
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 5. Action Buttons (Overflow-safe Wrap, Photo 2)
  Widget _buildActionButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Cancel / Reset Button
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          onPressed: _resetForm,
          child: Text(
            "Cancel / Reset",
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ),

        // Save Draft & Save Policy/Terms
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onPressed: () => _saveDocument(isDraft: true),
              child: Text(
                "Save Draft",
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                elevation: 1,
              ),
              onPressed: _isSaving ? null : () => _saveDocument(isDraft: false),
              icon: _isSaving
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined, size: 15),
              label: Text(
                _isSaving
                    ? "Saving..."
                    : (_editingDocId != null
                        ? (_selectedTab == 0 ? "Update Terms" : "Update Policy")
                        : (_selectedTab == 0 ? "Save Terms" : "Save Policy")),
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 6. Saved Terms & Return Policy Documents Table (Photo 2)
  Widget _buildSavedDocumentsSection() {
    final search = _searchController.text.trim().toLowerCase();
    final filtered = _documents.where((doc) {
      if (_filterType != "All Types" && doc.documentType != _filterType) return false;
      if (_filterStatus != "All Statuses" && doc.status != _filterStatus) return false;
      if (search.isNotEmpty && !doc.title.toLowerCase().contains(search) && !doc.content.toLowerCase().contains(search)) return false;
      return true;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.layers_outlined, color: Color(0xFF4F46E5), size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  "Saved Terms & Return Policy Documents",
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search & Filters Row
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 200, maxWidth: 360),
                child: _buildSearchInput(),
              ),
              SizedBox(width: 150, child: _buildTypeFilter()),
              SizedBox(width: 130, child: _buildStatusFilter()),
            ],
          ),
          const SizedBox(height: 18),

          // Data Table
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(36),
              alignment: Alignment.center,
              child: Text(
                "No matching documents found",
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 850),
                child: DataTable(
                  horizontalMargin: 12,
                  columnSpacing: 20,
                  headingRowHeight: 42,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 56,
                  headingTextStyle: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                  columns: const [
                    DataColumn(label: Text("ID")),
                    DataColumn(label: Text("DOCUMENT TYPE")),
                    DataColumn(label: Text("TITLE")),
                    DataColumn(label: Text("STATUS")),
                    DataColumn(label: Text("DEFAULT")),
                    DataColumn(label: Text("UPDATED BY")),
                    DataColumn(label: Text("UPDATED DATE")),
                    DataColumn(label: Text("ACTIONS")),
                  ],
                  rows: filtered.map((doc) {
                    return DataRow(
                      cells: [
                        // ID
                        DataCell(Text("#${doc.id}", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w600))),
                        // DOCUMENT TYPE
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: doc.documentType == "Return Policy" ? const Color(0xFFFEF3C7) : const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              doc.documentType,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: doc.documentType == "Return Policy" ? const Color(0xFFB45309) : const Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                        ),
                        // TITLE
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Text(
                              doc.title,
                              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // STATUS
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: doc.status == "Active" ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: doc.status == "Active" ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  doc.status,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: doc.status == "Active" ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // DEFAULT
                        DataCell(
                          doc.isDefault
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    "Default",
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF15803D),
                                    ),
                                  ),
                                )
                              : Text("-", style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
                        ),
                        // UPDATED BY
                        DataCell(Text(doc.updatedBy, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)))),
                        // UPDATED DATE
                        DataCell(Text(doc.updatedDate, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)))),
                        // ACTIONS (Eye -> View Modal, Edit -> Load form, Delete)
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // View Icon
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, size: 17, color: Color(0xFF64748B)),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                tooltip: "View Preview",
                                onPressed: () => _openViewDialog(doc),
                              ),
                              const SizedBox(width: 8),
                              // Edit Icon (Switches tab & loads data!)
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 17, color: Color(0xFF64748B)),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                tooltip: "Edit Document",
                                onPressed: () => _editDoc(doc),
                              ),
                              const SizedBox(width: 8),
                              // Delete Icon
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 17, color: Color(0xFFEF4444)),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                tooltip: "Delete Document",
                                onPressed: () => _deleteDoc(doc),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return TextField(
      controller: _searchController,
      onChanged: (v) => setState(() {}),
      style: GoogleFonts.inter(fontSize: 12.5),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        hintText: "Search by title...",
        hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.search, size: 17, color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
      ),
    );
  }

  Widget _buildTypeFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterType,
          isExpanded: true,
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1E293B)),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
          items: ["All Types", "Terms & Conditions", "Return Policy"]
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _filterType = v);
          },
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterStatus,
          isExpanded: true,
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1E293B)),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
          items: ["All Statuses", "Active", "Inactive"]
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _filterStatus = v);
          },
        ),
      ),
    );
  }
}
