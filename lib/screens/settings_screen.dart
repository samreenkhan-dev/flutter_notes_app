import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final supabase = Supabase.instance.client;

  bool isDark = false;
  bool notifications = true;
  String selectedLanguage = "English";

  void toggleTheme(bool value) => setState(() => isDark = value);
  void toggleNotifications(bool value) => setState(() => notifications = value);

  void changeLanguage(String? lang) {
    if (lang != null) setState(() => selectedLanguage = lang);
  }

  Future clearAllNotes() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    await supabase.from('notes').delete().eq('user_id', user.id);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("All notes deleted")));
  }

  void confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Delete All Notes"),
        content: const Text("Are you sure? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              clearAllNotes();
            },
            child: const Text("Delete"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 2,
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// 🌙 Dark Mode
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 4,
            child: SwitchListTile(
              value: isDark,
              onChanged: toggleTheme,
              title: const Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.bold)),
              secondary: const Icon(Icons.dark_mode, color: Colors.deepPurple),
            ),
          ),
          const SizedBox(height: 16),

          /// 🔔 Notifications
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 4,
            child: SwitchListTile(
              value: notifications,
              onChanged: toggleNotifications,
              title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
              secondary: const Icon(Icons.notifications, color: Colors.deepPurple),
            ),
          ),
          const SizedBox(height: 16),

          /// 🌐 Language
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.language, color: Colors.deepPurple),
              title: const Text("Language", style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: DropdownButton<String>(
                value: selectedLanguage,
                items: const [
                  DropdownMenuItem(value: "English", child: Text("English")),
                  DropdownMenuItem(value: "Urdu", child: Text("Urdu")),
                  DropdownMenuItem(value: "Arabic", child: Text("Arabic")),
                ],
                onChanged: changeLanguage,
              ),
            ),
          ),
          const SizedBox(height: 16),

          /// 🗑 Delete All Notes
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete All Notes", style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.red),
              onTap: confirmDeleteAll,
            ),
          ),
          const SizedBox(height: 16),

          /// 👤 Account Info
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.person, color: Colors.deepPurple),
              title: const Text("Account", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(supabase.auth.currentUser?.email ?? ""),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 16),

          /// ℹ️ About / App Version
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.info, color: Colors.deepPurple),
              title: const Text("About", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Notes App v1.0"),
              onTap: () {},
            ),
          ),

        ],
      ),
    );
  }
}