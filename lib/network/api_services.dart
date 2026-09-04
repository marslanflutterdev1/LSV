import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:satellite_view/network/custom_exception.dart';

class ApiServices {
  Future<dynamic> postRequest(
      String url, {
        Map<String, String>? headers,
        Map<String, dynamic>? body,
      }) async {
    try {
      headers = (headers != null && headers.isNotEmpty) ? headers : {"Content-Type": "application/json", "Accept": "application/json"};
      final http.Response response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 60));
      log("Status Code => ${response.statusCode} - Body => ${response.body}");
      if (response.statusCode == 200) {
        try{
          final data = jsonDecode(response.body);
          log("Response Status Code ==>> ${response.statusCode}");
          if (data is List) {
            log("Response in List");
            return data;
          } else if (data is Map<String, dynamic>) {
            log("Response in Map");
            return data;
          } else {
            log("Unknown Format");
            throw ParsingException("Unknown response format ${response.statusCode}");
          }
        }catch (e){
          throw ParsingException("Invalid JSON format ${response.statusCode}");
        }
      }else if (response.statusCode >= 300 && response.statusCode < 400) {
        throw RedirectionException(response.statusCode);
      }
      else if (response.statusCode >= 400 && response.statusCode < 500) {
        final message = jsonDecode(response.body) as Map<String, dynamic>;
        throw ClientErrorException(response.statusCode, message['message']);
      } else if (response.statusCode >= 500) {
        throw ServerErrorException(response.statusCode);
      } else {
        throw UnknownException(response.statusCode);
      }
    }on SocketException catch (e, s) {
      log("Stack Trace Line = $s");
      log('Socker Error: $e');
      throw NetworkException("No internet connection");
    } on TimeoutException catch (e, s) {
      log("Stack Trace Line = $s");
      log('Request Timeout: $e');
      throw TimeoutApiException("Request timed out");
    } on http.ClientException catch (e, s) {
      log("Stack Trace Line = $s");
      log('Client Error: $e');
      throw NetworkException(e.message);
    }
  }

  Future<dynamic> getRequest(String url, {Map<String, String>? headers}) async {
    try {
      headers = (headers != null && headers.isNotEmpty)
          ? headers
          : {"Content-Type": "application/json", "Accept": "application/json"};
      final http.Response response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log("Response StatusCode ==>> ${response.statusCode}");
        if (data is List) {
          log("Response in List");
          return data;
        } else if (data is Map<String, dynamic>) {
          log("Response in Map");
          return data;
        } else {
          log("Unknown Format");
          throw Exception("Unknown format of response");
        }
      } else {
        log("HTTP Error: ${response.statusCode}");
        throw Exception('HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } on http.ClientException catch (e, s) {
      /// Handle client-side errors (e.g., no internet connection)
      log("Stack Trace Line = $s");
      log('Client error: $e');
      throw Exception('Client error: $e');
    } on WebSocketException catch (e, s) {
      /// Handle WebSocket errors
      log("Stack Trace Line = $s");
      log('WebSocket error: $e');
      throw Exception('WebSocket error: $e');
    } on TimeoutException catch (e, s) {
      /// Handle timeout errors
      log("Stack Trace Line = $s");
      log('Request timeout: $e');
      throw Exception('Request timeout: $e');
    } on Exception catch (e, s) {
      log('Stack Trace Line = $s');
      log('Unknown Error Occur = $e');
      throw Exception('Unknown Error Occur = $e');
    }
  }
}