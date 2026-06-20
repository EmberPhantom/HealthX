import 'package:intl/intl.dart';

int calculateScore(int steps, int water, String sleepStr, {int stepGoal = 8000, int waterGoal = 2500}) {
  int score = 60;
  score += (steps / stepGoal * 15).clamp(0, 15).toInt();
  score += (water / waterGoal * 15).clamp(0, 15).toInt();
  if (sleepStr != '0h 0m') {
    score += 10;
  }
  return score.clamp(0, 100);
}

String timeAgo(DateTime dt, {bool showDate = true}) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return showDate ? DateFormat('MMM d, h:mm a').format(dt) : DateFormat('h:mm a').format(dt);
}
