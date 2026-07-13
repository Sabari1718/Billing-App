import 'package:flutter/material.dart';
import 'support_chat_screen.dart';

class ChatConstants {
  static final List<SupportContact> allContacts = [
    SupportContact(id: 10, shopName: "Sun Electronics", phone: "+91 9000000001", address: "Tech Park Road", dept: "Sales", category: "Business"),
    SupportContact(id: 11, shopName: "Bright Motors", phone: "+91 9000000002", address: "MG Road", dept: "Sales", category: "Business"),
    SupportContact(id: 12, shopName: "City Retail", phone: "+91 9000000003", address: "Main Market", dept: "Sales", category: "Business"),
    SupportContact(id: 13, shopName: "Global Traders", phone: "+91 9000000004", address: "Industrial Estate", dept: "Sales", category: "Business"),
    SupportContact(id: 14, shopName: "Star Agencies", phone: "+91 9000000005", address: "Railway Colony", dept: "Sales", category: "Business"),
    SupportContact(id: 15, shopName: "Raw Material Co", phone: "+91 9000000006", address: "North Block", dept: "Purchase", category: "Business"),
    SupportContact(id: 16, shopName: "Steel Hub", phone: "+91 9000000007", address: "Port Road", dept: "Purchase", category: "Business"),
    SupportContact(id: 17, shopName: "Plastic World", phone: "+91 9000000008", address: "Factory Zone", dept: "Purchase", category: "Business"),
    SupportContact(id: 18, shopName: "Chemical Supplies", phone: "+91 9000000009", address: "Chemical Park", dept: "Purchase", category: "Business"),
    SupportContact(id: 19, shopName: "Logistics Parts", phone: "+91 9000000010", address: "Outer Ring Road", dept: "Purchase", category: "Business"),
    
    SupportContact(id: 1, shopName: "Super Admin", phone: "101", address: "HQ", dept: "Admin", category: "Admin"),
    SupportContact(id: 2, shopName: "Tech Support", phone: "102", address: "HQ", dept: "Admin", category: "Admin"),
    SupportContact(id: 3, shopName: "Billing Admin", phone: "103", address: "HQ", dept: "Admin", category: "Admin"),
  ];
}
