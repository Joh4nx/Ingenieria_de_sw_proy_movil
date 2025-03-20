import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Función para "sanitizar" el email (reemplaza "@" y "." por guion bajo)
String sanitizeEmail(String email) {
  return email.toLowerCase().replaceAll(RegExp(r'[@.]'), '_');
}

/// ChatPage mejorado con header y chat bubbles con avatar.
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

  // Esta variable opcional se usará para guardar la imagen del producto.
  String? productImageBase64;

  @override
  void initState() {
    super.initState();
    _loadProductImage();
  }

  // Consulta la publicación para obtener la primera imagen.
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

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    _messageController.clear();
    final messageData = {
      'sender': _auth.currentUser!.email,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    };
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .collection('messages')
        .add(messageData);
    // Actualiza el último mensaje y el contador (aquí podrías incluir lógica adicional)
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .update({
      'lastMessage': message,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// Construye un chat bubble personalizado.
  Widget _buildMessage(String sender, String message, bool isMe) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment:
      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isMe)
          CircleAvatar(
            radius: 16,
            // En un escenario real podrías consultar la foto del usuario
            // Aquí mostramos la primera letra del email como placeholder
            child: Text(
              sender.isNotEmpty ? sender[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? Colors.blueAccent : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: TextStyle(color: isMe ? Colors.white : Colors.black),
            ),
          ),
        ),
        if (isMe) const SizedBox(width: 8),
        if (isMe)
          CircleAvatar(
            radius: 16,
            child: Text(
              sender.isNotEmpty ? sender[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 16),
            ),
          ),
      ],
    );
  }

  /// Header que muestra la imagen y título del producto.
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
              image: productImageBase64 != null
                  ? DecorationImage(
                image: MemoryImage(base64Decode(productImageBase64!)),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: productImageBase64 == null
                ? const Icon(Icons.image, size: 40, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.publicationTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = _auth.currentUser!.email!;
    final isMe = (String sender) => sender == currentUserEmail;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat con ${widget.publisherEmail}'),
      ),
      body: Column(
        children: [
          // Header con datos del producto.
          _buildHeader(),
          const Divider(height: 1),
          // Lista de mensajes.
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final sender = data['sender'] ?? 'Desconocido';
                    final message = data['message'] ?? '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _buildMessage(sender, message, isMe(sender)),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Campo para escribir mensaje.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.grey[200],
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
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
