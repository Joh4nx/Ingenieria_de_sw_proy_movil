// ==========================
// PUBLICAR PAGE
// ==========================
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class PublicarPage extends StatefulWidget {
  const PublicarPage({Key? key}) : super(key: key);

  @override
  _PublicarPageState createState() => _PublicarPageState();
}

class _PublicarPageState extends State<PublicarPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String? _selectedCategory;
  final List<String> _categories = [
    'Electrónica',
    'Muebles',
    'Ropa',
    'Vehículos',
    'Inmuebles',
    'Otros',
  ];

  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickImages() async {
    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages =
              pickedFiles.map((xfile) => File(xfile.path)).toList();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al seleccionar imágenes: $e';
      });
    }
  }

  Future<File?> compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 40,
      minWidth: 300,
      minHeight: 300,
    );
    if (result == null) return null;
    return File(result.path);
  }

  Future<List<String>> _convertImagesToBase64() async {
    List<String> base64Images = [];
    for (File image in _selectedImages) {
      File? compressedImage = await compressImage(image);
      File fileToConvert = compressedImage ?? image;
      final bytes = await fileToConvert.readAsBytes();
      base64Images.add(base64Encode(bytes));
    }
    return base64Images;
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, selecciona al menos una imagen.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      print("Convirtiendo imágenes a base64...");
      List<String> imageBase64List = await _convertImagesToBase64();
      print("Imágenes convertidas: ${imageBase64List.length}");
      User? user = FirebaseAuth.instance.currentUser;
      // Primero agregamos el documento sin publicationId
      final docRef = await FirebaseFirestore.instance.collection('publicaciones').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'category': _selectedCategory,
        'images': imageBase64List,
        'userId': user?.uid,
        'userEmail': user?.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Luego actualizamos el documento para agregar su ID.
      await docRef.update({'publicationId': docRef.id});
      print("Publicación guardada correctamente en Firestore.");
      Navigator.pop(context);
    } catch (e) {
      print("Error en la publicación: $e");
      setState(() {
        _errorMessage = 'Error al publicar. Intenta nuevamente.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: _selectedImages.isNotEmpty
                      ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(
                            _selectedImages[index],
                            width: 180,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  )
                      : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.photo_library,
                            size: 50, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Sube tus fotos',
                          style:
                          TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un precio';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Ingresa un precio válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((cat) => DropdownMenuItem<String>(
                  value: cat,
                  child: Text(cat),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecciona una categoría';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _publish,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                    'Publicar',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
