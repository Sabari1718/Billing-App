// import 'package:flutter/material.dart';
//
// import 'api service.dart';
//
//
// class RegisterPage extends StatefulWidget {
//   @override
//   State<RegisterPage> createState() => _RegisterPageState();
// }
//
// class _RegisterPageState extends State<RegisterPage> {
//   String userId = '';
//   String name = '';
//   String email = '';
//   String password = '';
//   bool isLoading = false;
//
//   void handleSubmit() async {
//     setState(() => isLoading = true);
//
//     try {
//       await ApiService.registerUser({
//         "user_id": userId,
//         "name": name,
//         "email": email,
//         "password": password,
//       });
//
//       Navigator.pushReplacementNamed(context, "/login");
//     } catch (e) {
//       showError(e.toString());
//     }
//
//     setState(() => isLoading = false);
//   }
//
//   void showError(String msg) {
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text(msg)));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: EdgeInsets.all(20),
//         child: ListView(
//           children: [
//             TextField(
//               onChanged: (v) => userId = v,
//               decoration: InputDecoration(labelText: "User ID"),
//             ),
//             TextField(
//               onChanged: (v) => name = v,
//               decoration: InputDecoration(labelText: "Name"),
//             ),
//             TextField(
//               onChanged: (v) => email = v,
//               decoration: InputDecoration(labelText: "Email"),
//             ),
//             TextField(
//               obscureText: true,
//               onChanged: (v) => password = v,
//               decoration: InputDecoration(labelText: "Password"),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: isLoading ? null : handleSubmit,
//               child: isLoading
//                   ? CircularProgressIndicator()
//                   : Text("Register"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }