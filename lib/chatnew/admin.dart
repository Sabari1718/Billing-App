import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'chatscreen.dart';

class AdminChat extends StatefulWidget {

  final String role;
  final int userId;

  const AdminChat({
    super.key,
    required this.role,
    required this.userId,
  });

  @override
  State<AdminChat> createState() => _AdminChatState();
}

class _AdminChatState extends State<AdminChat> {

  List users=[];
  List filteredUsers=[];

  String selectedType="user";

  String myName="";

  final baseUrl="http://localhost:3002";

////////////////////////////////////////////////
  /// INIT
////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();
    init();
  }

  Future init() async {
    await fetchUsers();
    await getMyName();
    await fetchLastMessages();
    filterUsers();
    setState(() {});
  }

////////////////////////////////////////////////
  /// FETCH USERS
////////////////////////////////////////////////

  Future fetchUsers() async{

    final res = await http.get(Uri.parse("$baseUrl/cl_users"));

    final decoded = jsonDecode(res.body);

    users = decoded["data"] ?? [];

    debugPrint("USERS → $users");
  }

////////////////////////////////////////////////
  /// GET MY NAME
////////////////////////////////////////////////

  Future getMyName() async {

    final me = users.firstWhere(
          (u)=>u["user_id"] == widget.userId,
      orElse: ()=>{},
    );

    myName = me["name"] ?? "";

    debugPrint("MY NAME → $myName");
  }

////////////////////////////////////////////////
  /// FETCH LAST MESSAGE + UNREAD 🔥
////////////////////////////////////////////////

  Future fetchLastMessages() async {

    final res = await http.get(
        Uri.parse("$baseUrl/messages/filter-by-role?userId=${widget.userId}&role=${widget.role}")
    );

    final decoded = jsonDecode(res.body);

    List list = decoded["data"]?["data"] ?? [];

    Map<String,dynamic> lastMap = {};
    Map<String,int> unreadMap = {};

    for(var m in list){

      String sender = m["sender_name"] ?? "";
      String receiver = m["receiver_name"] ?? "";

      String other = sender == myName ? receiver : sender;

      DateTime time =
          DateTime.tryParse(m["created_at"] ?? "") ?? DateTime.now();

      /// LAST MSG
      if(!lastMap.containsKey(other)){
        lastMap[other]=m;
      }else{
        DateTime old = DateTime.tryParse(
            lastMap[other]["created_at"] ?? ""
        ) ?? DateTime.now();

        if(time.isAfter(old)){
          lastMap[other]=m;
        }
      }

      /// UNREAD
      if(receiver == myName && m["is_seen"].toString()=="0"){
        unreadMap[other]=(unreadMap[other]??0)+1;
      }
    }

////////////////////////////////////////////////
    /// ATTACH DATA
////////////////////////////////////////////////

    for(var u in users){

      String name = u["name"] ?? "";

      u["last_msg"] = lastMap[name]?["message"] ?? "";
      u["unread"] = unreadMap[name] ?? 0;
    }
  }

////////////////////////////////////////////////
  /// FILTER
////////////////////////////////////////////////

  void filterUsers(){

    filteredUsers =
        users.where((u)=>u["role"]==selectedType).toList();

  }

////////////////////////////////////////////////
  /// UI
////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Admin Portal"),
      ),

      body: Column(

        children: [

////////////////////////////////////////////////
          /// TABS
////////////////////////////////////////////////

          Row(
            children: [
              tab("Users","user"),
              tab("Businesses","business"),
            ],
          ),

////////////////////////////////////////////////
          /// LIST
////////////////////////////////////////////////

          Expanded(
            child: ListView.builder(

              itemCount: filteredUsers.length,

              itemBuilder:(c,i){

                final user = filteredUsers[i];

                return ListTile(

                  title: Text(user["name"] ?? ""),

                  subtitle: Text(
                    user["last_msg"] ?? "No messages",
                    maxLines: 1,
                  ),

                  trailing: user["unread"] > 0
                      ? CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.green,
                    child: Text(
                      user["unread"].toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12),
                    ),
                  )
                      : null,

                  onTap:(){

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:(_)=>ChatScreen(
                          user:user,
                          role:widget.role,
                          userId:widget.userId,
                        ),
                      ),
                    ).then((_) => init());

                  },

                );

              },

            ),
          )

        ],

      ),

    );

  }

////////////////////////////////////////////////
  /// TAB
////////////////////////////////////////////////

  Widget tab(String t,String role){

    return GestureDetector(

      onTap: (){
        selectedType=role;
        filterUsers();
        setState(() {});
      },

      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          t,
          style: const TextStyle(
              fontWeight: FontWeight.bold
          ),
        ),
      ),

    );

  }
}