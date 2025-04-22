import 'package:flutter/material.dart';
import '../services/friend_service.dart';

class FriendController extends ChangeNotifier {
  final FriendService _friendService = FriendService();
  String? statusMessage;

  Future<void> addFriend(String email) async {
    statusMessage = await _friendService.addFriendByEmail(email);
    notifyListeners();
  }
}
