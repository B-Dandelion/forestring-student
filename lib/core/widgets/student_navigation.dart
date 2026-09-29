import 'package:flutter/material.dart';

import '../theme/forestring_theme.dart';

class StudentAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const StudentAppBar({
    super.key,
    this.title = '포레스트링 수강생',
  });

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: primaryColor,
      iconTheme: const IconThemeData(color: Colors.white),
      centerTitle: true,
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'ELAND',
          fontWeight: FontWeight.w500,
          fontSize: 20,
        ),
      ),
    );
  }
}
