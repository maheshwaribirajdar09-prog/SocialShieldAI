import 'package:flutter/material.dart';
import 'database_helper.dart';

class HistoryScreen extends StatefulWidget {
  final int userId;

  const HistoryScreen({
    super.key,
    required this.userId,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  List<Map<String, dynamic>> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final data = await dbHelper.getScanHistory(widget.userId);

    if (!mounted) return;

    setState(() {
      history = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : history.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 70,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 15),
                      Text(
                        'No scan history yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your analyzed profiles will appear here.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final scan = history[index];

                      final prediction =
                          scan['prediction']?.toString() ?? 'UNKNOWN';

                      final confidence =
                          (scan['confidence'] as num?)?.toDouble() ?? 0.0;

                      final confidenceLevel =
                          scan['confidence_level']?.toString() ?? '';

                      final username =
                          scan['profile_username']?.toString() ?? 'Unknown';

                      final riskFactors =
                          scan['risk_factors']?.toString() ?? '';

                      final scannedAt =
                          scan['scanned_at']?.toString() ?? '';

                      final isFake = prediction.toUpperCase() == 'FAKE';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    child: Icon(
                                      isFake
                                          ? Icons.warning
                                          : Icons.verified,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      username,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isFake
                                          ? Colors.red.shade100
                                          : Colors.green.shade100,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      prediction,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isFake
                                            ? Colors.red.shade800
                                            : Colors.green.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              Text(
                                'Confidence: ${confidence.toStringAsFixed(2)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                'Confidence Level: $confidenceLevel',
                              ),

                              if (riskFactors.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text(
                                  'Risk Factors:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(riskFactors),
                              ],

                              if (scannedAt.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Scanned: $scannedAt',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}