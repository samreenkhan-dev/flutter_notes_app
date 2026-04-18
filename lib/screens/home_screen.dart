import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/login_screen.dart';
import 'add_edit_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;

  List notes = [];
  String searchText = "";
  bool isSearching = false;

  File? profileImage;

  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  /// 📥 FETCH NOTES
  Future fetchNotes() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('notes')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    setState(() => notes = data);
  }

  /// 🗑 DELETE NOTE
  Future deleteNote(String id) async {
    await supabase.from('notes').delete().eq('id', id);
    fetchNotes();
  }

  void confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Note"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              deleteNote(id);
            },
            child: const Text("Delete"),
          )
        ],
      ),
    );
  }

  /// 📅 FORMAT DATE
  String formatDate(String? date) {
    if (date == null) return "";
    return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
  }

  /// 🚪 LOGOUT
  Future logout() async {
    await supabase.auth.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  /// 🖼 PICK PROFILE IMAGE
  Future<void> pickProfileImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/profile.jpg');
      await File(picked.path).copy(file.path);

      if (!mounted) return; // avoid context issues
      setState(() => profileImage = file);
    }
  }


  @override
  Widget build(BuildContext context) {
    final filteredNotes = notes.where((note) {
      final title = (note['title'] ?? "").toLowerCase();
      final content = (note['content'] ?? "").toLowerCase();
      return title.contains(searchText.toLowerCase()) ||
          content.contains(searchText.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],

      /// ☰ DRAWER
      drawer: Drawer(
        child: Column(
          children: [

            /// 👤 PROFILE HEADER (CLICKABLE)
            GestureDetector(
              onTap: pickProfileImage,
              child: UserAccountsDrawerHeader(
                decoration:
                const BoxDecoration(color: Colors.deepPurple),
                accountName: const Text("Welcome"),
                accountEmail:
                Text(supabase.auth.currentUser?.email?? ""),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: profileImage != null
                      ? FileImage(profileImage!)
                      : null,
                  child: profileImage == null
                      ? const Icon(Icons.person,
                      color: Colors.deepPurple)
                      : null,
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () => Navigator.pop(context),
            ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SettingsScreen()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: logout,
            ),
          ],
        ),
      ),

      /// 🔍 APPBAR
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,

        title: isSearching
            ? TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search notes...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() => searchText = value);
          },
        )
            : const Text("My Notes",
            style: TextStyle(color: Colors.white)),

        actions: [
          isSearching
              ? IconButton(
            icon: const Icon(Icons.close,
                color: Colors.white),
            onPressed: () {
              setState(() {
                isSearching = false;
                searchText = "";
              });
            },
          )
              : IconButton(
            icon: const Icon(Icons.search,
                color: Colors.white),
            onPressed: () {
              setState(() => isSearching = true);
            },
          ),
        ],
      ),

      /// ➕ ADD NOTE
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AddEditScreen()),
          );
          fetchNotes();
        },
      ),

      /// 📋 NOTES LIST
      body: filteredNotes.isEmpty
          ? const Center(child: Text("No notes found"))
          :
      ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filteredNotes.length,
        itemBuilder: (_, i) {
          final note = filteredNotes[i];

          return GestureDetector(
            onTap: () async {
              // Open note for editing
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddEditScreen(note: note)),
              );
              fetchNotes();
            },
            onLongPress: () {
              // Show delete dialog on long press
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text(
                    "Delete Note",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: const Text(
                    "Are you sure you want to delete this note? This action cannot be undone.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        deleteNote(note['id']);
                      },
                      child: const Text("Delete",style: TextStyle(color: Colors.white),),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 5)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    note['title'] ?? "",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Content (max 2 lines)
                  Text(
                    note['content'] ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),

                  // Image (if exists)
                  if (note['image_url'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          note['image_url'],
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  // Date aligned to bottom right
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      formatDate(note['created_at']),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      )
    );
  }
}