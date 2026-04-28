import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_client.dart';
import '../services/app_session.dart';

class FarmerChatPage extends StatefulWidget {
  final String contactName;
  final int? peerUserId;

  const FarmerChatPage({super.key, required this.contactName, this.peerUserId});

  @override
  State<FarmerChatPage> createState() => _FarmerChatPageState();
}

class _FarmerChatPageState extends State<FarmerChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ApiClient _api = ApiClient();
  List<Map<String, dynamic>> _apiMessages = [];

  bool get _useApi => widget.peerUserId != null && widget.peerUserId! > 0;

  @override
  void initState() {
    super.initState();
    if (_useApi) _loadApi();
  }

  Future<void> _loadApi() async {
    if (!_useApi) return;
    try {
      final rows = await _api.messagesWith(widget.peerUserId!);
      setState(() => _apiMessages = rows);
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (_useApi) {
      try {
        await _api.sendMessage(toUserId: widget.peerUserId!, body: text);
        _controller.clear();
        await _loadApi();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Open chat from Messages or a buyer profile to reply here.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Status bar color
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF024E44),
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF0FFE2),
      body: Column(
        children: [
          // Custom curved AppBar with shadow
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 40,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF024E44),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Back arrow
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFF0FFE2)),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                // Contact name
                Text(
                  widget.contactName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Chat messages
          Expanded(
            child: _useApi
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _apiMessages.length,
                    itemBuilder: (context, index) {
                      final m = _apiMessages[index];
                      final from = (m['from_user_id'] as num?)?.toInt() ?? 0;
                      final isMe = AppSession.userId != null && from == AppSession.userId;
                      final text = (m['body'] ?? '').toString();
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.green[300] : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 0),
                              bottomRight: Radius.circular(isMe ? 0 : 16),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 3,
                                offset: Offset(1, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            text,
                            style: TextStyle(
                              fontSize: 16,
                              color: isMe ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No conversation selected. Open this screen from Messages or a buyer profile.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
          ),

          // Input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFF0FFE2),
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    elevation: 3,
                    borderRadius: BorderRadius.circular(30),
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Type your message...",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send, color: Color(0xFF024E44)),
                          onPressed: _sendMessage,
                        ),
                      ),
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