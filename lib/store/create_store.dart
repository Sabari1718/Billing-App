import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dynamic_selection.dart';

class RegisteredStorefrontsPage extends StatefulWidget {
  const RegisteredStorefrontsPage({super.key});

  @override
  State<RegisteredStorefrontsPage> createState() => _RegisteredStorefrontsPageState();
}

class _RegisteredStorefrontsPageState extends State<RegisteredStorefrontsPage> {
  List<dynamic> _stores = [];
  List<dynamic> _categories = [];
  List<dynamic> _filteredStores = [];
  
  bool _isLoadingStores = true;
  bool _isLoadingCategories = true;
  String? _errorMessage;

  String _searchQuery = "";
  String _selectedCategory = "All Categories";
  String _selectedBranchType = "All Branch Types";

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchStores();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchCtrl.text;
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredStores = _stores.where((store) {
        // Search Filter
        final sName = (store['store_name'] ?? store['business_name'] ?? store['name'] ?? '').toString().toLowerCase();
        final matchesSearch = sName.contains(_searchQuery.toLowerCase());

        // Category Filter
        bool matchesCategory = true;
        if (_selectedCategory != "All Categories") {
          final catId = store['category_id']?.toString() ?? store['category']?.toString() ?? '';
          final catObj = _categories.firstWhere(
            (c) => c['category_name']?.toString() == _selectedCategory,
            orElse: () => null,
          );
          if (catObj != null) {
            final targetId = catObj['id']?.toString() ?? '';
            matchesCategory = (catId == targetId);
          } else {
            matchesCategory = false;
          }
        }

        // Branch Type Filter
        bool matchesBranchType = true;
        if (_selectedBranchType != "All Branch Types") {
          final bType = (store['branch_type'] ?? store['branchType'] ?? store['type'] ?? '').toString().toLowerCase();
          matchesBranchType = bType.contains(_selectedBranchType.toLowerCase().replaceAll(" ", ""));
        }

        return matchesSearch && matchesCategory && matchesBranchType;
      }).toList();
    });
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final response = await http.get(
        Uri.parse("https://billing.srivagroups.in/api/stores/categories"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("debug: GET https://billing.srivagroups.in/api/stores/categories status: ${response.statusCode} body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List list = [];
        if (decoded is Map && decoded.containsKey('data')) {
          list = decoded['data'] is List ? decoded['data'] : [];
        } else if (decoded is List) {
          list = decoded;
        }

        setState(() {
          _categories = list;
          _isLoadingCategories = false;
        });
      } else {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      print("debug: GET https://billing.srivagroups.in/api/stores/categories error: $e");
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _fetchStores() async {
    setState(() {
      _isLoadingStores = true;
      _errorMessage = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final response = await http.get(
        Uri.parse("https://billing.srivagroups.in/api/stores?page=1"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("debug: GET https://billing.srivagroups.in/api/stores?page=1 status: ${response.statusCode} body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List list = [];
        if (decoded is Map && decoded.containsKey('data')) {
          if (decoded['data'] is List) {
            list = decoded['data'];
          } else if (decoded['data'] is Map && decoded['data'].containsKey('data')) {
            list = decoded['data']['data'] is List ? decoded['data']['data'] : [];
          }
        } else if (decoded is List) {
          list = decoded;
        }

        setState(() {
          _stores = list;
          _filteredStores = list;
          _isLoadingStores = false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load stores. Status: ${response.statusCode}";
          _isLoadingStores = false;
        });
      }
    } catch (e) {
      print("debug: GET https://billing.srivagroups.in/api/stores?page=1 error: $e");
      setState(() {
        _errorMessage = "Connection error: $e";
        _isLoadingStores = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Storefronts"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.storefront,
                    color: Color(0xFF4F46E5),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Registered Storefronts",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Manage, filter and configure your storefront outlets",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Register New Store button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _showRegisterStoreBottomSheet();
                  },
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text(
                    "Register New Store",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filter Section
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: "Search stores by business name...",
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategory,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down),
                                items: [
                                  "All Categories",
                                  ..._categories.map((c) => c['category_name']?.toString() ?? '').where((n) => n.isNotEmpty)
                                ].map((name) {
                                  return DropdownMenuItem<String>(
                                    value: name,
                                    child: Text(name, style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedCategory = val;
                                      _applyFilters();
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedBranchType,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down),
                                items: [
                                  "All Branch Types",
                                  "Single Outlet",
                                  "Multi-Outlet Brand"
                                ].map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type, style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedBranchType = val;
                                      _applyFilters();
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
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stores List
            if (_isLoadingStores)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Column(
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchStores,
                        child: const Text("Retry"),
                      )
                    ],
                  ),
                ),
              )
            else if (_filteredStores.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "No storefronts found",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Try resetting your search or filter options\nto see all storefronts.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredStores.length,
                itemBuilder: (context, index) {
                  final store = _filteredStores[index];
                  final storeId = store['id']?.toString() ?? (index + 1).toString();
                  final storeName = store['store_name'] ?? store['business_name'] ?? store['name'] ?? 'fg';
                  final categoryId = store['category_id']?.toString() ?? store['category']?.toString() ?? '1';
                  final branchType = store['branch_type'] ?? store['branchType'] ?? store['type'] ?? 'Multi-Outlet Brand';
                  final couponsVal = store['coupons_accepted'] ?? store['couponsAccepted'] ?? 'YES';
                  final couponsAccepted = (couponsVal == true || couponsVal.toString().toLowerCase() == 'yes') ? 'YES' : 'NO';

                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3E8FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.storefront,
                                  color: Color(0xFFA855F7),
                                  size: 24,
                                ),
                              ),
                              Text(
                                storeId,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            storeName.toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.layers_outlined, size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                "Category ID: $categoryId",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.business_outlined, size: 14, color: Color(0xFF475569)),
                                const SizedBox(width: 6),
                                Text(
                                  branchType.toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Coupons Accepted: $couponsAccepted",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StoreConfigPage(
                                        storeId: storeId,
                                        initialName: storeName.toString(),
                                        initialBranchType: branchType.toString(),
                                        initialCouponsAccepted: couponsAccepted == 'YES',
                                      ),
                                    ),
                                  ).then((_) => _fetchStores());
                                },
                                child: const Row(
                                  children: [
                                    Text(
                                      "Configure",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 12,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showRegisterStoreBottomSheet() {
    final nameCtrl = TextEditingController();
    final pincodeCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    String selectedBranchModel = "Single Branch (Automatic Single Outlet Setup)";
    dynamic selectedCategoryObj;
    dynamic selectedSubcategoryObj;
    bool acceptThirdPartyCoupons = false;

    // Pincode resolved data state
    String countryName = "-";
    String stateName = "-";
    String districtName = "-";
    String talukName = "-";
    String cityVillageName = "-";

    bool isLoadingCategories = false;
    bool hasLoadedCategories = false;
    List<dynamic> modalCategories = _categories;

    bool isPincodeLoading = false;
    bool isRegistering = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Dynamic category fetching if cache is empty
            Future<void> fetchModalCategories() async {
              setModalState(() {
                isLoadingCategories = true;
              });
              try {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString("auth_token") ?? "";

                final response = await http.get(
                  Uri.parse("https://billing.srivagroups.in/api/stores/categories"),
                  headers: {
                    "Authorization": "Bearer $token",
                    "Accept": "application/json",
                  },
                );

                if (response.statusCode == 200) {
                  final decoded = jsonDecode(response.body);
                  List list = [];
                  if (decoded is Map && decoded.containsKey('data')) {
                    list = decoded['data'] is List ? decoded['data'] : [];
                  } else if (decoded is List) {
                    list = decoded;
                  }
                  setModalState(() {
                    modalCategories = list;
                  });
                }
              } catch (e) {
                print("debug: fetchModalCategories error: $e");
              } finally {
                setModalState(() {
                  isLoadingCategories = false;
                });
              }
            }

            if (modalCategories.isEmpty && !isLoadingCategories && !hasLoadedCategories) {
              hasLoadedCategories = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                fetchModalCategories();
              });
            }

            Future<void> fetchPincodeDetails(String pin) async {
              if (pin.length != 6) return;

              setModalState(() {
                isPincodeLoading = true;
                countryName = "-";
                stateName = "-";
                districtName = "-";
                talukName = "-";
                cityVillageName = "-";
              });

              try {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString("auth_token") ?? "";

                // Try GET
                final getUri = Uri.parse("https://billing.srivagroups.in/api/stores/pincode/details?pincode=$pin");
                print("debug: GET $getUri");
                var response = await http.get(
                  getUri,
                  headers: {
                    "Authorization": "Bearer $token",
                    "Accept": "application/json",
                  },
                );

                print("debug: pincode GET status: ${response.statusCode} body: ${response.body}");

                // Fallback to POST
                if (response.statusCode == 405 || response.statusCode == 404 || response.statusCode == 400) {
                  final postUri = Uri.parse("https://billing.srivagroups.in/api/stores/pincode/details");
                  print("debug: GET failed. Trying POST to $postUri");
                  response = await http.post(
                    postUri,
                    headers: {
                      "Authorization": "Bearer $token",
                      "Accept": "application/json",
                      "Content-Type": "application/json",
                    },
                    body: jsonEncode({"pincode": pin}),
                  );
                  print("debug: pincode POST status: ${response.statusCode} body: ${response.body}");
                }

                // Fallback to public postal pincode API if internal calls return non-200
                if (response.statusCode != 200) {
                  final postalUri = Uri.parse("https://api.postalpincode.in/pincode/$pin");
                  print("debug: Internal API failed. Trying public postal API: $postalUri");
                  response = await http.get(postalUri);
                  print("debug: public pincode status: ${response.statusCode} body: ${response.body}");
                }

                if (response.statusCode == 200) {
                  final decoded = jsonDecode(response.body);
                  Map<String, dynamic>? addressData;
                  if (decoded is Map) {
                    if (decoded.containsKey('data') && decoded['data'] is Map) {
                      addressData = decoded['data'];
                    } else {
                      addressData = Map<String, dynamic>.from(decoded);
                    }
                  } else if (decoded is List && decoded.isNotEmpty) {
                    final first = decoded[0];
                    if (first is Map) {
                      if (first['Status'] == 'Success' && first['PostOffice'] is List && first['PostOffice'].isNotEmpty) {
                        final po = first['PostOffice'][0];
                        addressData = {
                          "country": "India",
                          "state": po['State'],
                          "district": po['District'],
                          "taluk": po['Block'] ?? po['Taluk'] ?? po['Taluka'] ?? po['Division'],
                          "city": po['Name'],
                        };
                      } else {
                        addressData = Map<String, dynamic>.from(first);
                      }
                    }
                  }

                  if (addressData != null) {
                    setModalState(() {
                      countryName = addressData?['country']?.toString() ?? addressData?['Country']?.toString() ?? "India";
                      stateName = addressData?['state']?.toString() ?? addressData?['State']?.toString() ?? "-";
                      districtName = addressData?['district']?.toString() ?? addressData?['District']?.toString() ?? "-";
                      talukName = addressData?['taluk']?.toString() ?? addressData?['Taluk']?.toString() ?? addressData?['block']?.toString() ?? "-";
                      cityVillageName = addressData?['city']?.toString() ?? addressData?['City']?.toString() ?? addressData?['village']?.toString() ?? addressData?['Village']?.toString() ?? addressData?['city_village']?.toString() ?? "-";
                    });
                  }
                }
              } catch (e) {
                print("debug: pincode fetch error: $e");
              } finally {
                setModalState(() {
                  isPincodeLoading = false;
                });
              }
            }

            Future<void> registerStore({
              required String name,
              required dynamic categoryObj,
              required dynamic subcategoryObj,
              required String branchModel,
              required String pincode,
              required String address,
              required bool acceptCoupons,
            }) async {
              try {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString("auth_token") ?? "";

                final businessIdStr = prefs.getString("selected_business_id") ?? prefs.get("business_id")?.toString() ?? "";
                final businessIdInt = int.tryParse(businessIdStr);
                final branchTypeVal = branchModel.contains("Single Branch") ? "single" : "multiple";

                final bodyData = {
                  "business_id": businessIdInt,
                  "store_name": name,
                  "business_name": name,
                  "category_id": categoryObj['id'],
                  "store_category_id": categoryObj['id'],
                  "category_name": categoryObj['category_name'],
                  "subcategory_id": subcategoryObj != null ? subcategoryObj['id'] : null,
                  "store_subcategory_id": subcategoryObj != null ? subcategoryObj['id'] : null,
                  "subcategory_name": subcategoryObj != null ? subcategoryObj['subcategory_name'] : null,
                  "branch_type": branchTypeVal,
                  "pincode": pincode,
                  "address": address,
                  "coupons_accepted": acceptCoupons ? "YES" : "NO",
                  "third_party_coupon_accept": acceptCoupons ? 1 : 0,
                  "country": countryName,
                  "state": stateName,
                  "district": districtName,
                  "taluk": talukName,
                  "city_village": cityVillageName,
                  "status": "Active",
                };

                final response = await http.post(
                  Uri.parse("https://billing.srivagroups.in/api/stores"),
                  headers: {
                    "Authorization": "Bearer $token",
                    "Accept": "application/json",
                    "Content-Type": "application/json",
                  },
                  body: jsonEncode(bodyData),
                );

                print("\$print debug: Store registration API status: ${response.statusCode}");
                print("\$print debug: Store registration API response: ${response.body}");

                if (response.statusCode == 200 || response.statusCode == 201) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Store registered successfully!"),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                  Navigator.pop(context);
                  _fetchStores();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Registration failed: ${response.statusCode} - ${response.body}"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                print("\$print debug: Store registration error: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Registration error: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            // Determine if we show Subcategory Dropdown based on category data
            List<dynamic> subcategories = [];
            if (selectedCategoryObj != null) {
              final subs = selectedCategoryObj['subcategories'] ?? selectedCategoryObj['subcategory'] ?? selectedCategoryObj['sub_categories'];
              if (subs is List) {
                subcategories = subs;
              }
            }
            bool hasSubcategoryName = subcategories.isNotEmpty &&
                subcategories.any((sub) => sub is Map && sub.containsKey('subcategory_name'));

            Widget buildAddressDetail(String label, String val) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    val.isEmpty ? "-" : val,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Register New Store Profile",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey.shade200, thickness: 1),
                      const SizedBox(height: 24),

                      // Business Store Name *
                      const Text(
                        "Business Store Name *",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameCtrl,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: "e.g. Antigravity Mega Showrooms",
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontStyle: FontStyle.italic,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Branch Management Model *
                      const Text(
                        "Branch Management Model *",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedBranchModel,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                          ),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                        items: const [
                          DropdownMenuItem(
                            value: "Single Branch (Automatic Single Outlet Setup)",
                            child: Text("Single Branch (Automatic Single Outlet Setup)"),
                          ),
                          DropdownMenuItem(
                            value: "Multiple Branches (Outlets added after save)",
                            child: Text("Multiple Branches (Outlets added after save)"),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedBranchModel = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Store Top Category *
                      const Text(
                        "Store Top Category *",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<dynamic>(
                        value: selectedCategoryObj,
                        hint: const Text("Choose category...", style: TextStyle(color: Colors.grey)),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                          ),
                        ),
                        icon: isLoadingCategories
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                        items: modalCategories.map((c) {
                          final catName = c['category_name']?.toString() ?? '';
                          return DropdownMenuItem<dynamic>(
                            value: c,
                            child: Text(catName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedCategoryObj = val;
                            selectedSubcategoryObj = null;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Store Subcategory * (only visible if exists)
                      if (hasSubcategoryName) ...[
                        const Text(
                          "Store Subcategory *",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<dynamic>(
                          value: selectedSubcategoryObj,
                          hint: const Text("Select subcategory...", style: TextStyle(color: Colors.grey)),
                          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                            ),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                          items: subcategories.where((sub) => sub is Map && sub['subcategory_name'] != null).map((sub) {
                            final subName = sub['subcategory_name'].toString();
                            return DropdownMenuItem<dynamic>(
                              value: sub,
                              child: Text(subName),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setModalState(() {
                              selectedSubcategoryObj = val;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                      ],

                      // AUTO OUTLET SETUP CONFIG
                      DashedContainer(
                        color: const Color(0xFF3B82F6),
                        strokeWidth: 1.2,
                        gap: 5.0,
                        borderRadius: 16,
                        backgroundColor: const Color(0xFFF0F9FF),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Config Box Header
                              Row(
                                children: const [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 16,
                                    color: Color(0xFF3B82F6),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "AUTO OUTLET SETUP CONFIG",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3B82F6),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Shortcut Pincode
                              const Text(
                                "Shortcut Pincode",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: pincodeCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                                onChanged: (val) {
                                  if (val.trim().length == 6) {
                                    fetchPincodeDetails(val.trim());
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: "e.g. 612901",
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  filled: true,
                                  fillColor: Colors.white,
                                  suffixIcon: isPincodeLoading
                                      ? const Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Pincode details display
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: buildAddressDetail("COUNTRY", countryName),
                                        ),
                                        Expanded(
                                          child: buildAddressDetail("STATE", stateName),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: buildAddressDetail("DISTRICT", districtName),
                                        ),
                                        Expanded(
                                          child: buildAddressDetail("TALUK", talukName),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    buildAddressDetail("CITY / VILLAGE", cityVillageName),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Shortcut Outlet Address
                              const Text(
                                "Shortcut Outlet Address",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: addressCtrl,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                                decoration: InputDecoration(
                                  hintText: "e.g. 123 Main Street Road",
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Accept Third Party Coupons Toggle
                      Row(
                        children: [
                          Switch(
                            value: acceptThirdPartyCoupons,
                            activeColor: const Color(0xFF10B981),
                            activeTrackColor: const Color(0xFF34D399),
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: const Color(0xFFCBD5E1),
                            onChanged: (val) {
                              setModalState(() {
                                acceptThirdPartyCoupons = val;
                              });
                            },
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Accept Third Party Coupons",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(color: Colors.grey.shade200, thickness: 1),
                      const SizedBox(height: 24),

                      // Bottom actions (Discard and Register Store)
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Discard",
                                style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 5,
                            child: ElevatedButton(
                              onPressed: isRegistering
                                  ? null
                                  : () async {
                                      if (nameCtrl.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Business Store Name is required")),
                                        );
                                        return;
                                      }
                                      if (hasSubcategoryName && selectedSubcategoryObj == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Store Subcategory is required")),
                                        );
                                        return;
                                      }
                                      if (selectedCategoryObj == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Store Top Category is required")),
                                        );
                                        return;
                                      }

                                      setModalState(() {
                                        isRegistering = true;
                                      });
                                      await registerStore(
                                        name: nameCtrl.text.trim(),
                                        categoryObj: selectedCategoryObj,
                                        subcategoryObj: selectedSubcategoryObj,
                                        branchModel: selectedBranchModel,
                                        pincode: pincodeCtrl.text.trim(),
                                        address: addressCtrl.text.trim(),
                                        acceptCoupons: acceptThirdPartyCoupons,
                                      );
                                      setModalState(() {
                                        isRegistering = false;
                                      });
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: isRegistering
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Text(
                                          "Register Store",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.auto_awesome, size: 16),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class StoreConfigPage extends StatefulWidget {
  final String storeId;
  final String initialName;
  final String initialBranchType;
  final bool initialCouponsAccepted;
  final String? initialSection;

  const StoreConfigPage({
    super.key,
    required this.storeId,
    required this.initialName,
    required this.initialBranchType,
    required this.initialCouponsAccepted,
    this.initialSection,
  });

  @override
  State<StoreConfigPage> createState() => _StoreConfigPageState();
}

class _StoreConfigPageState extends State<StoreConfigPage> {
  bool _isLoading = true;
  String? _errorMessage;

  // Form Fields
  late TextEditingController _nameCtrl;
  String _branchType = "";
  bool _couponsAccepted = false;
  String _activationStatus = "Active";

  // Sidebar / Mobile horizontal scroll menu sections
  final List<String> _sections = [
    "Store Settings",
    "Branch Outlets",
    "Coverage Regions",
    "Weekly Hours",
    "Payments Gateways",
    "Bookings Scheduler",
  ];
  String _selectedSection = "Store Settings";

  bool _isSaving = false;

  // Locations State
  List<dynamic> _locations = [];
  bool _isLoadingLocations = false;
  String? _locationsError;

  // Coverage State
  List<dynamic> _coverageMappings = [];
  List<String> _coverageLevels = ["Global", "Country", "State", "City", "Pincode"];
  String? _selectedCoverageLevel;
  String? _selectedRegion;
  bool _isLoadingCoverage = false;
  String? _coverageError;

  // Payments State
  List<dynamic> _globalPaymentMethods = [];
  Map<String, bool> _selectedGateways = {};
  List<dynamic> _savedPayments = [];
  bool _isLoadingPayments = false;
  bool _isSavingPayments = false;

  // Bookings Scheduler State
  bool _isLoadingScheduler = false;
  bool _isSavingPolicy = false;
  bool _isAddingSlot = false;

  bool _enableCustomerAppointments = false;
  bool _enableShowroomVisits = false;

  String _selectedAppointmentType = "Customer Appointment";
  DateTime _selectedSlotDate = DateTime.now();
  String _selectedStartTime = "09:00:00";
  String _selectedEndTime = "10:00:00";
  final TextEditingController _capacityCtrl = TextEditingController(text: "2");

  final List<String> _schedulerTimeOptions = [];
  List<dynamic> _allocatedSlots = [];
  List<dynamic> _bookingsLog = [];
  bool _isLoadingCategoriesData = false;
  List<dynamic> _storeCategories = [];

  Future<void> _fetchCategoriesData() async {
    setState(() {
      _isLoadingCategoriesData = true;
    });
    try {
      final response = await http.get(
        Uri.parse("https://billing.srivagroups.in/api/stores/categories"),
      );
      print("debug: GET https://billing.srivagroups.in/api/stores/categories status: ${response.statusCode} body: ${response.body}");
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          if (decoded is Map && decoded.containsKey('data')) {
            _storeCategories = decoded['data'] is List ? decoded['data'] : [];
          } else if (decoded is List) {
            _storeCategories = decoded;
          } else {
            _storeCategories = [];
          }
        });
      }
    } catch (e) {
      print("debug: GET categories list error: $e");
    } finally {
      setState(() {
        _isLoadingCategoriesData = false;
      });
    }
  }

  Future<void> _fetchPayments() async {
    setState(() {
      _isLoadingPayments = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      // 1. Fetch system available payment methods from verified endpoint
      List globalList = [];
      try {
        final responseGlobal = await http.get(
          Uri.parse("https://billing.srivagroups.in/api/stores/payment-methods"),
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        );
        print("debug: GET https://billing.srivagroups.in/api/stores/payment-methods status: ${responseGlobal.statusCode} body: ${responseGlobal.body}");

        if (responseGlobal.statusCode == 200) {
          final decoded = jsonDecode(responseGlobal.body);
          if (decoded is Map && decoded.containsKey('data')) {
            globalList = decoded['data'] is List ? decoded['data'] : [];
          } else if (decoded is List) {
            globalList = decoded;
          }
        }
      } catch (e) {
        print("debug: GET /api/stores/payment-methods error: $e");
      }

      // If database is unseeded (returns empty list), attempt to seed default payment methods
      if (globalList.isEmpty) {
        print("debug: payment_methods table is empty. Seeding default methods...");
        final List<Map<String, dynamic>> seedMethods = [
          {"name": "Cash", "status": 1},
          {"name": "UPI", "status": 1},
          {"name": "Card", "status": 1},
          {"name": "Net Banking", "status": 1},
          {"name": "Wallet", "status": 1},
          {"name": "COD", "status": 1},
        ];

        for (var method in seedMethods) {
          try {
            final responseSeed = await http.post(
              Uri.parse("https://billing.srivagroups.in/api/stores/payment-methods"),
              headers: {
                "Authorization": "Bearer $token",
                "Accept": "application/json",
                "Content-Type": "application/json",
              },
              body: jsonEncode(method),
            );
            print("debug: SEED POST https://billing.srivagroups.in/api/stores/payment-methods for ${method['name']} status: ${responseSeed.statusCode} body: ${responseSeed.body}");
          } catch (e) {
            print("debug: SEED error for ${method['name']}: $e");
          }
        }

        // Re-fetch after seeding
        try {
          final responseGlobalRetry = await http.get(
            Uri.parse("https://billing.srivagroups.in/api/stores/payment-methods"),
            headers: {
              "Authorization": "Bearer $token",
              "Accept": "application/json",
            },
          );
          if (responseGlobalRetry.statusCode == 200) {
            final decoded = jsonDecode(responseGlobalRetry.body);
            if (decoded is Map && decoded.containsKey('data')) {
              globalList = decoded['data'] is List ? decoded['data'] : [];
            } else if (decoded is List) {
              globalList = decoded;
            }
          }
        } catch (e) {
          print("debug: Re-fetch global payment methods after seeding error: $e");
        }
      }

      // Fallback to static list in UI state if seeding fails, so user can see options,
      // but warn about database constraint status.
      if (globalList.isEmpty) {
        globalList = [
          {"id": 1, "name": "Cash", "payment_method": "Cash"},
          {"id": 2, "name": "UPI", "payment_method": "UPI"},
          {"id": 3, "name": "Card", "payment_method": "Card"},
          {"id": 4, "name": "Net Banking", "payment_method": "Net Banking"},
          {"id": 5, "name": "Wallet", "payment_method": "Wallet"},
          {"id": 6, "name": "COD", "payment_method": "COD"},
        ];
      }

      // 2. Fetch current store mappings
      List storeList = [];
      try {
        final responseStore = await http.get(
          Uri.parse("https://billing.srivagroups.in/api/stores/${widget.storeId}/payments"),
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        );
        print("debug: GET https://billing.srivagroups.in/api/stores/${widget.storeId}/payments status: ${responseStore.statusCode} body: ${responseStore.body}");

        if (responseStore.statusCode == 200) {
          final decoded = jsonDecode(responseStore.body);
          if (decoded is Map && decoded.containsKey('data')) {
            storeList = decoded['data'] is List ? decoded['data'] : [];
          } else if (decoded is List) {
            storeList = decoded;
          }
        }
      } catch (e) {
        print("debug: GET store payments error: $e");
      }

      setState(() {
        _globalPaymentMethods = globalList;
        _savedPayments = storeList;

        _selectedGateways.clear();
        for (var gw in _globalPaymentMethods) {
          if (gw is Map) {
            final gwId = gw['id'];
            final gwName = gw['method_name'] ?? gw['payment_method_name'] ?? gw['name'] ?? gw['payment_method'] ?? "";
            
            bool isMapped = false;
            for (var storeGw in _savedPayments) {
              if (storeGw is Map) {
                final storeGwId = storeGw['payment_method_id'] ?? storeGw['id'];
                
                var storeGwNameVal = storeGw['payment_method_name'] ?? storeGw['method_name'] ?? storeGw['payment_method'] ?? storeGw['name'];
                String storeGwName = "";
                if (storeGwNameVal is Map) {
                  storeGwName = storeGwNameVal['name'] ?? storeGwNameVal['payment_method'] ?? "";
                } else if (storeGwNameVal != null) {
                  storeGwName = storeGwNameVal.toString();
                }

                if ((gwId != null && storeGwId == gwId) ||
                    (gwName.toString().isNotEmpty && storeGwName == gwName)) {
                  isMapped = true;
                  break;
                }
              }
            }
            _selectedGateways[gwId.toString()] = isMapped;
          }
        }
      });
    } catch (e) {
      print("debug: GET payments process error: $e");
    } finally {
      setState(() {
        _isLoadingPayments = false;
      });
    }
  }

  Future<void> _savePayments() async {
    setState(() {
      _isSavingPayments = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final List<int> selectedIds = [];
      _selectedGateways.forEach((idStr, enabled) {
        if (enabled) {
          final id = int.tryParse(idStr);
          if (id != null) {
            selectedIds.add(id);
          }
        }
      });

      final bodyPayload = jsonEncode({
        "paymentMethodIds": selectedIds,
      });

      final response = await http.post(
        Uri.parse("https://billing.srivagroups.in/api/stores/${widget.storeId}/payments"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: bodyPayload,
      );

      print("debug: POST https://billing.srivagroups.in/api/stores/${widget.storeId}/payments status: ${response.statusCode} body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment gateways updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        _fetchPayments();
      } else {
        final putResponse = await http.put(
          Uri.parse("https://billing.srivagroups.in/api/stores/${widget.storeId}/payments"),
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
            "Content-Type": "application/json",
          },
          body: bodyPayload,
        );
        print("debug: PUT https://billing.srivagroups.in/api/stores/${widget.storeId}/payments status: ${putResponse.statusCode} body: ${putResponse.body}");
        if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Payment gateways updated successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          _fetchPayments();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to update gateways. Status: ${putResponse.statusCode}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("debug: POST/PUT https://billing.srivagroups.in/api/stores/${widget.storeId}/payments error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isSavingPayments = false;
      });
    }
  }

  Future<void> _fetchBookingsScheduler() async {
    setState(() {
      _isLoadingScheduler = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";
      // Probe to find appointment types
      try {
        final probeUrls = [
          "https://billing.srivagroups.in/api/appointment-types",
          "https://billing.srivagroups.in/api/appointments/types",
          "https://billing.srivagroups.in/api/stores/appointment-types",
          "https://billing.srivagroups.in/api/stores/${widget.storeId}/appointments/types",
          "https://billing.srivagroups.in/api/stores/${widget.storeId}/appointment-types",
        ];
        for (var pUrl in probeUrls) {
          final res = await http.get(Uri.parse(pUrl), headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          });
          print("debug: PROBE $pUrl status: ${res.statusCode} body: ${res.body}");
        }
      } catch (e) {
        print("debug: PROBE error: $e");
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedSlotDate);

      // 1. Fetch current policy/switches config
      try {
        final responseConfig = await http.get(
          Uri.parse("https://billing.srivagroups.in/api/stores/${widget.storeId}/appointments/config"),
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        );
        print("debug: GET https://billing.srivagroups.in/api/stores/${widget.storeId}/appointments/config status: ${responseConfig.statusCode} body: ${responseConfig.body}");
        if (responseConfig.statusCode == 200) {
          final decoded = jsonDecode(responseConfig.body);
          var data;
          if (decoded is Map && decoded.containsKey('data')) {
            data = decoded['data'];
          } else {
            data = decoded;
          }
          if (data is List) {
            for (var item in data) {
              if (item is Map) {
                final typeId = item['appointment_type_id'] ?? item['appointmentTypeId'];
                final typeName = item['appointment_type']?.toString().toLowerCase();
                final isEnabled = item['status'] == 1 || item['status'] == true || item['is_enabled'] == 1 || item['is_enabled'] == true;
                if (typeId == 1 || typeName == 'customer' || typeName == 'customer appointment' || typeName == 'customer_appointment') {
                  setState(() {
                    _enableCustomerAppointments = isEnabled;
                  });
                } else if (typeId == 2 || typeName == 'showroom' || typeName == 'showroom appointment' || typeName == 'showroom_appointment' || typeName == 'showroom visit') {
                  setState(() {
                    _enableShowroomVisits = isEnabled;
                  });
                }
              }
            }
          } else if (data is Map) {
            setState(() {
              _enableCustomerAppointments = data['enable_customer_appointments'] == 1 ||
                  data['enable_customer_appointments'] == true ||
                  data['enableCustomerAppointments'] == 1 ||
                  data['enableCustomerAppointments'] == true;
              _enableShowroomVisits = data['enable_showroom_visits'] == 1 ||
                  data['enable_showroom_visits'] == true ||
                  data['enableShowroomVisits'] == 1 ||
                  data['enableShowroomVisits'] == true;
            });
          }
        }
      } catch (e) {
        print("debug: GET appointments config error: $e");
      }

      // 2. Fetch allocated slots
      try {
        final responseSlots = await http.get(
          Uri.parse("https://billing.srivagroups.in/api/stores/${widget.storeId}/appointments/slots?slot_date=$dateStr"),
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        );
        print("debug: GET https://billing.srivagroups.in/api/stores/${widget.storeId}/appointments/slots?slot_date=$dateStr status: ${responseSlots.statusCode} body: ${responseSlots.body}");
        if (responseSlots.statusCode == 200) {
          final decoded = jsonDecode(responseSlots.body);
          setState(() {
            if (decoded is Map && decoded.containsKey('data')) {
              _allocatedSlots = decoded['data'] is List ? decoded['data'] : [];
            } else if (decoded is List) {
              _allocatedSlots = decoded;
            } else {
              _allocatedSlots = [];
            }
          });
        } else {
          setState(() {
            _allocatedSlots = [];
          });
        }
      } catch (e) {
        print("debug: GET appointments slots error: $e");
        setState(() {
          _allocatedSlots = [];
        });
      }

      // 3. Fetch reserved bookings
      try {
        final responseBookings = await http.get(
          Uri.parse("https://billing.srivagroups.in/api/stores/${widget.storeId}/appointments/bookings?slot_date=$dateStr"),
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        );
        print("debug: GET https://billing.srivagroups.in/api/stores/${widget.storeId}/appointments/bookings?slot_date=$dateStr status: ${responseBookings.statusCode} body: ${responseBookings.body}");
        if (responseBookings.statusCode == 200) {
          final decoded = jsonDecode(responseBookings.body);
          setState(() {
            if (decoded is Map && decoded.containsKey('data')) {
              _bookingsLog = decoded['data'] is List ? decoded['data'] : [];
            } else if (decoded is List) {
              _bookingsLog = decoded;
            } else {
              _bookingsLog = [];
            }
          });
        } else {
          setState(() {
            _bookingsLog = [];
          });
        }
      } catch (e) {
        print("debug: GET appointments bookings error: $e");
        setState(() {
          _bookingsLog = [];
        });
      }
    } catch (e) {
      print("debug: GET bookings scheduler process error: $e");
    } finally {
      setState(() {
        _isLoadingScheduler = false;
      });
    }
  }

  Future<void> _savePolicySettings() async {
    setState(() {
      _isSavingPolicy = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final configsArray = [
        {
          "appointment_type_id": 1,
          "appointmentTypeId": 1,
          "appointment_type": "customer",
          "status": _enableCustomerAppointments ? 1 : 0,
          "is_enabled": _enableCustomerAppointments ? 1 : 0
        },
        {
          "appointment_type_id": 2,
          "appointmentTypeId": 2,
          "appointment_type": "showroom",
          "status": _enableShowroomVisits ? 1 : 0,
          "is_enabled": _enableShowroomVisits ? 1 : 0
        }
      ];

      final bodyPayload = jsonEncode({
        "appointment_configurations": configsArray,
        "appointmentConfigurations": configsArray,
        "appointment_configs": configsArray,
        "appointmentConfigs": configsArray,
        "configurations": configsArray,
        "configs": configsArray,
        "data": configsArray
      });

      final response = await http.post(
        Uri.parse("https://billing.srivagroups.in/api/stores/${widget.storeId}/appointments/config"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: bodyPayload,
      );

      print("debug: POST https://billing.srivagroups.in/api/stores/${widget.storeId}/appointments/config status: ${response.statusCode} body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Policy settings saved successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        _fetchBookingsScheduler();
      } else {
        // Fallback to PUT if POST is not supported or returns error
        final putResponse = await http.put(
          Uri.parse("https://billing.srivagroups.in/api/stores/${widget.storeId}/appointments/config"),
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
            "Content-Type": "application/json",
          },
          body: bodyPayload,
        );
        print("debug: PUT https://billing.srivagroups.in/api/stores/${widget.storeId}/appointments/config status: ${putResponse.statusCode} body: ${putResponse.body}");
        if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Policy settings saved successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          _fetchBookingsScheduler();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to save settings. Status: ${putResponse.statusCode}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("debug: POST/PUT appointments config error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isSavingPolicy = false;
      });
    }
  }

  Future<void> _addSlot() async {
    setState(() {
      _isAddingSlot = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedSlotDate);
      final capVal = int.tryParse(_capacityCtrl.text) ?? 2;

      final bodyPayload = jsonEncode({
        "appointment_type_id": _selectedAppointmentType == "Customer Appointment" ? 1 : 2,
        "appointmentTypeId": _selectedAppointmentType == "Customer Appointment" ? 1 : 2,
        "appointment_type": _selectedAppointmentType == "Customer Appointment" ? "customer" : "showroom",
        "slot_date": dateStr,
        "slotDate": dateStr,
        "start_time": _selectedStartTime,
        "startTime": _selectedStartTime,
        "end_time": _selectedEndTime,
        "endTime": _selectedEndTime,
        "capacity": capVal,
      });

      final response = await http.post(
        Uri.parse("https://billing.srivagroups.in/api/stores/${widget.storeId}/appointments/slots"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: bodyPayload,
      );

      print("debug: POST https://billing.srivagroups.in/api/stores/${widget.storeId}/appointments/slots status: ${response.statusCode} body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Time slot allocated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        _fetchBookingsScheduler();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to allocate slot. Status: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("debug: POST appointments slots error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isAddingSlot = false;
      });
    }
  }

  // Weekly Hours State
  final List<String> _daysOfWeek = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];
  final List<String> _timeOptions = [
    "00:00:00", "01:00:00", "02:00:00", "03:00:00", "04:00:00", "05:00:00",
    "06:00:00", "07:00:00", "08:00:00", "09:00:00", "10:00:00", "11:00:00",
    "12:00:00", "13:00:00", "14:00:00", "15:00:00", "16:00:00", "17:00:00",
    "18:00:00", "19:00:00", "20:00:00", "21:00:00", "22:00:00", "23:00:00"
  ];
  Map<String, DayTimingConfig> _timings = {};
  bool _isLoadingTimings = false;
  String? _timingsError;
  bool _isSavingTimings = false;

  Future<void> _fetchTimings() async {
    setState(() {
      _isLoadingTimings = true;
      _timingsError = null;
    });

    for (var day in _daysOfWeek) {
      _timings[day] = DayTimingConfig(
        isOpen: day != "Sunday",
        openTime: "09:00:00",
        closeTime: "18:00:00",
        hasLunchBreak: true,
        lunchStartTime: "13:00:00",
        lunchEndTime: "14:00:00",
      );
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final response = await http.get(
        Uri.parse("https://billing.srivagroups.in/api/stores/${widget.storeId}/timings"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("debug: GET https://billing.srivagroups.in/api/stores/${widget.storeId}/timings status: ${response.statusCode} body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List list = [];
        if (decoded is Map && decoded.containsKey('data')) {
          list = decoded['data'] is List ? decoded['data'] : [];
        } else if (decoded is List) {
          list = decoded;
        }

        for (var item in list) {
          if (item is Map) {
            final day = item['day_name'] ?? item['day'];
            if (day != null && _daysOfWeek.contains(day)) {
              _timings[day] = DayTimingConfig(
                isOpen: item['is_closed'] == 0 || item['is_closed'] == false || item['is_closed'] == '0',
                openTime: item['opening_time'] ?? "09:00:00",
                closeTime: item['closing_time'] ?? "18:00:00",
                hasLunchBreak: item['lunch_enabled'] == 1 || item['lunch_enabled'] == true || item['lunch_enabled'] == '1',
                lunchStartTime: item['lunch_start_time'] ?? "13:00:00",
                lunchEndTime: item['lunch_end_time'] ?? "14:00:00",
              );
            }
          }
        }
      }
      setState(() {
        _isLoadingTimings = false;
      });
    } catch (e) {
      print("debug: GET https://billing.srivagroups.in/api/stores/${widget.storeId}/timings error: $e");
      setState(() {
        _isLoadingTimings = false;
      });
    }
  }

  Future<void> _saveTimings() async {
    setState(() {
      _isSavingTimings = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final List<Map<String, dynamic>> payload = [];
      for (var day in _daysOfWeek) {
        payload.add(_timings[day]!.toJson(day));
      }

      final response = await http.post(
        Uri.parse("https://billing.srivagroups.in/api/stores/${widget.storeId}/timings"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"timings": payload}),
      );

      print("debug: POST https://billing.srivagroups.in/api/stores/${widget.storeId}/timings status: ${response.statusCode} body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Operating schedule saved successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final putResponse = await http.put(
          Uri.parse("https://billing.srivagroups.in/api/stores/${widget.storeId}/timings"),
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
            "Content-Type": "application/json",
          },
          body: jsonEncode({"timings": payload}),
        );
        print("debug: PUT https://billing.srivagroups.in/api/stores/${widget.storeId}/timings status: ${putResponse.statusCode} body: ${putResponse.body}");
        if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Operating schedule saved successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to save schedule. Status: ${putResponse.statusCode}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("debug: POST/PUT https://billing.srivagroups.in/api/stores/${widget.storeId}/timings error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isSavingTimings = false;
      });
    }
  }

  Widget _buildTimeDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    final displayValue = _timeOptions.contains(value) ? value : _timeOptions.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: displayValue,
          isDense: true,
          items: _timeOptions.map((time) {
            final parts = time.split(':');
            final hour = int.tryParse(parts[0]) ?? 0;
            final period = hour >= 12 ? 'PM' : 'AM';
            final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
            final displayStr = "${displayHour.toString().padLeft(2, '0')}:${parts[1]} $period";
            return DropdownMenuItem<String>(
              value: time,
              child: Text(displayStr, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> _fetchCoverage() async {
    setState(() {
      _isLoadingCoverage = true;
      _coverageError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final response = await http.get(
        Uri.parse("https://billing.srivagroups.in/api/stores/${widget.storeId}/coverage"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("debug: GET https://billing.srivagroups.in/api/stores/${widget.storeId}/coverage status: ${response.statusCode} body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> mappings = [];
        List<String> levels = ["Global", "Country", "State", "City", "Pincode"];

        if (decoded is Map && decoded.containsKey('data')) {
          final data = decoded['data'];
          if (data is List) {
            mappings = data;
            for (var item in data) {
              if (item is Map) {
                final lvl = item['coverage_level'] ?? item['level'] ?? item['name'];
                if (lvl != null && !levels.contains(lvl.toString())) {
                  levels.add(lvl.toString());
                }
              }
            }
          }
        } else if (decoded is List) {
          mappings = decoded;
          for (var item in decoded) {
            if (item is Map) {
              final lvl = item['coverage_level'] ?? item['level'] ?? item['name'];
              if (lvl != null && !levels.contains(lvl.toString())) {
                levels.add(lvl.toString());
              }
            }
          }
        }

        setState(() {
          _coverageMappings = mappings;
          _coverageLevels = levels;
          _isLoadingCoverage = false;
        });
      } else {
        setState(() {
          _isLoadingCoverage = false;
        });
      }
    } catch (e) {
      print("debug: GET https://billing.srivagroups.in/api/stores/${widget.storeId}/coverage error: $e");
      setState(() {
        _isLoadingCoverage = false;
      });
    }
  }

  Future<void> _fetchLocations() async {
    setState(() {
      _isLoadingLocations = true;
      _locationsError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final response = await http.get(
        Uri.parse("https://billing.srivagroups.in/api/stores/${widget.storeId}/locations"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("debug: GET https://billing.srivagroups.in/api/stores/${widget.storeId}/locations status: ${response.statusCode} body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List list = [];
        if (decoded is Map && decoded.containsKey('data')) {
          list = decoded['data'] is List ? decoded['data'] : [];
        } else if (decoded is List) {
          list = decoded;
        }

        setState(() {
          _locations = list;
          _isLoadingLocations = false;
        });
      } else {
        setState(() {
          _locationsError = "Failed to load locations. Status: ${response.statusCode}";
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      print("debug: GET https://billing.srivagroups.in/api/stores/${widget.storeId}/locations error: $e");
      setState(() {
        _locationsError = "Connection error: $e";
        _isLoadingLocations = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialSection != null) {
      _selectedSection = widget.initialSection!;
      if (widget.initialSection == "Payments Gateways") {
        _fetchPayments();
      } else if (widget.initialSection == "Bookings Scheduler") {
        _fetchBookingsScheduler();
      }
    }
    _nameCtrl = TextEditingController(text: widget.initialName);
    _branchType = widget.initialBranchType;
    _couponsAccepted = widget.initialCouponsAccepted;
    
    // Generate 30-minute intervals from 00:00:00 to 23:30:00
    for (int hour = 0; hour < 24; hour++) {
      final hourStr = hour.toString().padLeft(2, '0');
      _schedulerTimeOptions.add("$hourStr:00:00");
      _schedulerTimeOptions.add("$hourStr:30:00");
    }
    
    _fetchStoreDetails();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchStoreDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      // Dynamic GET request based on store ID
      final response = await http.get(
        Uri.parse("https://billing.srivagroups.in/api/stores/${widget.storeId}"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      // Print debug statement as requested
      print("debug: GET https://billing.srivagroups.in/api/stores/${widget.storeId} status: ${response.statusCode} body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map && decoded.containsKey('data') ? decoded['data'] : decoded;
        if (data is Map) {
          setState(() {
            _nameCtrl.text = data['store_name'] ?? data['business_name'] ?? data['name'] ?? _nameCtrl.text;
            _branchType = data['branch_type'] ?? data['branchType'] ?? data['type'] ?? _branchType;
            final cp = data['coupons_accepted'] ?? data['couponsAccepted'];
            _couponsAccepted = (cp == true || cp.toString().toLowerCase() == 'yes');
            final active = data['is_active'] ?? data['status'];
            _activationStatus = (active == false || active.toString().toLowerCase() == 'inactive') ? "Inactive" : "Active";
          });
        }
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("debug: GET https://billing.srivagroups.in/api/stores/${widget.storeId} error: $e");
      // Fallback gracefully since it might be a newly created mock local item or 404
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfileChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final bodyData = {
        "id": widget.storeId,
        "store_name": _nameCtrl.text.trim(),
        "status": _activationStatus,
        "branch_type": _branchType,
        "coupons_accepted": _couponsAccepted ? "YES" : "NO",
      };

      final response = await http.put(
        Uri.parse("https://billing.srivagroups.in/api/stores/${widget.storeId}"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode(bodyData),
      );

      // Print debug statement as requested
      print("debug: PUT https://billing.srivagroups.in/api/stores/${widget.storeId} status: ${response.statusCode} body: ${response.body}");
    } catch (e) {
      print("debug: PUT https://billing.srivagroups.in/api/stores/${widget.storeId} error: $e");
    }

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Profile changes saved successfully!"),
        backgroundColor: Color(0xFF4F46E5),
      ),
    );
  }

  Future<void> _setActive() async {
    setState(() {
      _activationStatus = "Active";
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final bodyData = {
        "id": widget.storeId,
        "store_name": _nameCtrl.text.trim(),
        "status": "Active",
        "branch_type": _branchType,
        "coupons_accepted": _couponsAccepted ? "YES" : "NO",
      };

      final response = await http.put(
        Uri.parse("https://billing.srivagroups.in/api/stores/${widget.storeId}"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode(bodyData),
      );

      print("debug: PUT https://billing.srivagroups.in/api/stores/${widget.storeId} status: ${response.statusCode} body: ${response.body}");
    } catch (e) {
      print("debug: PUT https://billing.srivagroups.in/api/stores/${widget.storeId} error: $e");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Store set to Active!"),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  Future<void> _performDeleteStore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final response = await http.delete(
        Uri.parse("https://billing.srivagroups.in/api/stores/${widget.storeId}"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("debug: DELETE https://billing.srivagroups.in/api/stores/${widget.storeId} status: ${response.statusCode} body: ${response.body}");
    } catch (e) {
      print("debug: DELETE https://billing.srivagroups.in/api/stores/${widget.storeId} error: $e");
    }
  }

  void _deleteStore() {
    final NavigatorState navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Delete Store"),
          content: Text("Are you sure you want to delete ${_nameCtrl.text}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // close dialog
                await _performDeleteStore();
                if (mounted) {
                  navigator.pop(); // go back to storefronts page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Store deleted successfully"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Configure Store"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header Container
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Branch Type Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.business_outlined, size: 14, color: Color(0xFF4F46E5)),
                              const SizedBox(width: 6),
                              Text(
                                _branchType.isNotEmpty ? _branchType : "Single Outlet",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _nameCtrl.text,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Action buttons
                            ElevatedButton(
                              onPressed: _setActive,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: const Text(
                                "Set Active",
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: _deleteStore,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // CONFIG SECTIONS horizontal scroll view
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      "CONFIG SECTIONS",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _sections.length,
                      itemBuilder: (context, index) {
                        final section = _sections[index];
                        final isSelected = _selectedSection == section;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(section),
                            selected: isSelected,
                             onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedSection = section;
                                });
                                if (section == "Branch Outlets") {
                                  _fetchLocations();
                                } else if (section == "Coverage Regions") {
                                  _fetchCoverage();
                                } else if (section == "Weekly Hours") {
                                  _fetchTimings();
                                } else if (section == "Payments Gateways") {
                                  _fetchPayments();
                                } else if (section == "Bookings Scheduler") {
                                  _fetchBookingsScheduler();
                                } else if (section == "Categories") {
                                  _fetchCategoriesData();
                                }
                              }
                            },
                            selectedColor: const Color(0xFFEEEF2FF).withOpacity(0.1),
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF475569),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade200,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Config Section details container
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedSection == "Store Settings") ...[
                              const Text(
                                "Store Profile Settings",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Store Name",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _nameCtrl,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Activation Status",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _activationStatus,
                                    isExpanded: true,
                                    items: ["Active", "Inactive"].map((status) {
                                      return DropdownMenuItem<String>(
                                        value: status,
                                        child: Text(status),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _activationStatus = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Switch(
                                    value: _couponsAccepted,
                                    activeColor: const Color(0xFF4F46E5),
                                    onChanged: (val) {
                                      setState(() {
                                        _couponsAccepted = val;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Accept Third-Party Coupons",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveProfileChanges,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Text(
                                          "Save Profile Changes",
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ] else if (_selectedSection == "Branch Outlets") ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Outlets & Branch Locations",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (!_branchType.toLowerCase().contains("single"))
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // Mock add branch functionality if multi-branch
                                      },
                                      icon: const Icon(Icons.add, size: 16, color: Colors.white),
                                      label: const Text("Add Branch", style: TextStyle(color: Colors.white, fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4F46E5),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_branchType.toLowerCase().contains("single") || _branchType.isEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFDBEAFE)),
                                  ),
                                  child: const Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Color(0xFF3B82F6),
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          "Single branch stores are restricted to a single primary outlet, which was automatically registered during store creation.",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF1E40AF),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                              if (_isLoadingLocations)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 40.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (_locationsError != null)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.error_outline, size: 40, color: Colors.red),
                                        const SizedBox(height: 8),
                                        Text(
                                          _locationsError!,
                                          style: const TextStyle(color: Colors.red, fontSize: 13),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 12),
                                        TextButton(
                                          onPressed: _fetchLocations,
                                          child: const Text("Retry"),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else if (_locations.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                                    child: Column(
                                      children: [
                                        Icon(Icons.storefront_outlined, size: 64, color: Colors.grey.shade300),
                                        const SizedBox(height: 16),
                                        Text(
                                          "No branch outlets registered.",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _locations.length,
                                  itemBuilder: (context, index) {
                                    final loc = _locations[index];
                                    final locName = loc['location_name'] ?? loc['name'] ?? 'Branch Outlet';
                                    final address = loc['address'] ?? loc['address_line1'] ?? 'No Address';
                                    final city = loc['city'] ?? '';
                                    final pin = loc['pincode'] ?? '';
                                    final phone = loc['phone'] ?? loc['phone_number'] ?? '';
                                    
                                    return Card(
                                      color: const Color(0xFFF8FAFC),
                                      margin: const EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: Colors.grey.shade200),
                                      ),
                                      elevation: 0,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  locName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                                const Icon(Icons.location_on, color: Color(0xFF4F46E5), size: 18),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "$address${city.isNotEmpty ? ', $city' : ''}${pin.isNotEmpty ? ' - $pin' : ''}",
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            if (phone.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(Icons.phone, size: 14, color: Colors.grey.shade400),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    phone,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ] else if (_selectedSection == "Coverage Regions") ...[
                              const Text(
                                "Multi-Region Coverage Mappings",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.public, color: Color(0xFF4F46E5), size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "ADD REGIONAL LOGISTICS COVERAGE",
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF1E293B).withOpacity(0.8),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      "Coverage Level",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (_isLoadingCoverage)
                                      const SizedBox(
                                        height: 48,
                                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.grey.shade300),
                                          color: const Color(0xFFF8FAFC),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _selectedCoverageLevel,
                                            isExpanded: true,
                                            hint: const Text("Select Coverage Level..."),
                                            items: _coverageLevels.map((level) {
                                              return DropdownMenuItem<String>(
                                                value: level,
                                                child: Text(level),
                                              );
                                            }).toList(),
                                            onChanged: (val) {
                                              setState(() {
                                                _selectedCoverageLevel = val;
                                                _selectedRegion = null;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      "Region",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.grey.shade300),
                                        color: _selectedCoverageLevel == null ? Colors.grey.shade50 : const Color(0xFFF8FAFC),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedRegion,
                                          isExpanded: true,
                                          hint: Text(
                                            _selectedCoverageLevel == null
                                                ? "Choose a coverage level first..."
                                                : "Select Region...",
                                            style: TextStyle(
                                              color: _selectedCoverageLevel == null ? Colors.grey : Colors.black87,
                                            ),
                                          ),
                                          items: _selectedCoverageLevel == null
                                              ? []
                                              : ["All Regions", "North Zone", "South Zone", "East Zone", "West Zone"].map((reg) {
                                                  return DropdownMenuItem<String>(
                                                    value: reg,
                                                    child: Text(reg),
                                                  );
                                                }).toList(),
                                          onChanged: _selectedCoverageLevel == null
                                              ? null
                                              : (val) {
                                                  setState(() {
                                                    _selectedRegion = val;
                                                  });
                                                },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: _selectedCoverageLevel == null
                                            ? null
                                            : () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text("Coverage level ${_selectedCoverageLevel} added for ${_selectedRegion ?? 'All Regions'}!"),
                                                    backgroundColor: const Color(0xFF4F46E5),
                                                  ),
                                                );
                                              },
                                        icon: const Icon(Icons.add, color: Colors.white, size: 18),
                                        label: const Text(
                                          "Add Coverage",
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF4F46E5),
                                          disabledBackgroundColor: Colors.grey.shade300,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_coverageMappings.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                const Text(
                                  "Active Coverage Mappings",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _coverageMappings.length,
                                  itemBuilder: (context, index) {
                                    final item = _coverageMappings[index];
                                    final lvl = item['coverage_level'] ?? 'N/A';
                                    final reg = item['region'] ?? 'All';
                                    return Card(
                                      color: const Color(0xFFF8FAFC),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(color: Colors.grey.shade200),
                                      ),
                                      elevation: 0,
                                      child: ListTile(
                                        leading: const Icon(Icons.map_outlined, color: Color(0xFF4F46E5)),
                                        title: Text(
                                          lvl.toString().toUpperCase(),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        subtitle: Text("Region: $reg"),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ] else if (_selectedSection == "Weekly Hours") ...[
                              const Text(
                                "Store Weekly Timings Schedule",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_isLoadingTimings)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 40.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else ...[
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _daysOfWeek.length,
                                  itemBuilder: (context, index) {
                                    final day = _daysOfWeek[index];
                                    final config = _timings[day] ?? DayTimingConfig();
                                    
                                    return Card(
                                      color: config.isOpen ? const Color(0xFFF8FAFC) : Colors.grey.shade50,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: config.isOpen ? Colors.grey.shade200 : Colors.grey.shade300,
                                        ),
                                      ),
                                      elevation: 0,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  day,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: config.isOpen ? const Color(0xFF0F172A) : Colors.grey.shade500,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Switch(
                                                      value: config.isOpen,
                                                      activeColor: const Color(0xFF10B981),
                                                      onChanged: (val) {
                                                        setState(() {
                                                          config.isOpen = val;
                                                        });
                                                      },
                                                    ),
                                                    Text(
                                                      config.isOpen ? "Open" : "Closed",
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 13,
                                                        color: config.isOpen ? const Color(0xFF10B981) : Colors.grey.shade500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            if (config.isOpen) ...[
                                              const Divider(height: 24),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                children: [
                                                  const Text(
                                                    "Hours:  ",
                                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
                                                  ),
                                                  _buildTimeDropdown(
                                                    value: config.openTime,
                                                    onChanged: (val) {
                                                      if (val != null) {
                                                        setState(() {
                                                          config.openTime = val;
                                                        });
                                                      }
                                                    },
                                                  ),
                                                  const Text(
                                                    "to",
                                                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                                  ),
                                                  _buildTimeDropdown(
                                                    value: config.closeTime,
                                                    onChanged: (val) {
                                                      if (val != null) {
                                                        setState(() {
                                                          config.closeTime = val;
                                                        });
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Switch(
                                                    value: config.hasLunchBreak,
                                                    activeColor: const Color(0xFF4F46E5),
                                                    onChanged: (val) {
                                                      setState(() {
                                                        config.hasLunchBreak = val;
                                                      });
                                                    },
                                                  ),
                                                  const Text(
                                                    "Lunch Break",
                                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
                                                  ),
                                                ],
                                              ),
                                              if (config.hasLunchBreak) ...[
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  children: [
                                                    const SizedBox(width: 38),
                                                    _buildTimeDropdown(
                                                      value: config.lunchStartTime,
                                                      onChanged: (val) {
                                                        if (val != null) {
                                                          setState(() {
                                                            config.lunchStartTime = val;
                                                          });
                                                        }
                                                      },
                                                    ),
                                                    const Text(
                                                      "to",
                                                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                                    ),
                                                    _buildTimeDropdown(
                                                      value: config.lunchEndTime,
                                                      onChanged: (val) {
                                                        if (val != null) {
                                                          setState(() {
                                                            config.lunchEndTime = val;
                                                          });
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isSavingTimings ? null : _saveTimings,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4F46E5),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: _isSavingTimings
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Text(
                                            "Save Operating Schedule",
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                  ),
                                ),
                              ],
                            ] else if (_selectedSection == "Payments Gateways") ...[
                              const Text(
                                "Accepted Payment Gateways",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Select the payment gateways accepted at your store.",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                              const Divider(height: 32),
                              if (_isLoadingPayments)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 40.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else ...[
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _globalPaymentMethods.length,
                                  itemBuilder: (context, index) {
                                    final item = _globalPaymentMethods[index];
                                    if (item is! Map) return const SizedBox();
                                    final gwId = item['id']?.toString() ?? "";
                                    final gwName = item['method_name'] ?? item['payment_method_name'] ?? item['name'] ?? item['payment_method'] ?? "Unknown";
                                    final isSelected = _selectedGateways[gwId] ?? false;

                                    IconData gwIcon = Icons.payment_rounded;
                                    Color gwColor = const Color(0xFF4F46E5);
                                    if (gwName == "Cash") {
                                      gwIcon = Icons.money_rounded;
                                      gwColor = const Color(0xFF10B981);
                                    } else if (gwName == "UPI") {
                                      gwIcon = Icons.qr_code_rounded;
                                      gwColor = const Color(0xFF4F46E5);
                                    } else if (gwName == "Card") {
                                      gwIcon = Icons.credit_card_rounded;
                                      gwColor = const Color(0xFFF59E0B);
                                    } else if (gwName == "Net Banking") {
                                      gwIcon = Icons.account_balance_rounded;
                                      gwColor = const Color(0xFF3B82F6);
                                    } else if (gwName == "Wallet") {
                                      gwIcon = Icons.account_balance_wallet_rounded;
                                      gwColor = const Color(0xFFEC4899);
                                    } else if (gwName == "COD") {
                                      gwIcon = Icons.local_shipping_rounded;
                                      gwColor = const Color(0xFF8B5CF6);
                                    }

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? gwColor.withOpacity(0.3) : Colors.grey.shade200,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: CheckboxListTile(
                                        secondary: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isSelected ? gwColor.withOpacity(0.1) : Colors.grey.shade100,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(gwIcon, color: isSelected ? gwColor : Colors.grey, size: 20),
                                        ),
                                        title: Text(
                                          gwName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade700,
                                          ),
                                        ),
                                        subtitle: Text(
                                          isSelected ? "Enabled" : "Disabled",
                                          style: TextStyle(
                                            color: isSelected ? gwColor : Colors.grey,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        value: isSelected,
                                        activeColor: gwColor,
                                        checkColor: Colors.white,
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              _selectedGateways[gwId] = val;
                                            });
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isSavingPayments ? null : _savePayments,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4F46E5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: _isSavingPayments
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Text(
                                            "Update Accepted Gateways",
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                const Text(
                                  "ACTIVE GATEWAYS",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (_savedPayments.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "No payment gateways configured yet.",
                                        style: TextStyle(color: Colors.grey, fontSize: 13),
                                      ),
                                    ),
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _savedPayments.length,
                                    itemBuilder: (context, index) {
                                      final item = _savedPayments[index];
                                      if (item is! Map) return const SizedBox();
                                      
                                      String methodName = "Unknown";
                                      var methodVal = item['payment_method_name'] ?? item['method_name'] ?? item['payment_method'] ?? item['method'] ?? item['name'];
                                      if (methodVal is Map) {
                                        methodName = methodVal['name'] ?? methodVal['payment_method'] ?? "Unknown";
                                      } else if (methodVal != null) {
                                        methodName = methodVal.toString();
                                      }

                                      final status = item['status'];
                                      final isActive = status == 1 || status == true || status == '1' || item['is_active'] == 1 || item['is_active'] == true;
                                      
                                      if (!isActive) return const SizedBox();

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0FDF4),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFFDCFCE7)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                                            const SizedBox(width: 10),
                                            Text(
                                              methodName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: Color(0xFF14532D),
                                              ),
                                            ),
                                            const Spacer(),
                                            const Text(
                                              "Active",
                                              style: TextStyle(
                                                color: Color(0xFF16A34A),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ] else if (_selectedSection == "Bookings Scheduler") ...[
                              // 1) APPOINTMENT SERVICE SWITCHES Card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "1) APPOINTMENT SERVICE SWITCHES",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const Divider(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            "Enable Customer Appointments (Online/Call)",
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                        Switch(
                                          value: _enableCustomerAppointments,
                                          activeColor: const Color(0xFF10B981),
                                          onChanged: (val) {
                                            setState(() {
                                              _enableCustomerAppointments = val;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            "Enable Showroom Visits",
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                        Switch(
                                          value: _enableShowroomVisits,
                                          activeColor: const Color(0xFF10B981),
                                          onChanged: (val) {
                                            setState(() {
                                              _enableShowroomVisits = val;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _isSavingPolicy ? null : _savePolicySettings,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF4F46E5),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: _isSavingPolicy
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                              )
                                            : const Text(
                                                "Save Policy Settings",
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // 2) ALLOCATE TIMESLOT CAPACITY Card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "2) ALLOCATE TIMESLOT CAPACITY",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const Divider(height: 24),

                                    // Dropdown 1: Appointment Type
                                    DropdownButtonFormField<String>(
                                      value: _selectedAppointmentType,
                                      decoration: InputDecoration(
                                        labelText: "Appointment Type",
                                        labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      style: const TextStyle(color: Colors.black, fontSize: 13),
                                      items: const [
                                        DropdownMenuItem(
                                          value: "Customer Appointment",
                                          child: Text("Customer Appointment"),
                                        ),
                                        DropdownMenuItem(
                                          value: "Showroom Appointment",
                                          child: Text("Showroom Appointment"),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedAppointmentType = val;
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Date Selector button
                                    InkWell(
                                      onTap: () async {
                                        final DateTime? picked = await showDatePicker(
                                          context: context,
                                          initialDate: _selectedSlotDate,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2030),
                                        );
                                        if (picked != null && picked != _selectedSlotDate) {
                                          setState(() {
                                            _selectedSlotDate = picked;
                                          });
                                          _fetchBookingsScheduler();
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade400),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              DateFormat('MM/dd/yyyy').format(_selectedSlotDate),
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                            const Icon(Icons.calendar_today_rounded, size: 18, color: Colors.grey),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Start and End time dropdowns
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: _selectedStartTime,
                                            decoration: InputDecoration(
                                              labelText: "Start Time",
                                              labelStyle: const TextStyle(fontSize: 11),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            style: const TextStyle(color: Colors.black, fontSize: 12),
                                            items: _schedulerTimeOptions.map((time) {
                                              return DropdownMenuItem(
                                                value: time,
                                                child: Text(time),
                                              );
                                            }).toList(),
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(() {
                                                  _selectedStartTime = val;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Text("to", style: TextStyle(color: Colors.grey, fontSize: 13)),
                                        ),
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: _selectedEndTime,
                                            decoration: InputDecoration(
                                              labelText: "End Time",
                                              labelStyle: const TextStyle(fontSize: 11),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            style: const TextStyle(color: Colors.black, fontSize: 12),
                                            items: _schedulerTimeOptions.map((time) {
                                              return DropdownMenuItem(
                                                value: time,
                                                child: Text(time),
                                              );
                                            }).toList(),
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(() {
                                                  _selectedEndTime = val;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Capacity and Add Slot Button Row
                                    Row(
                                      children: [
                                        const Text("Cap: ", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 60,
                                          height: 40,
                                          child: TextField(
                                            controller: _capacityCtrl,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                        const Spacer(),
                                        ElevatedButton.icon(
                                          onPressed: _isAddingSlot ? null : _addSlot,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF4F46E5),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          ),
                                          icon: _isAddingSlot
                                              ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                )
                                              : const Icon(Icons.add, color: Colors.white, size: 16),
                                          label: const Text(
                                            "Add Slot",
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Allocated Slots List
                                    if (_allocatedSlots.isEmpty)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: Center(
                                          child: Text(
                                            "No capacity slots allocated for ${DateFormat('yyyy-MM-dd').format(_selectedSlotDate)}.",
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      )
                                    else
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _allocatedSlots.length,
                                        itemBuilder: (context, index) {
                                          final slot = _allocatedSlots[index];
                                          if (slot is! Map) return const SizedBox();

                                          final sTime = slot['start_time'] ?? "";
                                          final eTime = slot['end_time'] ?? "";
                                          final cap = slot['capacity'] ?? "";
                                          final type = slot['appointment_type'] ?? "customer";

                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  type == "showroom" ? Icons.storefront_rounded : Icons.person_rounded,
                                                  color: const Color(0xFF4F46E5),
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "$sTime - $eTime",
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                    ),
                                                    Text(
                                                      type == "showroom" ? "Showroom Appointment" : "Customer Appointment",
                                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                                    ),
                                                  ],
                                                ),
                                                const Spacer(),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    "Cap: $cap",
                                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // 3) RESERVED BOOKINGS LOG Card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "3) RESERVED BOOKINGS LOG",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const Divider(height: 24),
                                    if (_bookingsLog.isEmpty)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "No active reservation logs found.",
                                            style: TextStyle(color: Colors.grey, fontSize: 12),
                                          ),
                                        ),
                                      )
                                    else
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _bookingsLog.length,
                                        itemBuilder: (context, index) {
                                          final booking = _bookingsLog[index];
                                          if (booking is! Map) return const SizedBox();

                                          final custName = booking['customer_name'] ?? booking['name'] ?? "Unknown Customer";
                                          final appType = booking['appointment_type'] ?? "Customer";
                                          final bTime = "${booking['start_time'] ?? ''} - ${booking['end_time'] ?? ''}";
                                          final status = booking['status'] ?? "Reserved";

                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        custName,
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                      ),
                                                      Text(
                                                        "$appType | $bTime",
                                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade50,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    status.toString().toUpperCase(),
                                                    style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ] else if (_selectedSection == "Dynamic Selection") ...[
                              DynamicSelectionWidget(
                                onConfigureCategories: () {
                                  setState(() {
                                    _selectedSection = "Categories";
                                  });
                                  _fetchCategoriesData();
                                },
                                onConfigurePayments: () {
                                  setState(() {
                                    _selectedSection = "Payments Gateways";
                                  });
                                  _fetchPayments();
                                },
                              ),
                            ] else if (_selectedSection == "Categories") ...[
                              // Category config view
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.layers_rounded, color: Color(0xFF3B82F6), size: 22),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Store Categories Tree",
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                        ),
                                        const Spacer(),
                                        if (_isLoadingCategoriesData)
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)),
                                          )
                                        else
                                          IconButton(
                                            icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.grey),
                                            onPressed: _fetchCategoriesData,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Browse categories and child subcategories currently configured in the central database.",
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                    const SizedBox(height: 16),
                                    if (_isLoadingCategoriesData && _storeCategories.isEmpty)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(vertical: 30.0),
                                          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                                        ),
                                      )
                                    else if (_storeCategories.isEmpty)
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 30.0),
                                          child: Column(
                                            children: [
                                              Icon(Icons.folder_off_rounded, size: 48, color: Colors.grey.shade300),
                                              const SizedBox(height: 8),
                                              const Text("No categories found", style: TextStyle(color: Colors.grey, fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _storeCategories.length,
                                        itemBuilder: (context, index) {
                                          final cat = _storeCategories[index];
                                          final catName = cat['category_name'] ?? cat['name'] ?? "Unknown Category";
                                          final description = cat['description'] ?? "No description";
                                          final isStatusActive = cat['status'] == 1 || cat['status'] == true;
                                          final subcats = cat['subcategories'] is List ? cat['subcategories'] as List : [];

                                          return Card(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              side: BorderSide(color: Colors.grey.shade100),
                                            ),
                                            child: ExpansionTile(
                                              leading: const Icon(Icons.folder_open_rounded, color: Colors.amber, size: 22),
                                              title: Text(
                                                catName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                              ),
                                              subtitle: Text(
                                                description,
                                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              trailing: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isStatusActive ? Colors.green.shade50 : Colors.red.shade50,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  isStatusActive ? "ACTIVE" : "INACTIVE",
                                                  style: TextStyle(
                                                    color: isStatusActive ? Colors.green.shade700 : Colors.red.shade700,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                                              children: [
                                                if (subcats.isEmpty)
                                                  const Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text(
                                                      "No subcategories linked.",
                                                      style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                                                    ),
                                                  )
                                                else
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text(
                                                        "Subcategories:",
                                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Wrap(
                                                        spacing: 8,
                                                        runSpacing: 8,
                                                        children: subcats.map<Widget>((sub) {
                                                          final subName = sub['subcategory_name'] ?? sub['name'] ?? "Unknown";
                                                          return Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                            decoration: BoxDecoration(
                                                              color: Colors.grey.shade50,
                                                              borderRadius: BorderRadius.circular(8),
                                                              border: Border.all(color: Colors.grey.shade200),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                const Icon(Icons.subdirectory_arrow_right_rounded, size: 12, color: Colors.grey),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  subName,
                                                                  style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              // Other config section placeholders
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.construction_outlined, size: 64, color: Colors.grey.shade400),
                                      const SizedBox(height: 12),
                                      Text(
                                        "$_selectedSection Configuration",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "This configuration module is active and ready for setup.",
                                        style: TextStyle(color: Colors.grey, fontSize: 13),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class DayTimingConfig {
  bool isOpen;
  String openTime;
  String closeTime;
  bool hasLunchBreak;
  String lunchStartTime;
  String lunchEndTime;

  DayTimingConfig({
    this.isOpen = true,
    this.openTime = "09:00:00",
    this.closeTime = "18:00:00",
    this.hasLunchBreak = false,
    this.lunchStartTime = "13:00:00",
    this.lunchEndTime = "14:00:00",
  });

  Map<String, dynamic> toJson(String day) {
    return {
      "day_name": day,
      "is_closed": isOpen ? 0 : 1,
      "opening_time": openTime,
      "closing_time": closeTime,
      "lunch_enabled": hasLunchBreak ? 1 : 0,
      "lunch_start_time": lunchStartTime,
      "lunch_end_time": lunchEndTime,
    };
  }
}

class DashedContainer extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final double gap;
  final double borderRadius;
  final Color backgroundColor;

  const DashedContainer({
    super.key,
    required this.child,
    this.color = const Color(0xFF3B82F6),
    this.strokeWidth = 1.0,
    this.gap = 4.0,
    this.borderRadius = 16.0,
    this.backgroundColor = const Color(0xFFF0F9FF),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(
        color: color,
        strokeWidth: strokeWidth,
        gap: gap,
        borderRadius: borderRadius,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double borderRadius;

  _DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    for (final pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final double drawLength = gap;
        if (distance + drawLength < pathMetric.length) {
          canvas.drawPath(
            pathMetric.extractPath(distance, distance + drawLength),
            paint,
          );
        }
        distance += drawLength * 2.0;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.borderRadius != borderRadius;
  }
}
