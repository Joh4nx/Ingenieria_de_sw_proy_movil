import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:appmarketplace/screens/admin_panel.dart'; // Si necesitas ProductCard, MyAppColors

class UserProfilePage extends StatelessWidget {
  final String userId;
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
    final Timestamp? createdAt = userData['createdAt'];
    final registrationDate = createdAt != null
        ? DateFormat('dd/MM/yyyy').format(createdAt.toDate())
        : "Fecha no disponible";

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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: imageProvider,
                    backgroundColor: Colors.grey[300],
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
                  const SizedBox(height: 8),
                  Text(
                    "Registrado el: $registrationDate",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const Divider(thickness: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Publicaciones",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('publicaciones')
                  .where('userId', isEqualTo: userId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Este usuario no tiene publicaciones."));
                }
                final docs = snapshot.data!.docs;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.56,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    data['publicationId'] = docs[index].id;
                    return ProductCard(
                      title: data['title'] ?? 'Sin título',
                      price: data['price'] != null ? "\$${data['price']}" : "",
                      image: (data['images'] != null && (data['images'] as List).isNotEmpty)
                          ? data['images'][0] as String
                          : "",
                      publicationId: data['publicationId'] ?? '',
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
