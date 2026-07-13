// import 'package:flutter/material.dart';
//
// class Quotationsscreen extends StatefulWidget {
//   const Quotationsscreen({super.key});
//
//   @override
//   State<Quotationsscreen> createState() => _QuotationsscreenState();
// }
//
// class _QuotationsscreenState extends State<Quotationsscreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FB),
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         title: const Text(
//           "Quotations",
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 10),
//             child: ElevatedButton.icon(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.deepPurple,
//                 padding: const EdgeInsets.symmetric(horizontal: 10),
//               ),
//               onPressed: () {},
//               icon: const Icon(Icons.add, size: 18),
//               label: const Text("New", style: TextStyle(fontSize: 12)),
//             ),
//           )
//         ],
//       ),
//
//       body: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           children: [
//
//             /// 🔹 CARDS (WRAP FIX)
//             Wrap(
//               spacing: 10,
//               runSpacing: 10,
//               children: [
//                 _buildCard("Pending", "00", Colors.orange, Icons.access_time),
//                 _buildCard("Accepted", "00", Colors.green, Icons.check),
//                 _buildCard("Expired", "00", Colors.red, Icons.close),
//                 _buildCard("Total", "₹0", Colors.deepPurple, Icons.receipt),
//               ],
//             ),
//
//             const SizedBox(height: 15),
//
//             /// 🔹 SEARCH + FILTER (RESPONSIVE)
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     decoration: InputDecoration(
//                       hintText: "Search...",
//                       prefixIcon: const Icon(Icons.search),
//                       filled: true,
//                       fillColor: Colors.white,
//                       contentPadding: const EdgeInsets.symmetric(vertical: 0),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Container(
//                   padding:
//                   const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: const Icon(Icons.filter_list),
//                 )
//               ],
//             ),
//
//             const SizedBox(height: 15),
//
//             /// 🔹 TABLE (SCROLL FIX 🔥)
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade200,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Row(
//                   children: const [
//                     _Header("ID"),
//                     _Header("Date"),
//                     _Header("Customer"),
//                     _Header("Items"),
//                     _Header("Amount"),
//                     _Header("Exp"),
//                     _Header("Status"),
//                     _Header("Action"),
//                   ],
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 10),
//
//             /// 🔹 EMPTY STATE
//             const Expanded(
//               child: Center(
//                 child: Text(
//                   "No quotations found",
//                   style: TextStyle(color: Colors.grey),
//                 ),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// 🔹 CARD
//   Widget _buildCard(
//       String title, String value, Color color, IconData icon) {
//     return SizedBox(
//       width: (MediaQuery.of(context).size.width - 36) / 2,
//       child: Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 16,
//               backgroundColor: color.withOpacity(0.1),
//               child: Icon(icon, color: color, size: 18),
//             ),
//             const SizedBox(width: 8),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(title,
//                     style: const TextStyle(
//                         fontSize: 12, color: Colors.grey)),
//                 Text(value,
//                     style: const TextStyle(
//                         fontWeight: FontWeight.bold)),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// /// 🔹 TABLE HEADER ITEM
// class _Header extends StatelessWidget {
//   final String text;
//   const _Header(this.text);
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       child: Text(
//         text,
//         style: const TextStyle(fontWeight: FontWeight.bold),
//       ),
//     );
//   }
// }