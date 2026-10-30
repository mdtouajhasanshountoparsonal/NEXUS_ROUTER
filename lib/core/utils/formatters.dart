import 'package:intl/intl.dart';

String formatMbps(double value) => value.toStringAsFixed(1);

String formatUptime(Duration duration) {
  final days = duration.inDays;
  final hours = duration.inHours % 24;
  final minutes = duration.inMinutes % 60;
  if (days > 0) return '${days}d ${hours}h';
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m';
}

String timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 45) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('d MMM').format(time);
}

String formatDateTime(DateTime time) {
  return DateFormat('d MMM yyyy, h:mm a').format(time);
}

String formatTime(DateTime time) => DateFormat('h:mm a').format(time);
