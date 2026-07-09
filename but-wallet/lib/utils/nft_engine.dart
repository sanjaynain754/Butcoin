import 'balance_service.dart';

class NFTEngine {
  static final List<Map<String, dynamic>> _nfts = [
    {
      'id': 'NFT-001',
      'name': 'BUT Genesis',
      'description': 'First ever BUT Network NFT',
      'creator': 'system',
      'owner': 'system',
      'price': 100.0,
      'created_at': '2026-01-01',
      'image_url': '',
    },
    {
      'id': 'NFT-002',
      'name': 'Quantum Shield',
      'description': '512-bit security token',
      'creator': 'system',
      'owner': 'system',
      'price': 500.0,
      'created_at': '2026-02-15',
      'image_url': '',
    },
    {
      'id': 'NFT-003',
      'name': 'Crypto Universe',
      'description': 'Blockchain Universe Technology',
      'creator': 'user_demo',
      'owner': 'user_demo',
      'price': 250.0,
      'created_at': '2026-03-10',
      'image_url': '',
    },
  ];

  static int _nextId = 4;

  static Future<List<Map<String, dynamic>>> getAllNFTs() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _nfts;
  }

  static Future<List<Map<String, dynamic>>> getUserNFTs(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _nfts.where((n) => n['owner'] == userId).toList();
  }

  static Future<Map<String, dynamic>> createNFT({
    required String name,
    required String description,
    required String creator,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    if (name.isEmpty || description.isEmpty) {
      return {'success': false, 'error': 'Name and description required'};
    }

    final nftId = 'NFT-${_nextId.toString().padLeft(3, '0')}';
    _nextId++;

    final nftData = {
      'id': nftId,
      'name': name,
      'description': description,
      'creator': creator,
      'owner': creator,
      'price': 50.0,
      'created_at': DateTime.now().toIso8601String().substring(0, 10),
      'image_url': '',
    };

    _nfts.add(nftData);

    return {'success': true, 'nft_data': nftData};
  }

  static Future<Map<String, dynamic>> buyNFT(String nftId, String buyer) async {
    await Future.delayed(const Duration(seconds: 1));

    final index = _nfts.indexWhere((n) => n['id'] == nftId);
    if (index < 0) {
      return {'success': false, 'error': 'NFT not found'};
    }

    final nft = _nfts[index];
    if (nft['owner'] == buyer) {
      return {'success': false, 'error': 'Already owned'};
    }

    final price = nft['price'] as double;
    final priceBites = (price * 1000).toInt();

    // Check balance
    final balance = await BalanceService.getBalance();
    if (balance < priceBites) {
      return {'success': false, 'error': 'Insufficient balance'};
    }

    // Transfer BUT
    await BalanceService.sendTransaction(nft['creator'], priceBites, 10, 'NFT Purchase: $nftId');

    // Transfer ownership
    _nfts[index]['owner'] = buyer;
    _nfts[index]['price'] = price * 1.1; // 10% price increase

    return {'success': true, 'nft': _nfts[index]};
  }

  static Future<Map<String, dynamic>> sellNFT(String nftId, double price) async {
    final index = _nfts.indexWhere((n) => n['id'] == nftId);
    if (index < 0) {
      return {'success': false, 'error': 'NFT not found'};
    }

    _nfts[index]['price'] = price;

    return {'success': true, 'nft': _nfts[index]};
  }
}
