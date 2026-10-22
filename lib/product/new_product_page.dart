import 'dart:io';
import 'package:flutter/material.dart';
import 'package:billingapp/Auth/api service.dart';

part 'new_product_page_logic.dart';

class NewProductScreen extends StatefulWidget {
  const NewProductScreen({super.key});

  @override
  State<NewProductScreen> createState() => _NewProductScreenState();
}

class _NewProductScreenState extends State<NewProductScreen> with NewProductScreenLogic {

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
          ),
          if (required)
            const Text(
              " *",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumeric = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Product"),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark 
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Purple Banner Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF818CF8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Create New Product",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Add a new item to your enterprise catalog with detailed attributes",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.add, size: 14, color: Color(0xFF4F46E5)),
                                SizedBox(width: 4),
                                Text("Add Product", style: TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white38),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.list, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text("Product List", style: TextStyle(color: Colors.white, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Product Classification Card
                Card(
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.category, color: Colors.blue, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Product Classification",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                  ),
                                  Text(
                                    "Define the sector, category and brand hierarchy for this product",
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                        const Divider(height: 30),
                        
                        // Sector Title Dropdown
                        _buildFieldLabel("Sector Title", required: true),
                        IgnorePointer(
                          ignoring: isClassificationLocked,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedSectorTitle,
                            hint: const Text("Select Sector Title"),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isClassificationLocked ? Colors.grey.shade100 : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                            ),
                            items: sectorTitles.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedSectorTitle = val;
                              });
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 16),

                        // Sector Dropdown
                        _buildFieldLabel("Sector", required: true),
                        IgnorePointer(
                          ignoring: isClassificationLocked || selectedSectorTitle == null,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedSector,
                            hint: Text(selectedSectorTitle == null ? "Select Sector Title first" : "Select Sector"),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isClassificationLocked || selectedSectorTitle == null ? Colors.grey.shade100 : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                            ),
                            items: sectors.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedSector = val;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Category Dropdown
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildFieldLabel("Category", required: true),
                            if (selectedSector != null)
                              TextButton(
                                onPressed: () {},
                                child: const Text("+ Secondary Category", style: TextStyle(fontSize: 12, color: Colors.blueAccent)),
                              ),
                          ],
                        ),
                        IgnorePointer(
                          ignoring: isClassificationLocked || selectedSector == null,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedCategory,
                            hint: Text(selectedSector == null ? "Select Sector first" : "Select Category"),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isClassificationLocked || selectedSector == null ? Colors.grey.shade100 : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                            ),
                            items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedCategory = val;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Brand Dropdown
                        _buildFieldLabel("Brand", required: true),
                        IgnorePointer(
                          ignoring: isClassificationLocked,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedBrand,
                            hint: const Text("Select Brand"),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isClassificationLocked ? Colors.grey.shade100 : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                            ),
                            items: brands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedBrand = val;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Fix Classification Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (selectedSectorTitle == null || selectedSector == null || selectedCategory == null || selectedBrand == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Please select all classification fields first.")),
                                );
                                return;
                              }
                              setState(() {
                                isClassificationLocked = !isClassificationLocked;
                              });
                            },
                            icon: Icon(isClassificationLocked ? Icons.lock : Icons.lock_open, size: 16),
                            label: Text(isClassificationLocked ? "Unlock Classification" : "Fix Classification"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isClassificationLocked ? Colors.amber.shade700 : const Color(0xFF64748B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Product Details Form Card
                Card(
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
                        _buildFieldLabel("Product Name", required: true),
                        _buildTextField(nameController, "e.g. Wireless Ergonomic Keyboard"),
                        
                        const SizedBox(height: 16),

                        _buildFieldLabel("HSN Code"),
                        _buildTextField(hsnController, "e.g. 84716060"),

                        const SizedBox(height: 16),

                        _buildFieldLabel("Series"),
                        _buildTextField(seriesController, "e.g. Pro-Series v2"),

                        const SizedBox(height: 16),

                        _buildFieldLabel("Alternative Name"),
                        _buildTextField(altNameController, "e.g. Bluetooth Keyboard / Keypad"),

                        const SizedBox(height: 16),

                        _buildFieldLabel("MRP (₹)"),
                        _buildTextField(mrpController, "0.00", isNumeric: true),

                        const SizedBox(height: 16),

                        _buildFieldLabel("Status"),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Switch(
                                    value: isProductActive,
                                    onChanged: (val) {
                                      setState(() {
                                        isProductActive = val;
                                      });
                                    },
                                    activeColor: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isProductActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isProductActive ? "ACTIVE" : "INACTIVE",
                                      style: TextStyle(
                                        color: isProductActive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        _buildFieldLabel("Description"),
                        _buildTextField(descController, "Enter detailed description of the product features, specification, or model details...", maxLines: 4),

                        const SizedBox(height: 16),

                        // Image Upload Widget (Dotted Border design)
                        _buildFieldLabel("Product Image"),
                        CustomPaint(
                          painter: DashedBorderPainter(color: Colors.grey.shade300),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF2563EB), size: 24),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Click to upload or drag image here",
                                  style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "PNG, JPG, WEBP up to 5MB",
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Preferred Supplier & Info
                Card(
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
                        _buildFieldLabel("Additional Info"),
                        _buildTextField(addInfoController, "Enter warranty info, dimensions, weight, compliance standards...", maxLines: 3),

                        const SizedBox(height: 16),

                        _buildFieldLabel("Preferred Supplier"),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: selectedSupplier,
                          hint: const Text("-- Select Preferred Supplier --"),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                          ),
                          items: suppliers.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedSupplier = val;
                            });
                          },
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Checkbox(
                              value: setAsDefaultSupplier,
                              onChanged: (val) {
                                setState(() {
                                  setAsDefaultSupplier = val ?? false;
                                });
                              },
                              activeColor: const Color(0xFF4F46E5),
                            ),
                            const Text(
                              "Set as Default Supplier",
                              style: TextStyle(fontSize: 13, color: Colors.black87),
                            )
                          ],
                        ),

                        const SizedBox(height: 16),

                        _buildFieldLabel("Notes"),
                        _buildTextField(notesController, "Internal notes or handling instructions...", maxLines: 3),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 5. Save and Cancel Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _resetForm,
                        icon: const Icon(Icons.sync, size: 16),
                        label: const Text("Reset Form"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          foregroundColor: Colors.grey.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveProduct,
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text("Save Product"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          shadowColor: const Color(0xFF4F46E5).withOpacity(0.4),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Dashed Border Painter
class DashedBorderPainter extends CustomPainter {
  final Color color;
  DashedBorderPainter({this.color = Colors.grey});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    const double dashWidth = 5.0;
    const double dashSpace = 3.0;
    
    // Draw top
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
    // Draw right
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(size.width, startY), Offset(size.width, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
    // Draw bottom
    double endX = size.width;
    while (endX > 0) {
      canvas.drawLine(Offset(endX, size.height), Offset(endX - dashWidth, size.height), paint);
      endX -= dashWidth + dashSpace;
    }
    // Draw left
    double endY = size.height;
    while (endY > 0) {
      canvas.drawLine(Offset(0, endY), Offset(0, endY - dashWidth), paint);
      endY -= dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
