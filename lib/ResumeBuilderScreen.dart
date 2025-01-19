import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';


class ResumeBuilderScreen extends StatefulWidget {
  @override
  _ResumeBuilderScreenState createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen> {
  File? _image;
  final picker = ImagePicker();
  final pdf = pw.Document();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController positionController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController profileController = TextEditingController();
  final TextEditingController educationController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController skillsController = TextEditingController();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    // List of color gradients
    final gradients = [
      [PdfColor.fromInt(0xFF2193b0), PdfColor.fromInt(0xFF6dd5ed)], // Blue to Light Blue
      [PdfColor.fromInt(0xFFff7e5f), PdfColor.fromInt(0xFFfeb47b)], // Orange to Peach
      [PdfColor.fromInt(0xFF00c6ff), PdfColor.fromInt(0xFF0072ff)], // Cyan to Blue
      [PdfColor.fromInt(0xFF7F00FF), PdfColor.fromInt(0xFFE100FF)], // Violet to Pink
      [PdfColor.fromInt(0xFF43cea2), PdfColor.fromInt(0xFF185a9d)], // Green to Blue
    ];

    // Randomly pick a gradient
    final random = Random();
    final gradient = gradients[random.nextInt(gradients.length)];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Stack(
            children: [
              // Background Gradient
              pw.Positioned.fill(
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: gradient,
                      begin: pw.Alignment.topLeft,
                      end: pw.Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              // Content
              pw.Padding(
                padding: const pw.EdgeInsets.all(16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (_image != null)
                      pw.Center(
                        child: pw.Container(
                          width: 100,
                          height: 100,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            image: pw.DecorationImage(
                              image: pw.MemoryImage(_image!.readAsBytesSync()),
                              fit: pw.BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    pw.SizedBox(height: 10),
                    pw.Center(
                      child: pw.Text(
                        nameController.text.toUpperCase(),
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Center(
                      child: pw.Text(
                        positionController.text,
                        style: pw.TextStyle(fontSize: 18, fontStyle: pw.FontStyle.italic),
                      ),
                    ),
                    pw.Divider(thickness: 2),
                    pw.SizedBox(height: 10),

                    // Contact Information
                    pw.Text("Contact Information",
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Bullet(text: "Phone: ${contactController.text}"),
                    pw.Bullet(text: "Email: ${emailController.text}"),
                    pw.Bullet(text: "Address: ${addressController.text}"),
                    pw.SizedBox(height: 10),

                    // Profile
                    pw.Text("Profile Summary",
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text(profileController.text, textAlign: pw.TextAlign.justify),
                    pw.SizedBox(height: 10),

                    // Education
                    pw.Text("Education",
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text(educationController.text, textAlign: pw.TextAlign.justify),
                    pw.SizedBox(height: 10),

                    // Work Experience
                    pw.Text("Work Experience",
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text(experienceController.text, textAlign: pw.TextAlign.justify),
                    pw.SizedBox(height: 10),

                    // Skills
                    pw.Text("Skills",
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text(skillsController.text, textAlign: pw.TextAlign.justify),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'professional_resume.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Resume Builder"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final result = await showModalBottomSheet<int>(
                      context: context,
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(Icons.camera),
                            title: Text("Camera"),
                            onTap: () => Navigator.pop(context, 0),
                          ),
                          ListTile(
                            leading: Icon(Icons.photo_library),
                            title: Text("Gallery"),
                            onTap: () => Navigator.pop(context, 1),
                          ),
                        ],
                      ),
                    );

                    if (result == 0) {
                      await _pickImage(ImageSource.camera);
                    } else if (result == 1) {
                      await _pickImage(ImageSource.gallery);
                    }
                  },
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _image != null ? FileImage(_image!) : null,
                    child: _image == null
                        ? Icon(Icons.add_a_photo, size: 30, color: Colors.white)
                        : null,
                  ),
                ),
              ),
              SizedBox(height: 20),
              _buildTextField("Name", nameController),
              _buildTextField("Position", positionController),
              _buildTextField("Contact", contactController),
              _buildTextField("Email", emailController),
              _buildTextField("Address", addressController),
              _buildTextField("Profile", profileController, maxLines: 4),
              _buildTextField("Education", educationController, maxLines: 3),
              _buildTextField("Work Experience", experienceController, maxLines: 3),
              _buildTextField("Skills", skillsController, maxLines: 3),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _generatePdf,
                child: Text("Download Professional Resume",style: TextStyle(color: Colors.deepOrangeAccent),),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
