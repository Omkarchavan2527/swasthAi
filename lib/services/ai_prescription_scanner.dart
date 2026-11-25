import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ExtractedMedicine {
  String name;
  String dosage;
  String frequency;
  List<String> scheduledTimes;
  String instructions;
  int reminderBeforeMinutes;
  int gracePeriodMinutes;
  bool isSelected;

  ExtractedMedicine({
    required this.name,
    required this.dosage,
    this.frequency = 'Daily',
    required this.scheduledTimes,
    this.instructions = 'Take as prescribed by doctor',
    this.reminderBeforeMinutes = 15,
    this.gracePeriodMinutes = 15,
    this.isSelected = true,
  });

  factory ExtractedMedicine.fromJson(Map<String, dynamic> json) {
    List<String> times = ['08:00'];
    if (json['scheduledTimes'] is List) {
      times = (json['scheduledTimes'] as List)
          .map((t) => t.toString().trim())
          .where((t) => t.isNotEmpty)
          .toList();
    } else if (json['timing'] != null) {
      final t = json['timing'].toString().toLowerCase();
      if (t.contains('morning') || t.contains('breakfast')) {
        times = ['08:00'];
      } else if (t.contains('afternoon') || t.contains('lunch')) {
        times = ['13:00'];
      } else if (t.contains('night') || t.contains('dinner')) {
        times = ['20:00'];
      }
    }

    if (times.isEmpty) times = ['08:00'];

    return ExtractedMedicine(
      name: json['name']?.toString() ?? 'Prescribed Medicine',
      dosage: json['dosage']?.toString() ?? '1 tablet',
      frequency: json['frequency']?.toString() ?? 'Daily',
      scheduledTimes: times,
      instructions: json['instructions']?.toString() ?? 'Take as prescribed by doctor',
      reminderBeforeMinutes: int.tryParse(json['reminderBeforeMinutes']?.toString() ?? '') ?? 15,
      gracePeriodMinutes: int.tryParse(json['gracePeriodMinutes']?.toString() ?? '') ?? 15,
    );
  }
}

class AIPrescriptionScanResult {
  final File imageFile;
  final bool isValidPrescription;
  final String? rejectionReason;
  final List<ExtractedMedicine> medicines;
  final String? rawDoctorNote;
  final bool usedAI;

  AIPrescriptionScanResult({
    required this.imageFile,
    this.isValidPrescription = true,
    this.rejectionReason,
    required this.medicines,
    this.rawDoctorNote,
    this.usedAI = true,
  });
}

class AIPrescriptionScanner {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickPrescriptionImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      return null;
    }
  }

  Future<AIPrescriptionScanResult> analyzePrescription({
    required File imageFile,
    required String apiKey,
    String? preferredModel,
  }) async {
    if (apiKey.trim().isEmpty) {
      // If no API key provided, do NOT inject fake medicines on random photos
      await Future.delayed(const Duration(milliseconds: 600));
      return AIPrescriptionScanResult(
        imageFile: imageFile,
        isValidPrescription: false,
        rejectionReason:
            'AI API Key not configured. Please enter your OpenRouter or Gemini API key in Settings -> AI Health Assistant to analyze real prescription photos with Vision OCR.',
        medicines: [],
        usedAI: false,
      );
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      const prompt = '''You are an expert clinical pharmacist and AI medical vision OCR system.
Analyze this image carefully.

CRITICAL INSTRUCTIONS:
1. STRICT VERIFICATION: First, inspect the image to determine if it is genuinely a medical doctor's prescription, hospital Rx slip, treatment chart, or medicine label.
2. If the image is NOT a medical prescription (for example: random photo, selfie, person, animal, vehicle, food, scenery, objects, non-medical document, handwritten note unrelated to medicine, or blurred unreadable image):
You MUST respond with:
{
  "isValidPrescription": false,
  "rejectionReason": "Explain what is in the photo and why it is not a medical prescription (e.g. 'This image shows a room / landscape / person and does not contain a doctor prescription or medications.')",
  "medicines": []
}

3. ONLY IF the image is a genuine medical prescription containing prescribed medicines:
Extract each prescribed medicine, its dosage/strength, dosage frequency, exact scheduled times in 24-hour HH:MM format (08:00 for morning, 13:00 for afternoon, 20:00 for night), and instructions.
Respond with:
{
  "isValidPrescription": true,
  "rejectionReason": null,
  "doctorName": "Doctor name if written, or null",
  "hospitalName": "Hospital/Clinic name if written, or null",
  "medicines": [
    {
      "name": "Medicine name and strength",
      "dosage": "e.g. 1 tablet, 500mg, 5ml",
      "frequency": "Daily / Twice Daily",
      "scheduledTimes": ["08:00", "20:00"],
      "instructions": "Food instructions or advice",
      "reminderBeforeMinutes": 15,
      "gracePeriodMinutes": 15
    }
  ]
}

DO NOT include markdown formatting or backticks. Return ONLY raw valid JSON.''';

      String rawText = '';

      if (apiKey.trim().startsWith('AIza')) {
        // Direct Google Gemini API
        final response = await http.post(
          Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey.trim()}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {
                    'inline_data': {
                      'mime_type': 'image/jpeg',
                      'data': base64Image,
                    }
                  },
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.1,
              'maxOutputTokens': 1024,
            }
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          rawText = data['candidates'][0]['content']['parts'][0]['text'] as String;
        }
      } else {
        // OpenRouter API (sk-or-...) with vision fallback models
        final visionModelsToTry = {
          preferredModel ?? 'google/gemini-2.0-flash-001',
          'google/gemini-2.0-flash-001',
          'google/gemini-flash-1.5',
          'openrouter/auto',
          'google/gemini-2.0-flash-lite-001',
          'openai/gpt-4o-mini',
          'meta-llama/llama-3.2-11b-vision-instruct:free',
        }.where((m) => m.isNotEmpty).toList();

        for (final modelId in visionModelsToTry) {
          try {
            final response = await http.post(
              Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
              headers: {
                'Authorization': 'Bearer ${apiKey.trim()}',
                'Content-Type': 'application/json',
                'HTTP-Referer': 'https://swasthai.app',
                'X-Title': 'SwasthAI Health',
              },
              body: jsonEncode({
                'model': modelId,
                'messages': [
                  {
                    'role': 'user',
                    'content': [
                      {'type': 'text', 'text': prompt},
                      {
                        'type': 'image_url',
                        'image_url': {
                          'url': 'data:image/jpeg;base64,$base64Image',
                        },
                      },
                    ],
                  },
                ],
                'temperature': 0.1,
                'max_tokens': 1024,
              }),
            );

            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              final content = data['choices']?[0]?['message']?['content'];
              if (content != null && content.toString().trim().isNotEmpty) {
                rawText = content.toString();
                break;
              }
            }
          } catch (_) {}
        }
      }

      if (rawText.isNotEmpty) {
        // Clean markdown backticks
        rawText = rawText.trim();
        if (rawText.startsWith('```json')) {
          rawText = rawText.substring(7);
        } else if (rawText.startsWith('```')) {
          rawText = rawText.substring(3);
        }
        if (rawText.endsWith('```')) {
          rawText = rawText.substring(0, rawText.length - 3);
        }
        rawText = rawText.trim();

        final parsed = jsonDecode(rawText);

        if (parsed is Map<String, dynamic>) {
          final isValid = parsed['isValidPrescription'] == true;
          final rejection = parsed['rejectionReason']?.toString();
          final medsJson = parsed['medicines'];

          List<ExtractedMedicine> meds = [];
          if (isValid && medsJson is List) {
            meds = medsJson
                .map((m) => ExtractedMedicine.fromJson(m as Map<String, dynamic>))
                .toList();
          }

          if (!isValid || meds.isEmpty) {
            return AIPrescriptionScanResult(
              imageFile: imageFile,
              isValidPrescription: false,
              rejectionReason: rejection ??
                  'No valid doctor prescription or medicines detected in this photo. Please upload a clear prescription.',
              medicines: [],
              usedAI: true,
            );
          }

          final doc = parsed['doctorName'];
          final note = doc != null && doc.toString().isNotEmpty
              ? 'Doctor: $doc • Extracted ${meds.length} medicines'
              : 'Successfully extracted ${meds.length} medicines';

          return AIPrescriptionScanResult(
            imageFile: imageFile,
            isValidPrescription: true,
            medicines: meds,
            rawDoctorNote: note,
            usedAI: true,
          );
        } else if (parsed is List) {
          final list = parsed
              .map((m) => ExtractedMedicine.fromJson(m as Map<String, dynamic>))
              .toList();

          if (list.isNotEmpty) {
            return AIPrescriptionScanResult(
              imageFile: imageFile,
              isValidPrescription: true,
              medicines: list,
              rawDoctorNote: 'Extracted ${list.length} prescribed medicines.',
              usedAI: true,
            );
          }
        }
      }
    } catch (_) {}

    // Never return fake dummy medicines on unclear or non-prescription images!
    return AIPrescriptionScanResult(
      imageFile: imageFile,
      isValidPrescription: false,
      rejectionReason:
          'Could not identify a clear doctor prescription in this image. Please take a well-lit, focused photo of your prescription slip.',
      medicines: [],
      usedAI: true,
    );
  }
}
