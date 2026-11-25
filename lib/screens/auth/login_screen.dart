import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/i18n/app_translations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _familyCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  int _activeTab = 0; // 0: Primary Account, 1: Family Member Access

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _familyCodeController.dispose();
    super.dispose();
  }

  void _loginWithEmailPassword() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final authService = ref.read(authServiceProvider);

    try {
      final user = await authService.loginUser(email: email, password: password);
      ref.read(authProvider.notifier).loginCloud(email, userId: user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${user.fullName}! ✓'),
            backgroundColor: const Color(0xFF00685F),
          ),
        );
        context.go('/dashboard/home');
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loginWithFamilyCode() async {
    if (_isLoading) return;
    final code = _familyCodeController.text.trim().toUpperCase();
    final phone = _phoneController.text.trim();

    if (code.isEmpty && phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your 6-character Family Access Code (e.g. FAM-A1B2C3)')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authService = ref.read(authServiceProvider);

    try {
      final member = await authService.loginFamilyMember(
        accessCode: code,
        phone: phone.isNotEmpty ? phone : null,
      );

      // Authenticate in Riverpod as Family Member
      ref.read(authProvider.notifier).loginAsFamilyMember(
        memberId: member.id,
        memberName: member.name,
        accessCode: code.isNotEmpty ? code : member.accessCode,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${member.name}! Profile unlocked ✓'),
            backgroundColor: const Color(0xFF00685F),
          ),
        );
        context.go('/dashboard/home');
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scanFamilyQrCode() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.black,
              title: const Text('Scan Family Access QR Code', style: TextStyle(color: Colors.white, fontSize: 16)),
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    final rawValue = barcode.rawValue;
                    if (rawValue != null && rawValue.isNotEmpty) {
                      Navigator.pop(ctx);
                      setState(() {
                        _familyCodeController.text = rawValue.trim().toUpperCase();
                      });
                      _loginWithFamilyCode();
                      break;
                    }
                  }
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Point camera at the QR code on the family head’s phone',
                style: TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF121C2A)),
          onPressed: () => context.go('/landing'),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.verified_user, color: Color(0xFF00685F), size: 18),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.tr(lang, 'appTitle'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00685F)),
                ),
                Text(
                  AppTranslations.tr(lang, 'securityVault'),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          DropdownButton<String>(
            value: lang,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              DropdownMenuItem(value: 'hi', child: Text('हिंदी', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              DropdownMenuItem(value: 'mr', child: Text('मराठी', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            ],
            onChanged: (v) {
              if (v != null) {
                ref.read(languageProvider.notifier).updateValue(v);
              }
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Intro
                Text(
                  AppTranslations.tr(lang, 'signIn'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF121C2A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppTranslations.tr(lang, 'appSubtitle'),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 20),

                // Card Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Mode Switcher Tabs
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _activeTab = 0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _activeTab == 0 ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: _activeTab == 0
                                        ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 2)]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person, size: 14, color: _activeTab == 0 ? const Color(0xFF00685F) : const Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppTranslations.tr(lang, 'primaryAccountTab'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: _activeTab == 0 ? FontWeight.bold : FontWeight.w500,
                                          color: _activeTab == 0 ? const Color(0xFF00685F) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _activeTab = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _activeTab == 1 ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: _activeTab == 1
                                        ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 2)]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.family_restroom, size: 14, color: _activeTab == 1 ? const Color(0xFF00685F) : const Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppTranslations.tr(lang, 'familyCodeTab'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: _activeTab == 1 ? FontWeight.bold : FontWeight.w500,
                                          color: _activeTab == 1 ? const Color(0xFF00685F) : const Color(0xFF64748B),
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
                      const SizedBox(height: 18),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_activeTab == 0) ...[
                              Text(AppTranslations.tr(lang, 'email'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                enabled: !_isLoading,
                                decoration: InputDecoration(
                                  hintText: 'name@example.com',
                                  filled: true,
                                  fillColor: const Color(0xFFF8F9FF),
                                  prefixIcon: const Icon(Icons.mail_outline, size: 18, color: Color(0xFF00685F)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  isDense: true,
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Enter your email address';
                                  if (!v.contains('@')) return 'Enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              Text(AppTranslations.tr(lang, 'password'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                enabled: !_isLoading,
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  filled: true,
                                  fillColor: const Color(0xFFF8F9FF),
                                  prefixIcon: const Icon(Icons.lock_outline, size: 18, color: Color(0xFF00685F)),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18, color: const Color(0xFF94A3B8)),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  isDense: true,
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Enter your password';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),

                              // Remember Me
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          activeColor: const Color(0xFF00685F),
                                          onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(AppTranslations.tr(lang, 'rememberDevice'), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00685F),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  icon: _isLoading
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.lock, size: 18),
                                  label: Text(
                                    _isLoading ? AppTranslations.tr(lang, 'loading') : AppTranslations.tr(lang, 'loginBtn'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  onPressed: _isLoading ? null : _loginWithEmailPassword,
                                ),
                              ),
                            ] else ...[
                              // FAMILY MEMBER CODE ACCESS TAB
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(AppTranslations.tr(lang, 'mobileAccessCode'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 20)),
                                    icon: const Icon(Icons.qr_code_scanner, size: 14, color: Color(0xFF00685F)),
                                    label: Text(AppTranslations.tr(lang, 'scanFamilyQr'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00685F))),
                                    onPressed: _scanFamilyQrCode,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _familyCodeController,
                                textCapitalization: TextCapitalization.characters,
                                enabled: !_isLoading,
                                style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: 'e.g. FAM-A1B2C3',
                                  filled: true,
                                  fillColor: const Color(0xFFF8F9FF),
                                  prefixIcon: const Icon(Icons.vpn_key, size: 18, color: Color(0xFF00685F)),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.qr_code_scanner, size: 20, color: Color(0xFF00685F)),
                                    tooltip: 'Scan QR from Family Head Phone',
                                    onPressed: _scanFamilyQrCode,
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 12),

                              Text(AppTranslations.tr(lang, 'phone'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                enabled: !_isLoading,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 9876543210',
                                  filled: true,
                                  fillColor: const Color(0xFFF8F9FF),
                                  prefixIcon: const Icon(Icons.phone, size: 18, color: Color(0xFF00685F)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Info Card explaining Zero Credentials Needed
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCCFBF1).withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF00685F).withOpacity(0.2)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.info_outline, size: 18, color: Color(0xFF00685F)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        AppTranslations.tr(lang, 'scanQrToLogin'),
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF0F766E), height: 1.35),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Family Member Access Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00685F),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  icon: _isLoading
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.family_restroom, size: 18),
                                  label: Text(
                                    _isLoading ? AppTranslations.tr(lang, 'loading') : AppTranslations.tr(lang, 'familyCodeTab'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  onPressed: _isLoading ? null : _loginWithFamilyCode,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Data Privacy Framework Footer Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6EEFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.health_and_safety, color: Color(0xFF00685F), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${AppTranslations.tr(lang, 'securityVault')} • 256-Bit Encrypted Health Storage.',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF3D4947), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Link to Sign Up
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${AppTranslations.tr(lang, 'noAccount').split('?')[0]}?",
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      TextButton(
                        onPressed: () => context.go('/signup'),
                        child: Text(
                          AppTranslations.tr(lang, 'signUp'),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF00685F)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
