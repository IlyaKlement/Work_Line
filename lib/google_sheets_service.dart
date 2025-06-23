import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart' show rootBundle;

class GoogleSheetsService {
  final String _spreadsheetId = '1mtkoIgMSQ5WSJcy8zWhbHGndXsC8B8DB81j3YFGXKeE'; 
  late SheetsApi _sheetsApi;

  GoogleSheetsService();

  Future<void> _initialize() async {
    String serviceAccountJson = await rootBundle.loadString('assets/service_account.json');
    
    final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
    
    final authClient = await clientViaServiceAccount(accountCredentials, [SheetsApi.spreadsheetsScope]);
    
    _sheetsApi = SheetsApi(authClient);
  }

  Future<List<Map<String, String>>> getRows(String sheetName) async {
    await _initialize(); 
    
    final response = await _sheetsApi.spreadsheets.values.get(
      _spreadsheetId,
      sheetName, 
    );

    final values = response.values;
    if (values == null || values.isEmpty) return [];

    final headers = List<String>.from(values.first);
    
    return values.skip(1).map((row) {
      final Map<String, String> rowMap = {};
      for (var i = 0; i < headers.length; i++) {
        final key = headers[i];
        final value = i < row.length ? row[i] : '';
        rowMap[key] = value.toString();
      }
      return rowMap;
    }).toList();
  }
}
