import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'chatscreen.dart';

class UserFlow extends StatefulWidget {

  final String role;
  final int userId;

  const UserFlow({
    super.key,
    required this.role,
    required this.userId
  });

  @override
  State<UserFlow> createState() => _UserFlowState();
}

class _UserFlowState extends State<UserFlow> {

  final String baseUrl="http://localhost:3002";

  List users=[];
  List businessTypes=[];
  List filteredUsers=[];

  String? selectedBusiness;

  bool loading=true;

////////////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();

    debugPrint("USER FLOW STARTED");
    debugPrint("ROLE → ${widget.role}");
    debugPrint("USER ID → ${widget.userId}");

    fetchUsers();
  }

////////////////////////////////////////////////////////////

  Future fetchUsers() async {

    final url="$baseUrl/cl_users";

    debugPrint("API CALL → $url");

    final res=await http.get(Uri.parse(url));

    debugPrint("RAW RESPONSE → ${res.body}");

    final decoded=jsonDecode(res.body);

    users=decoded["data"] ?? []; // ✅ SAFE

    debugPrint("TOTAL USERS → ${users.length}");

////////////////////////////////////////////////////////////
    /// FIXED BUSINESS TYPES 🔥
////////////////////////////////////////////////////////////

    businessTypes = users
        .where((u)=>u["role"]=="business" && u["business_type"] != null)
        .map((u)=>u["business_type"].toString())
        .toSet()
        .toList();

    debugPrint("BUSINESS TYPES → $businessTypes");

    loading=false;

    setState(() {});
  }

////////////////////////////////////////////////////////////

  void filterUsers(){

    debugPrint("SELECTED BUSINESS → $selectedBusiness");

    filteredUsers = users.where((u){
      return u["business_type"]==selectedBusiness;
    }).toList();

    debugPrint("FILTERED USERS → ${filteredUsers.length}");
  }

////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {

    if(loading){
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(

      appBar: AppBar(
        title: const Text("Select Business Type"),
      ),

      body: Padding(

        padding: const EdgeInsets.all(15),

        child: Column(

          children: [

////////////////////////////////////////////////
            /// SELECT BUSINESS TYPE
////////////////////////////////////////////////

            DropdownButtonFormField(

              hint: const Text("Select Business Type"),

              value: selectedBusiness,

              items: businessTypes.map((type){

                return DropdownMenuItem(

                  value:type,
                  child:Text(type),

                );

              }).toList(),

              onChanged:(value){

                debugPrint("BUSINESS TYPE SELECTED → $value");

                selectedBusiness=value.toString();

                filterUsers();

                setState(() {});

              },

            ),

            const SizedBox(height:20),

////////////////////////////////////////////////
            /// BUSINESS USERS
////////////////////////////////////////////////

            Expanded(

              child: filteredUsers.isEmpty
                  ? const Center(child: Text("No users found"))
                  : ListView.builder(

                itemCount: filteredUsers.length,

                itemBuilder:(c,i){

                  final user=filteredUsers[i];

                  String name=user["name"] ?? "No Name"; // ✅ SAFE

                  return ListTile(

                    leading: CircleAvatar(
                      child: Text(name[0]),
                    ),

                    title: Text(name),

                    subtitle: Text(user["email"] ?? ""),

                    onTap:(){

                      debugPrint("CHAT OPENED");
                      debugPrint("CHAT WITH → ${user["name"]}");
                      debugPrint("BUSINESS ID → ${user["user_id"]}");

                      Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder:(_)=>ChatScreen(

                            user:user,
                            role:"business",
                            userId:widget.userId,

                          ),

                        ),

                      );

                    },

                  );

                },

              ),

            )

          ],

        ),

      ),

    );

  }

}