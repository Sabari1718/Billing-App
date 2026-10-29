part of 'add suppier.dart';

extension _AddSupplierScreenStateWidgets on _AddSupplierScreenState {
  // --- CARD 1: TAX INFO (PHOTOS 2 & 3) ---
  Widget _buildTaxInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
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
              Icon(Icons.credit_card_outlined, color: Color(0xFF4F46E5), size: 20),
              SizedBox(width: 8),
              Text(
                "Tax Information & Registration",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const Divider(height: 24),

          // With GST / Without GST Switch (Photo 2 & 3)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "With GST",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isGST ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Without GST",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: !isGST ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 10),
              Switch(
                value: !isGST,
                activeThumbColor: const Color(0xFF4F46E5),
                activeTrackColor: const Color(0xFFC7D2FE),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey.shade300,
                onChanged: (v) {
                  setState(() {
                    isGST = !v;
                  });
                },
              ),
            ],
          ),

          if (isGST) ...[
            const SizedBox(height: 20),
            _buildLabel("GST NUMBER *"),
            TextFormField(
              controller: gstNumber,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: "E.G. 22AAAAA0000A1Z5",
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F46E5))),
                fillColor: Colors.white,
                filled: true,
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],

          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text("Next", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CARD 2: GENERAL INFO (PHOTO 4) ---
  Widget _buildGeneralInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
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
              Icon(Icons.person_add_alt_1_outlined, color: Color(0xFF4F46E5), size: 20),
              SizedBox(width: 8),
              Text(
                "General Information",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const Divider(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 650;
              if (isWide) {
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildColumnField("SUPPLIER NAME *", supplierName, "Enter full name")),
                        const SizedBox(width: 14),
                        Expanded(child: _buildColumnField("COMPANY NAME", companyName, "Enter company registered name")),
                        const SizedBox(width: 14),
                        Expanded(child: _buildColumnField("PAN NUMBER", panNumber, "ABCDE1234F", uppercase: true)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildColumnField("EMAIL ADDRESS", email, "example@company.com", keyboardType: TextInputType.emailAddress)),
                        const SizedBox(width: 14),
                        Expanded(child: _buildColumnField("PRIMARY PHONE NUMBER *", phone, "+91 00000 00000", keyboardType: TextInputType.phone)),
                        const SizedBox(width: 14),
                        Expanded(child: _buildColumnField("PINCODE *", generalPincode, "6-digit Pincode (e.g. 600001)", keyboardType: TextInputType.number, onChanged: (v) {
                          if (v.length == 6) fetchLocationFromPincode(v);
                        })),
                      ],
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildColumnField("SUPPLIER NAME *", supplierName, "Enter full name"),
                    const SizedBox(height: 12),
                    _buildColumnField("COMPANY NAME", companyName, "Enter company registered name"),
                    const SizedBox(height: 12),
                    _buildColumnField("PAN NUMBER", panNumber, "ABCDE1234F", uppercase: true),
                    const SizedBox(height: 12),
                    _buildColumnField("EMAIL ADDRESS", email, "example@company.com", keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _buildColumnField("PRIMARY PHONE NUMBER *", phone, "+91 00000 00000", keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _buildColumnField("PINCODE *", generalPincode, "6-digit Pincode (e.g. 600001)", keyboardType: TextInputType.number, onChanged: (v) {
                      if (v.length == 6) fetchLocationFromPincode(v);
                    }),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // --- CARD 2.5: ASSOCIATED BRANCHES (PHOTO 4) ---
  Widget _buildBranchesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
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
              Icon(Icons.language_outlined, color: Color(0xFF4F46E5), size: 20),
              SizedBox(width: 8),
              Text(
                "Associated Branches",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const Divider(height: 24),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: branchesList.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final branch = branchesList[idx];
              return LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth > 550;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: _buildColumnField("BRANCH NAME", branch.nameController, "e.g. Head Office")),
                        const SizedBox(width: 10),
                        Expanded(child: _buildColumnField("BRANCH PHONE", branch.phoneController, "Phone Number", keyboardType: TextInputType.phone)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildColumnField("BRANCH PINCODE", branch.pincodeController, "6-digit Pincode")),
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: InkWell(
                            onTap: () {
                              if (branchesList.length > 1) {
                                setState(() => branchesList.removeAt(idx));
                              } else {
                                branch.nameController.clear();
                                branch.phoneController.clear();
                                branch.pincodeController.clear();
                              }
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildColumnField("BRANCH NAME", branch.nameController, "e.g. Head Office"),
                          const SizedBox(height: 8),
                          _buildColumnField("BRANCH PHONE", branch.phoneController, "Phone Number", keyboardType: TextInputType.phone),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(child: _buildColumnField("BRANCH PINCODE", branch.pincodeController, "6-digit Pincode")),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  if (branchesList.length > 1) {
                                    setState(() => branchesList.removeAt(idx));
                                  } else {
                                    branch.nameController.clear();
                                    branch.phoneController.clear();
                                    branch.pincodeController.clear();
                                  }
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                },
              );
            },
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                branchesList.add(BranchRowData());
              });
            },
            icon: const Icon(Icons.add, size: 14, color: Color(0xFF4F46E5)),
            label: const Text(
              "+ Add Another Branch",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              side: const BorderSide(color: Color(0xFF4F46E5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }

  // --- CARD 3: ADDRESS DETAILS (PHOTO 5) ---
  Widget _buildAddressCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
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
              Icon(Icons.location_on_outlined, color: Color(0xFF4F46E5), size: 20),
              SizedBox(width: 8),
              Text(
                "Address Details",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const Divider(height: 24),

          // Address Type Segmented Tabs (Photo 5)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                _buildSegmentTab("Shopping Complex", Icons.apartment_outlined),
                _buildSegmentTab("Factory", Icons.factory_outlined),
                _buildSegmentTab("Warehouse", Icons.warehouse_outlined),
              ],
            ),
          ),
          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 650;
              if (isWide) {
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildColumnField("BUILD NAME/NO", building, "Building Name/No")),
                        const SizedBox(width: 14),
                        Expanded(child: _buildColumnField("STREET", street, "Street Name")),
                        const SizedBox(width: 14),
                        Expanded(child: _buildColumnField("LANDMARK", landmark, "Near Landmark")),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildColumnField("CITY", city, "City")),
                        const SizedBox(width: 14),
                        Expanded(child: _buildColumnField("STATE", state, "State")),
                        const SizedBox(width: 14),
                        Expanded(child: _buildColumnField("PINCODE", pincode, "642109", keyboardType: TextInputType.number, onChanged: (v) {
                          if (v.length == 6) fetchLocationFromPincode(v);
                        })),
                      ],
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildColumnField("BUILD NAME/NO", building, "Building Name/No"),
                    const SizedBox(height: 12),
                    _buildColumnField("STREET", street, "Street Name"),
                    const SizedBox(height: 12),
                    _buildColumnField("LANDMARK", landmark, "Near Landmark"),
                    const SizedBox(height: 12),
                    _buildColumnField("CITY", city, "City"),
                    const SizedBox(height: 12),
                    _buildColumnField("STATE", state, "State"),
                    const SizedBox(height: 12),
                    _buildColumnField("PINCODE", pincode, "642109", keyboardType: TextInputType.number, onChanged: (v) {
                      if (v.length == 6) fetchLocationFromPincode(v);
                    }),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(String type, IconData icon) {
    final bool isSelected = selectedAddressType == type;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedAddressType = type;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: isSelected ? Colors.white : const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumnField(String label, TextEditingController controller, String hint, {bool uppercase = false, TextInputType keyboardType = TextInputType.text, Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: uppercase ? TextCapitalization.characters : TextCapitalization.none,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F46E5))),
            fillColor: Colors.white,
            filled: true,
          ),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.3),
      ),
    );
  }
}
