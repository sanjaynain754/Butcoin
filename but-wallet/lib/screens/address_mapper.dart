import 'package:flutter/material.dart';
import '../utils/name_resolver.dart';

class AddressMapper extends StatefulWidget {
  const AddressMapper({super.key});

  @override
  State<AddressMapper> createState() => _AddressMapperState();
}

class _AddressMapperState extends State<AddressMapper> {
  final TextEditingController _hostController = TextEditingController();
  String? _resolvedRoute;
  bool _isResolving = false;
  String? _registrationStatus;

  void _resolveHost() async {
    final host = _hostController.text.trim();
    if (host.isEmpty) return;

    setState(() {
      _isResolving = true;
      _resolvedRoute = null;
    });

    // Simulate network resolution delay
    final route = await NameResolver.lookupCanonicalRoute(host);

    setState(() {
      _isResolving = false;
      _resolvedRoute = route;
    });
  }

  void _registerCurrentHost() async {
    final host = _hostController.text.trim();
    if (host.isEmpty) {
      setState(() {
        _registrationStatus = 'Error: No hostname provided';
      });
      return;
    }

    final success = await NameResolver.bindHostToRoute(host);

    setState(() {
      if (success) {
        _registrationStatus = 'Binding confirmed for: $host';
      } else {
        _registrationStatus = 'Error: Binding conflict detected';
      }
    });

    // Clear status after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _registrationStatus = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Address Mapper'),
        backgroundColor: Colors.indigo[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input field disguised as hostname lookup
            TextField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'Enter Hostname (e.g. rahul)',
                hintText: 'but://',
                prefixIcon: Icon(Icons.dns),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _resolveHost(),
            ),
            const SizedBox(height: 12),

            // Resolve button
            ElevatedButton.icon(
              onPressed: _isResolving ? null : _resolveHost,
              icon: const Icon(Icons.search),
              label: Text(_isResolving ? 'Resolving...' : 'Resolve Hostname'),
            ),
            const SizedBox(height: 8),

            // Register button
            OutlinedButton.icon(
              onPressed: _registerCurrentHost,
              icon: const Icon(Icons.add_link),
              label: const Text('Register This Hostname'),
            ),

            // Status message
            if (_registrationStatus != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _registrationStatus!,
                  style: TextStyle(
                    color: _registrationStatus!.startsWith('Error') ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const Divider(height: 32),

            // Resolved route card
            if (_isResolving)
              const Center(child: CircularProgressIndicator()),

            if (_resolvedRoute != null)
              Card(
                color: Colors.grey[850],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resolved Network Route:',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _resolvedRoute!,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              // Copy to clipboard
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Route copied to buffer')),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 16, color: Colors.white54),
                            label: const Text('Copy', style: TextStyle(color: Colors.white54)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
