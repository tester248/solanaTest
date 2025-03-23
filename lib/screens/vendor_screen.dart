import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/auth_service.dart';
import '../models/menu_item.dart';
import '../screens/login_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../services/notification_service.dart';
import '../utils/navigation_utils.dart';
import '../widgets/custom_app_bar.dart';

class VendorScreen extends StatefulWidget {
  @override
  _VendorScreenState createState() => _VendorScreenState();
}

class _VendorScreenState extends State<VendorScreen> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  List<MenuItem> menuItems = [];
  List<MenuItem> cartItems = [];
  double totalAmount = 0.0;
  bool waitingForRFID = false;

  @override
  void initState() {
    super.initState();
    _loadMenu();
    
  }

  Future<void> _loadMenu() async {
    final items = await _authService.getMenuItems();
    setState(() {
      menuItems = items;
    });
  }

  void _startPollingRFID() {
    // Poll the API endpoint every 2 seconds when waiting for RFID
    Future.doWhile(() async {
      if (!waitingForRFID) return false;

      try {
        final response = await _authService.checkRFIDStatus();
        if (response != null) {
          // Show debug toast
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Card Detected! UID: $response'),
              duration: Duration(seconds: 6),
            ),
          );
          
          // Process transaction
          await _processRFIDTransaction(response);
          return false;
        }
      } catch (e) {
        print('Error polling RFID: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      await Future.delayed(Duration(seconds: 7));
      return waitingForRFID;
    });
  }

  void _addToCart(MenuItem item) {
    setState(() {
      final existingItem = cartItems.firstWhere(
        (cartItem) => cartItem.id == item.id,
        orElse: () => item..quantity = 0,
      );

      if (!cartItems.contains(existingItem)) {
        existingItem.quantity = 1;
        cartItems.add(existingItem);
      } else {
        existingItem.quantity++;
      }

      _calculateTotal();
    });
  }

  void _removeFromCart(MenuItem item) {
    setState(() {
      item.quantity--;
      if (item.quantity <= 0) {
        cartItems.remove(item);
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    totalAmount = cartItems.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  Future<void> _processRFIDTransaction(String cardUID) async {
  try {
    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add items to cart')),
      );
      return;
    }

    // First get student data using cardUID
    final studentData = await _authService.getStudentByRFID(cardUID);
    
    if (studentData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Student not found for this card'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await _authService.processRFIDTransaction(
      cardUID,
      totalAmount,
    );

    if (success) {
      final currentUser = await _authService.getCurrentUser();
      final transaction = TransactionModel(
        id: '',  // Firestore will generate this
        studentId: studentData['username'],
        vendorId: currentUser!.id,
        vendorName: currentUser.username,
        amount: totalAmount,
        timestamp: DateTime.now(),
        status: 'completed',
        type: 'purchase',
        items: cartItems.map((item) => TransactionItem(
          itemId: item.id,
          name: item.name,
          price: item.price,
          quantity: item.quantity,
          category: item.category,
        )).toList(),
      );

      print('Debug: Saving transaction with data: ${transaction.toMap()}');

      try {
        await _authService.saveTransaction(transaction);
        
        // Use the notification service
        await _notificationService.sendTransactionSMS(
          studentName: studentData['username'],
          amount: totalAmount,
          vendorName: currentUser.username,
          items: cartItems,
        );
        
        setState(() {
          cartItems.clear();
          totalAmount = 0;
          waitingForRFID = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error saving transaction: $e');
        throw e;
      }
    } else {
      setState(() {
        waitingForRFID = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    print('Error processing transaction: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Transaction failed: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<void> _sendTransactionSMS({
  required String studentName,
  required double amount,
  required String vendorName,
  required List<MenuItem> items,
}) async {
  try {
    const accountSid = 'ACf50c53d912f76e9bd0d05fe0090488e1';
    const authToken = '4e40a346d3746554cd146cd84c643d7e';
    const fromNumber = '+18157066809';
    const toNumber = '+918446872705';

    final url = Uri.parse(
      'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json'
    );

    // Format items list
    final itemsList = items.map((item) => 
      '${item.name} x${item.quantity} - ${item.price * item.quantity} tokens'
    ).join('\n');

    // Create message body
    final messageBody = '''
Your child $studentName has spent $amount tokens at $vendorName.
Purchases:
$itemsList
    ''';

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic ' + 
          base64Encode(utf8.encode('$accountSid:$authToken')),
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'To': toNumber,
        'From': fromNumber,
        'Body': messageBody,
      },
    );

    if (response.statusCode == 201) {
      print('Transaction SMS sent successfully');
    } else {
      print('Failed to send SMS: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  } catch (e) {
    print('Error sending SMS: $e');
  }
}

  // void _navigateToTransactionHistory() {
  //   NavigationUtils.pushScreen(
  //     context,
  //     TransactionHistoryScreen(vendorId: currentUser?.id ?? ''),
  //   );
  // }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    NavigationUtils.pushAndRemoveUntil(context, LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Vendor Dashboard',
        // additionalActions: [
        //   IconButton(
        //     icon: const Icon(Icons.history),
        //     onPressed: () => _showTransactionHistory(),
        //   ),
        // ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Card(
              margin: EdgeInsets.all(8),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Menu Items',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: menuItems.length,
                      itemBuilder: (context, index) {
                        final item = menuItems[index];
                        return ListTile(
                          title: Text(item.name),
                          subtitle: Text('${item.price.toStringAsFixed(2)} tokens'),
                          trailing: IconButton(
                            icon: Icon(Icons.add_circle),
                            onPressed: () => _addToCart(item),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Cart and Total
          Expanded(
            flex: 1,
            child: Card(
              margin: EdgeInsets.all(8),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Current Order',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              // Item details
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '${item.price.toStringAsFixed(2)} tokens',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Quantity controls
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MaterialButton(
                                    minWidth: 30,
                                    height: 30,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: CircleBorder(),
                                    onPressed: () => _removeFromCart(item),
                                    child: Icon(Icons.remove, size: 18),
                                  ),
                                  SizedBox(
                                    width: 30,
                                    child: Text(
                                      '${item.quantity}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  MaterialButton(
                                    minWidth: 30,
                                    height: 30,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: CircleBorder(),
                                    onPressed: () => _addToCart(item),
                                    child: Icon(Icons.add, size: 18),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Total: ${totalAmount.toStringAsFixed(2)} tokens',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: totalAmount > 0 
                            ? () {
                                setState(() => waitingForRFID = true);
                                _startPollingRFID(); // Start polling when button is clicked
                              }
                            : null,
                          child: Text(waitingForRFID 
                            ? 'Waiting for card...' 
                            : 'Process Payment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: waitingForRFID 
                              ? Colors.orange 
                              : Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    setState(() {
      waitingForRFID = false;
    });
    super.dispose();
  }
}