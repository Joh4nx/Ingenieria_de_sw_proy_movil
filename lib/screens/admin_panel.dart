import 'dart:convert';
import 'dart:io';
import 'package:appmarketplace/screens/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

/// ----------------------------------------------------------------
/// Clase auxiliar: Paleta de colores (MyAppColors)
/// ----------------------------------------------------------------
class MyAppColors {
  static final Color primaryColor = const Color(0xFF6C5CE7);
  static final Color secondaryColor = const Color(0xFF00B894);
  static final Color accentColor = const Color(0xFFFF7675);
  static final Color backgroundColor = const Color(0xFFF8F9FA);
  static final Color surfaceColor = Colors.white;
  static final Color onSurfaceColor = Colors.black;
}

/// ----------------------------------------------------------------
/// Widget para mostrar imágenes desde Base64 o placeholder
/// ----------------------------------------------------------------
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
///-----------------
///favoritos widwegt
///-------------------------------------------------------------

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
              Icon(Icons.favorite_border, size: 20, color: MyAppColors.primaryColor),
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
                color: isLiked ? Colors.red : MyAppColors.primaryColor,
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


/// ----------------------------------------------------------------
/// Widget ProductCard: Muestra la tarjeta de publicación con imagen, título, precio y, opcionalmente, botón de eliminar.
/// Se utiliza tanto en la Home como en el panel de administración.
/// ----------------------------------------------------------------
class ProductCard extends StatelessWidget {
  final String title;
  final String price;
  final String image;
  final String publicationId;
  final bool showDeleteButton;
  final VoidCallback? onDelete;

  const ProductCard({
    Key? key,
    required this.title,
    required this.price,
    required this.image,
    required this.publicationId,
    this.showDeleteButton = false,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: image.isNotEmpty
                    ? ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Base64ImageWidget(
                    base64String: image,
                    fit: BoxFit.cover,
                  ),
                )
                    : Container(
                  color: Colors.grey[300],
                  child: const Center(
                      child: Icon(Icons.image, size: 50, color: Colors.white)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              // Aquí se muestra el precio y el botón de likes
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: TextStyle(color: MyAppColors.secondaryColor),
                    ),
                    FavoriteButton(publicationId: publicationId),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDeleteButton)
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ),
      ],
    );
  }
}

/// ----------------------------------------------------------------
/// Función para sanitizar el email (reemplaza "@" y "." por "_")
/// ----------------------------------------------------------------
String sanitizeEmail(String email) {
  return email.toLowerCase().replaceAll(RegExp(r'[@.]'), '_');
}

/// ----------------------------------------------------------------
/// Función para generar chatRoomId (ordena los emails alfabéticamente)
/// ----------------------------------------------------------------
String generateChatRoomId(String publicationId, String email1, String email2) {
  List<String> emails = [email1, email2];
  emails.sort();
  return '$publicationId#${sanitizeEmail(emails[0])}#${sanitizeEmail(emails[1])}';
}

/// ----------------------------------------------------------------
/// EDIT PUBLICATION PAGE (Stub)
/// ----------------------------------------------------------------
class EditPublicationPage extends StatelessWidget {
  final Map<String, dynamic> publicationData;
  const EditPublicationPage({Key? key, required this.publicationData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Publicación")),
      body: Center(
        child: Text("Editar publicación: ${publicationData['title'] ?? ''}"),
      ),
    );
  }
}

/// ----------------------------------------------------------------
/// ADMIN PUBLICATION DETAIL PAGE
/// Detalle de publicación para el administrador con botones de Editar y Eliminar.
/// ----------------------------------------------------------------
class AdminPublicationDetailPage extends StatelessWidget {
  final Map<String, dynamic> publicationData;
  const AdminPublicationDetailPage({Key? key, required this.publicationData})
      : super(key: key);

  Future<void> _deletePublication(BuildContext context, String publicationId) async {
    try {
      await FirebaseFirestore.instance.collection('publicaciones').doc(publicationId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Publicación eliminada correctamente")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al eliminar publicación: $e")),
      );
    }
  }

  void _confirmDelete(BuildContext context, String publicationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar publicación"),
        content: const Text("¿Estás seguro de que deseas eliminar esta publicación?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deletePublication(context, publicationId);
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _contactPublisher(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final currentUserEmail = currentUser.email!;
    final publicationId = publicationData['publicationId'] ?? '';
    final publisherEmail = publicationData['userEmail'] ?? 'Desconocido';
    final chatRoomId = generateChatRoomId(publicationId, currentUserEmail, publisherEmail);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatRoomId: chatRoomId,
          publisherEmail: publisherEmail,
          publicationTitle: publicationData['title'] ?? '',
          publicationId: publicationId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = publicationData['title'] ?? '';
    final description = publicationData['description'] ?? '';
    final price = publicationData['price'] != null ? "\$${publicationData['price']}" : '';
    final category = publicationData['category'] ?? '';
    final publisherEmail = publicationData['userEmail'] ?? 'Desconocido';
    final publicationId = publicationData['publicationId'] ?? '';
    final List<dynamic> images = publicationData['images'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text("Detalle: $title"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, publicationId),
          ),
        ],
      ),
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
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.image, size: 50, color: Colors.white)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(category, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(price, style: const TextStyle(fontSize: 20, color: Colors.green)),
                  const SizedBox(height: 16),
                  Text(description, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  Text('Publicado por: $publisherEmail', style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _confirmDelete(context, publicationId),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        icon: const Icon(Icons.delete),
                        label: const Text("Eliminar"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _contactPublisher(context),
                      icon: const Icon(Icons.message),
                      label: const Text("Contactar"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
///-----------------------------
///pantala para per el perfil de un usuario registrado
///----------------------------------------

class UserProfilePage extends StatelessWidget {
  final String userId; // Id del documento en 'usuarios'
  final Map<String, dynamic> userData;

  const UserProfilePage({
    Key? key,
    required this.userId,
    required this.userData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayName = userData['displayName'] ?? "Sin nombre";
    final email = userData['email'] ?? "Sin correo";
    final photo = userData['photoURL'] ?? "";
    ImageProvider? imageProvider;
    if (photo.isNotEmpty) {
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

    return Scaffold(
      appBar: AppBar(title: Text(displayName)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 50,
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              "Publicaciones",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // StreamBuilder para mostrar las publicaciones del usuario
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('publicaciones')
                  .where('userId', isEqualTo: userId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("No hay publicaciones.");
                }
                final posts = snapshot.data!.docs;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.56,
                  ),
                  itemBuilder: (context, index) {
                    final data = posts[index].data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Sin título';
                    final price = data['price'] != null ? "\$${data['price']}" : "";
                    final List<dynamic> images = data['images'] ?? [];
                    return ProductCard(
                      title: title,
                      price: price,
                      image: images.isNotEmpty ? images[0] as String : "",
                      publicationId: posts[index].id,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}



/// ----------------------------------------------------------------
/// ChatPage: Pantalla para chatear (única definición)
/// ----------------------------------------------------------------
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
        'isReport': false,
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

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MyAppColors.primaryColor,
            MyAppColors.primaryColor.withOpacity(0.85)
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
            color: MyAppColors.primaryColor.withOpacity(0.4),
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
              color: isMe ? MyAppColors.primaryColor : Theme.of(context).colorScheme.surface,
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
  Widget build(BuildContext context) {
    final currentUserSanitized = sanitizeEmail(_auth.currentUser!.email!);
    return Scaffold(
      appBar: AppBar(title: Text('Chat con ${widget.publisherEmail}')),
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
                  color: MyAppColors.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ----------------------------------------------------------------
/// ANALISIS PAGE: Dashboard básico con dos pestañas.
/// ----------------------------------------------------------------
class AnalisisPage extends StatefulWidget {
  const AnalisisPage({Key? key}) : super(key: key);

  @override
  _AnalisisPageState createState() => _AnalisisPageState();
}

class _AnalisisPageState extends State<AnalisisPage> {
  // Colores para cada categoría
  final Map<String, Color> categoryColors = {
    'Electrónica': Colors.blue,
    'Muebles': Colors.brown,
    'Ropa': Colors.pink,
    'Vehículos': Colors.red,
    'Inmuebles': Colors.green,
    'Otros': Colors.grey,
  };

  Map<String, int> _groupByCategory(List<QueryDocumentSnapshot> docs) {
    Map<String, int> counts = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final category = (data['category'] ?? 'Otros').toString();
      counts[category] = (counts[category] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> _groupByDay(List<QueryDocumentSnapshot> docs) {
    Map<String, int> counts = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      Timestamp timestamp = data['createdAt'] ?? Timestamp.now();
      final date = timestamp.toDate();
      final key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  Widget _buildPublicacionesDashboard() {
    return SingleChildScrollView(
      child: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('publicaciones').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              int activeCount = snapshot.data!.docs.length;
              int deletedCount = 0;
              return Card(
                margin: const EdgeInsets.all(16),
                child: ListTile(
                  title: const Text("Publicaciones Activas vs Eliminadas"),
                  subtitle: Text("Activas: $activeCount   |   Eliminadas: $deletedCount"),
                ),
              );
            },
          ),
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('publicaciones').get(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
              if (snapshot.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              final categoryCounts = _groupByCategory(docs);
              final List<PieChartSectionData> sections = categoryCounts.entries.map((entry) {
                final color = categoryColors[entry.key] ?? Colors.blueGrey;
                return PieChartSectionData(
                  value: entry.value.toDouble(),
                  title: "${entry.key}\n${entry.value}",
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  color: color,
                );
              }).toList();
              List<Widget> legendItems = [];
              categoryCounts.forEach((category, count) {
                final color = categoryColors[category] ?? Colors.blueGrey;
                legendItems.add(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 16, height: 16, color: color),
                      const SizedBox(width: 4),
                      Text(category, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              });
              return Card(
                margin: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Publicaciones por Categoría", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: legendItems,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('publicaciones').get(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
              if (snapshot.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              final growthMap = _groupByDay(docs);
              final sortedDates = growthMap.keys.toList()..sort();
              List<FlSpot> spots = [];
              for (int i = 0; i < sortedDates.length; i++) {
                spots.add(FlSpot(i.toDouble(), growthMap[sortedDates[i]]!.toDouble()));
              }
              return Card(
                margin: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Crecimiento de Publicaciones", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(
                      height: 250,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(show: true),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    int index = value.toInt();
                                    if (index < sortedDates.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(sortedDates[index], style: const TextStyle(fontSize: 10)),
                                      );
                                    }
                                    return const Text("");
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: true, interval: 1),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLikesDashboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('publicaciones').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        List<Map<String, dynamic>> publications = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['publicationId'] = doc.id;
          return data;
        }).toList();
        publications.sort((a, b) {
          int likesA = a['likes'] is List ? (a['likes'] as List).length : (a['likes'] ?? 0);
          int likesB = b['likes'] is List ? (b['likes'] as List).length : (b['likes'] ?? 0);
          return likesB.compareTo(likesA);
        });
        final topLikes = publications.take(3).toList();
        List<BarChartGroupData> barGroups = [];
        for (int i = 0; i < topLikes.length; i++) {
          final pub = topLikes[i];
          int likes = pub['likes'] is List ? (pub['likes'] as List).length : (pub['likes'] ?? 0);
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: likes.toDouble(),
                  width: 20,
                  color: MyAppColors.primaryColor,
                ),
              ],
            ),
          );
        }
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Publicaciones con más Likes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: topLikes.map((pub) {
                    final title = pub['title'] ?? 'Sin título';
                    int likes = pub['likes'] is List ? (pub['likes'] as List).length : (pub['likes'] ?? 0);
                    return Text("$title: $likes likes", style: const TextStyle(fontSize: 12));
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: topLikes.isNotEmpty
                          ? (topLikes.first['likes'] is List
                          ? (topLikes.first['likes'] as List).length.toDouble() + 1
                          : (topLikes.first['likes'] ?? 0) + 1)
                          : 10,
                      barGroups: barGroups,
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index >= 0 && index < topLikes.length) {
                                final title = topLikes[index]['title'] ?? '';
                                return Text(title, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center);
                              }
                              return const Text("");
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, interval: 1),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInteraccionesDashboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').snapshots(),
      builder: (context, chatSnapshot) {
        if (chatSnapshot.hasError) return Center(child: Text("Error: ${chatSnapshot.error}"));
        if (chatSnapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final chatDocs = chatSnapshot.data!.docs;
        final totalChats = chatDocs.length;
        int totalMessages = 0;
        Map<String, int> pubInteraction = {};
        Map<String, String> pubTitles = {};
        for (var doc in chatDocs) {
          final data = doc.data() as Map<String, dynamic>;
          int messagesCount = data['messagesCount'] is List ? (data['messagesCount'] as List).length : (data['messagesCount'] ?? 0);
          totalMessages += messagesCount;
          final pubId = data['publicationId'] ?? 'desconocido';
          pubInteraction[pubId] = (pubInteraction[pubId] ?? 0) + 1;
          if (!pubTitles.containsKey(pubId)) {
            pubTitles[pubId] = data['publicationTitle'] ?? pubId;
          }
        }
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('publicaciones').get(),
          builder: (context, pubSnapshot) {
            if (pubSnapshot.hasError) return Center(child: Text("Error: ${pubSnapshot.error}"));
            if (pubSnapshot.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            final activePubIds = pubSnapshot.data!.docs.map((doc) => doc.id).toSet();
            pubInteraction.removeWhere((pubId, count) => !activePubIds.contains(pubId));
            pubTitles.removeWhere((pubId, title) => !activePubIds.contains(pubId));
            List<MapEntry<String, int>> topPublications = pubInteraction.entries.toList();
            topPublications.sort((a, b) => b.value.compareTo(a.value));
            topPublications = topPublications.take(3).toList();
            List<BarChartGroupData> barGroups = [];
            for (int i = 0; i < topPublications.length; i++) {
              final entry = topPublications[i];
              barGroups.add(
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.toDouble(),
                      width: 20,
                      color: MyAppColors.primaryColor,
                    ),
                  ],
                ),
              );
            }
            return Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Dashboard de Interacciones y Chats", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Chats iniciados: $totalChats"),
                    Text("Mensajes enviados: $totalMessages"),
                    const SizedBox(height: 16),
                    const Text("Publicaciones con más interacción:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: topPublications.map((e) {
                        final title = pubTitles[e.key]!;
                        return Text("$title: ${e.value} chats", style: const TextStyle(fontSize: 12));
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: topPublications.isNotEmpty ? topPublications.first.value.toDouble() + 1 : 10,
                          barGroups: barGroups,
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  int index = value.toInt();
                                  if (index >= 0 && index < topPublications.length) {
                                    final pubId = topPublications[index].key;
                                    final title = pubTitles[pubId]!;
                                    return Text(title, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center);
                                  }
                                  return const Text("");
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true, interval: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildClientesDashboard() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildInteraccionesDashboard(),
          _buildUsuariosDashboard(),
        ],
      ),
    );
  }

  Widget _buildUsuariosDashboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final userDocs = snapshot.data!.docs;
        final totalUsers = userDocs.length;
        Map<String, int> userGrowth = {};
        for (var doc in userDocs) {
          final data = doc.data() as Map<String, dynamic>;
          Timestamp timestamp = data['createdAt'] ?? Timestamp.now();
          final date = timestamp.toDate();
          final key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          userGrowth[key] = (userGrowth[key] ?? 0) + 1;
        }
        final sortedDays = userGrowth.keys.toList()..sort();
        List<FlSpot> spots = [];
        for (int i = 0; i < sortedDays.length; i++) {
          spots.add(FlSpot(i.toDouble(), userGrowth[sortedDays[i]]!.toDouble()));
        }
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Dashboard de Usuarios", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Usuarios registrados: $totalUsers"),
                const SizedBox(height: 16),
                const Text("Evolución de usuarios:", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      borderData: FlBorderData(show: true),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index < sortedDays.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(sortedDays[index], style: const TextStyle(fontSize: 10)),
                                );
                              }
                              return const Text("");
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, interval: 1),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Dashboard de Análisis"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Análisis de publicaciones"),
              Tab(text: "Análisis de clientes"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildPublicacionesDashboard(),
                  _buildLikesDashboard(),
                ],
              ),
            ),
            _buildClientesDashboard(),
          ],
        ),
      ),
    );
  }
}

/// ----------------------------------------------------------------
/// ADMIN PUBLICATIONS PAGE: Pantalla inicial del administrador para ver publicaciones.
/// Replica la estructura de la Home Page: búsqueda, filtros, publicidad y grid de publicaciones.
/// ----------------------------------------------------------------
class AdminPublicationsPage extends StatefulWidget {
  const AdminPublicationsPage({Key? key}) : super(key: key);

  @override
  State<AdminPublicationsPage> createState() => _AdminPublicationsPageState();
}

class _AdminPublicationsPageState extends State<AdminPublicationsPage> {
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
        // Barra de búsqueda
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
        // Filtros
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
        // Sección publicitaria
        const AdvertisementSection(),
      ],
    );
  }

  // Método que muestra el diálogo para confirmar y recoger el motivo, y elimina la publicación
  Future<void> _deletePublication(BuildContext context, Map<String, dynamic> data) async {
    final TextEditingController reasonController = TextEditingController();

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar publicación"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Ingresa el motivo por el cual eliminas la publicación:"),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: "Motivo de eliminación",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
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
      final String reason = reasonController.text.trim();
      if (reason.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debes ingresar un motivo para eliminar la publicación.")),
        );
        return;
      }

      try {
        final String publicationId = data['publicationId']; // Ej: "ghju26hGZG9BGZaxFD1e"
        final String publicationTitle = data['title'];       // Ej: "lampara"
        final String ownerId = data['userId'];                 // Ej: "I6r7gwuUGlY3LLQVFAQxDdIAUkw2"

        // Crea la notificación en Firestore para el dueño de la publicación
        await FirebaseFirestore.instance.collection('notificaciones').add({
          'recipientId': ownerId,
          'message': "Tu publicación '$publicationTitle' fue eliminada por el administrador. Motivo: $reason",
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });

        // Elimina la publicación
        await FirebaseFirestore.instance
            .collection('publicaciones')
            .doc(publicationId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Publicación eliminada y notificación enviada.")),
        );
        // Puedes actualizar la vista o recargar la lista aquí
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al eliminar la publicación: $e")),
        );
      }
    }
  }

  // Método que muestra un diálogo simple para confirmar la eliminación y luego llama a _deletePublication
  void _confirmDelete(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar publicación"),
        content: const Text("¿Estás seguro de que deseas eliminar esta publicación?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deletePublication(context, data);
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 56),
      children: [
        _buildTopSection(),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('publicaciones')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
              return const Center(child: Text('No hay publicaciones.'));
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
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminPublicationDetailPage(publicationData: data),
                      ),
                    );
                  },
                  child: ProductCard(
                    title: title,
                    price: price,
                    image: images.isNotEmpty ? images[0] as String : "",
                    publicationId: data['publicationId'] ?? '',
                    showDeleteButton: true,
                    onDelete: () => _confirmDelete(data),
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
/// ----------------------------------------------------------------
/// ADMIN USERS PAGE
/// ----------------------------------------------------------------
class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({Key? key}) : super(key: key);


  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  Future<void> _deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario eliminado correctamente")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al eliminar usuario: $e")),
      );
    }
  }

  void _confirmDelete(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar usuario"),
        content: const Text("¿Estás seguro de que deseas eliminar este usuario?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteUser(userId);
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
      appBar: AppBar(title: const Text("Administrar Usuarios")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return const Center(child: Text("No hay usuarios."));
          final users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final data = users[index].data() as Map<String, dynamic>;
              final displayName = data['displayName'] ?? "Sin nombre";
              final email = data['email'] ?? "Sin correo";
              final photo = data['photoURL'] ?? "";
              ImageProvider? imageProvider;
              if (photo.isNotEmpty) {
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
              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfilePage(
                        userId: users[index].id,
                        userData: data,
                      ),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundImage: imageProvider,
                  child: imageProvider == null ? const Icon(Icons.person) : null,
                ),
                title: Text(displayName),
                subtitle: Text(email),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Se obtiene el valor de isAdmin, asignando false si es nulo
                    IconButton(
                      icon: Icon(
                        (data['isAdmin'] ?? false)
                            ? Icons.remove_moderator
                            : Icons.admin_panel_settings,
                        color: (data['isAdmin'] ?? false) ? Colors.orange : Colors.blue,
                      ),
                      tooltip: (data['isAdmin'] ?? false)
                          ? "Revertir a usuario"
                          : "Hacer admin",
                      onPressed: () async {
                        bool currentRole = data['isAdmin'] ?? false;
                        bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(currentRole
                                ? "Revertir rol de admin"
                                : "Promover a admin"),
                            content: Text(currentRole
                                ? "¿Estás seguro de que deseas revertir el rol de admin a usuario normal?"
                                : "¿Estás seguro de que deseas promover este usuario a admin?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancelar"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Confirmar"),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await FirebaseFirestore.instance
                                .collection('usuarios')
                                .doc(users[index].id)
                                .update({'isAdmin': !currentRole});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Rol actualizado correctamente.")),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error al actualizar el rol: $e")),
                            );
                          }
                        }
                      },
                    ),
                    // Botón para eliminar usuario
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: "Eliminar usuario",
                      onPressed: () {
                        _confirmDelete(users[index].id);
                      },
                    ),
                  ],
                ),
              );


            },
          );
        },
      ),
    );
  }
}


/// ----------------------------------------------------------------
/// ADMIN CHATS PAGE
/// ----------------------------------------------------------------
class AdminChatsPage extends StatefulWidget {
  const AdminChatsPage({Key? key}) : super(key: key);

  @override
  State<AdminChatsPage> createState() => _AdminChatsPageState();
}

class _AdminChatsPageState extends State<AdminChatsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = _auth.currentUser?.email;
    if (currentUserEmail == null) return const Center(child: Text('No autenticado.'));
    final sanitizedAdmin = sanitizeEmail(currentUserEmail);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Chats del Administrador"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Chats"),
              Tab(text: "Reportes"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Pestaña 1: Chats normales (no reportes)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('isReport', isEqualTo: false) // Chats normales
                  .orderBy('lastMessageTimestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay chats.'));
                }
                final chatDocs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: chatDocs.length,
                  itemBuilder: (context, index) {
                    final data = chatDocs[index].data() as Map<String, dynamic>;
                    final publicationTitle = data['publicationTitle'] ?? 'Chat';
                    final publicationId = data['publicationId'] ?? '';
                    final lastMessage = data['lastMessage'] ?? '';
                    final participants = List<String>.from(data['participants'] ?? []);
                    final otherParticipant = participants.firstWhere(
                          (p) => p != sanitizedAdmin,
                      orElse: () => 'Desconocido',
                    );
                    return ListTile(
                      leading: Base64ImageWidget(
                        base64String: data['publicationImage'] as String? ?? "",
                        width: 40,
                        height: 40,
                        placeholder: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          child: Icon(Icons.article,
                              size: 20, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                      title: Text(publicationTitle),
                      subtitle: Text(
                        "Chat con: $otherParticipant\n$lastMessage",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              chatRoomId: chatDocs[index].id,
                              publisherEmail: otherParticipant,
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
            ),
            // Pestaña 2: Reportes (chats con isReport == true)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('isReport', isEqualTo: true)
                  .orderBy('lastMessageTimestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay reportes.'));
                }
                final chatDocs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: chatDocs.length,
                  itemBuilder: (context, index) {
                    final data = chatDocs[index].data() as Map<String, dynamic>;
                    final publicationTitle = data['publicationTitle'] ?? 'Reporte';
                    final publicationId = data['publicationId'] ?? '';
                    final lastMessage = data['lastMessage'] ?? '';
                    return ListTile(
                      leading: Base64ImageWidget(
                        base64String: data['publicationImage'] as String? ?? "",
                        width: 40,
                        height: 40,
                        placeholder: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          child: Icon(Icons.article,
                              size: 20, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                      title: Text(publicationTitle),
                      subtitle: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              chatRoomId: chatDocs[index].id,
                              publisherEmail: "Reporte", // Indicador para reportes
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
            ),
          ],
        ),
      ),
    );
  }
}



/// ----------------------------------------------------------------
/// PERFIL PAGE: Información del administrador y sus publicaciones.
/// ----------------------------------------------------------------
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
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
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
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()));
                Map<String, dynamic>? data = (snapshot.hasData && snapshot.data!.exists)
                    ? snapshot.data!.data()
                    : null;
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
                        backgroundColor: Colors.grey[300],
                        backgroundImage: imageProvider,
                        child: imageProvider == null
                            ? const Icon(Icons.person, size: 50, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                children: const [
                  Text("Mis Publicaciones", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text("No tienes publicaciones.")));
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
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      final pubData = publications[index].data() as Map<String, dynamic>;
                      final title = pubData['title'] ?? 'Sin título';
                      final price = pubData['price'] != null ? "\$${pubData['price']}" : "";
                      final List<dynamic> images = pubData['images'] ?? [];
                      return InkWell(
                        onTap: () {
                          // En Mis Publicaciones se navega a AdminPublicationDetailPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminPublicationDetailPage(publicationData: pubData),
                            ),
                          );
                        },
                        child: ProductCard(
                          title: title,
                          price: price,
                          image: images.isNotEmpty ? images[0] as String : "",
                          publicationId: pubData['publicationId'] ?? '',
                          showDeleteButton: true,
                          onDelete: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Eliminar publicación"),
                                content: const Text("¿Estás seguro de que deseas eliminar esta publicación?"),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text("Cancelar")),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      FirebaseFirestore.instance.collection('publicaciones').doc(pubData['publicationId']).delete();
                                    },
                                    child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
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

/// ----------------------------------------------------------------
/// EDIT PROFILE PAGE: Permite editar el perfil del usuario.
/// ----------------------------------------------------------------
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
    if (decodedImage == null) throw Exception("Error al decodificar la imagen.");
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
      await FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).set(updateData, SetOptions(merge: true));
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
        padding: const EdgeInsets.all(16.0),
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
                        ? const Icon(Icons.person, size: 50, color: Colors.white)
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

/// ----------------------------------------------------------------
/// ADMIN HOME PAGE: Panel principal para administradores.
/// Contiene pestañas para Publicaciones, Usuarios, Chats, Análisis y Perfil.
/// ----------------------------------------------------------------
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;
  final List<Widget> _screens = const [
    AdminPublicationsPage(),
    AdminUsersPage(),
    AdminChatsPage(),
    AnalisisPage(),
    PerfilPage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Administrador"),
        backgroundColor: MyAppColors.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar sesión",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: MyAppColors.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Publicaciones'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Usuarios'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Análisis'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

/// ----------------------------------------------------------------
/// MAIN: Punto de entrada de la aplicación.
/// ----------------------------------------------------------------
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marketplace Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          // Se usan propiedades modernas: titleMedium, bodyLarge y bodyMedium.
          titleMedium: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          bodyLarge: const TextStyle(fontSize: 16),
          bodyMedium: const TextStyle(fontSize: 14),
        ),
        colorScheme: ColorScheme.light(
          primary: MyAppColors.primaryColor,
          onPrimary: Colors.white,
          secondary: MyAppColors.secondaryColor,
          onSecondary: Colors.white,
          surface: MyAppColors.surfaceColor,
          onSurface: MyAppColors.onSurfaceColor,
          background: MyAppColors.backgroundColor,
          onBackground: MyAppColors.onSurfaceColor,
          error: MyAppColors.accentColor,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: MyAppColors.backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: MyAppColors.primaryColor,
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
            backgroundColor: MyAppColors.primaryColor,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: MyAppColors.primaryColor),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: MyAppColors.surfaceColor,
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
            borderSide: BorderSide(color: MyAppColors.primaryColor, width: 2),
          ),
        ),
        cardTheme: CardTheme(
          color: MyAppColors.surfaceColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: MyAppColors.primaryColor,
          unselectedItemColor: Colors.grey.shade600,
          backgroundColor: MyAppColors.surfaceColor,
          elevation: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        ),
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => const AdminHomePage(),
      },
    );
  }
}
