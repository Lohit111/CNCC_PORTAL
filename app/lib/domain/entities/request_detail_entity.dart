import 'package:cncc_portal/domain/entities/request_entity.dart';
import 'package:cncc_portal/domain/entities/track_entity.dart';
import 'package:cncc_portal/domain/entities/assignment_entity.dart';
import 'package:cncc_portal/domain/entities/store_request_entity.dart';
import 'package:cncc_portal/domain/entities/user_entity.dart';

/// Composite entity returned by all request list/detail endpoints.
/// Contains the full context needed to render a request without additional queries.
class RequestDetail {
  final Request request;
  final List<Track> timeline;
  final List<Assignment> assignments;
  final List<StoreRequest> storeRequests;
  final Map<String, User> users;

  RequestDetail({
    required this.request,
    required this.timeline,
    required this.assignments,
    required this.storeRequests,
    required this.users,
  });

  factory RequestDetail.fromJson(Map<String, dynamic> json) {
    final usersMap = (json['users'] as Map<String, dynamic>? ?? {}).map(
      (key, value) =>
          MapEntry(key, User.fromJson(value as Map<String, dynamic>)),
    );

    return RequestDetail(
      request: Request.fromJson(json['request'] as Map<String, dynamic>),
      timeline: (json['timeline'] as List<dynamic>? ?? [])
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList(),
      assignments: (json['assignments'] as List<dynamic>? ?? [])
          .map((e) => Assignment.fromJson(e as Map<String, dynamic>))
          .toList(),
      storeRequests: (json['store_requests'] as List<dynamic>? ?? [])
          .map((e) => StoreRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
      users: usersMap,
    );
  }

  /// Convenience: get a user by ID from the embedded users map
  User? getUser(String userId) => users[userId];

  /// Get the raiser's name or email as fallback
  String get raiserDisplay {
    final u = users[request.raisedBy];
    return u?.name ?? u?.email ?? request.raisedBy;
  }
}

/// Composite entity for paginated request list responses
class RequestPage {
  final List<RequestDetail> requests;
  final int total;
  final int page;
  final int pages;

  RequestPage({
    required this.requests,
    required this.total,
    required this.page,
    required this.pages,
  });

  factory RequestPage.fromJson(Map<String, dynamic> json) {
    return RequestPage(
      requests: (json['requests'] as List<dynamic>? ?? [])
          .map((e) => RequestDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      pages: json['pages'] as int,
    );
  }
}
