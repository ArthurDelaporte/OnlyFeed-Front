// lib/core/pages/not_found_page.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyfeed_frontend/core/widgets/scaffold_with_menubar.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithMenubar(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              SizedBox(height: 16),
              Text(
                "404",
                style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.red),
              ),
              SizedBox(height: 8),
              Text(
                "core.not_found".tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: Icon(Icons.home),
                label: Text("core.go_home".tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}