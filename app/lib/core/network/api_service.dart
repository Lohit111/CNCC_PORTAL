import 'package:dio/dio.dart';
import 'dio_client.dart';
import '../models/request_model.dart';
import '../models/comment_model.dart';
import '../models/assignment_model.dart';
import '../models/store_request_model.dart';

class ApiService {
  final DioClient _dioClient = DioClient();

  // ==================== AUTH ====================
  
  Future<Map<String, dynamic>> login() async {
    final response = await _dioClient.post('/auth/login');
    return response.data;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dioClient.get('/auth/me');
    return response.data;
  }

  // ==================== USER REQUESTS ====================
  
  Future<RequestModel> createRequest({
    required int mainTypeId,
    required int subTypeId,
    required String description,
  }) async {
    final response = await _dioClient.post(
      '/user/requests',
      data: {
        'main_type_id': mainTypeId,
        'sub_type_id': subTypeId,
        'description': description,
      },
    );
    return RequestModel.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getMyRequests({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dioClient.get(
      '/user/requests',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data;
  }

  Future<RequestModel> getRequestDetail(String requestId) async {
    final response = await _dioClient.get('/user/requests/$requestId');
    return RequestModel.fromJson(response.data);
  }

  Future<CommentModel> replyToRequest(String requestId, String message) async {
    final response = await _dioClient.post(
      '/user/requests/$requestId/reply',
      queryParameters: {'message': message},
    );
    return CommentModel.fromJson(response.data);
  }

  Future<List<CommentModel>> getRequestComments(String requestId) async {
    final response = await _dioClient.get('/user/requests/$requestId/comments');
    return (response.data as List)
        .map((json) => CommentModel.fromJson(json))
        .toList();
  }

  // ==================== ADMIN REQUESTS ====================
  
  Future<Map<String, dynamic>> getAllRequests({
    int page = 1,
    int pageSize = 20,
    String? statusFilter,
  }) async {
    final response = await _dioClient.get(
      '/admin/requests',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (statusFilter != null) 'status_filter': statusFilter,
      },
    );
    return response.data;
  }

  Future<CommentModel> rejectRequest(String requestId, String reason) async {
    final response = await _dioClient.post(
      '/admin/requests/$requestId/reject',
      queryParameters: {'reason': reason},
    );
    return CommentModel.fromJson(response.data);
  }

  Future<CommentModel> adminReplyToRequest(
    String requestId,
    String message,
  ) async {
    final response = await _dioClient.post(
      '/admin/requests/$requestId/reply',
      queryParameters: {'message': message},
    );
    return CommentModel.fromJson(response.data);
  }

  Future<List<AssignmentModel>> assignStaff(
    String requestId,
    List<String> staffIds,
  ) async {
    final response = await _dioClient.post(
      '/admin/requests/$requestId/assign',
      data: {
        'request_id': requestId,
        'staff_ids': staffIds,
      },
    );
    return (response.data as List)
        .map((json) => AssignmentModel.fromJson(json))
        .toList();
  }

  Future<List<AssignmentModel>> reassignStaff({
    required String requestId,
    required List<String> newStaffIds,
    required String reason,
  }) async {
    final response = await _dioClient.post(
      '/admin/requests/reassign',
      data: {
        'request_id': requestId,
        'new_staff_ids': newStaffIds,
        'reason': reason,
      },
    );
    return (response.data as List)
        .map((json) => AssignmentModel.fromJson(json))
        .toList();
  }

  // ==================== ADMIN ROLES ====================
  
  Future<Map<String, dynamic>> uploadRolesCsv(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dioClient.post(
      '/admin/roles/upload-csv',
      data: formData,
    );
    return response.data;
  }

  // ==================== ADMIN TYPES ====================
  
  Future<List<Map<String, dynamic>>> getMainTypes() async {
    final response = await _dioClient.get('/admin/types/main');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> createMainType(String name) async {
    final response = await _dioClient.post(
      '/admin/types/main',
      data: {'name': name},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> createSubType(
    String name,
    int mainTypeId,
  ) async {
    final response = await _dioClient.post(
      '/admin/types/sub',
      data: {'name': name, 'main_type_id': mainTypeId},
    );
    return response.data;
  }

  // ==================== STAFF REQUESTS ====================
  
  Future<Map<String, dynamic>> getAssignedRequests({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dioClient.get(
      '/staff/requests/assigned',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data;
  }

  Future<RequestModel> startRequest(String requestId) async {
    final response = await _dioClient.post('/staff/requests/$requestId/start');
    return RequestModel.fromJson(response.data);
  }

  Future<RequestModel> completeRequest(String requestId) async {
    final response =
        await _dioClient.post('/staff/requests/$requestId/complete');
    return RequestModel.fromJson(response.data);
  }

  Future<CommentModel> forwardRequest(
    String requestId,
    String reason,
  ) async {
    final response = await _dioClient.post(
      '/staff/requests/$requestId/forward',
      queryParameters: {'reason': reason},
    );
    return CommentModel.fromJson(response.data);
  }

  Future<List<CommentModel>> getStaffRequestComments(String requestId) async {
    final response =
        await _dioClient.get('/staff/requests/$requestId/comments');
    return (response.data as List)
        .map((json) => CommentModel.fromJson(json))
        .toList();
  }

  // ==================== STAFF STORE REQUESTS ====================
  
  Future<StoreRequestModel> createEquipmentRequest({
    required String parentRequestId,
    required String description,
  }) async {
    final response = await _dioClient.post(
      '/staff/store-requests',
      data: {
        'parent_request_id': parentRequestId,
        'description': description,
      },
    );
    return StoreRequestModel.fromJson(response.data);
  }

  Future<List<StoreRequestModel>> getMyStoreRequests() async {
    final response = await _dioClient.get('/staff/store-requests');
    return (response.data as List)
        .map((json) => StoreRequestModel.fromJson(json))
        .toList();
  }

  // ==================== STORE REQUESTS ====================
  
  Future<List<StoreRequestModel>> getAllStoreRequests({
    String? statusFilter,
  }) async {
    final response = await _dioClient.get(
      '/store/requests',
      queryParameters: {
        if (statusFilter != null) 'status_filter': statusFilter,
      },
    );
    return (response.data as List)
        .map((json) => StoreRequestModel.fromJson(json))
        .toList();
  }

  Future<StoreRequestModel> approveEquipmentRequest(
    String requestId,
    String comment,
  ) async {
    final response = await _dioClient.post(
      '/store/requests/$requestId/approve',
      data: {'response_comment': comment},
    );
    return StoreRequestModel.fromJson(response.data);
  }

  Future<StoreRequestModel> rejectEquipmentRequest(
    String requestId,
    String comment,
  ) async {
    final response = await _dioClient.post(
      '/store/requests/$requestId/reject',
      data: {'response_comment': comment},
    );
    return StoreRequestModel.fromJson(response.data);
  }

  Future<StoreRequestModel> fulfillEquipmentRequest(String requestId) async {
    final response =
        await _dioClient.post('/store/requests/$requestId/fulfill');
    return StoreRequestModel.fromJson(response.data);
  }
}
