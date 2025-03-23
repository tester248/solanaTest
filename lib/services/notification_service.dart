import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/menu_item.dart';

class NotificationService {
  Future<void> sendTransactionSMS({
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

      final itemsList = items.map((item) => 
        '${item.name} x${item.quantity} - ${item.price * item.quantity} tokens'
      ).join('\n');

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
}