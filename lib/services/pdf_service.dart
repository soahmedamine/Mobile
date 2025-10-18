import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../models/travel.dart';
import 'package:intl/intl.dart';

class PdfService {
  final pdf = pw.Document();

  Future<void> generateTravelPdf(Travel travel) async {
    final primaryColor = PdfColor.fromHex('#2196F3');
    final secondaryColor = PdfColor.fromHex('#1976D2');
    final accentColor = PdfColor.fromHex('#FFC107');
    final lightGray = PdfColor.fromHex('#F5F5F5');
    final darkGray = PdfColor.fromHex('#424242');
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Container(
            child: pw.Column(
              children: [
                // Header Section with Gradient-like effect
                _buildHeader(primaryColor, secondaryColor),
                
                // Main Content
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(30),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Destination Title Card
                        _buildDestinationCard(travel, primaryColor, accentColor),
                        
                        pw.SizedBox(height: 25),
                        
                        // Description Section
                        _buildSection(
                          'Description',
                          travel.description,
                          primaryColor,
                          darkGray,
                        ),
                        
                        pw.SizedBox(height: 25),
                        
                        // Travel Details Grid
                        _buildDetailsGrid(travel, primaryColor, lightGray, darkGray),
                        
                        pw.Spacer(),
                        
                        // Footer
                        _buildFooter(primaryColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Afficher l'aperçu ou imprimer
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // Header with company branding
  pw.Widget _buildHeader(PdfColor primaryColor, PdfColor secondaryColor) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 30),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Smart Travel',
            style: pw.TextStyle(
              fontSize: 42,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              letterSpacing: 2,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Your Journey Begins Here',
            style: pw.TextStyle(
              fontSize: 16,
              color: PdfColor.fromInt(0xFFB3E5FC),
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // Destination Card with accent
  pw.Widget _buildDestinationCard(
    Travel travel,
    PdfColor primaryColor,
    PdfColor accentColor,
  ) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: primaryColor, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        color: PdfColors.blue50,
      ),
      padding: const pw.EdgeInsets.all(20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DESTINATION',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  travel.destination,
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: pw.BoxDecoration(
              color: accentColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
            ),
            child: pw.Text(
              '${travel.prix} €',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Section builder
  pw.Widget _buildSection(
    String title,
    String content,
    PdfColor primaryColor,
    PdfColor textColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8, left: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: primaryColor, width: 3),
            ),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 4),
          child: pw.Text(
            content,
            style: pw.TextStyle(
              fontSize: 14,
              color: textColor,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // Details Grid
  pw.Widget _buildDetailsGrid(
    Travel travel,
    PdfColor primaryColor,
    PdfColor lightGray,
    PdfColor darkGray,
  ) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'fr_FR');
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8, left: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: primaryColor, width: 3),
            ),
          ),
          child: pw.Text(
            'Informations du Voyage',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Column(
          children: [
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildInfoCard(
                    'Date de Départ',
                    dateFormat.format(travel.dateDepart.toLocal()),
                    primaryColor,
                    lightGray,
                    darkGray,
                  ),
                ),
                pw.SizedBox(width: 15),
                pw.Expanded(
                  child: _buildInfoCard(
                    'Date de Retour',
                    dateFormat.format(travel.dateRetour.toLocal()),
                    primaryColor,
                    lightGray,
                    darkGray,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 15),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildInfoCard(
                    'Transport',
                    travel.transport,
                    primaryColor,
                    lightGray,
                    darkGray,
                  ),
                ),
                pw.SizedBox(width: 15),
                pw.Expanded(
                  child: _buildInfoCard(
                    'Hébergement',
                    travel.hebergement,
                    primaryColor,
                    lightGray,
                    darkGray,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 15),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildInfoCard(
                    'Places Disponibles',
                    '${travel.placesDisponibles}',
                    primaryColor,
                    lightGray,
                    darkGray,
                  ),
                ),
                pw.SizedBox(width: 15),
                pw.Expanded(child: pw.Container()),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Info Card
  pw.Widget _buildInfoCard(
    String label,
    String value,
    PdfColor primaryColor,
    PdfColor bgColor,
    PdfColor textColor,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey600,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // Footer
  pw.Widget _buildFooter(PdfColor primaryColor) {
    final now = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 20),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated on $now',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
          pw.Text(
            'Smart Travel © 2025',
            style: pw.TextStyle(
              fontSize: 10,
              color: primaryColor,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
