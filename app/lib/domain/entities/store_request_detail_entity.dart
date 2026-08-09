import 'package:cncc_portal/domain/entities/store_request_entity.dart';
import 'package:cncc_portal/domain/entities/request_entity.dart';
import 'package:cncc_portal/domain/entities/track_entity.dart';
import 'package:cncc_portal/domain/entities/assignment_entity.dart';
import 'package:cncc_portal/domain/entities/user_entity.dart';

/// Parent request context embedded in store request detail responses.
/// Excludes store_requests since that is provided at the top level.
class ParentRequestDetail {
  final Request request;
  final List<Track> timeline;
  final List<Assignment> assignments;
  final Map<String, User> users;

  ParentRequestDetail({
    required this.request,
    required this.timeline,
    required this.assignments,
    required this.users,
  });

  factory ParentRequestDetail.fromJson(Map<String, dynamic> json) {
    final usersMap = (json['users'] as Map<String, dynamic>? ?? {}).map(
      (key, value) =>
          MapEntry(key, User.fromJson(value as Map<String, dynamic>)),
    );

    return ParentRequestDetail(
      request: Request.fromJson(json['request'] as Map<String, dynamic>),
      timeline: (json['timeline'] as List<dynamic>? ?? [])
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList(),
      assignments: (json['assignments'] as List<dynamic>? ?? [])
          .map((e) => Assignment.fromJson(e as Map<String, dynamic>))
          .toList(),
      users: usersMap,
    );
  }

  User? getUser(String userId) => users[userId];
}

/// Composite entity returned by store list endpoints.
class StoreRequestDetail {
  final StoreRequest storeRequest;
  final ParentRequestDetail? parentRequest;

  StoreRequestDetail({
    required this.storeRequest,
    this.parentRequest,
  });

  factory StoreRequestDetail.fromJson(Map<String, dynamic> json) {
    return StoreRequestDetail(
      storeRequest:
          StoreRequest.fromJson(json['store_request'] as Map<String, dynamic>),
      parentRequest: json['parent_request'] != null
          ? ParentRequestDetail.fromJson(
              json['parent_request'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Paginated store request list response
class StoreRequestPage {
  final List<StoreRequestDetail> storeRequests;
  final int total;
  final int page;
  final int pages;

  StoreRequestPage({
    required this.storeRequests,
    required this.total,
    required this.page,
    required this.pages,
  });

  factory StoreRequestPage.fromJson(Map<String, dynamic> json) {
    return StoreRequestPage(
      storeRequests: (json['store_requests'] as List<dynamic>? ?? [])
          .map((e) => StoreRequestDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      pages: json['pages'] as int,
    );
  }
}
