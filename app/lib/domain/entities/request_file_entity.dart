class RequestFile {
  final String id;
  final String requestId;
  final String fileName;
  final String contentType;
  final int fileSize;
  final String url;
  final DateTime createdAt;

  const RequestFile({
    required this.id,
    required this.requestId,
    required this.fileName,
    required this.contentType,
    required this.fileSize,
    required this.url,
    required this.createdAt,
  });

  factory RequestFile.fromJson(Map<String, dynamic> json) {
    return RequestFile(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      fileName: json['file_name'] as String,
      contentType: json['content_type'] as String,
      fileSize: json['file_size'] as int,
      url: json['url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}