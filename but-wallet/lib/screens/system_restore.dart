import 'package:flutter/material.dart';
import '../utils/recovery_engine.dart';

class SystemRestore extends StatefulWidget {
  const SystemRestore({super.key});

  @override
  State<SystemRestore> createState() => _SystemRestoreState();
}

class _SystemRestoreState extends State<SystemRestore> {
  final List<TextEditingController> _guardianControllers = [];
  String _restoreStatus = '';
  bool _isRestoring = false;
  bool _isGuardiansSet = false;

  @override
  void initState() {
    super.initState();
    // Initialize 4 guardian input controllers
    for (int i = 0; i < 4; i++) {
      _guardianControllers.add(TextEditingController());
    }
    _checkGuardianStatus();
  }

  void _checkGuardianStatus() async {
    final isSet = await RecoveryEngine.areGuardiansConfigured();
    setState(() {
      _isGuardiansSet = isSet;
    });
  }

  void _configureGuardians() async {
    final guardians = _guardianControllers
        .map((c) => c.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (guardians.length < 4) {
      setState(() {
        _restoreStatus = 'Error: All 4 recovery nodes required';
      });
      return;
    }

    final success = await RecoveryEngine.configureRecoveryNodes(guardians);

    setState(() {
      if (success) {
        _restoreStatus = 'Recovery nodes configured successfully';
        _isGuardiansSet = true;
      } else {
        _restoreStatus = 'Error: Node configuration failed';
      }
    });

    // Clear status after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _restoreStatus = '';
        });
      }
    });
  }

  void _initiateSystemRestore() async {
    setState(() {
      _isRestoring = true;
      _restoreStatus = 'Requesting node approvals...';
    });

    // This simulates the 20-minute approval window
    final result = await RecoveryEngine.initiateRecoverySequence();

    setState(() {
      _isRestoring = false;
      if (result) {
        _restoreStatus = 'System state restored successfully';
      } else {
        _restoreStatus = 'Recovery denied: Not enough node approvals';
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _guardianControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Restore & Recovery'),
        backgroundColor: Colors.teal[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card disguised as system info
              Card(
                color: Colors.blueGrey[800],
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.cyanAccent),
                          SizedBox(width: 8),
                          Text(
                            'Recovery Node Configuration',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Configure 4 trusted nodes for system state recovery. '
                        'All 4 nodes must approve within a 20-minute window.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Guardian input fields
              if (!_isGuardiansSet) ...[
                const Text(
                  'Enter Recovery Node Addresses:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(4, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextField(
                      controller: _guardianControllers[index],
                      decoration: InputDecoration(
                        labelText: 'Node ${index + 1} (e.g. family member ID)',
                        prefixIcon: Icon(Icons.person, color: Colors.teal[300]),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[850],
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _configureGuardians,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Recovery Configuration'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ] else ...[
                // Already configured - show restore button
                Card(
                  color: Colors.green[900],
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.greenAccent, size: 32),
                        SizedBox(width: 12),
                        Text(
                          'Recovery Nodes: Configured',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isRestoring ? null : _initiateSystemRestore,
                  icon: _isRestoring
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restore),
                  label: Text(_isRestoring ? 'Restoring...' : 'Initiate System Restore'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],

              // Status display
              if (_restoreStatus.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  color: _restoreStatus.startsWith('Error') ||
                          _restoreStatus.contains('denied')
                      ? Colors.red[900]
                      : Colors.green[900],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      _restoreStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Approval simulation panel
              if (_isGuardiansSet)
                Card(
                  color: Colors.grey[850],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Node Approval Simulator',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Use this to simulate guardian responses',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                RecoveryEngine.simulateNodeApproval(0);
                                setState(() {
                                  _restoreStatus = 'Node 1: Approved';
                                });
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text('Approve N1'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                RecoveryEngine.simulateNodeApproval(1);
                                setState(() {
                                  _restoreStatus = 'Node 2: Approved';
                                });
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text('Approve N2'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                RecoveryEngine.simulateNodeApproval(2);
                                setState(() {
                                  _restoreStatus = 'Node 3: Approved';
                                });
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text('Approve N3'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                RecoveryEngine.simulateNodeApproval(3);
                                setState(() {
                                  _restoreStatus = 'Node 4: Approved';
                                });
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text('Approve N4'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              RecoveryEngine.simulateNodeRejection();
                              setState(() {
                                _restoreStatus = 'Recovery denied: Node rejected';
                              });
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Simulate Node Rejection'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
