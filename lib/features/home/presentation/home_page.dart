// lib/features/home/presentation/home_page.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:onlyfeed_frontend/core/widgets/scaffold_with_header.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithHeader(
      body: Center(
        child: Text(context.tr('app.welcome')),
      ),
    );
  }
}
