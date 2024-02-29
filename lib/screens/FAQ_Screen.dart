import 'package:flutter/material.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  _FAQScreenState createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  List<Item> _filteredItems = [];
  final TextEditingController _searchController = TextEditingController();
  final List<Item> _items = <Item>[
    Item(
      'What is QuickPost?',
      'QuickPost is a revolutionary social media platform designed to tackle common issues faced by users on traditional social media sites. Our app emphasizes safe, efficient, and enjoyable online interactions without the drawbacks of addiction or privacy invasions. QuickPost uses advanced AI technology to ensure a safe environment for all users, including children, by automatically filtering out inappropriate content.',
    ),
    Item(
      'What makes QuickPost different from other social media apps?',
      'QuickPost stands out by addressing the core issues of traditional social media platforms, such as addiction, privacy concerns, and exposure to inappropriate content. Our app is designed to foster a healthy, enjoyable, and safe online community for users of all ages. With QuickPost, you get the benefits of connecting with others without the common downsides.',
    ),
    Item(
      'What is the purpose of QuickPost?',
      'The purpose of QuickPost is to offer a safe, engaging, and non-addictive social media experience that respects user privacy and promotes healthy online interactions. Our platform uses advanced AI to ensure a secure environment for all ages by filtering out inappropriate content, making it the ideal choice for users seeking meaningful and safe digital connections without compromising personal data.',
    ),
    Item(
      'How do I get started?',
      'To get started with QuickPost, download the app from your app store, create an account, and customize your profile. Follow the on-screen guide to set your preferences for a personalized experience. Explore the app to connect with friends, share posts, and enjoy curated content safely. Remember, QuickPost is designed for ease of use, so you can dive right into connecting and sharing in a safer online environment.',
    ),
    Item(
      'How does QuickPost prevent addiction?',
      'QuickPost is built with features that encourage responsible use. Our app includes tools to help users manage their time effectively, such as reminders to take breaks and features that limit daily usage. Our goal is to provide a platform that enhances your life without becoming a distraction.',
    ),
    Item(
      'Can I customize my content feed on QuickPost?',
      'Yes, QuickPost allows you to customize your content feed. Our platform offers various filters and settings to ensure you see more of what interests you and less of what doesn\'t. This way, you can enjoy a personalized social media experience that aligns with your preferences and values.',
    ),
    Item(
      'What safety features does QuickPost have?',
      'Safety is a cornerstone of QuickPost. We use cutting-edge AI to screen and remove any posts that contain harmful language, images, or videos. Our app is designed to be a safe space for users of all ages, with additional protections to ensure it remains child-friendly.',
    ),
    Item(
      'How can I ensure my child is safe on QuickPost?',
      'QuickPost\'s AI moderation system plays a significant role in creating a safe environment for children. Additionally, we offer parental control features that allow you to monitor and manage your child\'s interaction with the app. These tools ensure that your child enjoys a safe and positive social media experience.',
    ),
    Item(
      'What privacy options are available in QuickPost?',
      'QuickPost’s privacy settings allow you to control who can see your posts and personal information. You can make your account private, manage who can tag you in posts, and decide whether your activity status is visible to others. These settings help you maintain your desired level of privacy on the platform.',
    ),
    Item(
      'Does QuickPost collect my data?',
      'Unlike other social media platforms, QuickPost prioritizes user privacy. We do not collect app usage data or any personal information. Your activities on QuickPost remain private, as we believe in offering a secure and unintrusive online environment.',
    ),
    Item(
      'How do I change my password?',
      'To change your password, navigate to the Account Settings section and select "Change Password." You will need to enter your current password and then your new password. It’s recommended to choose a strong password that includes a mix of letters, numbers, and special characters.',
    ),
    Item(
      'Can I log out of all devices from within the app?',
      'Yes, you can secure your account by logging out of all devices. This option is available in the Account Settings section. It’s a useful feature if you suspect unauthorized access to your account.',
    ),
    Item(
      'What should I do if I want to delete my account?',
      'If you decide to delete your QuickPost account, you can do so in the Account Settings. Please note that this action is irreversible. Upon confirmation, your account and all associated data will be permanently removed. Consider backing up any important information before proceeding with account deletion.',
    ),
    Item(
      'How do I customize my notification settings?',
      'In the Notification Settings, you can tailor how and when you want to receive notifications. This includes settings for receiving notifications about new posts, comments, likes, and direct messages. You can also adjust sound and vibration settings for notifications.',
    ),
    Item(
      'How do I report inappropriate content or behavior?',
      'Although our AI actively filters out inappropriate content, we also provide users with the ability to report any content or behavior that may have slipped through. This feature is easily accessible within the app, ensuring that our community remains a safe space for everyone.',
    ),
    Item(
      'How can I report a problem or provide feedback?',
      'QuickPost values your input. If you encounter a problem or have suggestions for improvement, you can report this through the Help & Support section. There, you’ll find options to contact our support team, report a problem, or send feedback directly through the app.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Initially, all FAQs are displayed.
    _filteredItems = _items;
    _searchController.addListener(_filterFAQs);
  }

  void _filterFAQs() {
    final query = _searchController.text.toLowerCase();

    if (query.isNotEmpty) {
      _filteredItems = _items.where((Item item) {
        return item.question.toLowerCase().contains(query) ||
            item.answer.toLowerCase().contains(query);
      }).toList();
    } else {
      _filteredItems = _items;
    }

    setState(() {}); // Update the UI with the filtered list
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQs'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search FAQs',
                suffixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: _filteredItems.map<Widget>((Item item) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ExpansionPanelList.radio(
                        elevation: 1,
                        expandedHeaderPadding: const EdgeInsets.all(0),
                        children: [
                          ExpansionPanelRadio(
                            value: item,
                            headerBuilder:
                                (BuildContext context, bool isExpanded) {
                              return ListTile(
                                title: Text(
                                  item.question,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              );
                            },
                            body: ListTile(
                              title: Text(item.answer),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Item {
  Item(this.question, this.answer, {this.isExpanded = false});

  final String question;
  final String answer;
  bool isExpanded;
}
