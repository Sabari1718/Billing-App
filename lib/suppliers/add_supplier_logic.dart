part of 'add suppier.dart';

mixin AddSupplierLogic on State<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  int currentStep = 1;

  // Controllers
  final TextEditingController supplierName = TextEditingController();
  final TextEditingController companyName = TextEditingController();
  final TextEditingController panNumber = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController gstNumber = TextEditingController();

  final TextEditingController building = TextEditingController();
  final TextEditingController street = TextEditingController();
  final TextEditingController landmark = TextEditingController();
  final TextEditingController city = TextEditingController();
  final TextEditingController state = TextEditingController();
  final TextEditingController pincode = TextEditingController();
  final TextEditingController generalPincode = TextEditingController();

  // Associated branches
  List<BranchRowData> branchesList = [];

  bool isGST = true;
  bool isLoading = false;
  bool isPincodeLoading = false;
  String token = "";
  String selectedAddressType = "Shopping Complex";

  @override
  void dispose() {
    supplierName.dispose();
    companyName.dispose();
    panNumber.dispose();
    email.dispose();
    phone.dispose();
    gstNumber.dispose();
    building.dispose();
    street.dispose();
    landmark.dispose();
    city.dispose();
    state.dispose();
    pincode.dispose();
    generalPincode.dispose();
    for (var b in branchesList) {
      b.dispose();
    }
    super.dispose();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString("auth_token") ?? "";
    });
  }

  // 📍 PINCODE AUTOFILL
  Future<void> fetchLocationFromPincode(String pin) async {
    if (pin.length != 6) return;

    setState(() => isPincodeLoading = true);
    final url = Uri.parse("https://api.postalpincode.in/pincode/$pin");

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data != null && data is List && data.isNotEmpty && data[0]['Status'] == 'Success') {
        final postOffice = data[0]['PostOffice'][0];
        final district = postOffice['District'];
        final stateName = postOffice['State'];

        setState(() {
          city.text = district;
          state.text = stateName;
        });
      }
    } catch (e) {
      AppLogger.error("Pincode API Error", e);
    } finally {
      if (mounted) setState(() => isPincodeLoading = false);
    }
  }

  // 🔥 API SAVE
  Future<void> saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    final url = Uri.parse("https://billing.srivagroups.in/api/suppliers/");

    // Format branches array
    List<Map<String, String>> formattedBranches = [];
    for (var b in branchesList) {
      if (b.nameController.text.trim().isNotEmpty) {
        formattedBranches.add({
          "branch_name": b.nameController.text.trim(),
          "branch_phone": b.phoneController.text.trim(),
          "branch_pincode": b.pincodeController.text.trim(),
        });
      }
    }

    final finalPin = pincode.text.trim().isNotEmpty ? pincode.text.trim() : generalPincode.text.trim();

    final body = {
      "supplier_name": supplierName.text.trim(),
      "company_name": companyName.text.trim().isEmpty ? supplierName.text.trim() : companyName.text.trim(),
      "pan_number": panNumber.text.toUpperCase().trim(),
      "email": email.text.trim(),
      "primary_phone": phone.text.trim(),
      "is_gst_registered": isGST,
      "gst_number": isGST ? gstNumber.text.toUpperCase().trim() : "",
      "building_name": building.text.trim(),
      "street": street.text.trim(),
      "landmark": landmark.text.trim(),
      "city": city.text.trim(),
      "state": state.text.trim(),
      "pincode": finalPin,
      "status": "verified",
      "is_same_as_permanent": false,
      "branches": formattedBranches,
    };

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Supplier Saved Successfully ✅"), backgroundColor: Color(0xFF10B981)),
          );
          Navigator.pop(context, true); // Pop with refresh result
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save: ${response.body} ❌"), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      AppLogger.error("Save Supplier Error", e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Network Error ❌"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Next step handler with validation
  void _handleNextStep() {
    if (currentStep == 1) {
      if (isGST && gstNumber.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter GST number ⚠️"), backgroundColor: Colors.orange),
        );
        return;
      }
      if (isGST && gstNumber.text.trim().length != 15) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("GST number must be 15 digits ⚠️"), backgroundColor: Colors.orange),
        );
        return;
      }
      if (isGST && companyName.text.isEmpty && gstNumber.text.length >= 7) {
        setState(() {
          companyName.text = "GST Business Group Ltd";
        });
      }
      setState(() => currentStep = 2);
    } else if (currentStep == 2) {
      if (supplierName.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter Supplier Name ⚠️"), backgroundColor: Colors.orange),
        );
        return;
      }
      if (phone.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter Phone Number ⚠️"), backgroundColor: Colors.orange),
        );
        return;
      }
      setState(() => currentStep = 3);
    } else if (currentStep == 3) {
      saveSupplier();
    }
  }

  void _handleBackStep() {
    if (currentStep > 1) {
      setState(() => currentStep--);
    }
  }
}
