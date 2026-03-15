import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/application/auth_controller.dart';

class SignUpDialog extends StatefulWidget {
  const SignUpDialog({
    super.key,
    required this.controller,
    required this.initialEmail,
  });

  final AuthController controller;
  final String initialEmail;

  @override
  State<SignUpDialog> createState() => _SignUpDialogState();
}

class _SignUpDialogState extends State<SignUpDialog> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  late final TextEditingController _emailController;
  bool _submitting = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _companyController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _message = null;
    });

    final result = await widget.controller.requestSignUp(
      companyName: _companyController.text,
      fullName: _fullNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
      _message = result.message;
      _isSuccess = result.isSuccess;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kaydol',
            style: TextStyle(
              color: AppPalette.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Sirket ve kullanici bilgilerini birak. Ekibimiz hesap acilisi icin sizinle iletisime gecsin.',
            style: TextStyle(
              color: AppPalette.muted,
              height: 1.5,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(
                    labelText: 'Sirket adi',
                    hintText: 'Workflow Teknoloji',
                    prefixIcon: Icon(
                      Icons.apartment_rounded,
                      color: AppPalette.muted,
                      size: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Sirket adi gerekli.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Ad soyad',
                    hintText: 'Salih Ceylan',
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      color: AppPalette.muted,
                      size: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ad soyad gerekli.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    hintText: 'ornek@workflow.com',
                    prefixIcon: Icon(
                      Icons.alternate_email_rounded,
                      color: AppPalette.muted,
                      size: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'E-posta gerekli.';
                    }
                    if (!value.contains('@')) {
                      return 'Gecerli bir e-posta girin.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                    hintText: '05xx xxx xx xx',
                    prefixIcon: Icon(
                      Icons.call_outlined,
                      color: AppPalette.muted,
                      size: 20,
                    ),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color:
                          (_isSuccess ? AppPalette.success : AppPalette.danger)
                              .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            (_isSuccess
                                    ? AppPalette.success
                                    : AppPalette.danger)
                                .withValues(alpha: 0.16),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _isSuccess
                              ? AppPalette.success
                              : AppPalette.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Kapat'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(_submitting ? 'Gonderiliyor...' : 'Talep Gonder'),
        ),
      ],
    );
  }
}
