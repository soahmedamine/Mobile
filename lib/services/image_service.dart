import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  // Sélectionner une image depuis la galerie
  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Convertir l'image en base64 pour le stockage
      return await _imageToBase64(image);
    } catch (e) {
      print('Erreur lors de la sélection de l\'image: $e');
      return null;
    }
  }

  // Prendre une photo avec la caméra
  Future<String?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Convertir l'image en base64 pour le stockage
      return await _imageToBase64(image);
    } catch (e) {
      print('Erreur lors de la prise de photo: $e');
      return null;
    }
  }

  // Convertir une image en base64
  Future<String> _imageToBase64(XFile image) async {
    final bytes = await image.readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  // Vérifier si une chaîne est une image base64
  bool isBase64Image(String? imageUrl) {
    if (imageUrl == null) return false;
    return imageUrl.startsWith('data:image/');
  }

  // Obtenir les bytes depuis une URL base64
  Uint8List? getBase64ImageBytes(String base64String) {
    try {
      if (base64String.startsWith('data:image/')) {
        final base64Data = base64String.split(',')[1];
        return base64Decode(base64Data);
      }
      return null;
    } catch (e) {
      print('Erreur lors du décodage de l\'image: $e');
      return null;
    }
  }
}
