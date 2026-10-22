part of 'add suppier.dart';

extension _AddSupplierScreenStateWidgets on _AddSupplierScreenState {
  // --- CARD 1: TAX INFO ---
  Widget _buildTaxInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.assignment_ind_outlined, color: Color(0xFF6366F1), size: 20),
              SizedBox(width: 8),
              Text(
                "Tax Information & Registration",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const Divider(height: 24),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "With GST",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isGST ? const Color(0xFF6366F1) : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text("|", style: TextStyle(color: Colors.grey.shade300)),
                    const SizedBox(width: 8),
                    Text(
                      "Without GST",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: !isGST ? const Color(0xFF6366F1) : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: !isGST,
                  activeColor: const Color(0xFF6366F1),
                  onChanged: (v) {
                    setState(() {
                      isGST = !v;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (isGST) ...[
            const Text(
              "GST NUMBER *",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: gstNumber,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: "E.G. 22AAAAAO0000A1",
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                fillColor: Colors.white,
                filled: true,
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              onChanged: (v) {
                if (v.length == 15) {
                  setState(() {
                    companyName.text = "GST Business Group Ltd";
                  });
                }
              },
            ),
            const SizedBox(height: 6),
            const Text(
              "Auto-fills company info based on GSTN",
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  // --- CARD 2: GENERAL INFO ---
  Widget _buildGeneralInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.person_add_alt_1_outlined, color: Color(0xFF6366F1), size: 20),
              SizedBox(width: 8),
              Text(
                "General Information",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const Divider(height: 24),

          _buildLabel("SUPPLIER NAME *"),
          _buildTextField(supplierName, "Enter full name"),
          const SizedBox(height: 16),

          _buildLabel("COMPANY NAME"),
          _buildTextField(companyName, "Enter company registered name"),
          const SizedBox(height: 16),

          _buildLabel("PAN NUMBER"),
          _buildTextField(panNumber, "ABCDE1234F", uppercase: true),
          const SizedBox(height: 16),

          _buildLabel("EMAIL ADDRESS"),
          _buildTextField(email, "example@company.com", keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),

          _buildLabel("PRIMARY PHONE NUMBER *"),
          _buildTextField(phone, "+91 00000 00000", keyboardType: TextInputType.phone),
        ],
      ),
    );
  }

  // --- CARD 2.5: ASSOCIATED BRANCHES ---
  Widget _buildBranchesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.language_outlined, color: Color(0xFF6366F1), size: 20),
              SizedBox(width: 8),
              Text(
                "Associated Branches",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const Divider(height: 24),

          if (branchesList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "No branches added yet. Click below to add branches.",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: branchesList.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final branch = branchesList[idx];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Branch #${idx + 1}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                branchesList.removeAt(idx);
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text("BRANCH NAME", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: branch.nameController,
                        decoration: InputDecoration(
                          hintText: "e.g. Head Office",
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text("BRANCH PHONE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: branch.phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: "Phone Number",
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              setState(() {
                branchesList.add(BranchRowData());
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3), style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF6366F1).withOpacity(0.03),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add, size: 14, color: Color(0xFF6366F1)),
                  SizedBox(width: 6),
                  Text(
                    "Add Another Branch",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CARD 3: ADDRESS CARD ---
  Widget _buildAddressCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_on_outlined, color: Color(0xFF6366F1), size: 20),
              SizedBox(width: 8),
              Text(
                "Address Details",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const Divider(height: 24),

          const Text(
            "ADDRESS TYPE",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          _buildAddressTypeOption("Shopping Complex", Icons.business),
          _buildAddressTypeOption("Factory", Icons.domain_outlined),
          _buildAddressTypeOption("Warehouse", Icons.warehouse_outlined),
          const SizedBox(height: 20),

          _buildLabel("BUILD NAME/NO"),
          _buildTextField(building, "Building Name/No"),
          const SizedBox(height: 16),

          _buildLabel("STREET"),
          _buildTextField(street, "Street Name"),
          const SizedBox(height: 16),

          _buildLabel("LANDMARK"),
          _buildTextField(landmark, "Near Landmark"),
          const SizedBox(height: 16),

          _buildLabel("PINCODE"),
          TextFormField(
            controller: pincode,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "000000",
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              fillColor: Colors.white,
              filled: true,
              suffixIcon: isPincodeLoading
                  ? Container(
                      width: 20,
                      height: 20,
                      padding: const EdgeInsets.all(12),
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            onChanged: (v) {
              if (v.length == 6) fetchLocationFromPincode(v);
            },
          ),
          const SizedBox(height: 16),

          _buildLabel("CITY"),
          _buildTextField(city, "City"),
          const SizedBox(height: 16),

          _buildLabel("STATE"),
          _buildTextField(state, "State"),
        ],
      ),
    );
  }

  Widget _buildAddressTypeOption(String type, IconData icon) {
    final bool isSelected = selectedAddressType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAddressType = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade500,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              type,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF1E1B4B) : Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF6366F1), size: 20)
            else
              Icon(Icons.circle_outlined, color: Colors.grey.shade300, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool uppercase = false, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: uppercase ? TextCapitalization.characters : TextCapitalization.none,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        fillColor: Colors.white,
        filled: true,
      ),
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
    );
  }
}
