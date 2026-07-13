import 'dart:io';

void main() {
  final dir = Directory('c:/Users/welcome/StudioProjects/BillingApp/lib/mainscreen');
  if (!dir.existsSync()) {
    print('Directory lib/mainscreen not found!');
    return;
  }

  print('Fixing files in lib/mainscreen...');

  dir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      var content = entity.readAsStringSync();
      var changed = false;

      // 1. Replace package:lockscreen/ with package:billingapp/mainscreen/
      if (content.contains('package:lockscreen/')) {
        content = content.replaceAll('package:lockscreen/', 'package:billingapp/mainscreen/');
        changed = true;
      }

      // 2. Replace App ID USERAPP-95386 with empty string
      if (content.contains('USERAPP-95386')) {
        content = content.replaceAll('USERAPP-95386', '');
        changed = true;
      }

      // 3. Fix app name, app version, software version in mobile_validation_service.dart
      if (entity.path.endsWith('mobile_validation_service.dart')) {
        // Replace software version 1.4.1 with 1.1.1
        content = content.replaceAll("const String softwareVersion = '1.4.1';", "const String softwareVersion = '1.1.1';");
        content = content.replaceAll('const String softwareVersion = "1.4.1";', 'const String softwareVersion = "1.1.1";');
        content = content.replaceAll('const String softwareVersion = \'1.4.1\';', 'const String softwareVersion = \'1.1.1\';');
        
        // Force version to 1.1.1
        content = content.replaceAll("version = packageInfo.version;", "version = '1.1.1';");
        content = content.replaceAll("String version = '1.0.0';", "String version = '1.1.1';");
        
        // Force app name to Billing App
        content = content.replaceAll("appName = packageInfo.appName.isNotEmpty ? packageInfo.appName : 'Payment App';", "appName = 'Billing App';");
        content = content.replaceAll("String appName = 'Payment App';", "String appName = 'Billing App';");
        changed = true;
      }

      // 4. Fix software version in custom_flow_service.dart
      if (entity.path.endsWith('custom_flow_service.dart')) {
        content = content.replaceAll("'software_version': '1.4.1',", "'software_version': '1.1.1',");
        content = content.replaceAll("'softwareVersion': '1.4.1',", "'softwareVersion': '1.1.1',");
        content = content.replaceAll('"software_version": "1.4.1",', '"software_version": "1.1.1",');
        content = content.replaceAll('"softwareVersion": "1.4.1",', '"softwareVersion": "1.1.1",');
        content = content.replaceAll("String version = '1.0.0';", "String version = '1.1.1';");
        changed = true;
      }

      // 5. Fix app constants
      if (entity.path.endsWith('constants.dart')) {
        content = content.replaceAll("static const String appName = 'Antigravity';", "static const String appName = 'Billing App';");
        content = content.replaceAll("static const String appSubtitle = 'Advanced Security Sentinel';", "static const String appSubtitle = 'Billing App Security';");
        changed = true;
      }

      // 6. Fix lock screen title and messages
      if (entity.path.endsWith('app_lock_screen.dart')) {
        content = content.replaceAll("'ANTIGRAVITY SECURE VAULT'", "'BILLING APP SECURE VAULT'");
        content = content.replaceAll("unlock Antigravity", "unlock Billing App");
        changed = true;
      }

      // 7. Fix main.dart references in mainscreen
      if (entity.path.endsWith('main.dart')) {
        content = content.replaceAll("title: 'Antigravity',", "title: 'Billing App',");
        changed = true;
      }

      if (changed) {
        entity.writeAsStringSync(content);
        print('Fixed: ${entity.path}');
      }
    }
  });

  // Also fix pubspec.yaml version
  final pubspecFile = File('c:/Users/welcome/StudioProjects/BillingApp/pubspec.yaml');
  if (pubspecFile.existsSync()) {
    var pubspecContent = pubspecFile.readAsStringSync();
    if (pubspecContent.contains('version: 1.0.0+1')) {
      pubspecContent = pubspecContent.replaceAll('version: 1.0.0+1', 'version: 1.1.1+1');
      pubspecFile.writeAsStringSync(pubspecContent);
      print('Fixed pubspec.yaml version to 1.1.1+1');
    }
  }

  print('Fixing completed successfully!');
}
