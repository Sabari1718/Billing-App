part of 'new_product_page.dart';

mixin NewProductScreenLogic on State<NewProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Dropdown Selections
  String? selectedSectorTitle;
  String? selectedSector;
  String? selectedCategory;
  String? selectedBrand;
  String? selectedSupplier;

  // Controllers
  final nameController = TextEditingController();
  final hsnController = TextEditingController();
  final seriesController = TextEditingController();
  final altNameController = TextEditingController();
  final mrpController = TextEditingController();
  final descController = TextEditingController();
  final addInfoController = TextEditingController();
  final notesController = TextEditingController();

  // Status variables
  bool isClassificationLocked = false;
  bool isProductActive = true;
  bool setAsDefaultSupplier = true;
  File? selectedImage;

  // Mock Options
  final sectorTitles = ["Retail Catalog", "Wholesale Distribution", "Service Inventory"];
  final sectors = ["Electronics & Tech", "Consumer Goods", "Industrial Equipment"];
  final categories = ["Peripherals", "Mobile Devices", "Audio Gear"];
  final brands = ["Logitech", "Apple", "Samsung", "Sony"];
  final suppliers = ["Sriva Groups Pvt Ltd", "Prime Distributor Corp", "Global Supplies Inc"];

  @override
  void dispose() {
    nameController.dispose();
    hsnController.dispose();
    seriesController.dispose();
    altNameController.dispose();
    mrpController.dispose();
    descController.dispose();
    addInfoController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      selectedSectorTitle = null;
      selectedSector = null;
      selectedCategory = null;
      selectedBrand = null;
      selectedSupplier = null;
      nameController.clear();
      hsnController.clear();
      seriesController.clear();
      altNameController.clear();
      mrpController.clear();
      descController.clear();
      addInfoController.clear();
      notesController.clear();
      isClassificationLocked = false;
      isProductActive = true;
      setAsDefaultSupplier = true;
      selectedImage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Form reset successfully.")),
    );
  }

  void _saveProduct() {
    if (selectedSectorTitle == null || selectedSector == null || selectedCategory == null || selectedBrand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Please complete and fix the Product Classification first."),
        ),
      );
      return;
    }
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Product Name is required."),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text("Success"),
          ],
        ),
        content: Text("Product '\${nameController.text.trim()}' created successfully!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }
}
