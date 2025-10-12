import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/travel.dart';

class PdfService {
  final pdf = pw.Document();

  Future<void> generateTravelPdf(Travel travel) async {
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            children: [
              pw.Text('Smart Travel', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Destination: ${travel.destination}'),
              pw.Text('Description: ${travel.description}'),
              pw.Text('Date de départ: ${travel.dateDepart.toLocal()}'),
              pw.Text('Date de retour: ${travel.dateRetour.toLocal()}'),
              pw.Text('Prix: ${travel.prix}'),
              pw.Text('Places disponibles: ${travel.placesDisponibles}'),
              pw.Text('Transport: ${travel.transport}'),
              pw.Text('Hébergement: ${travel.hebergement}'),
            ],
          ),
        ),
      ),
    );

    // Afficher l'aperçu ou imprimer
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
