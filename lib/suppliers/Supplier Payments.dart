import 'package:flutter/material.dart';

class SupplierPaymentsPage extends StatefulWidget {
  const SupplierPaymentsPage({super.key});

  @override
  State<SupplierPaymentsPage> createState() =>
      _SupplierPaymentsPageState();
}

class _SupplierPaymentsPageState extends State<SupplierPaymentsPage> {
  String tab = "history"; // history / dues

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text("Supplier Payments"),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NewPaymentPage(),
                ),
              );
            },
            child: const Text("Make Payment"),
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [

            /// 🔥 SUMMARY CARDS
            _summaryCard("Total Paid (Monthly)", "₹1,24,500", Colors.green),
            const SizedBox(height: 10),
            _summaryCard("Outstanding Balance", "₹45,200", Colors.red),

            const SizedBox(height: 16),

            /// 🔥 TAB SWITCH
            Row(
              children: [
                _tabBtn("Payment History", "history"),
                const SizedBox(width: 10),
                _tabBtn("Upcoming Dues", "dues"),
              ],
            ),

            const SizedBox(height: 16),

            /// 🔥 CONTENT SWITCH
            Expanded(
              child: tab == "history"
                  ? _paymentHistory()
                  : _upcomingDues(),
            )
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Text(value,
              style:
              const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _tabBtn(String text, String value) {
    final isActive = tab == value;

    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
          isActive ? Colors.deepPurple : Colors.grey.shade300,
        ),
        onPressed: () {
          setState(() => tab = value);
        },
        child: Text(
          text,
          style: TextStyle(
              color: isActive ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  /// 🔥 PAYMENT HISTORY UI
  Widget _paymentHistory() {
    return ListView(
      children: [
        _historyItem("PAY-1001", "Techtronics", "₹15,400", "Bank"),
        _historyItem("PAY-1002", "Global Parts", "₹4,000", "Cash"),
        _historyItem("PAY-1003", "Vertex", "₹12,800", "UPI"),
      ],
    );
  }

  Widget _historyItem(id, supplier, amount, mode) {
    return Card(
      child: ListTile(
        title: Text(supplier),
        subtitle: Text(id),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(amount,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(mode, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  /// 🔥 UPCOMING DUES UI
  Widget _upcomingDues() {
    return ListView(
      children: [
        _dueItem("INV-7782", "Unity", "₹22,100", "6 days"),
        _dueItem("INV-7822", "Vertex", "₹12,800", "11 days"),
      ],
    );
  }

  Widget _dueItem(id, supplier, amount, days) {
    return Card(
      child: ListTile(
        title: Text(supplier),
        subtitle: Text("$id • $days left"),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NewPaymentPage(),
              ),
            );
          },
          child: const Text("Pay Now"),
        ),
      ),
    );
  }
}



class NewPaymentPage extends StatefulWidget {
  const NewPaymentPage({super.key});

  @override
  State<NewPaymentPage> createState() => _NewPaymentPageState();
}

class _NewPaymentPageState extends State<NewPaymentPage> {

  int step = 0;

  final supplier = TextEditingController();
  final invoice = TextEditingController();

  final amount = TextEditingController();
  final ref = TextEditingController();
  final notes = TextEditingController();

  String mode = "Bank";
  String category = "Full Payment";

  void next() {
    if (step < 1) setState(() => step++);
  }

  void back() {
    if (step > 0) setState(() => step--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Make Payment")),

      body: Column(
        children: [

          /// 🔥 STEP INDICATOR
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stepCircle(0, "Supplier"),
                _stepCircle(1, "Payment"),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: step == 0 ? _step1() : _step2(),
            ),
          ),

          /// 🔥 BOTTOM BUTTON
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [

                if (step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: back,
                      child: const Text("Back"),
                    ),
                  ),

                if (step > 0) const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton(
                    onPressed: step == 1 ? submit : next,
                    child: Text(step == 1 ? "Record Payment" : "Next"),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// 📌 STEP 1
  Widget _step1() {
    return Column(
      children: [
        _input("Select Supplier", controller: supplier),
        _input("Invoice Reference", controller: invoice),
      ],
    );
  }

  /// 📌 STEP 2
  Widget _step2() {
    return Column(
      children: [

        _input("Amount", controller: amount),

        DropdownButtonFormField(
          value: category,
          items: ["Full Payment", "Partial Payment"]
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => category = v.toString()),
          decoration: _dec("Payment Category"),
        ),

        DropdownButtonFormField(
          value: mode,
          items: ["Bank", "Cash", "UPI"]
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => mode = v.toString()),
          decoration: _dec("Payment Mode"),
        ),

        _input("Reference / Transaction No", controller: ref),

        const SizedBox(height: 10),

        TextField(
          controller: notes,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "Additional Notes",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  /// 🔹 COMMON INPUT
  Widget _input(String label, {TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: _dec(label),
      ),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _stepCircle(int index, String title) {
    bool active = step == index;

    return Column(
      children: [
        CircleAvatar(
          backgroundColor: active ? Colors.deepPurple : Colors.grey,
          child: Text("${index + 1}"),
        ),
        const SizedBox(height: 4),
        Text(title)
      ],
    );
  }

  void submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment Recorded")),
    );
    Navigator.pop(context);
  }
}