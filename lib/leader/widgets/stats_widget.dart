
// stats_widget.dart


import 'package:flutter/material.dart';

class StatsWidget extends StatelessWidget {
  final int totalEvents;
  final int totalMembers;
  final int totalAttendees;

  const StatsWidget({
    required this.totalEvents,
    required this.totalMembers,
    required this.totalAttendees,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Sub-Events', totalEvents),
            _buildStatItem('Members', totalMembers),
            _buildStatItem('Attendees', totalAttendees),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 14)),
      ],
    );
  }
}
