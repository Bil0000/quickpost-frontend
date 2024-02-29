import 'package:flutter/material.dart';
import 'package:quickpost_flutter/screens/FAQ_Screen.dart';
import 'package:quickpost_flutter/screens/contact_form_screen.dart';
import 'package:quickpost_flutter/screens/feedback_form_screen.dart';
import 'package:quickpost_flutter/screens/report_problem_screen.dart';
import 'package:quickpost_flutter/screens/user_guide_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  _HelpSupportScreenState createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor:
            Colors.deepPurple, // Adjust this to match your app theme
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.question_answer),
            title: const Text('FAQs'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FAQScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Contact Us'),
            subtitle: const Text('Get in touch with our support team'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContactFormScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.report_problem),
            title: const Text('Report a Problem'),
            subtitle: const Text('Report a problem or a bug in the app'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportProblemScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('User Guide'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserGuideScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Send Feedback'),
            subtitle: const Text(
                'Share your feedback about the app or how to enhance it'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FeedbackFormScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
