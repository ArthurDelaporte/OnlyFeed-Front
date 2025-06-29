import 'package:flutter/material.dart';

class ReportDialog extends StatefulWidget {
  final String targetId;
  final String type;
  final void Function(String reason) onReport;

  const ReportDialog({
    super.key,
    required this.targetId,
    required this.type,
    required this.onReport,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selectedReason;

  final List<String> reasons = [
    'Contenu inapproprié',
    'Spam',
    'Discours haineux',
    'Usurpation d\'identité',
    'Autre',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Signaler'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: reasons.map((reason) {
          return RadioListTile<String>(
            title: Text(reason),
            value: reason,
            groupValue: _selectedReason,
            onChanged: (value) {
              setState(() {
                _selectedReason = value;
              });
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _selectedReason == null
              ? null
              : () {
                  widget.onReport(_selectedReason!);
                  Navigator.pop(context);
                },
          child: const Text('Envoyer'),
        ),
      ],
    );
  }
}