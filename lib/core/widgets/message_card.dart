// // lib/core/components/message_card.dart
// import 'package:flutter/material.dart';
// import 'package:page_transition/page_transition.dart';
// import '../services/message_service.dart';
// import '../models/user.dart';
// import '../../features/views/message_page.dart';
// import '../../features/views/user_profile.dart'; // You'll create this

// class MessageCard extends StatelessWidget {
//   final Message message;
//   final User? friend;
//   final VoidCallback? onChatTap;
//   final VoidCallback? onAvatarTap;

//   const MessageCard({
//     super.key,
//     required this.message,
//     this.friend,
//     this.onChatTap,
//     this.onAvatarTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     // Determine friend info
//     final friendName = friend?.username ?? 'Unknown User';
//     final friendId = friend?.id ?? message.senderId;
//     final friendPhoto = friend?.photoUrl;

//     return Column(
//       children: [
//         Container(
//           width: MediaQuery.of(context).size.width,
//           height: 80,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(5),
//           ),
//           child: Row(
//             children: [
//               GestureDetector(
//                 onTap: onAvatarTap ?? () {
//                   // Navigate to User Profile
//                   Navigator.push(
//                     context,
//                     PageTransition(
//                       type: PageTransitionType.fade,
//                       child: UserProfilePage(
//                         userId: friendId,
//                         userName: friendName,
//                         userPhoto: friendPhoto,
//                       ),
//                     ),
//                   );
//                 },
//                 child: Container(
//                   margin: const EdgeInsets.only(left: 10, right: 20),
//                   child: CircleAvatar(
//                     radius: 30,
//                     backgroundColor: Colors.blue,
//                     backgroundImage: friendPhoto != null
//                         ? NetworkImage(friendPhoto)
//                         : null,
//                     child: friendPhoto == null
//                         ? Text(
//                             friendName.isNotEmpty
//                                 ? friendName[0].toUpperCase()
//                                 : '?',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           )
//                         : null,
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: GestureDetector(
//                   onTap: onChatTap ?? () {
//                     // Navigate to MessagePage (Chat)
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => MessagePage(
//                           friendId: friendId,
//                           friendName: friendName,
//                           friendPhotoUrl: friendPhoto,
//                         ),
//                       ),
//                     );
//                   },
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Container(
//                         margin: const EdgeInsets.only(top: 12, bottom: 4),
//                         child: Text(
//                           friendName,
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                       SizedBox(
//                         width: 260,
//                         child: Text(
//                           message.content,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             color: message.isRead ? Colors.grey : Colors.white,
//                             fontWeight: message.isRead ? FontWeight.normal : FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               // Unread indicator or time
//               Container(
//                 margin: const EdgeInsets.only(right: 15),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       _formatTime(message.sentAt),
//                       style: const TextStyle(
//                         color: Colors.grey,
//                         fontSize: 12,
//                       ),
//                     ),
//                     if (!message.isRead)
//                       Container(
//                         margin: const EdgeInsets.only(top: 4),
//                         width: 10,
//                         height: 10,
//                         decoration: const BoxDecoration(
//                           color: Colors.blue,
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         // Divider
//         const Divider(
//           height: 1,
//           thickness: 0.5,
//           color: Colors.grey,
//         ),
//       ],
//     );
//   }

//   String _formatTime(DateTime time) {
//     final now = DateTime.now();
//     final difference = now.difference(time);

//     if (difference.inDays > 0) {
//       return '${difference.inDays}d';
//     } else if (difference.inHours > 0) {
//       return '${difference.inHours}h';
//     } else if (difference.inMinutes > 0) {
//       return '${difference.inMinutes}m';
//     } else {
//       return 'Now';
//     }
//   }
// }