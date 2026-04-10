import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NetworkClient {
  static final NetworkClient _instance = NetworkClient._internal();
  factory NetworkClient() => _instance;

  late final Dio _dio;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  NetworkClient._internal() {
    _dio = Dio(BaseOptions(
      // baseUrl: 'http://localhost:8000/api/v1',
      baseUrl: 'http://103.248.208.109:8000/api/v1',
      // baseUrl: 'https://cncc-portal.onrender.com/api/v1',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getFirebaseToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ));
  }

  Future<String?> _getFirebaseToken() async {
    final user = _auth.currentUser;
    return await user?.getIdToken();
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
}
