import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class EditPublicationPage extends StatefulWidget {
  final Map<String, dynamic> publicationData;
  const EditPublicationPage({Key? key, required this.publicationData})
      : super(key: key);

  @override
  _EditPublicationPageState createState() => _EditPublicationPageState();
}

class _EditPublicationPageState extends State<EditPublicationPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  String? _selectedCategory;
  final List<String> _categories = [
    'Electrónica',
    'Muebles',
    'Ropa',
    'Vehículos',
    'Inmuebles',
    'Otros',
  ];

  // Lista para imágenes nuevas seleccionadas.
  List<File> _selectedImages = [];
  // Imágenes originales (almacenadas en Firestore como base64).
  List<String> _originalImages = [];

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Prellenamos los campos con la información actual.
    _titleController =
        TextEditingController(text: widget.publicationData['title'] ?? '');
    _descriptionController =
        TextEditingController(text: widget.publicationData['description'] ?? '');
    _priceController = TextEditingController(
        text: widget.publicationData['price']?.toString() ?? '');
    _selectedCategory = widget.publicationData['category'];
    if (widget.publicationData['images'] != null) {
      _originalImages = List<String>.from(widget.publicationData['images']);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// Permite seleccionar nuevas imágenes desde la galería.
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

  /// Comprime la imagen usando flutter_image_compress.
  Future<File?> compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 40,
      minWidth: 300,
      minHeight: 300,
    );
    return result != null ? File(result.path) : null;
  }

  /// Convierte las imágenes seleccionadas a base64 (después de comprimir).
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

  /// Actualiza la publicación en Firestore.
  Future<void> _updatePublication() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      List<String> imagesToUpdate;
      // Si se seleccionaron nuevas imágenes, se usan; de lo contrario se mantienen las originales.
      if (_selectedImages.isNotEmpty) {
        imagesToUpdate = await _convertImagesToBase64();
      } else {
        imagesToUpdate = _originalImages;
      }
      // Mapa con los datos actualizados.
      Map<String, dynamic> updateData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'category': _selectedCategory,
        'images': imagesToUpdate,
      };
      String publicationId = widget.publicationData['publicationId'];
      await FirebaseFirestore.instance
          .collection('publicaciones')
          .doc(publicationId)
          .update(updateData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Publicación actualizada correctamente")),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage =
        'Error al actualizar la publicación. Intenta nuevamente.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Elimina la publicación en Firestore.
  Future<void> _deletePublication() async {
    try {
      String publicationId = widget.publicationData['publicationId'];
      await FirebaseFirestore.instance
          .collection('publicaciones')
          .doc(publicationId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Publicación eliminada correctamente")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al eliminar la publicación: $e")),
      );
    }
  }

  /// Muestra un diálogo de confirmación para borrar la publicación.
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar publicación"),
        content:
        const Text("¿Estás seguro de que deseas eliminar esta publicación?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deletePublication();
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Publicación"),
        actions: [
          // Botón para borrar la publicación.
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
          )
        ],
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
                      : (_originalImages.isNotEmpty
                      ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _originalImages.length,
                    itemBuilder: (context, index) {
                      try {
                        final bytes = base64Decode(_originalImages[index]);
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.memory(
                              bytes,
                              width: 180,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      } catch (e) {
                        return Container(
                          width: 180,
                          color: Colors.grey,
                          child: const Center(
                              child: Icon(Icons.error, color: Colors.white)),
                        );
                      }
                    },
                  )
                      : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.photo_library, size: 50, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Sube tus fotos',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )),
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
                  onPressed: _isLoading ? null : _updatePublication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                    'Actualizar publicación',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _confirmDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  icon: const Icon(Icons.delete),
                  label: const Text(
                    'Borrar publicación',
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
