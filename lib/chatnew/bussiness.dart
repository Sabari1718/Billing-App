import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'chatscreen.dart';

class BusinessChat extends StatefulWidget {
  final String role;
  final int userId;

  const BusinessChat({
    super.key,
    required this.role,
    required this.userId
  });

  @override
  State<BusinessChat> createState() => _BusinessChatState();
}

class _BusinessChatState extends State<BusinessChat> {

  final baseUrl = "http://localhost:3002";

  List users = [];
  List filtered = [];

  String myName = "";
  String? selectedType;

////////////////////////////////////////////////
  /// DEBUG
////////////////////////////////////////////////

  void log(String title, dynamic data){
    debugPrint("🔹 $title → $data");
  }

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
    await fetchMyName();
    await fetchLastMessages();
    filter();
    setState(() {});
  }

////////////////////////////////////////////////
  /// FETCH USERS
////////////////////////////////////////////////

  Future fetchUsers() async {

    final res = await http.get(Uri.parse("$baseUrl/cl_users"));

    final decoded = jsonDecode(res.body);

    users = decoded["data"] ?? [];

    log("USERS", users);
  }

////////////////////////////////////////////////
  /// GET MY NAME
////////////////////////////////////////////////

  Future fetchMyName() async {

    final me = users.firstWhere(
          (u)=>u["user_id"] == widget.userId,
      orElse: ()=>{},
    );

    myName = me["name"] ?? "";

    log("MY NAME", myName);
  }

////////////////////////////////////////////////
  /// FETCH MESSAGES (FIXED 🔥)
////////////////////////////////////////////////

  Future fetchLastMessages() async {

    final res = await http.get(
        Uri.parse("$baseUrl/messages/filter-by-role?userId=${widget.userId}&role=${widget.role}")
    );

    final decoded = jsonDecode(res.body);

    List list = decoded["data"]?["data"] ?? [];

    log("TOTAL MSG", list.length);

    Map<String, dynamic> lastMsgMap = {};
    Map<String, int> unreadMap = {};

    for (var m in list) {

      String sender = m["sender_name"] ?? "";
      String receiver = m["receiver_name"] ?? "";

      /// identify other person
      String other = sender == myName ? receiver : sender;

      DateTime time =
          DateTime.tryParse(m["created_at"] ?? "") ?? DateTime.now();

      /// LAST MESSAGE
      if(!lastMsgMap.containsKey(other)){
        lastMsgMap[other] = m;
      }else{
        DateTime old =
            DateTime.tryParse(lastMsgMap[other]["created_at"] ?? "")
                ?? DateTime.now();

        if(time.isAfter(old)){
          lastMsgMap[other] = m;
        }
      }

      /// UNREAD COUNT 🔥
      if(receiver == myName && m["is_seen"].toString() == "0"){
        unreadMap[other] = (unreadMap[other] ?? 0) + 1;
      }
    }

    log("LAST MSG MAP", lastMsgMap);
    log("UNREAD MAP", unreadMap);

////////////////////////////////////////////////
    /// ATTACH TO USERS
////////////////////////////////////////////////

    for (var u in users) {

      String name = u["name"] ?? "";

      var msg = lastMsgMap[name];

      u["last_message"] = msg?["message"] ?? "";
      u["unread"] = unreadMap[name] ?? 0;
    }
  }

////////////////////////////////////////////////
  /// FILTER
////////////////////////////////////////////////

  void filter(){

    if(selectedType == null){
      filtered = users;
    }else{
      filtered = users.where((u)=>u["role"] == selectedType).toList();
    }
  }

////////////////////////////////////////////////
  /// UI
////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Business Inbox"),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: (){
          init();
        },
        child: const Icon(Icons.refresh),
      ),

      body: Column(

        children: [

////////////////////////////////////////////////
          /// TABS
////////////////////////////////////////////////

          Row(
            children: [
              tab("Users","user"),
              tab("Admin","admin"),
            ],
          ),

////////////////////////////////////////////////
          /// LIST
////////////////////////////////////////////////

          Expanded(
            child: ListView.builder(

              itemCount: filtered.length,

              itemBuilder:(c,i){

                final user = filtered[i];

                return ListTile(

                  title: Text(user["name"] ?? ""),

                  subtitle: Text(
                    user["last_message"] ?? "No messages",
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

  Widget tab(String title,String role){

    return GestureDetector(
      onTap:(){
        selectedType = role;
        filter();
        setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }
}