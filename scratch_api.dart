import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  var res = await http.get(Uri.parse('https://billing.srivagroups.in/api/GroupCatgeorybrandallProductList?category_group_id=15'));
  print(res.statusCode);
  print(res.body);
}
