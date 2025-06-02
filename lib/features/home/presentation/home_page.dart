// lib/features/home/presentation/home_page.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import 'package:onlyfeed_frontend/core/widgets/scaffold_with_menubar.dart';
import 'package:onlyfeed_frontend/shared/shared.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleNotifier>().locale;

    return ScaffoldWithMenubar(
      body: Center(
        child: Text("app.welcome".tr()),
      ),
    );
  }
}
