import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:google_fonts/google_fonts.dart';

// Importa las páginas que se usan en las rutas.
import 'edit_publication_page.dart';
import 'publicar_page.dart';

/// Widget para mostrar imágenes en Base64 o un placeholder (asset) si no hay imagen.
class Base64ImageWidget extends StatelessWidget {
  final String? base64String;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;

  const Base64ImageWidget({
    Key? key,
    required this.base64String,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (base64String == null || base64String!.isEmpty) {
      return placeholder ??
          Image.asset(
            'assets/images/placeholder.png',
            width: width,
            height: height,
            fit: fit,
          );
    }
    try {
      final bytes = base64Decode(base64String!);
      return Image.memory(bytes, fit: fit, width: width, height: height);
    } catch (e) {
      return placeholder ??
          Image.asset(
            'assets/images/placeholder.png',
            width: width,
            height: height,
            fit: fit,
          );
    }
  }
}

/// Widget para el botón de favoritos (likes).
class FavoriteButton extends StatefulWidget {
  final String publicationId;
  const FavoriteButton({Key? key, required this.publicationId}) : super(key: key);

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _toggleLike(List<dynamic> currentLikes) async {
    if (currentUser == null) return;
    final userId = sanitizeEmail(currentUser!.email!);
    final docRef = FirebaseFirestore.instance
        .collection('publicaciones')
        .doc(widget.publicationId);
    if (currentLikes.contains(userId)) {
      await docRef.update({'likes': FieldValue.arrayRemove([userId])});
    } else {
      await docRef.update({'likes': FieldValue.arrayUnion([userId])});
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('publicaciones')
          .doc(widget.publicationId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border, size: 20, color: MyApp.primaryColor),
              const SizedBox(width: 4),
              const Text("0"),
            ],
          );
        }
        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final List<dynamic> likes = data['likes'] ?? [];
        final userId = currentUser != null ? sanitizeEmail(currentUser!.email!) : "";
        final isLiked = likes.contains(userId);
        return InkWell(
          onTap: () => _toggleLike(likes),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: isLiked ? Colors.red : MyApp.primaryColor,
              ),
              const SizedBox(width: 4),
              Text(likes.length.toString()),
            ],
          ),
        );
      },
    );
  }
}
///-------------------------
///notificaciones
///-------------------------------------------



/// Nuevo diseño para las tarjetas de productos.
class ProductCard extends StatelessWidget {
  final String title;
  final String price;
  final String image;
  final String publicationId;

  const ProductCard({
    Key? key,
    required this.title,
    required this.price,
    required this.image,
    required this.publicationId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280, // Altura fija para la tarjeta completa
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Sección de imagen
            Container(
              height: 180,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Base64ImageWidget(
                      base64String: image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Sección de contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              price,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: MyApp.secondaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          FavoriteButton(publicationId: publicationId),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Función para "sanitizar" el email (reemplaza "@" y "." por guion bajo)
String sanitizeEmail(String email) {
  return email.toLowerCase().replaceAll(RegExp(r'[@.]'), '_');
}

/// **********************************************************************
/// Sección de publicidad en un solo carrusel.
class AutoScrollCarousel extends StatefulWidget {
  final List<Widget> items;
  final double height;
  final Duration interval;

  const AutoScrollCarousel({
    Key? key,
    required this.items,
    this.height = 280,
    this.interval = const Duration(seconds: 5),
  }) : super(key: key);

  @override
  _AutoScrollCarouselState createState() => _AutoScrollCarouselState();
}

class _AutoScrollCarouselState extends State<AutoScrollCarousel> {
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _timer = Timer.periodic(widget.interval, (Timer timer) {
      if (widget.items.isNotEmpty) {
        int nextPage = _pageController.page!.toInt() + 1;
        if (nextPage >= widget.items.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.items.length,
        itemBuilder: (context, index) => widget.items[index],
      ),
    );
  }
}

/// Sección de publicaciones populares.
class AdvertisementSection extends StatelessWidget {
  const AdvertisementSection({Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchCombinedPopularPosts() async {
    final pubSnapshot =
    await FirebaseFirestore.instance.collection('publicaciones').get();
    List<Map<String, dynamic>> publications = pubSnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['publicationId'] = doc.id;
      return data;
    }).toList();

    for (var pub in publications) {
      pub['likesCount'] =
      pub['likes'] is List ? (pub['likes'] as List).length : (pub['likes'] ?? 0);
    }

    final chatSnapshot =
    await FirebaseFirestore.instance.collection('chats').get();
    Map<String, int> pubInteraction = {};
    for (var doc in chatSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final pubId = data['publicationId'] ?? 'desconocido';
      pubInteraction[pubId] = (pubInteraction[pubId] ?? 0) + 1;
    }

    for (var pub in publications) {
      pub['interactionCount'] = pubInteraction[pub['publicationId']] ?? 0;
      pub['compositeScore'] =
          (pub['likesCount'] as int) + (pub['interactionCount'] as int);
    }

    publications.sort((a, b) =>
        (b['compositeScore'] as int).compareTo(a['compositeScore'] as int));

    return publications.take(5).toList();
  }

  Widget _buildProductCard(Map<String, dynamic> pub, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PublicationDetailPage(data: pub),
            ),
          );
        },
        child: ProductCard(
          title: pub['title'] ?? 'Sin título',
          price: pub['price'] != null ? "\$${pub['price']}" : "",
          image: (pub['images'] != null && (pub['images'] as List).isNotEmpty)
              ? (pub['images'][0] as String)
              : "",
          publicationId: pub['publicationId'] ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Detecta el ancho de pantalla para definir si es tablet
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchCombinedPopularPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox();
        }
        List<Map<String, dynamic>> popularPosts = snapshot.data!;

        List<Widget> items;
        if (isTablet) {
          // En tablet, agrupar en pares
          items = [];
          for (int i = 0; i < popularPosts.length; i += 2) {
            Widget first = _buildProductCard(popularPosts[i], context);
            Widget second;
            if (i + 1 < popularPosts.length) {
              second = _buildProductCard(popularPosts[i + 1], context);
            } else {
              second = const SizedBox(); // Espacio vacío si es impar
            }
            items.add(
              Row(
                children: [
                  Expanded(child: first),
                  const SizedBox(width: 8),
                  Expanded(child: second),
                ],
              ),
            );
          }
        } else {
          // En móvil, se muestra una sola tarjeta por slide.
          items = popularPosts.map((pub) {
            return _buildProductCard(pub, context);
          }).toList();
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("Lo más popular",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            AutoScrollCarousel(items: items, height: 280),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

/// Sección de comentarios para la publicación.
class CommentsSection extends StatefulWidget {
  final String publicationId;
  const CommentsSection({Key? key, required this.publicationId}) : super(key: key);

  @override
  _CommentsSectionState createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final TextEditingController _commentController = TextEditingController();

  void _postComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final commentData = {
      'userId': currentUser.uid,
      'userEmail': currentUser.email,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('publicaciones')
        .doc(widget.publicationId)
        .collection('comments')
        .add(commentData);

    _commentController.clear();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Comentarios",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('publicaciones')
              .doc(widget.publicationId)
              .collection('comments')
              .orderBy('timestamp', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("No hay comentarios."),
              );
            }
            final comments = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final data = comments[index].data() as Map<String, dynamic>;
                final commentText = data['comment'] ?? '';
                final userEmail = data['userEmail'] ?? 'Anónimo';
                return ListTile(
                  title: Text(userEmail,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(commentText),
                );
              },
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: "Escribe un comentario...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _postComment,
              )
            ],
          ),
        ),
      ],
    );
  }
}

/// PUBLICATION DETAIL PAGE para ver publicaciones generales (sin edición).
class PublicationDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const PublicationDetailPage({Key? key, required this.data}) : super(key: key);

  String _generateChatRoomId(String publicationId, String email1, String email2) {
    return '$publicationId#${sanitizeEmail(email1)}#${sanitizeEmail(email2)}';
  }

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? '';
    final description = data['description'] ?? '';
    final price = data['price'] != null ? "\$${data['price']}" : '';
    final category = data['category'] ?? '';
    final publisherEmail = data['userEmail'] ?? 'Desconocido';
    final publicationId = data['publicationId'] ?? '';
    final List<dynamic> images = data['images'] ?? [];
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sección de imagen
            images.isNotEmpty
                ? SizedBox(
              height: 300,
              child: PageView.builder(
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Base64ImageWidget(
                    base64String: images[index] as String,
                    fit: BoxFit.cover,
                  );
                },
              ),
            )
                : Container(
              height: 300,
              color: Theme.of(context).colorScheme.surface,
              child: Image.asset(
                'assets/images/placeholder.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila con el título y el botón de reportar con diálogo detallado
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Título de la publicación
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Botón de reportar con estilo mejorado
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.flag),
                          color: Colors.redAccent,
                          tooltip: "Reportar publicación",
                          // Dentro del IconButton del reporte:
                          onPressed: () {
                            // Se muestra el diálogo que explica el proceso y solicita el motivo del reporte
                            showDialog(
                              context: context,
                              builder: (context) {
                                String reportReason = "";
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    return AlertDialog(
                                      title: const Text("Reportar publicación"),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Al reportar esta publicación, estás indicando que contiene contenido inapropiado o viola nuestras políticas. "
                                                  "Por favor, indícanos el motivo específico por el cual deseas reportarla:",
                                            ),
                                            const SizedBox(height: 12),
                                            TextField(
                                              maxLines: 3,
                                              onChanged: (value) {
                                                setState(() {
                                                  reportReason = value;
                                                });
                                              },
                                              decoration: const InputDecoration(
                                                hintText: "Motivo del reporte...",
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text("Cancelar"),
                                        ),
                                        TextButton(
                                          // Dentro del botón de "Reportar" en el diálogo:
                                          onPressed: () async {
                                            if (reportReason.trim().isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Por favor, ingresa un motivo para reportar.")),
                                              );
                                              return;
                                            }
                                            // Guarda el reporte en la colección 'reports'
                                            await FirebaseFirestore.instance.collection('reports').add({
                                              'publicationId': publicationId,
                                              'reportedBy': currentUser != null ? sanitizeEmail(currentUser.email!) : 'Desconocido',
                                              'reason': reportReason.trim(),
                                              'timestamp': FieldValue.serverTimestamp(),
                                            });

                                            // Creamos o actualizamos la sala de chat para el reporte
                                            // Usamos un ID único que combine el publicationId y el usuario que reporta
                                            final String reportChatRoomId = "report_${publicationId}#${sanitizeEmail(currentUser!.email!)}";
                                            final chatRef = FirebaseFirestore.instance.collection('chats').doc(reportChatRoomId);
                                            final chatDoc = await chatRef.get();
                                            if (!chatDoc.exists) {
                                              // Crea la sala de chat marcándola como reporte
                                              await chatRef.set({
                                                'participants': [sanitizeEmail(currentUser.email!)],
                                                'publicationTitle': "Reporte de publicación",
                                                'publicationId': publicationId,
                                                'lastMessage': "",
                                                'lastMessageTimestamp': FieldValue.serverTimestamp(),
                                                'createdAt': FieldValue.serverTimestamp(),
                                                'unreadCounts': {sanitizeEmail(currentUser.email!): 0},
                                                'isReport': true, // Marca este chat como reporte
                                              });
                                            }
                                            // Envía el mensaje con el motivo del reporte
                                            final String reportMessage = "Reporte: $reportReason";
                                            await chatRef.collection('messages').add({
                                              'sender': sanitizeEmail(currentUser.email!),
                                              'message': reportMessage,
                                              'timestamp': FieldValue.serverTimestamp(),
                                            });
                                            // Actualiza el último mensaje del chat
                                            await chatRef.update({
                                              'lastMessage': reportMessage,
                                              'lastMessageTimestamp': FieldValue.serverTimestamp(),
                                            });

                                            Navigator.of(context).pop();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Publicación reportada y enviada al administrador.")),
                                            );
                                          },


                                          child: const Text(
                                            "Reportar",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },

                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Categoría
                  Text(
                    category,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Precio
                  Text(
                    price,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Descripción
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  // Publicado por...
                  Text(
                    'Publicado por: $publisherEmail',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Botón para enviar mensaje
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
                        final chatRoomId = _generateChatRoomId(
                          publicationId,
                          currentUserEmail,
                          publisherEmail,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              chatRoomId: chatRoomId,
                              publisherEmail: publisherEmail,
                              publicationTitle: title,
                              publicationId: publicationId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.message),
                      label: const Text('Enviar mensaje'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Sección de comentarios
                  CommentsSection(publicationId: publicationId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// PUBLICATION DETAIL OWNER PAGE: Detalle para publicaciones propias con botones de Editar y Eliminar.
class PublicationDetailOwnerPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const PublicationDetailOwnerPage({Key? key, required this.data}) : super(key: key);

  Future<void> _deletePublication(BuildContext context) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar publicación"),
        content: const Text("¿Estás seguro de que deseas eliminar esta publicación?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      String publicationId = data['publicationId'];
      await FirebaseFirestore.instance
          .collection('publicaciones')
          .doc(publicationId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Publicación eliminada correctamente")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? '';
    final description = data['description'] ?? '';
    final price = data['price'] != null ? "\$${data['price']}" : '';
    final category = data['category'] ?? '';
    final publisherEmail = data['userEmail'] ?? 'Desconocido';
    final publicationId = data['publicationId'] ?? '';
    final List<dynamic> images = data['images'] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            images.isNotEmpty
                ? SizedBox(
              height: 300,
              child: PageView.builder(
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Base64ImageWidget(
                    base64String: images[index] as String,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  );
                },
              ),
            )
                : Container(
              height: 300,
              color: Theme.of(context).colorScheme.surface,
              child: Image.asset(
                'assets/images/placeholder.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(category,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.7))),
                  const SizedBox(height: 8),
                  Text(price,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                          color: Theme.of(context).colorScheme.secondary)),
                  const SizedBox(height: 16),
                  Text(description, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  Text('Publicado por: $publisherEmail',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.7))),
                  const SizedBox(height: 24),
                  // Botones de Editar y Eliminar para publicaciones propias.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditPublicationPage(publicationData: data),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text("Editar"),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _deletePublication(context),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        icon: const Icon(Icons.delete),
                        label: const Text("Eliminar"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Sección de comentarios.
                  CommentsSection(publicationId: publicationId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CHAT PAGE: Pantalla para chatear.
class ChatPage extends StatefulWidget {
  final String chatRoomId;
  final String publisherEmail;
  final String publicationTitle;
  final String publicationId;
  const ChatPage({
    Key? key,
    required this.chatRoomId,
    required this.publisherEmail,
    required this.publicationTitle,
    required this.publicationId,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? productImageBase64;
  String? currentUserPhoto;
  String? publisherPhoto;

  @override
  void initState() {
    super.initState();
    _createChatRoomIfNotExists();
    _resetUnreadCount();
    _loadProductImage();
    _loadProfilePhotos();
  }

  Future<void> _loadProductImage() async {
    final doc = await FirebaseFirestore.instance
        .collection('publicaciones')
        .doc(widget.publicationId)
        .get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final List<dynamic>? images = data['images'];
      if (images != null && images.isNotEmpty) {
        setState(() {
          productImageBase64 = images[0] as String;
        });
      }
    }
  }

  Future<void> _loadProfilePhotos() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      setState(() {
        currentUserPhoto = currentUser.photoURL;
      });
    }
    final querySnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('email', isEqualTo: widget.publisherEmail)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      final data = querySnapshot.docs.first.data();
      setState(() {
        publisherPhoto = data['photoURL'] as String?;
      });
    }
  }

  Future<void> _createChatRoomIfNotExists() async {
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatRoomId);
    final snapshot = await chatRef.get();
    if (!snapshot.exists) {
      final currentUserSanitized = sanitizeEmail(_auth.currentUser!.email!);
      final publisherSanitized = sanitizeEmail(widget.publisherEmail);
      String publicationImage = "";
      final pubDoc = await FirebaseFirestore.instance.collection('publicaciones').doc(widget.publicationId).get();
      if (pubDoc.exists) {
        final pubData = pubDoc.data() as Map<String, dynamic>;
        final List<dynamic> images = pubData['images'] ?? [];
        if (images.isNotEmpty) {
          publicationImage = images[0] as String;
        }
      }
      await chatRef.set({
        'participants': [currentUserSanitized, publisherSanitized],
        'publicationTitle': widget.publicationTitle,
        'publicationId': widget.publicationId,
        'publicationImage': publicationImage,
        'unreadCounts': {currentUserSanitized: 0, publisherSanitized: 0},
        'lastMessage': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _resetUnreadCount() async {
    final currentUserSanitized = sanitizeEmail(_auth.currentUser!.email!);
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .update({'unreadCounts.$currentUserSanitized': 0});
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    _messageController.clear();
    final currentUserSanitized = sanitizeEmail(_auth.currentUser!.email!);
    final recipientSanitized = sanitizeEmail(widget.publisherEmail);
    final messageData = {
      'sender': currentUserSanitized,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    };
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatRoomId);
    await chatRef.collection('messages').add(messageData);
    await chatRef.update({
      'lastMessage': message,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'unreadCounts.$recipientSanitized': FieldValue.increment(1),
    });
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MyApp.primaryColor,
            MyApp.primaryColor.withOpacity(0.85)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: MyApp.primaryColor.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: productImageBase64 != null
                  ? DecorationImage(
                image: MemoryImage(base64Decode(productImageBase64!)),
                fit: BoxFit.cover,
              )
                  : null,
              color: Theme.of(context).colorScheme.surface,
            ),
            child: productImageBase64 == null
                ? Icon(Icons.image, size: 40, color: Theme.of(context).colorScheme.onSurface)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.publicationTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String email) {
    String? photo;
    final currentUserEmail = _auth.currentUser!.email!;
    if (email == currentUserEmail) {
      photo = currentUserPhoto;
    } else {
      photo = publisherPhoto;
    }
    if (photo != null && photo.isNotEmpty) {
      if (photo.startsWith("http")) {
        return CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(photo),
        );
      } else {
        try {
          final normalized = base64.normalize(photo.trim());
          return CircleAvatar(
            radius: 20,
            backgroundImage: MemoryImage(base64Decode(normalized)),
          );
        } catch (e) {
          return CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: Text(
              email.isNotEmpty ? email[0].toUpperCase() : '?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
      }
    } else {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Text(
          email.isNotEmpty ? email[0].toUpperCase() : '?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
  }

  Widget _buildChatBubble(String sender, String message, bool isMe, bool showAvatar) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isMe && showAvatar) ...[
          _buildAvatar(sender),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? MyApp.primaryColor : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(20),
              ),
            ),
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isMe
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
        if (isMe && showAvatar) ...[
          const SizedBox(width: 8),
          _buildAvatar(sender),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserSanitized = sanitizeEmail(_auth.currentUser!.email!);
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat con ${widget.publisherEmail}'),
      ),
      body: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final currentData = messages[index].data() as Map<String, dynamic>;
                    final sender = currentData['sender'] ?? 'Desconocido';
                    final message = currentData['message'] ?? '';
                    final isMe = sender == currentUserSanitized;
                    bool showAvatar = false;
                    if (index == messages.length - 1) {
                      showAvatar = true;
                    } else {
                      final nextData = messages[index + 1].data() as Map<String, dynamic>;
                      if (nextData['sender'] != sender) {
                        showAvatar = true;
                      }
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _buildChatBubble(sender, message, isMe, showAvatar),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: MyApp.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// MAIN
void main() {
  runApp(const MyApp());
}

/// Clase principal con la nueva paleta de colores moderna.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // Nueva paleta de colores.
  static final Color primaryColor = const Color(0xFF6C5CE7);
  static final Color secondaryColor = const Color(0xFF00B894);
  static final Color accentColor = const Color(0xFFFF7675);
  static final Color backgroundColor = const Color(0xFFF8F9FA);
  static final Color surfaceColor = Colors.white;
  static final Color onSurfaceColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marketplace Pro',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          titleLarge: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          titleMedium: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          titleSmall: const TextStyle(fontSize: 18),
          bodyLarge: TextStyle(fontSize: 16, color: onSurfaceColor.withOpacity(0.8)),
          bodyMedium: TextStyle(fontSize: 14, color: onSurfaceColor.withOpacity(0.7)),
        ),
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          onPrimary: Colors.white,
          secondary: secondaryColor,
          onSecondary: Colors.white,
          surface: surfaceColor,
          onSurface: onSurfaceColor,
          background: backgroundColor,
          onBackground: onSurfaceColor,
          error: accentColor,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          elevation: 6,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: primaryColor,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: primaryColor),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
        ),
        cardTheme: CardTheme(
          color: surfaceColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey.shade600,
          backgroundColor: surfaceColor,
          elevation: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        ),
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomePage(),
        '/publicar': (context) => const PublicarPage(),
      },
    );
  }
}

/// HOME PAGE CON NUEVO DISEÑO MODERNO.
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    InicioPage(),
    MensajesPage(),
    PerfilPage(),
  ];

  @override
  Widget build(BuildContext context) {
    // Usa el uid del usuario actual para la consulta.
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace Pro'),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notificaciones')
                .where('recipientId', isEqualTo: currentUserId)
                .where('read', isEqualTo: false)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              bool hasUnread =
                  snapshot.hasData && snapshot.data!.docs.isNotEmpty;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),
                  if (hasUnread)
                    const Positioned(
                      right: 12,
                      top: 12,
                      child: CircleAvatar(
                        radius: 5,
                        backgroundColor: Colors.red,
                      ),
                    ),
                ],
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Cerrar Sesión'),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        backgroundColor: MyApp.primaryColor,
        child: const Icon(Icons.add, size: 30),
        onPressed: () {
          Navigator.pushNamed(context, '/publicar');
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: MyApp.primaryColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: [
            _buildNavItem(Icons.home_outlined, 'Inicio'),
            _buildNavItem(Icons.chat_bubble_outline, 'Mensajes'),
            _buildNavItem(Icons.person_outline, 'Perfil'),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, size: 26),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        decoration: BoxDecoration(
          color: MyApp.primaryColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, size: 26),
      ),
      label: label,
    );
  }
}

/// INICIO PAGE: Búsqueda, filtros, publicidad y listado de publicaciones.
/// INICIO PAGE: Búsqueda, filtros, publicidad y listado de publicaciones.
class InicioPage extends StatefulWidget {
  const InicioPage({Key? key}) : super(key: key);
  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedCategoryFilter = 'Todas';
  String _selectedPriceFilter = 'Todos';
  final List<String> _categoryOptions = [
    'Todas',
    'Electrónica',
    'Muebles',
    'Ropa',
    'Vehículos',
    'Inmuebles',
    'Otros',
  ];
  final List<String> _priceOptions = [
    'Todos',
    '0-50',
    '50-100',
    '100-200',
    '>200',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _priceInRange(num price) {
    switch (_selectedPriceFilter) {
      case '0-50':
        return price >= 0 && price <= 50;
      case '50-100':
        return price > 50 && price <= 100;
      case '100-200':
        return price > 100 && price <= 200;
      case '>200':
        return price > 200;
      default:
        return true;
    }
  }

  Widget _buildTopSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar publicaciones...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategoryFilter,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                  items: _categoryOptions
                      .map((cat) => DropdownMenuItem<String>(
                    value: cat,
                    child: Text(cat),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryFilter = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPriceFilter,
                  decoration: const InputDecoration(
                    labelText: 'Precio',
                    border: OutlineInputBorder(),
                  ),
                  items: _priceOptions
                      .map((range) => DropdownMenuItem<String>(
                    value: range,
                    child: Text(range),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPriceFilter = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 56),
      children: [
        _buildTopSection(),
        const AdvertisementSection(),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('publicaciones')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No hay publicaciones.'));
            }
            final docs = snapshot.data!.docs;
            final filteredDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title']?.toString().toLowerCase() ?? "";
              final description = data['description']?.toString().toLowerCase() ?? "";
              final category = data['category']?.toString().toLowerCase() ?? "";
              final price = data['price'] is num ? data['price'] as num : 0;
              return (title.contains(_searchQuery) || description.contains(_searchQuery)) &&
                  (_selectedCategoryFilter == 'Todas' ||
                      category == _selectedCategoryFilter.toLowerCase()) &&
                  _priceInRange(price);
            }).toList();
            for (var doc in filteredDocs) {
              (doc.data() as Map<String, dynamic>)['publicationId'] = doc.id;
            }
            final screenWidth = MediaQuery.of(context).size.width;
            final crossAxisCount = screenWidth >= 600 ? 4 : 2;
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.56,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) {
                final data = filteredDocs[index].data() as Map<String, dynamic>;
                final title = data['title'] ?? 'Sin título';
                final price = data['price'] != null ? "\$${data['price']}" : "";
                final List<dynamic> images = data['images'] ?? [];
                return InkWell(
                  onTap: () {
                    // En la vista general se navega a PublicationDetailPage (sin edición).
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PublicationDetailPage(data: data),
                      ),
                    );
                  },
                  child: ProductCard(
                    title: title,
                    price: price,
                    image: images.isNotEmpty ? images[0] as String : "",
                    publicationId: data['publicationId'] ?? '',
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/// MENSAJES PAGE: Lista de conversaciones.
class MensajesPage extends StatefulWidget {
  const MensajesPage({Key? key}) : super(key: key);
  @override
  State<MensajesPage> createState() => _MensajesPageState();
}

class _MensajesPageState extends State<MensajesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    final currentUserEmail = _auth.currentUser?.email;
    if (currentUserEmail == null) {
      return const Center(child: Text('No autenticado.'));
    }
    final sanitizedCurrentUser = sanitizeEmail(currentUserEmail);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: sanitizedCurrentUser)
          .orderBy('lastMessageTimestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay conversaciones.'));
        }
        final chatDocs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: chatDocs.length,
          itemBuilder: (context, index) {
            final data = chatDocs[index].data() as Map<String, dynamic>;
            final publicationTitle = data['publicationTitle'] ?? 'Publicación';
            final publicationId = data['publicationId'] ?? '';
            final lastMessage = data['lastMessage'] ?? '';
            final participants = List<String>.from(data['participants'] ?? []);
            final otherEmail = participants.firstWhere(
                  (email) => email != sanitizedCurrentUser,
              orElse: () => 'Desconocido',
            );
            final unreadCounts = (data['unreadCounts'] as Map<String, dynamic>?) ?? {};
            final unreadCount = (unreadCounts[sanitizedCurrentUser] ?? 0) as int;
            final publicationImageBase64 = data['publicationImage'] as String? ?? "";
            return ListTile(
              leading: Base64ImageWidget(
                base64String: publicationImageBase64,
                width: 40,
                height: 40,
                placeholder: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: Icon(
                    Icons.article,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              title: Text(publicationTitle),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chat con: $otherEmail'),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              trailing: unreadCount > 0
                  ? CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.error,
                radius: 12,
                child: Text(
                  unreadCount.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onError,
                  ),
                ),
              )
                  : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      chatRoomId: chatDocs[index].id,
                      publisherEmail: otherEmail,
                      publicationTitle: publicationTitle,
                      publicationId: publicationId,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// PERFIL PAGE: Información del usuario y sus publicaciones.
class PerfilPage extends StatefulWidget {
  const PerfilPage({Key? key}) : super(key: key);
  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  User? user = FirebaseAuth.instance.currentUser;

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserData() async {
    return FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).get();
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onBackground
                .withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mi Perfil")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: _getUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                Map<String, dynamic>? data =
                (snapshot.hasData && snapshot.data!.exists) ? snapshot.data!.data() : null;
                final displayName = data?['displayName'] ?? user?.displayName ?? "Usuario";
                final email = user?.email ?? "Correo no disponible";
                final photo = data?['photoURL'] ?? user?.photoURL;
                ImageProvider? imageProvider;
                if (photo != null && photo.isNotEmpty) {
                  if (photo.startsWith("http")) {
                    imageProvider = NetworkImage(photo);
                  } else {
                    try {
                      imageProvider = MemoryImage(base64Decode(photo));
                    } catch (e) {
                      imageProvider = null;
                    }
                  }
                }
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        backgroundImage: imageProvider,
                        child: imageProvider == null
                            ? Icon(Icons.person,
                            size: 50,
                            color: Theme.of(context).colorScheme.onSurface)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        email,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildInfoItem("Miembro desde", "01/01/2023"),
                              _buildInfoItem("Puntuación", "4.8"),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EditProfilePage()),
                          );
                          setState(() {});
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text("Editar perfil"),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(thickness: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text("Mis Publicaciones",
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('publicaciones')
                  .where('userId', isEqualTo: user?.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text("No tienes publicaciones.")),
                  );
                }
                final publications = snapshot.data!.docs;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: publications.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.6, // <- Aquí está el problema
                    ),
                    itemBuilder: (context, index) {
                      final pubData = publications[index].data() as Map<String, dynamic>;
                      final title = pubData['title'] ?? 'Sin título';
                      final price = pubData['price'] != null ? "\$${pubData['price']}" : "";
                      final List<dynamic> images = pubData['images'] ?? [];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PublicationDetailOwnerPage(data: pubData),
                            ),
                          );
                        },
                        child: ProductCard(
                          title: title,
                          price: price,
                          image: images.isNotEmpty ? images[0] as String : "",
                          publicationId: pubData['publicationId'] ?? '',
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// EDIT PROFILE PAGE: Pantalla para editar el perfil del usuario.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _displayNameController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _displayNameController.text = user?.displayName ?? "";
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String> _compressAndEncodeImage(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null)
      throw Exception("Error al decodificar la imagen.");
    final compressedImage = img.encodeJpg(decodedImage, quality: 50);
    return base64Encode(compressedImage);
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final newDisplayName = _displayNameController.text.trim();
      await user?.updateDisplayName(newDisplayName);

      Map<String, dynamic> updateData = {'displayName': newDisplayName};

      if (_imageFile != null) {
        final base64Image = await _compressAndEncodeImage(_imageFile!);
        updateData['photoURL'] = base64Image;
      }

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user!.uid)
          .set(updateData, SetOptions(merge: true));

      await user?.reload();
      user = FirebaseAuth.instance.currentUser;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perfil actualizado correctamente")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al actualizar perfil: $e")),
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    String? currentPhoto = user?.photoURL;
    ImageProvider? profileImage;
    if (_imageFile != null) {
      profileImage = FileImage(_imageFile!);
    } else if (currentPhoto != null && currentPhoto.isNotEmpty) {
      if (currentPhoto.startsWith("http")) {
        profileImage = NetworkImage(currentPhoto);
      } else {
        try {
          profileImage = MemoryImage(base64Decode(currentPhoto));
        } catch (_) {
          profileImage = null;
        }
      }
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Perfil")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    backgroundImage: profileImage,
                    child: profileImage == null
                        ? Icon(Icons.person,
                        size: 50,
                        color: Theme.of(context).colorScheme.onSurface)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: "Nombre de usuario",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return "El nombre de usuario no puede estar vacío";
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updateProfile,
                child: const Text("Guardar cambios"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
