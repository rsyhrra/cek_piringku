import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/badge_model.dart';
import '../constants/dummy_data.dart';
import 'database_service.dart';

class RewardService extends ChangeNotifier {
  User _user = DummyData.currentUser;
  List<BadgeModel> _badges = DummyData.allBadges;
  final DatabaseService _db = DatabaseService();
  
  User get user => _user;
  List<BadgeModel> get badges => _badges;

  RewardService() {
    refreshUserData();
  }

  Future<void> refreshUserData() async {
    final userFromDb = await _db.getUser();
    if (userFromDb != null) {
      _user = userFromDb;
    } else {
      _user = DummyData.currentUser; // Fallback
    }
    notifyListeners();
  }

  Future<void> _saveData() async {
    await _db.updateUser(_user);
  }

  Future<void> logout() async {
    // For local SQLite, we could clear the tables or just reset the current session
    // For this simple implementation, we'll just go back to AuthScreen
    _user = DummyData.currentUser;
    notifyListeners();
  }

  Future<void> addScanReward(bool isStandardMet) async {
    int pointsEarned = 10;
    
    if (isStandardMet) {
      pointsEarned += 20;
    }

    int newStreak = _user.streak + 1;
    
    if (newStreak == 3) {
      pointsEarned += 30;
    } else if (newStreak == 7) {
      pointsEarned += 70;
    }

    _user = _user.copyWith(
      points: _user.points + pointsEarned,
      streak: newStreak,
      totalScans: _user.totalScans + 1,
    );

    await _saveData();
    await _checkBadges();
    notifyListeners();
  }

  Future<void> _checkBadges() async {
    if (_user.totalScans >= 30) {
      _unlockBadge('5');
    }
    if (_user.streak >= 7) {
      _unlockBadge('4');
    }
  }

  void _unlockBadge(String id) {
    final index = _badges.indexWhere((b) => b.id == id);
    if (index != -1 && !_badges[index].isUnlocked) {
      _badges[index] = _badges[index].copyWith(isUnlocked: true);
    }
  }
}
