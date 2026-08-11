import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_text_style.dart';

class BookingChatDetailScreen extends StatefulWidget {
  final String bookingId;
  final String providerName;
  final String providerPhone;
  final String serviceTitle;
  final String status;

  const BookingChatDetailScreen({
    super.key,
    required this.bookingId,
    required this.providerName,
    required this.providerPhone,
    required this.serviceTitle,
    required this.status,
  });

  @override
  State<BookingChatDetailScreen> createState() => _BookingChatDetailScreenState();
}

class _BookingChatDetailScreenState extends State<BookingChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get _isJobDone {
    final st = widget.status.toLowerCase();
    return ['completed', 'work_completed', 'paid_and_closed', 'closed'].contains(st);
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _sendMessage() async {
    if (_isJobDone) return;

    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    final user = _auth.currentUser;

    await _firestore
        .collection('bookings')
        .doc(widget.bookingId)
        .collection('messages')
        .add({
      'senderId': user?.uid ?? 'customer',
      'senderName': 'Customer',
      'senderType': 'customer',
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _formatMessageTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final dt = timestamp.toDate();
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _auth.currentUser?.uid ?? 'customer';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: AppColors.primary.withValues(alpha: 0.08),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.title, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.providerName.isNotEmpty ? widget.providerName : "Assigned Technician",
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.title,
                    ),
                  ),
                  Text(
                    widget.serviceTitle,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.providerPhone.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.phone_rounded, color: AppColors.primary, size: 20),
                onPressed: () => _makePhoneCall(widget.providerPhone),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('bookings')
                  .doc(widget.bookingId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isJobDone
                                ? "Chat history for this completed job."
                                : "Start conversation with ${widget.providerName.isNotEmpty ? widget.providerName : 'your technician'}",
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.title,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isMe = (data['senderType'] == 'customer') || (data['senderId'] == currentUid);
                    final text = data['text'] ?? '';
                    final timeStr = _formatMessageTime(data['createdAt'] as Timestamp?);
                    final senderName = data['senderName'] ?? (isMe ? 'You' : widget.providerName);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                              child: const Icon(Icons.build_rounded, size: 14, color: AppColors.primary),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: isMe
                                    ? const LinearGradient(
                                        colors: [Color(0xFF000062), Color(0xFF1A1A80)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isMe ? null : const Color(0xFFF0F4FF), // Soft Ice-Blue tint for receiver
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                                border: isMe ? null : Border.all(color: const Color(0xFFDCE4F7), width: 1.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: isMe
                                        ? const Color(0x1F000062)
                                        : const Color(0x0A000000),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isMe)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Text(
                                        senderName,
                                        style: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    text,
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: isMe ? Colors.white : const Color(0xFF1E293B),
                                      fontSize: 14,
                                      height: 1.35,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        timeStr,
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 10,
                                          color: isMe ? Colors.white70 : Colors.blueGrey.shade400,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.done_all_rounded, size: 13, color: Colors.white70),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isMe) const SizedBox(width: 4),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _isJobDone
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  color: const Color(0xFFFFF3E0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_clock_rounded, size: 20, color: Color(0xFFE65100)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "This job is completed. Chat is read-only and will auto-delete after 7 days.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            color: Colors.deepOrange.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Color(0x0C000062), blurRadius: 12, offset: Offset(0, -3)),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _msgController,
                            textCapitalization: TextCapitalization.sentences,
                            style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14),
                            decoration: InputDecoration(
                              hintText: "Type a message...",
                              hintStyle: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, color: Colors.grey),
                              fillColor: const Color(0xFFF1F5F9),
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF000062), Color(0xFF1A1A80)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            onPressed: _sendMessage,
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
}