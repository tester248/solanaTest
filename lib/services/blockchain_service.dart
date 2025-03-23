import 'package:http/http.dart' as http;
import 'dart:convert';

class BlockchainService {
  static const String baseUrl = 'https://solanadevtest.onrender.com/api';
  static const String mintingWalletAddress = 'kiQR5Wuj9qHegtDnH1aumUX9SbDt5haN6kirmUrStdo';

  Future<double> getWalletBalance(String walletAddress) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/equinoxbalance/$walletAddress')
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['balance'] ?? 0).toDouble();
      }
      throw Exception('Failed to fetch balance: ${response.statusCode}');
    } catch (e) {
      print('Error fetching balance: $e');
      rethrow;
    }
  }

  Future<bool> transferTokens({
    required List<int> payerSecretArray,
    required String recipientWalletAddress,
    required double amount,
  }) async {
    try {
      print('Debug: Starting token transfer');
      print('Debug: Recipient address: $recipientWalletAddress');
      print('Debug: Amount: $amount');

      final response = await http.post(
        Uri.parse('$baseUrl/transferequinox'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'payerSecretArray': payerSecretArray,
          'recipientWalletAddress': recipientWalletAddress,
          'amount': amount.toInt(), // Convert to integer
        }),
      );

      print('Debug: Transfer API response status: ${response.statusCode}');
      print('Debug: Transfer API response body: ${response.body}');

      if (response.statusCode != 200) {
        print('Debug: Transfer failed with status ${response.statusCode}');
        return false;
      }

      // Verify the transfer by checking new balance
      await Future.delayed(Duration(seconds: 2)); // Wait for blockchain update
      final newBalance = await getWalletBalance(recipientWalletAddress);
      print('Debug: New recipient balance: $newBalance');

      return true;
    } catch (e) {
      print('Error in transferTokens: $e');
      return false;
    }
  }

  Future<bool> buyTokens({
    required String recipientWalletAddress,
    required double amount,
  }) async {
    try {
      print('Debug: Attempting to buy $amount tokens');
      final response = await http.post(
        Uri.parse('$baseUrl/buyequinox'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'recipientWalletAddress': recipientWalletAddress,
          'amount': amount.toInt(), // API expects integer
        }),
      );

      print('Debug: Buy response: ${response.statusCode} - ${response.body}');
      if (response.statusCode != 200) {
        throw Exception('Buy tokens failed: ${response.body}');
      }

      return true;
    } catch (e) {
      print('Error buying tokens: $e');
      rethrow;
    }
  }

  Future<bool> updateWalletBalance(
    String walletAddress,
    String privateKey,
    double currentBalance,
    double newBalance,
  ) async {
    try {
      
      final difference = newBalance - await getWalletBalance(walletAddress);
      print('Debug: Starting balance update');
      print('Debug: Current balance: $currentBalance');
      print('Debug: Target balance: $newBalance');
      print('Debug: Difference: $difference');

      // Get initial balance to verify
      final initialBalance = await getWalletBalance(walletAddress);
      print('Debug: Initial verified balance: $initialBalance');

      if (difference > 0) {
        // Adding tokens
        print('Debug: Adding ${difference.toInt()} tokens');
        bool buySuccess = await buyTokens(
          recipientWalletAddress: walletAddress,
          amount: difference,
        );
        
        if (!buySuccess) {
          print('Debug: Buy tokens failed');
          return false;
        }

        // Wait for transaction to process
        await Future.delayed(Duration(seconds: 10));
        
        // Verify new balance
        final afterBuyBalance = await getWalletBalance(walletAddress);
        print('Debug: Balance after buying: $afterBuyBalance');
        
        if (afterBuyBalance < newBalance) {
          print('Debug: Balance verification failed after buying');
          return false;
        }
      } else if (difference < 0) {
        List<int> payerSecretArray2 = privateKey.split(',').map(int.parse).toList();
        // Removing tokens
        print('Debug: Removing ${difference.abs().toInt()} tokens');
        bool transferSuccess = await transferTokens(
          payerSecretArray: payerSecretArray2,
          recipientWalletAddress: mintingWalletAddress,
          amount: difference.abs(),
        );

        if (!transferSuccess) {
          print('Debug: Transfer tokens failed');
          return false;
        }

        // Wait for transaction to process
        await Future.delayed(Duration(seconds: 10));
        
        // Verify new balance
        final afterTransferBalance = await getWalletBalance(walletAddress);
        print('Debug: Balance after transfer: $afterTransferBalance');
        
        if (afterTransferBalance > newBalance) {
          print('Debug: Balance verification failed after transfer');
          return false;
        }
      }

      // Final balance verification
      final finalBalance = await getWalletBalance(walletAddress);
      print('Debug: Final balance: $finalBalance');
      
      // Allow small rounding differences
      if ((finalBalance - newBalance).abs() > 0.01) {
        print('Debug: Final balance verification failed');
        return false;
      }

      print('Debug: Balance update completed successfully');
      return true;
    } catch (e) {
      print('Error updating wallet balance: $e');
      return false;
    }
  }
}