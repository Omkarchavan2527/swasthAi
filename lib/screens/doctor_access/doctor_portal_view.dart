import 'package:flutter/material.dart';

class DoctorPortalView extends StatelessWidget {
  const DoctorPortalView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Web Portal Info')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Doctor Web Portal is hosted online as a web app. Doctors log in on their browser using the 6-digit OTP code or by scanning the patient\'s QR code.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
