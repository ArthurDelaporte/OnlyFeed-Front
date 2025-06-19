import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import 'package:onlyfeed_frontend/core/widgets/scaffold_with_menubar.dart';
import 'package:onlyfeed_frontend/shared/shared.dart';

class BecomeCreatorSuccessPage extends StatefulWidget {
  final String? accountId;

  const BecomeCreatorSuccessPage({super.key, required this.accountId});

  @override
  State<BecomeCreatorSuccessPage> createState() => _BecomeCreatorSuccessPageState();
}

class _BecomeCreatorSuccessPageState extends State<BecomeCreatorSuccessPage> {
  final _dio = DioClient().dio;
  bool _loading = true;
  String? _error;
  bool _hasHandled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasHandled) {
      _hasHandled = true;
      _handleCompleteConnect();
    }
  }

  Future<void> _handleCompleteConnect() async {
    final accountId = GoRouterState.of(context).uri.queryParameters['account_id'];
    if (accountId == null) {
      setState(() {
        _error = "Paramètre manquant";
        _loading = false;
      });
      return;
    }

    try {
      await _dio.get("/api/stripe/complete-connect", queryParameters: {
        "account_id": accountId,
      });

      await context.read<SessionNotifier>().refreshUser();

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Une erreur est survenue : $e";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleNotifier>().locale;
    final session = context.watch<SessionNotifier>();
    final user = session.user;
    final username = user?["username"];
    if (_loading) {
      return ScaffoldWithMenubar(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return ScaffoldWithMenubar(
        body: Center(child: Text(_error!)),
      );
    }

    return ScaffoldWithMenubar(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
            SizedBox(height: 20),
            Text("profile_page.success".tr(), style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/$username'),
              child: Text("user.back_profile".tr()),
            )
          ],
        ),
      ),
    );
  }
}