import 'package:http/http.dart' as http;
void main() async {
  var r = await http.post(Uri.parse('https://billing.srivagroups.in/api/delivery-charge'), body: '{}', headers: {'Content-Type': 'application/json'});
  print(r.body);
}
