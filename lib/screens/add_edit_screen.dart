import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddEditScreen extends StatefulWidget {
  final Map? note;
  const AddEditScreen({super.key, this.note});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final supabase = Supabase.instance.client;

  final title = TextEditingController();
  final content = TextEditingController();

  File? localImage;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      title.text = widget.note!['title'] ?? '';
      content.text = widget.note!['content'] ?? '';
    }
  }

  Future pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => localImage = File(picked.path));
    }
  }

  Future<String> uploadFile(File file, String path) async {
    await supabase.storage.from('bucket1').upload(path, file);
    return supabase.storage.from('bucket1').getPublicUrl(path);
  }

  Future saveNote() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => saving = true);

    String? imageUrl = widget.note?['image_url'];

    try {
      if (localImage != null) {
        String path = "images/${DateTime.now().millisecondsSinceEpoch}.jpg";
        imageUrl = await uploadFile(localImage!, path);
      }

      if (widget.note == null) {
        await supabase.from('notes').insert({
          'user_id': user.id,
          'title': title.text.trim(),
          'content': content.text.trim(),
          'image_url': imageUrl,
        });
      } else {
        await supabase.from('notes').update({
          'title': title.text.trim(),
          'content': content.text.trim(),
          'image_url': imageUrl,
        }).eq('id', widget.note!['id']);
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingImage = widget.note?['image_url'];

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(
          widget.note == null ? "Add Note" : "Edit Note",
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          saving
              ? const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          )
              : IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: saveNote,
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // IMAGE CARD
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: localImage != null
                      ? Image.file(localImage!, fit: BoxFit.cover)
                      : existingImage != null
                      ? Image.network(existingImage, fit: BoxFit.cover)
                      : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.image,
                            size: 50, color: Colors.deepPurple),
                        SizedBox(height: 10),
                        Text("Tap to add image"),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // TITLE FIELD
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: TextField(
                controller: title,
                decoration: const InputDecoration(
                  hintText: "Title",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 15),

            // CONTENT FIELD
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: TextField(
                controller: content,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: "Write your thoughts...",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}