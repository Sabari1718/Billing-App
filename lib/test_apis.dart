import 'package:flutter/material.dart';
import 'package:billingapp/Auth/api service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final teams = await ApiService.getTeams();
    print("TEAMS:");
    print(teams);
    
    final emps = await ApiService.getEmployees();
    print("EMPLOYEES:");
    print(emps);
    
    final roles = await ApiService.getRoles();
    print("ROLES:");
    print(roles);
  } catch (e) {
    print("ERROR: $e");
  }
}
