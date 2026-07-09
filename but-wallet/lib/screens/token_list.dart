import 'package:flutter/material.dart';
import '../utils/token_manager.dart';
import 'token_create.dart';

class TokenListScreen extends StatefulWidget {
  const TokenListScreen({super.key});

  @override
  State<TokenListScreen> createState() => _TokenListScreenState();
}

class _TokenListScreenState extends State<TokenListScreen> {
  List<Map<String, dynamic>> _tokens = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTokens();
  }

  void _loadTokens() async {
    setState(() => _isLoading = true);
    final tokens = await TokenManager.getAllTokens();
    setState(() {
      _tokens = tokens;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Tokens'),
        backgroundColor: Colors.teal[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Token',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TokenCreateScreen()),
              );
              _loadTokens();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tokens.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.token, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No tokens yet',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TokenCreateScreen(),
                            ),
                          );
                          _loadTokens();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create First Token'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadTokens(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _tokens.length,
                    itemBuilder: (context, index) {
                      final token = _tokens[index];
                      return _buildTokenCard(token);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TokenCreateScreen()),
          );
          _loadTokens();
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTokenCard(Map<String, dynamic> token) {
    final isVerified = token['verified'] == true;
    final isFeatured = token['featured'] == true;

    return Card(
      color: isFeatured ? Colors.amber[900] : Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isFeatured ? Colors.amber : Colors.teal,
          child: Text(
            token['symbol'].toString().substring(0, 2),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Text(
              token['name'],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            if (isVerified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified, color: Colors.blue, size: 16),
            ],
            if (isFeatured) ...[
              const SizedBox(width: 4),
              const Icon(Icons.diamond, color: Colors.amber, size: 16),
            ],
          ],
        ),
        subtitle: Text(
          '${token['symbol']} • Supply: ${token['total_supply']}',
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        trailing: Text(
          token['tier'].toString().toUpperCase(),
          style: TextStyle(
            color: isFeatured ? Colors.amber : Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
