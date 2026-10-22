part of 'variant_master.dart';

class VariantConfigPanel extends StatefulWidget {
  final String activeName;
  final Map<String, dynamic> config;
  final Function(Map<String, dynamic>) onConfigChanged;

  const VariantConfigPanel({
    super.key,
    required this.activeName,
    required this.config,
    required this.onConfigChanged,
  });

  @override
  State<VariantConfigPanel> createState() => _VariantConfigPanelState();
}

class _VariantConfigPanelState extends State<VariantConfigPanel> {
  late TextEditingController minStockCtrl;
  late TextEditingController maxStockCtrl;
  late TextEditingController warrantyDurCtrl;
  late TextEditingController guaranteeDurCtrl;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant VariantConfigPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeName != widget.activeName) {
      minStockCtrl.dispose();
      maxStockCtrl.dispose();
      warrantyDurCtrl.dispose();
      guaranteeDurCtrl.dispose();
      _initControllers();
    }
  }

  void _initControllers() {
    minStockCtrl = TextEditingController(text: widget.config['minStock']?.toString() ?? '0');
    maxStockCtrl = TextEditingController(text: widget.config['maxStock']?.toString() ?? '999');
    warrantyDurCtrl = TextEditingController(text: widget.config['warrantyDuration']?.toString() ?? '1');
    guaranteeDurCtrl = TextEditingController(text: widget.config['guaranteeDuration']?.toString() ?? '1');
  }

  @override
  void dispose() {
    minStockCtrl.dispose();
    maxStockCtrl.dispose();
    warrantyDurCtrl.dispose();
    guaranteeDurCtrl.dispose();
    super.dispose();
  }

  void _update() {
    final updated = {
      ...widget.config,
      'minStock': minStockCtrl.text,
      'maxStock': maxStockCtrl.text,
      'warrantyDuration': warrantyDurCtrl.text,
      'guaranteeDuration': guaranteeDurCtrl.text,
    };
    widget.onConfigChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final activeName = widget.activeName;
    final config = widget.config;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 20),
              const SizedBox(width: 8),
              Text(
                activeName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const Spacer(),
              const Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
              const SizedBox(width: 12),
              const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          // Dotted line
          Row(
            children: List.generate(
              30,
              (index) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 1,
                  color: Colors.grey.shade300,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MIN STOCK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: minStockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      onChanged: (val) => _update(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MAX STOCK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: maxStockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      onChanged: (val) => _update(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: config['warrantyEnabled'] == true,
                      activeColor: const Color(0xFF2563EB),
                      onChanged: (val) {
                        setState(() {
                          config['warrantyEnabled'] = val == true;
                        });
                        _update();
                      },
                    ),
                    const Text('Warranty Policy', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  ],
                ),
                if (config['warrantyEnabled'] == true) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DURATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            TextField(
                              controller: warrantyDurCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onChanged: (val) => _update(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('UNIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: config['warrantyUnit']?.toString() ?? 'Months',
                                  isExpanded: true,
                                  items: ['Days', 'Months', 'Years'].map((u) {
                                    return DropdownMenuItem<String>(
                                      value: u,
                                      child: Text(u),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        config['warrantyUnit'] = val;
                                      });
                                      _update();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: config['guaranteeEnabled'] == true,
                      activeColor: const Color(0xFF2563EB),
                      onChanged: (val) {
                        setState(() {
                          config['guaranteeEnabled'] = val == true;
                        });
                        _update();
                      },
                    ),
                    const Text('Guarantee Policy', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  ],
                ),
                if (config['guaranteeEnabled'] == true) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DURATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            TextField(
                              controller: guaranteeDurCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onChanged: (val) => _update(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('UNIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: config['guaranteeUnit']?.toString() ?? 'Months',
                                  isExpanded: true,
                                  items: ['Days', 'Months', 'Years'].map((u) {
                                    return DropdownMenuItem<String>(
                                      value: u,
                                      child: Text(u),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        config['guaranteeUnit'] = val;
                                      });
                                      _update();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Active: Manufacturers Defect Warranty',
                    style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
