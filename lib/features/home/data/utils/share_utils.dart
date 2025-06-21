import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareNewsLink({
  required BuildContext context,
  required String? url,
  required String? title,
}) async {
  if (url == null || url.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Không có liên kết để chia sẻ.')),
    );
    return;
  }

  final box = context.findRenderObject() as RenderBox?;
  final subject = title ?? 'Tin tức được chia sẻ';
  final sharePositionOrigin = box != null ? box.localToGlobal(Offset.zero) & box
      .size : null;

  await Share.share(
    url,
    subject: subject,
    sharePositionOrigin: sharePositionOrigin,
  );
}