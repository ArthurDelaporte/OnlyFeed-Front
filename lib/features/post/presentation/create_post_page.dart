import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyfeed_frontend/core/widgets/scaffold_with_menubar.dart';
import 'package:onlyfeed_frontend/features/post/services/post_service.dart';
import 'package:provider/provider.dart';
import 'package:onlyfeed_frontend/features/post/providers/post_provider.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _postService = PostService();
  
  File? _mediaFile;
  Uint8List? _webImageBytes;
  String? _fileName;
  bool _isPaid = false;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      
      if (image != null) {
        if (kIsWeb) {
          // Pour le web, lire l'image comme bytes
          final bytes = await image.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            _fileName = image.name;
            _mediaFile = null; // S'assurer de ne pas utiliser _mediaFile sur le web
          });
        } else {
          // Pour mobile, utiliser File comme avant
          setState(() {
            _mediaFile = File(image.path);
            _fileName = image.name;
            _webImageBytes = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("post.image_pick_error".tr())),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    if (kIsWeb) {
      // Sur le web, demander directement la galerie car la caméra peut ne pas fonctionner correctement
      _pickImage(ImageSource.gallery);
    } else {
      // Sur mobile, montrer les options
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: Text("post.pick_from_gallery".tr()),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: Text("post.take_photo".tr()),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Future<void> _submitPost() async {
    final bool hasImage = kIsWeb ? _webImageBytes != null : _mediaFile != null;
    
    if (_formKey.currentState!.validate() && hasImage) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Utiliser le Provider pour créer le post
        await context.read<PostProvider>().createPost(
          title: _titleController.text,
          description: _descriptionController.text,
          isPaid: _isPaid,
          mediaFile: _mediaFile,
          imageBytes: _webImageBytes,
          fileName: _fileName,
        );

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("post.create_success".tr())),
          );
          context.go('/profile'); // Redirection vers la page de profil
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${e.toString()}")),
          );
        }
      }
    } else if (!hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("post.media_required".tr())),
      );
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _mediaFile = null;
      _webImageBytes = null;
      _fileName = null;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithMenubar(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Prévisualisation de l'image
                    if (_mediaFile != null && !kIsWeb)
                      // Aperçu pour mobile
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _mediaFile!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: _clearSelectedImage,
                          ),
                        ],
                      )
                    else if (_webImageBytes != null && kIsWeb)
                      // Aperçu pour web
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _webImageBytes!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: _clearSelectedImage,
                          ),
                        ],
                      )
                    else
                      // Zone de sélection d'image
                      InkWell(
                        onTap: _showImagePickerOptions,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_a_photo, size: 48),
                                const SizedBox(height: 8),
                                Text("post.add_photo".tr()),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Champ titre
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: ("post.title".tr()),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return ("post.title_required".tr());
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Champ description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: ("post.description".tr()),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),

                    // Switch contenu payant
                    SwitchListTile(
                      title: Text("post.paid_content".tr()),
                      subtitle: Text("post.paid_content_desc".tr()),
                      value: _isPaid,
                      onChanged: (bool value) {
                        setState(() {
                          _isPaid = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Bouton de soumission
                    ElevatedButton(
                      onPressed: _submitPost,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text("post.publish".tr()),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}