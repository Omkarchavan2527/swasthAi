import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/i18n/app_translations.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/rag_context_builder.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _useRag = true;

  @override
  void initState() {
    super.initState();
    try {
      final box = Hive.box('settings');
      _useRag = box.get('assistant_use_rag', defaultValue: true) as bool;
    } catch (_) {}
  }

  void _toggleRag(bool value) {
    if (_useRag == value) return;
    setState(() {
      _useRag = value;
    });
    try {
      Hive.box('settings').put('assistant_use_rag', value);
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _ensureWelcomeMessage(String lang) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(assistantMessagesProvider.notifier).setInitialWelcome(
          AppTranslations.tr(lang, 'assistantWelcome'),
        );
      }
    });
  }

  List<Map<String, String>> _getQuickQueries(String lang) {
    return [
      {
        'title': AppTranslations.tr(lang, 'query1Title'),
        'query': AppTranslations.tr(lang, 'query1Text'),
      },
      {
        'title': AppTranslations.tr(lang, 'query2Title'),
        'query': AppTranslations.tr(lang, 'query2Text'),
      },
      {
        'title': AppTranslations.tr(lang, 'query3Title'),
        'query': AppTranslations.tr(lang, 'query3Text'),
      },
      {
        'title': AppTranslations.tr(lang, 'query4Title'),
        'query': AppTranslations.tr(lang, 'query4Text'),
      },
    ];
  }

  String _buildSystemContext(String lang, {String? userQuery, bool useRag = true}) {
    final activeMember = ref.read(activeMemberProvider);
    final String languageInstruction;
    if (lang == 'mr') {
      languageInstruction =
          'CRITICAL REQUIREMENT: The user has selected Marathi (मराठी). You MUST reply entirely in natural, fluent Marathi using Devnagari script (देवनागरी लिपी). Even if the user asks in English or uses medical abbreviations like BP, Sugar, or HbA1c, formulate the entire response in polite Marathi. Never respond in English.';
    } else if (lang == 'hi') {
      languageInstruction =
          'CRITICAL REQUIREMENT: The user has selected Hindi (हिंदी). You MUST reply entirely in natural, fluent Hindi using Devnagari script (देवनागरी लिपि). Even if the user asks in English or uses medical abbreviations like BP, Sugar, or HbA1c, formulate the entire response in polite Hindi. Never respond in English.';
    } else {
      languageInstruction =
          'Respond in clear, accessible, empathetic English.';
    }

    if (activeMember == null || !useRag) {
      return '''You are SwasthAI, an empathetic and certified clinical companion for family healthcare in India.
Language Instruction: $languageInstruction
${activeMember != null ? 'Active Patient: ${activeMember.name} (${activeMember.relationship}, ${activeMember.age}y, ${activeMember.gender})' : ''}

Mode: General Clinical Healthcare Assistant (Simple Chat Mode).
Guidelines:
1. Provide scientifically sound, empathetic, and easy-to-understand explanations suitable for Indian families.
2. Provide general medical education, lifestyle recommendations, dietary advice, and first-aid instructions.
3. If discussing medications or treatments, explain purposes, general precautions, and common dosages in India.
4. Always advise consulting a certified medical doctor for prescriptions or dosage changes.
5. In severe symptoms (severe chest pain, severe breathlessness), advise emergency 108 assistance immediately.''';
    }

    // Build RAG context from real medical data
    final ragContext = RagContextBuilder.buildContext(ref);

    // Build query-specific relevant records (if a user query is provided)
    String queryRelevantRecords = '';
    if (userQuery != null && userQuery.isNotEmpty) {
      queryRelevantRecords = RagContextBuilder.searchRelevantRecords(ref, userQuery);
    }

    return '''You are SwasthAI, a certified clinical health companion for Indian families.
Language Instruction: $languageInstruction

Mode: True RAG Health Assistant (Grounded in Patient Records).

═══════════════════════════════════════════
PATIENT MEDICAL DATA (from SwasthAI database)
═══════════════════════════════════════════
$ragContext
$queryRelevantRecords

═══════════════════════════════════════════
RAG CLINICAL GUIDELINES
═══════════════════════════════════════════
1. You have access to the patient's REAL medical records, medicines, vitals, and health history shown above. Always reference this actual data in your responses when relevant.
2. When the user asks about their medicines, respond with their ACTUAL prescribed medicines from the data above — do not make up generic medication advice.
3. When discussing vitals (BP, sugar, weight, heart rate), reference their ACTUAL recorded measurements and trends from the data above.
4. When the user asks about their medical history, refer to their ACTUAL records (lab reports, prescriptions, doctor visits) from the data above.
5. If a vital reading is in a concerning range (marked with ⚠️), proactively flag it and recommend medical attention.
6. Include relevant Indian health context (e.g. dietary adjustments with roti/dal/rice, hydration in Indian climate).
7. If the patient has chronic conditions listed in their profile, tailor advice accordingly (e.g. diabetic diet for diabetes, salt restriction for hypertension).
8. Track medicine adherence: if doses are pending for today, gently remind the patient.
9. Always include a brief note recommending consulting the treating physician for changes in dosage or treatment.
10. In severe symptoms (severe chest pain, severe breathlessness), advise emergency 108 assistance immediately.
11. If no relevant medical data exists for a question, honestly say you don't have that specific record and suggest the user add it to SwasthAI for future reference.''';
  }

  Future<void> _sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;
    final lang = ref.read(languageProvider);

    final activeRagMode = _useRag;
    _controller.clear();
    ref.read(assistantMessagesProvider.notifier).addMessage(
          AssistantMessage(text: cleanText, isUser: true, isRag: activeRagMode),
        );
    setState(() {
      _isLoading = true;
    });
    _scrollToBottom();

    final apiKey = ref.read(geminiApiKeyProvider).trim();

    try {
      String responseText;
      if (apiKey.isEmpty) {
        // Fallback / offline mode
        await Future.delayed(const Duration(milliseconds: 600));
        responseText = _getOfflineResponse(cleanText, lang);
      } else if (apiKey.startsWith('AIza')) {
        // Direct Google Gemini API
        final response = await http.post(
          Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': cleanText}
                ]
              }
            ],
            'systemInstruction': {
              'parts': [
                {'text': _buildSystemContext(lang, userQuery: cleanText, useRag: _useRag)}
              ]
            },
            'generationConfig': {'maxOutputTokens': 1024, 'temperature': 0.7},
          }),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          responseText =
              data['candidates'][0]['content']['parts'][0]['text'] as String;
        } else {
          responseText =
              'Could not connect to Gemini API. Please check your API key in Settings.';
        }
      } else {
        // OpenRouter API (sk-or-...) with automatic fallback chain
        final userModel = ref.read(openrouterModelProvider);
        final modelsToTry = {
          userModel,
          'google/gemini-2.0-flash-001',
          'google/gemini-flash-1.5',
          'openrouter/auto',
          'google/gemini-2.0-flash-lite-001',
          'openai/gpt-4o-mini',
        }.where((m) => m.isNotEmpty).toList();

        String? lastError;
        String? successfulResponse;

        for (final modelId in modelsToTry) {
          try {
            final response = await http.post(
              Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
                'HTTP-Referer': 'https://swasthai.app',
                'X-Title': 'SwasthAI Health Companion',
              },
              body: jsonEncode({
                'model': modelId,
                'messages': [
                  {
                    'role': 'system',
                    'content': _buildSystemContext(lang, userQuery: cleanText, useRag: _useRag),
                  },
                  {
                    'role': 'user',
                    'content': cleanText,
                  },
                ],
                'max_tokens': 1024,
                'temperature': 0.7,
              }),
            );

            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              successfulResponse =
                  data['choices'][0]['message']['content'] as String;
              break;
            } else {
              try {
                final errData = jsonDecode(response.body);
                lastError = errData['error']?['message'] ?? response.body;
              } catch (_) {
                lastError = 'HTTP ${response.statusCode}: ${response.body}';
              }
            }
          } catch (e) {
            lastError = e.toString();
          }
        }

        if (successfulResponse != null) {
          responseText = successfulResponse;
        } else {
          responseText =
              'OpenRouter: $lastError\n\nPlease check your key in Settings > OpenRouter AI Model.';
        }
      }
      if (mounted) {
        ref.read(assistantMessagesProvider.notifier).addMessage(
              AssistantMessage(text: responseText, isUser: false, isRag: activeRagMode),
            );
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ref.read(assistantMessagesProvider.notifier).addMessage(
              AssistantMessage(
                text: lang == 'mr'
                    ? 'इंटरनेट कनेक्शन तपासा आणि पुन्हा प्रयत्न करा.'
                    : lang == 'hi'
                        ? 'कृपया अपना इंटरनेट कनेक्शन जांचें और पुनः प्रयास करें।'
                        : 'Error connecting to AI service. Please check your internet connection.',
                isUser: false,
                isRag: activeRagMode,
              ),
            );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getOfflineResponse(String input, String lang) {
    final lower = input.toLowerCase();

    if (lang == 'mr') {
      // 1. Medicine timing / meal interaction (Query 2)
      if (lower.contains('जेवण') || lower.contains('औषध') || lower.contains('गोळी') || lower.contains('वेळ') || lower.contains('timing') || lower.contains('meal')) {
        return 'औषधांच्या योग्य परिणामासाठी वेळांचे नियोजन आवश्यक आहे:\n• उपाशीपोटी (उदा. थायरॉईड किंवा गॅसच्या गोळ्या): सकाळी चहा किंवा नाश्त्याच्या ३०-४५ मिनिटे आधी घ्याव्यात.\n• जेवणानंतर (उदा. मधुमेहाच्या गोळ्या किंवा वेदनाशामक): पोटाची जळजळ टाळण्यासाठी जेवणानंतर १० ते १५ मिनिटांत घ्याव्यात.\n• जर डोस चुकला, तर आठवण झाल्यावर लगेच घ्यावा, पण दुहेरी डोस कधीही घेऊ नका.';
      }
      // 2. Doctor visit symptoms / questions (Query 4)
      if (lower.contains('डॉक्टर') || lower.contains('भेट') || lower.contains('लक्षण') || lower.contains('visit') || lower.contains('doctor') || lower.contains('symptom')) {
        return 'डॉक्टरांना भेटताना खालील गोष्टी आवर्जून सांगा:\n१. मुख्य लक्षणे कधीपासून सुरू झाली व त्यांचा त्रास किती तीव्र आहे.\n२. चालू असलेल्या सर्व औषधांची यादी किंवा स्वास्थAI मधील डोस हिस्ट्री.\n३. अलीकडील रक्तदाब किंवा साखरेचे मोजमाप.\n४. आहार किंवा औषधांची ॲलर्जी.\n५. आहारातील पथ्ये किंवा औषधांचे दुष्परिणाम याबद्दल नक्की विचारा.';
      }
      // 3. Blood Pressure / Hypertension (Query 3)
      if (lower.contains('bp') || lower.contains('रक्तदाब') || lower.contains('pressure') || lower.contains('नाडी') || lower.contains('pulse')) {
        return 'ICMR व WHO मार्गदर्शक तत्त्वांनुसार:\n• सामान्य रक्तदाब: १२०/८० mmHg पेक्षा कमी (नाडी: ६०-१०० ठोके/मिनिट).\n• हायपरटेन्शन (उच्च रक्तदाब): १४०/९० mmHg च्या वर.\n• काळजी: जेवणात मीठ कमी ठेवा, दररोज ३० मिनिटे चाला, ताण कमी करा व औषधे न चुकता वेळेवर घ्या.';
      }
      // 4. Blood Sugar / Diabetes / HbA1c (Query 1)
      if (lower.contains('sugar') || lower.contains('साखर') || lower.contains('मधुमेह') || lower.contains('hba1c') || lower.contains('glucose')) {
        return 'मधुमेह व्यवस्थापनासाठी महत्त्वाचे निकष:\n• उपाशीपोटी साखर (Fasting): ७०-११० mg/dL\n• जेवणानंतर २ तासांनी (PP): १४० mg/dL पेक्षा कमी\n• HbA1c (९० दिवसांची सरासरी): ५.७% पेक्षा कमी सामान्य, ६.५% वर मधुमेह.\n• आहारात ज्वारी, बाजरी, हिरव्या भाज्या व प्रथिनांचा समावेश करा. गोड पदार्थ व मैदा टाळा.';
      }
      // 5. Lab Report / Tests
      if (lower.contains('lab') || lower.contains('रिपोर्ट') || lower.contains('अहवाल') || lower.contains('तपासणी') || lower.contains('test')) {
        return 'वैद्यकीय अहवाल (Lab Reports) समजून घेण्यासाठी:\n• तुमचे सर्व रक्त तपासणी, मूत्र चाचणी किंवा क्ष-किरण अहवाल स्वास्थAI च्या "नोंदी" विभागात फोटो किंवा PDF स्वरूपात जोडून सुरक्षित ठेवा.\n• अहवालातील ठळक लाल किंवा तारांकित आकडे सामान्य मर्यादेबाहेर असल्याचे दर्शवतात, ते त्वरित डॉक्टरांना दाखवा.';
      }
      // 6. Fever, Cough, Cold
      if (lower.contains('ताप') || lower.contains('खोकला') || lower.contains('सर्दी') || lower.contains('डोकेदुखी') || lower.contains('fever') || lower.contains('cough') || lower.contains('cold')) {
        return 'ताप किंवा सर्दी-खोकल्यासाठी प्राथमिक काळजी:\n• भरपूर कोमट पाणी प्या व विश्रांती घ्या.\n• मिठाच्या पाण्याच्या गुळण्या करा व वाफ घ्या.\n• जर ताप १००°F पेक्षा जास्त असेल किंवा ३ दिवसांपेक्षा जास्त दिवस राहिल्यास त्वरित डॉक्टरांचा सल्ला घ्या.';
      }
      // 7. Emergency / Severe Symptoms
      if (lower.contains('आणीबाणी') || lower.contains('अपघात') || lower.contains('छातीत') || lower.contains('चक्कर') || lower.contains('emergency') || lower.contains('108')) {
        return '🚨 तातडीची सूचना:\nछातीत तीव्र दुखणे, श्वास घेण्यास त्रास, अचानक पक्षाघाताची लक्षणे किंवा बेशुद्ध पडल्यास वेळ न दवडता ताबडतोब १०८ रुग्णवाहिका बोलवा किंवा जवळच्या आपत्कालीन रुग्णालयात पोहोचा!';
      }
      // 8. Maternal / Children / Vaccines
      if (lower.contains('लस') || lower.contains('लसीकरण') || lower.contains('गरोदर') || lower.contains('बाळ') || lower.contains('vaccine') || lower.contains('baby') || lower.contains('pregnancy')) {
        return 'माता व बाल आरोग्य मार्गदर्शन:\n• बालकांचे राष्ट्रीय लसीकरण वेळापत्रकानुसार पोलिओ, बीसीजी, पेंटाव्हॅलेंट व गोवर लसी वेळेवर द्या.\n• गरोदर मातांनी नियमित लोह, फॉलिक ॲसिडच्या गोळ्या घ्याव्यात व सोनोग्राफी तपासण्या कराव्यात.';
      }
      return 'तुमच्या आरोग्य प्रश्नाबद्दल धन्यवाद. स्वास्थAI नुसार, आपल्या कौटुंबिक आरोग्याची नियमित काळजी घ्या आणि सर्व औषधे वेळेवर घ्या. काही गंभीर लक्षणे जाणवल्यास नेहमी आपल्या तज्ज्ञ डॉक्टरांचा सल्ला घ्या किंवा १०८ वर संपर्क साधा.';
    }

    if (lang == 'hi') {
      // 1. Medicine timing / meal interaction (Query 2)
      if (lower.contains('भोजन') || lower.contains('दवा') || lower.contains('दवाई') || lower.contains('समय') || lower.contains('timing') || lower.contains('meal') || lower.contains('food')) {
        return 'दवाइयों के सर्वोत्तम प्रभाव के लिए सही समय जरूरी है:\n• खाली पेट (जैसे थायरॉयड या गैस की दवा): सुबह चाय या नाश्ते से ३०-४५ मिनट पहले लें।\n• भोजन के बाद (जैसे डायबिटीज की दवा या दर्द निवारक): पेट की जलन से बचने के लिए भोजन के १०-१५ मिनट बाद लें।\n• यदि खुराक छूट जाए, तो याद आने पर तुरंत लें, लेकिन कभी भी दोहरी खुराक न लें।';
      }
      // 2. Doctor visit symptoms / questions (Query 4)
      if (lower.contains('डॉक्टर') || lower.contains('परामर्श') || lower.contains('लक्षण') || lower.contains('प्रश्न') || lower.contains('visit') || lower.contains('doctor') || lower.contains('symptom')) {
        return 'डॉक्टर से मिलते समय मुख्य बिंदु अवश्य साझा करें:\n१. बीमारी या लक्षण कब से शुरू हुए और कितनी परेशानी है।\n२. आपकी सभी वर्तमान दवाओं की सूची या स्वास्थAI की खुराक हिस्ट्री।\n३. हाल ही के ब्लड प्रेशर या शुगर के माप।\n४. किसी दवा या खाद्य पदार्थ से एलर्जी।\n५. जीवनशैली या खुराक में बदलाव के बारे में डॉक्टर से खुलकर पूछें।';
      }
      // 3. Blood Pressure / Hypertension (Query 3)
      if (lower.contains('bp') || lower.contains('रक्तचाप') || lower.contains('pressure') || lower.contains('पल्स') || lower.contains('pulse')) {
        return 'ICMR एवं WHO दिशानिर्देशों के अनुसार:\n• सामान्य रक्तचाप: १२०/८० mmHg से कम (पल्स: ६०-१०० प्रति मिनट).\n• उच्च रक्तचाप (Hypertension): १४०/९० mmHg से अधिक.\n• नियंत्रण के लिए: भोजन में नमक कम करें, प्रतिदिन ३० मिनट टहलें और दवाइयां नियमित रूप से लें।';
      }
      // 4. Blood Sugar / Diabetes / HbA1c (Query 1)
      if (lower.contains('sugar') || lower.contains('शर्करा') || lower.contains('शुगर') || lower.contains('मधुमेह') || lower.contains('hba1c') || lower.contains('glucose')) {
        return 'मधुमेह प्रबंधन के मुख्य मानक:\n• खाली पेट ब्लड शुगर (Fasting): ७०-११० mg/dL\n• भोजन के २ घंटे बाद (PP): १४० mg/dL से कम\n• HbA1c (९० दिनों का औसत स्तर): ५.७% से कम सामान्य, ६.५% से अधिक मधुमेह।\n• साबुत अनाज (ज्वार, बाजरा, ओट्स) खाएं और मीठी चीजों से परहेज रखें।';
      }
      // 5. Lab Report / Tests
      if (lower.contains('lab') || lower.contains('रिपोर्ट') || lower.contains('जांच') || lower.contains('test')) {
        return 'लैब रिपोर्ट्स का रिकॉर्ड व समीक्षा:\n• अपने सभी ब्लड टेस्ट, यूरिन टेस्ट या स्कैन रिपोर्ट्स स्वास्थAI के "रिकॉर्ड" सेक्शन में फोटो या PDF के रूप में सुरक्षित रखें।\n• यदि कोई संख्या सामान्य सीमा (Reference Range) से बाहर है, तो तुरंत अपने डॉक्टर को दिखाएं।';
      }
      // 6. Fever, Cough, Cold
      if (lower.contains('बुखार') || lower.contains('खांसी') || lower.contains('जुकाम') || lower.contains('सिरदर्द') || lower.contains('fever') || lower.contains('cough') || lower.contains('cold')) {
        return 'सामान्य बुखार या जुकाम के लिए प्राथमिक देखभाल:\n• गुनगुना पानी पिएं और पर्याप्त आराम करें।\n• नमक के पानी से गरारे करें और भाप लें।\n• यदि बुखार १००°F से अधिक हो या ३ दिन से ज्यादा रहे तो डॉक्टर से संपर्क करें।';
      }
      // 7. Emergency
      if (lower.contains('आपातकालीन') || lower.contains('दुर्घटना') || lower.contains('सीने में दर्द') || lower.contains('चक्कर') || lower.contains('emergency') || lower.contains('108')) {
        return '🚨 आपातकालीन सूचना:\nसीने में तेज दर्द, सांस लेने में तकलीफ, अचानक कमजोरी या बेहोशी की स्थिति में बिना देर किए तुरंत १०८ एम्बुलेंस को कॉल करें या नजदीकी आपातकालीन केंद्र जाएं!';
      }
      // 8. Maternal / Children / Vaccines
      if (lower.contains('टीका') || lower.contains('टीकाकरण') || lower.contains('गर्भवती') || lower.contains('बच्चा') || lower.contains('शिशु') || lower.contains('vaccine') || lower.contains('pregnancy')) {
        return 'मातृ एवं शिशु स्वास्थ्य दिशानिर्देश:\n• बच्चों को पोलियो, बीसीजी, पेंटावेलेंट और खसरा के टीके समय पर लगवाएं।\n• गर्भवती महिलाएं नियमित आयरन और फोलिक एसिड लें और समय पर चेकअप करवाएं।';
      }
      return 'आपके स्वास्थ्य संबंधी प्रश्न के लिए धन्यवाद। स्वास्थAI आपकी सेहत का ध्यान रखने में सदैव साथ है। कृपया अपनी नियमित दवाएं समय पर लें। किसी भी गंभीर लक्षण में डॉक्टर से परामर्श लें या १०८ पर कॉल करें।';
    }

    // Default English
    if (lower.contains('meal') || lower.contains('timing') || lower.contains('food') || lower.contains('absorp') || lower.contains('medicine')) {
      return 'For optimal medication efficacy and stomach protection:\n• Empty Stomach (e.g. Thyroid, Antacids): Take 30-45 minutes before morning breakfast with plain water.\n• Post-Meal (e.g. Metformin, Pain Relievers): Take 10-15 minutes after food to minimize gastrointestinal discomfort.\n• If a dose is missed, take it when remembered, but never take a double dose to compensate.';
    }
    if (lower.contains('doctor') || lower.contains('visit') || lower.contains('symptom') || lower.contains('report to doctor')) {
      return 'Key points to share with your physician during consultation:\n1. Onset, duration, and severity of your symptoms.\n2. Complete list of current medications and doses tracked in SwasthAI.\n3. Recent vitals measurements (BP, blood glucose logs).\n4. Any known drug allergies or adverse reactions.\n5. Inquire about dietary precautions and lifestyle recommendations.';
    }
    if (lower.contains('bp') || lower.contains('blood pressure') || lower.contains('hypertension') || lower.contains('pulse')) {
      return 'Based on ICMR clinical guidelines:\n• Normal Blood Pressure: Below 120/80 mmHg (Resting Heart Rate: 60-100 bpm).\n• Stage 1 Hypertension: 130-139 / 80-89 mmHg.\n• Key Steps: Restrict dietary sodium, engage in 30 minutes of daily brisk walking, and adhere to prescribed antihypertensives.';
    }
    if (lower.contains('sugar') || lower.contains('diabetes') || lower.contains('glucose') || lower.contains('hba1c')) {
      return 'Key diabetic clinical targets:\n• Fasting Blood Sugar: 70–110 mg/dL\n• Post-Prandial (2 hrs after food): Below 140 mg/dL\n• HbA1c (90-day average): Below 5.7% is normal; 6.5%+ indicates diabetic range.\n• Prefer complex carbohydrates (millet, oats, dal) and maintain consistent meal timing.';
    }
    if (lower.contains('lab') || lower.contains('report') || lower.contains('test')) {
      return 'Reviewing diagnostic lab reports:\n• Store your pathology reports and imaging scans securely in the SwasthAI Records Vault.\n• Parameters highlighted with an asterisk or red flags indicate out-of-range values that should be reviewed with your doctor.';
    }
    if (lower.contains('emergency') || lower.contains('chest pain') || lower.contains('108')) {
      return '🚨 Emergency Protocol:\nIf experiencing sudden severe chest pain, shortness of breath, acute weakness, or loss of consciousness, immediately dial 108 for an ambulance or reach the nearest emergency department.';
    }
    return 'Thank you for your question. Based on your family health records, '
        'I recommend continuing your prescribed daily routine and maintaining hydration. '
        'If you experience persistent headaches, dizziness, or chest discomfort, please seek immediate medical attention or dial 108.';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final activeMember = ref.watch(activeMemberProvider);
    final lang = ref.watch(languageProvider);
    final messages = ref.watch(assistantMessagesProvider);
    _ensureWelcomeMessage(lang);
    final quickQueries = _getQuickQueries(lang);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.health_and_safety, color: Color(0xFF00685F), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        AppTranslations.tr(lang, 'assistantTitle'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF121C2A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00685F),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    activeMember != null
                        ? '${activeMember.name} (${activeMember.relationship}, ${activeMember.age}y)'
                        : AppTranslations.tr(lang, 'assistantSubtitle'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF00685F),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => _toggleRag(!_useRag),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _useRag ? const Color(0xFFCCFBF1) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _useRag ? const Color(0xFF99F6E4) : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _useRag ? Icons.folder_shared : Icons.auto_awesome,
                    size: 13,
                    color: _useRag ? const Color(0xFF00685F) : const Color(0xFF475569),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _useRag ? AppTranslations.tr(lang, 'ragMode') : AppTranslations.tr(lang, 'simpleMode'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _useRag ? const Color(0xFF00685F) : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF64748B), size: 20),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: [
                    const Icon(Icons.security, color: Color(0xFF00685F), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      AppTranslations.tr(lang, 'aboutAi'),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                content: Text(
                  '${AppTranslations.tr(lang, 'appTitle')} gives you two powerful AI modes:\n\n'
                  '1. ${AppTranslations.tr(lang, 'ragMode')}: Answers are grounded in your actual family medical records, prescriptions, vitals & medicine schedule.\n\n'
                  '2. ${AppTranslations.tr(lang, 'simpleMode')}: General clinical health guidance without referencing personal files.\n\n'
                  '• You can switch between them anytime using the toggle.\n'
                  '• Powered by OpenRouter AI / Gemini.\n'
                  '• In medical emergencies, call helpline 108 immediately.',
                  style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF334155)),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      AppTranslations.tr(lang, 'understood'),
                      style: const TextStyle(color: Color(0xFF00685F), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFF64748B), size: 20),
            tooltip: 'Clear Chat',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Clear Chat History?'),
                  content: const Text('This will clear the current conversation and start fresh.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(AppTranslations.tr(lang, 'cancel')),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBA1A1A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(assistantMessagesProvider.notifier).clearChat(
                              AppTranslations.tr(lang, 'assistantWelcome'),
                            );
                      },
                      child: Text(AppTranslations.tr(lang, 'delete')),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Safety Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            color: const Color(0xFFE6EEFF),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: Color(0xFF00685F), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppTranslations.tr(lang, 'disclaimer'),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF3D4947), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Interactive Mode Switcher (Records RAG vs General AI)
          Container(
            margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleRag(true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: _useRag ? const Color(0xFF00685F) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _useRag
                            ? [const BoxShadow(color: Color(0x1F00685F), blurRadius: 4, offset: Offset(0, 1))]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_shared,
                            size: 14,
                            color: _useRag ? Colors.white : const Color(0xFF475569),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppTranslations.tr(lang, 'ragMode'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _useRag ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleRag(false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: !_useRag ? const Color(0xFF00685F) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: !_useRag
                            ? [const BoxShadow(color: Color(0x1F00685F), blurRadius: 4, offset: Offset(0, 1))]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: !_useRag ? Colors.white : const Color(0xFF475569),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppTranslations.tr(lang, 'simpleMode'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: !_useRag ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active Mode Context Hint Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            child: Row(
              children: [
                Icon(
                  _useRag ? Icons.check_circle_outline : Icons.info_outline,
                  size: 12,
                  color: _useRag ? const Color(0xFF00685F) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    _useRag
                        ? AppTranslations.tr(lang, 'ragEnabledHint')
                        : AppTranslations.tr(lang, 'simpleEnabledHint'),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: _useRag ? const Color(0xFF00685F) : const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Messages Stream
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              itemCount: messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == messages.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00685F),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00685F)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppTranslations.tr(lang, 'loading'),
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return _buildClinicalBubble(context, messages[index]);
              },
            ),
          ),

          // Quick Health Queries Carousel (Suggestions)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: const Color(0xFFF8F9FF),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: quickQueries.map((q) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _sendMessage(q['query']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x060F172A), blurRadius: 2, offset: Offset(0, 1)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flash_on, color: Color(0xFF00685F), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              q['title']!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF121C2A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              textInputAction: TextInputAction.send,
                              onSubmitted: _sendMessage,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF121C2A)),
                              decoration: InputDecoration(
                                hintText: _useRag
                                    ? AppTranslations.tr(lang, 'askQuestionRag')
                                    : AppTranslations.tr(lang, 'askQuestionGeneral'),
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.mic, color: Color(0xFF00685F), size: 20),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppTranslations.tr(lang, 'listening')),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00685F),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: () => _sendMessage(_controller.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalBubble(BuildContext context, AssistantMessage msg) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(msg.timestamp),
              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF00685F),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Color(0xFFCCFBF1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Color(0xFF006F67), size: 16),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF00685F),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.health_and_safety, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'SwasthAI',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: msg.isRag ? const Color(0xFFCCFBF1) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: msg.isRag ? const Color(0xFF99F6E4) : const Color(0xFFBFDBFE),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              msg.isRag ? Icons.folder_shared : Icons.auto_awesome,
                              size: 10,
                              color: msg.isRag ? const Color(0xFF00685F) : const Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              msg.isRag ? 'Records RAG' : 'General AI',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: msg.isRag ? const Color(0xFF00685F) : const Color(0xFF1D4ED8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(msg.timestamp),
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x040F172A), blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                    child: SelectableText(
                      msg.text,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}
