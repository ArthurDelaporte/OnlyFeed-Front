// lib/features/admin/presentation/admin_dashboard_page.dart
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:onlyfeed_frontend/shared/shared.dart';
import 'package:onlyfeed_frontend/core/widgets/scaffold_with_menubar.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleNotifier>().locale;

    return ScaffoldWithMenubar(
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "admin.dashboard_title".tr(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("admin.stats".tr(), style: Theme.of(context).textTheme.titleMedium),
                      TextButton.icon(
                        onPressed: () => context.go('/admin/dashboard'),
                        icon: Icon(Icons.arrow_forward),
                        label: Text("core.see_more".tr()),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  isMobile
                      ? Column(
                    children: [
                      Placeholder(fallbackHeight: 200),
                      SizedBox(height: 12),
                      Placeholder(fallbackHeight: 200),
                    ],
                  )
                      : Row(
                    children: [
                      Expanded(child: Placeholder(fallbackHeight: 200)),
                      SizedBox(width: 12),
                      Expanded(child: Placeholder(fallbackHeight: 200)),
                    ],
                  ),

                  SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("admin.recent_reports".tr(), style: Theme.of(context).textTheme.titleMedium),
                      TextButton.icon(
                        onPressed: () => context.go('/admin/dashboard'),
                        icon: Icon(Icons.arrow_forward),
                        label: Text("core.see_more".tr()),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    height: 300,
                    width: double.infinity,
                    child: Placeholder(),
                  ),

                  SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("admin.users_list".tr(), style: Theme.of(context).textTheme.titleMedium),
                      TextButton.icon(
                        onPressed: () => context.go('/admin/dashboard'),
                        icon: Icon(Icons.arrow_forward),
                        label: Text("core.see_more".tr()),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    height: 400,
                    width: double.infinity,
                    child: Placeholder(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
