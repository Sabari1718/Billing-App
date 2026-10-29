part of 'purchase_bill_entry.dart';

extension _PurchaseBillEntryPageStateWidgets on _PurchaseBillEntryPageState {
  Widget _buildStepIndicator() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: _buildHorizontalStepItem(
              1,
              "STEP 1",
              "Supplier & Metadata",
              currentStep == 1,
              currentStep > 1,
            ),
          ),
          Container(
            width: 20,
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: currentStep > 1 ? const Color(0xFF6366F1) : Colors.grey.shade300,
          ),
          Expanded(
            child: _buildHorizontalStepItem(
              2,
              "STEP 2",
              "Products Purchase Entry",
              currentStep == 2,
              currentStep > 2,
            ),
          ),
          Container(
            width: 20,
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: currentStep > 2 ? const Color(0xFF6366F1) : Colors.grey.shade300,
          ),
          Expanded(
            child: _buildHorizontalStepItem(
              3,
              "STEP 3",
              "Payment & Summary",
              currentStep == 3,
              false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalStepItem(int stepNum, String stepLabel, String title, bool isActive, bool isCompleted) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? const Color(0xFF6366F1)
                : isCompleted
                    ? const Color(0xFF10B981)
                    : Colors.white,
            border: Border.all(
              color: isActive
                  ? const Color(0xFF6366F1)
                  : isCompleted
                      ? const Color(0xFF10B981)
                      : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : Text(
                    "$stepNum",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stepLabel,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? const Color(0xFF6366F1) : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepRow(int stepNum, String title, String subtitle, bool isCompleted, bool isActive) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? const Color(0xFF10B981)
                : isActive
                    ? Colors.blue.shade600
                    : Colors.white,
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF10B981)
                  : isActive
                      ? Colors.blue.shade600
                      : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    stepNum.toString(),
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isActive 
                      ? Colors.blue.shade600 
                      : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, String value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: value.contains("dd/yyyy") ? Colors.grey.shade400 : const Color(0xFF1E293B),
                    fontWeight: value.contains("dd/yyyy") ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                Icon(Icons.calendar_month, color: Colors.grey.shade400, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField(String label, String value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
                ),
                Icon(Icons.access_time, color: Colors.grey.shade400, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  Widget _buildTextField(String label, String value, {bool isEditable = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isEditable ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: isEditable ? const Color(0xFF1E293B) : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputTextField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
          ),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFormTextField(
    String label, 
    TextEditingController controller, 
    String hint, 
    {bool isNumeric = false, 
    bool isEnabled = true, 
    ValueChanged<String>? onChanged}
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: isEnabled ? Colors.white : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            enabled: isEnabled,
            keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                borderSide: const BorderSide(color: Colors.blue, width: 1.5),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            style: TextStyle(
              fontSize: 13, 
              fontWeight: FontWeight.bold, 
              color: isEnabled ? const Color(0xFF1E293B) : Colors.grey.shade600,
            ),
            onChanged: (val) {
              if (onChanged != null) {
                onChanged(val);
              } else {
                _calculateFormValues();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFormDropdownField(
    String label, 
    String value, 
    List<String> items, 
    ValueChanged<String?> onChanged
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade500, size: 20),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormDiscountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Discount",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
            Container(
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isDiscountPercentage = true;
                        _calculateFormValues();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDiscountPercentage ? Colors.blue.shade600 : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "%",
                        style: TextStyle(
                          color: isDiscountPercentage ? Colors.white : Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isDiscountPercentage = false;
                        _calculateFormValues();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !isDiscountPercentage ? Colors.blue.shade600 : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "₹",
                        style: TextStyle(
                          color: !isDiscountPercentage ? Colors.white : Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: discountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              suffixText: isDiscountPercentage ? "%" : "₹",
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                borderSide: const BorderSide(color: Colors.blue, width: 1.5),
              ),
            ),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            onChanged: (val) {
              _calculateFormValues();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFormAddButton() {
    return Container(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _addFormItemToList,
        icon: const Icon(Icons.add, size: 16, color: Colors.white),
        label: const Text("Add", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildSummaryField(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
        ),
      ],
    );
  }

  Widget _buildBottomButtonsBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton(
            onPressed: () {
              if (currentStep > 1) {
                setState(() {
                  currentStep--;
                });
              } else {
                Navigator.pop(context);
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Text(
              currentStep == 2 ? "Back to Supplier" : (currentStep > 1 ? "Back" : "Cancel"),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
          ),
          ElevatedButton(
            onPressed: isSubmitting ? null : _handleNextOrSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D6EFD),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white), strokeWidth: 2),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentStep == 1
                            ? "Next: Product Entry"
                            : currentStep == 2
                                ? "Next: Payment & Summary"
                                : "Submit Bill",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        currentStep == 3 ? Icons.check : Icons.arrow_forward,
                        size: 16,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {required double screenWidth}) {
    final bool isMobile = screenWidth < 500;
    return SizedBox(
      width: isMobile ? double.infinity : (screenWidth - 80) / 2,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
