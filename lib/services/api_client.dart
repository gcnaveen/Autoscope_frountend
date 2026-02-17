// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class ApiException implements Exception {
//   final int statusCode;
//   final String message;
//   final dynamic body;

//   ApiException(this.statusCode, this.message, {this.body});

//   @override
//   String toString() => 'ApiException($statusCode): $message';
// }

// class ApiClient {
//   ApiClient({
//     required this.baseUrl,
//   });

//   final String baseUrl;

//   String? _token;

//   void setToken(String? token) {
//     _token = token;
//   }

//   bool _shouldAttachAuth(String path) {
//     // Add all public endpoints here
//     const publicPaths = <String>{
//       '/auth/login',
//       '/auth/register',
//     };

//     // If your API uses query params, strip them
//     final cleanPath = path.split('?').first;
//     return !publicPaths.contains(cleanPath);
//   }

//   Uri _uri(String path) {
//     // supports absolute URL too, but prefer relative paths
//     if (path.startsWith('http://') || path.startsWith('https://')) {
//       return Uri.parse(path);
//     }
//     return Uri.parse('$baseUrl$path');
//   }

//   Map<String, String> _headers({required bool auth}) {
//     final h = <String, String>{
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//     };

//     if (auth && _token != null && _token!.isNotEmpty) {
//       h['Authorization'] = 'Bearer $_token';
//     }
//     return h;
//   }

//   dynamic _decode(http.Response res) {
//     if (res.body.isEmpty) return null;
//     try {
//       return jsonDecode(res.body);
//     } catch (_) {
//       return res.body;
//     }
//   }

//   void _throwIfNotOk(http.Response res, dynamic decoded) {
//     if (res.statusCode >= 200 && res.statusCode < 300) return;

//     String msg = 'Request failed';
//     if (decoded is Map && decoded['message'] != null) {
//       msg = decoded['message'].toString();
//     } else if (decoded is String && decoded.isNotEmpty) {
//       msg = decoded;
//     }

//     throw ApiException(res.statusCode, msg, body: decoded);
//   }

//   Future<dynamic> getJson(String path) async {
//     final auth = _shouldAttachAuth(path);
//     final res = await http.get(_uri(path), headers: _headers(auth: auth));
//     final decoded = _decode(res);
//     _throwIfNotOk(res, decoded);
//     return decoded;
//   }

//   Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
//     final auth = _shouldAttachAuth(path);
//     final res = await http.post(
//       _uri(path),
//       headers: _headers(auth: auth),
//       body: jsonEncode(body),
//     );
//     final decoded = _decode(res);
//     _throwIfNotOk(res, decoded);
//     return decoded;
//   }

//   Future<dynamic> putJson(String path, Map<String, dynamic> body) async {
//     final auth = _shouldAttachAuth(path);
//     final res = await http.put(
//       _uri(path),
//       headers: _headers(auth: auth),
//       body: jsonEncode(body),
//     );
//     final decoded = _decode(res);
//     _throwIfNotOk(res, decoded);
//     return decoded;
//   }

//   Future<dynamic> deleteJson(String path) async {
//     final auth = _shouldAttachAuth(path);
//     final res = await http.delete(_uri(path), headers: _headers(auth: auth));
//     final decoded = _decode(res);
//     _throwIfNotOk(res, decoded);
//     return decoded;
//   }

//   /// ✅ RAW GET (for PDF / binary)
//   Future<http.Response> getBytes(
//     String path, {
//     Map<String, String>? extraHeaders,
//   }) async {
//     final auth = _shouldAttachAuth(path);
//     // start with normal headers but override Accept for pdf in caller if needed
//     final h = _headers(auth: auth);
//     if (extraHeaders != null) {
//       h.addAll(extraHeaders);
//     }

//     // IMPORTANT: For binary download, Content-Type header is not required,
//     // but keeping it won't usually break. If your backend complains, remove it here.
//     final res = await http.get(_uri(path), headers: h);

//     // if not ok, decode JSON/text error and throw ApiException
//     if (res.statusCode < 200 || res.statusCode >= 300) {
//       final decoded = _decode(res);
//       _throwIfNotOk(res, decoded);
//     }

//     return res;
//   }
  
// }


import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic body;

  ApiException(this.statusCode, this.message, {this.body});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
  });

  final String baseUrl;

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  bool _shouldAttachAuth(String path) {
    // Add all public endpoints here
    const publicPaths = <String>{
      '/auth/login',
      '/auth/register',
    };

    // If your API uses query params, strip them
    final cleanPath = path.split('?').first;
    return !publicPaths.contains(cleanPath);
  }

  Uri _uri(String path) {
    // supports absolute URL too, but prefer relative paths
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path);
    }
    return Uri.parse('$baseUrl$path');
  }

  Map<String, String> _headers({required bool auth}) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth && _token != null && _token!.isNotEmpty) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  dynamic _decode(http.Response res) {
    if (res.body.isEmpty) return null;
    try {
      return jsonDecode(res.body);
    } catch (_) {
      return res.body;
    }
  }

  void _throwIfNotOk(http.Response res, dynamic decoded) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;

    String msg = 'Request failed';
    if (decoded is Map && decoded['message'] != null) {
      msg = decoded['message'].toString();
    } else if (decoded is String && decoded.isNotEmpty) {
      msg = decoded;
    }

    throw ApiException(res.statusCode, msg, body: decoded);
  }

  Future<dynamic> getJson(String path) async {
    final auth = _shouldAttachAuth(path);
    final res = await http.get(_uri(path), headers: _headers(auth: auth));
    final decoded = _decode(res);
    _throwIfNotOk(res, decoded);
    return decoded;
  }

  Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    final auth = _shouldAttachAuth(path);
    final res = await http.post(
      _uri(path),
      headers: _headers(auth: auth),
      body: jsonEncode(body),
    );
    final decoded = _decode(res);
    _throwIfNotOk(res, decoded);
    return decoded;
  }

  Future<dynamic> putJson(String path, Map<String, dynamic> body) async {
    final auth = _shouldAttachAuth(path);
    final res = await http.put(
      _uri(path),
      headers: _headers(auth: auth),
      body: jsonEncode(body),
    );
    final decoded = _decode(res);
    _throwIfNotOk(res, decoded);
    return decoded;
  }

  Future<dynamic> deleteJson(String path) async {
    final auth = _shouldAttachAuth(path);
    final res = await http.delete(_uri(path), headers: _headers(auth: auth));
    final decoded = _decode(res);
    _throwIfNotOk(res, decoded);
    return decoded;
  }

  /// ✅ RAW GET (for PDF / binary)
  Future<http.Response> getBytes(
    String path, {
    Map<String, String>? extraHeaders,
  }) async {
    final auth = _shouldAttachAuth(path);

    // ✅ PDF/Binary download: DO NOT send Content-Type on GET.
    // It can trigger CORS preflight in browsers and break downloads.
    final h = _headers(auth: auth);
    h.remove('Content-Type');

    // start with normal headers but override Accept for pdf in caller if needed
    if (extraHeaders != null) {
      h.addAll(extraHeaders);
    }

    final res = await http.get(_uri(path), headers: h);

    // if not ok, decode JSON/text error and throw ApiException
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final decoded = _decode(res);
      _throwIfNotOk(res, decoded);
    }

    return res;
  }
}

