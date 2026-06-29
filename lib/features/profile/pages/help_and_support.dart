import 'package:flutter/material.dart';
import 'package:glint/app/app_routes.dart';
import 'package:glint/core/backgrounds/chat_background.dart';
import 'package:glint/core/constants/app_colors.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChatBackground(
        child: Scaffold(
          backgroundColor: AppColors.backgroundTransparent,
          appBar: AppBar(
            title: const Text(
              'Help & Support',
              style: TextStyle(color: AppColors.textColor),
            ),
            backgroundColor: AppColors.backgroundTransparent,
            centerTitle: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textColor),
              onPressed: () => AppNavigator.pop(),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.only(top: 16, left: 5),
              children: [
                _buildSectionTitle('Frequently Asked Questions'),
                const SizedBox(height: 8),
                _buildFaqItem(
                  context: context,
                  question: 'How do I add a friend?',
                  answer: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: AppColors.mutedTextColor, fontSize: 14),
                      children: [
                        TextSpan(text: 'Go to the '),
                        TextSpan(
                          text: '\u{e492}',
                          style: TextStyle(
                            fontFamily: 'MaterialIcons',
                            fontSize: 16, 
                            color: Colors.blue, 
                          ),
                        ),
                        TextSpan(text: ' tab and search for a user, and tap "Add" button.'),
                      ],
                    ),
                  ),
                ),
                _buildFaqItem(
                  context: context,
                  question: 'How do I delete a message?',
                  answer: const Text(
                    'Long-press on your message and select "Delete". The message will be removed for everyone.',
                    style: TextStyle(color: AppColors.mutedTextColor, fontSize: 14),
                  ),
                ),
                _buildFaqItem(
                  context: context,
                  question: 'Why can\'t I see someone\'s status?',
                  answer: const Text(
                    'Only friends can see each other\'s online status and profile details.',
                    style: TextStyle(color: AppColors.mutedTextColor, fontSize: 14),
                  ),
                ),
                _buildFaqItem(
                  context: context,
                  question: 'How do I log out?',
                  answer: const Text(
                    'Go to Settings and tap "Logout" at the bottom.',
                    style: TextStyle(color: AppColors.mutedTextColor, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Contact Support'),
                const SizedBox(height: 8),
                Card(
                  color: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.email, color: Colors.blue),
                    title: const Text(
                      'Email Us',
                      style: TextStyle(color: AppColors.textColor),
                    ),
                    subtitle: const Text(
                      '-----------------',
                      style: TextStyle(color: AppColors.mutedTextColor),
                    ),
                    onTap: () {
                      // Optionally launch email intent
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFaqItem({required BuildContext context, required String question, required Widget answer}) {
    return Card(
      color: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: const TextStyle(
              color: AppColors.textColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity, 
                child: answer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
