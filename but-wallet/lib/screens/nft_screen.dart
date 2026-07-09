import 'package:flutter/material.dart';
import '../utils/nft_engine.dart';

class NFTScreen extends StatefulWidget {
  const NFTScreen({super.key});

  @override
  State<NFTScreen> createState() => _NFTScreenState();
}

class _NFTScreenState extends State<NFTScreen> {
  List<Map<String, dynamic>> _nfts = [];
  bool _isLoading = true;
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _showCreateForm = false;

  @override
  void initState() {
    super.initState();
    _loadNFTs();
  }

  void _loadNFTs() async {
    setState(() => _isLoading = true);
    final nfts = await NFTEngine.getAllNFTs();
    setState(() {
      _nfts = nfts;
      _isLoading = false;
    });
  }

  void _createNFT() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();

    if (name.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and description required'), backgroundColor: Colors.red),
      );
      return;
    }

    final result = await NFTEngine.createNFT(
      name: name,
      description: desc,
      creator: 'current_user',
    );

    if (result['success'] == true) {
      setState(() {
        _showCreateForm = false;
        _nameController.clear();
        _descController.clear();
      });
      _loadNFTs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFT Created Successfully!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result['error']}'), backgroundColor: Colors.red),
      );
    }
  }

  void _buyNFT(String nftId) async {
    final result = await NFTEngine.buyNFT(nftId, 'current_user');
    if (result['success'] == true) {
      _loadNFTs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFT Purchased!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result['error']}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFT Gallery'),
        backgroundColor: Colors.pink[800],
        actions: [
          IconButton(
            icon: Icon(_showCreateForm ? Icons.grid_view : Icons.add),
            onPressed: () => setState(() => _showCreateForm = !_showCreateForm),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showCreateForm
              ? _buildCreateForm()
              : _buildNFTGrid(),
    );
  }

  Widget _buildCreateForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: Colors.grey[850],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Create New NFT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'NFT Name',
                  hintText: 'e.g. My First NFT',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your NFT...',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _createNFT,
                icon: const Icon(Icons.rocket_launch),
                label: const Text('Mint NFT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _showCreateForm = false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNFTGrid() {
    if (_nfts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No NFTs yet', style: TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showCreateForm = true),
              icon: const Icon(Icons.add),
              label: const Text('Create First NFT'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: _nfts.length,
      itemBuilder: (context, index) {
        final nft = _nfts[index];
        return _buildNFTCard(nft);
      },
    );
  }

  Widget _buildNFTCard(Map<String, dynamic> nft) {
    final isOwned = nft['owner'] == 'current_user';
    final colors = [Colors.purple, Colors.blue, Colors.green, Colors.orange, Colors.red];
    final color = colors[nft['name'].length % colors.length];

    return Card(
      color: Colors.grey[850],
      child: InkWell(
        onTap: () {
          if (!isOwned) {
            _showBuyDialog(nft);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // NFT Image Placeholder
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Center(
                  child: Icon(
                    Icons.image,
                    size: 48,
                    color: color,
                  ),
                ),
              ),
            ),
            // NFT Info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nft['name'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${nft['price']} BUT',
                    style: TextStyle(color: Colors.amber[300], fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (isOwned)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('OWNED', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBuyDialog(Map<String, dynamic> nft) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(nft['name'], style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(nft['description'], style: TextStyle(color: Colors.grey[300])),
            const SizedBox(height: 12),
            Text('Price: ${nft['price']} BUT', style: const TextStyle(color: Colors.amber, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Creator: ${nft['creator']}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _buyNFT(nft['id']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            child: const Text('Buy Now'),
          ),
        ],
      ),
    );
  }
}
