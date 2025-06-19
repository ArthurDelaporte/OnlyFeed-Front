import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:onlyfeed_frontend/shared/shared.dart';
import 'package:onlyfeed_frontend/core/widgets/scaffold_with_menubar.dart';

class BecomeCreatorErrorPage extends StatefulWidget {

  const BecomeCreatorErrorPage({super.key});

  @override
  State<BecomeCreatorErrorPage> createState() => _BecomeCreatorErrorPageState();
}
class _BecomeCreatorErrorPageState extends State<BecomeCreatorErrorPage> {

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionNotifier>();
    final user = session.user;
    final username = user?["username"];

    return ScaffoldWithMenubar(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 80),
            SizedBox(height: 20),
            Text(
              "profile_page.error".tr(),
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/${username}'),
              child: Text("user.back_profile".tr()),
            ),
          ],
        ),
      ),
    );
  }
}