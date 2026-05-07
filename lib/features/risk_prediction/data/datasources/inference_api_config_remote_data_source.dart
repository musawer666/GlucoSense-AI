import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exceptions.dart';

/// Reads remote inference API settings from Firestore.
abstract class InferenceApiConfigRemoteDataSource {
  /// Resolves [base_url] from Firestore (see implementation for supported paths).
  Future<String> fetchBaseUrl();
}

class InferenceApiConfigRemoteDataSourceImpl
    implements InferenceApiConfigRemoteDataSource {
  InferenceApiConfigRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _baseUrlFieldSnake = 'base_url';
  static const _baseUrlFieldCamel = 'baseUrl';

  static const List<(String collection, String documentId)> _docPaths = [
    ('api_config', 'inference_api'),
    // Common typo in Firebase (missing "n") — matches this project's console name.
    ('api_cofig', 'inference_api'),
    ('ai', 'inference_api'),
    ('ai', 'inferenceApi'),
    ('api_config', 'ai'),
  ];

  static const List<String> _collectionsToScan = [
    'api_config',
    'api_cofig',
    'ai',
  ];

  @override
  Future<String> fetchBaseUrl() async {
    const source = GetOptions(source: Source.server);

    for (final (collection, docId) in _docPaths) {
      final snap =
          await _firestore.collection(collection).doc(docId).get(source);
      if (snap.exists) {
        final url = _parseBaseUrl(snap.data());
        if (url != null) return url;
      }
    }

    for (final collection in _collectionsToScan) {
      final url = await _firstBaseUrlInCollection(collection, source);
      if (url != null) return url;
    }

    throw const ServerException(
      'Could not find a base URL for the inference API. In Firestore, add '
      'string field base_url on inference_api under api_config (or api_cofig), '
      'or ai/inference_api. Use the same Firebase project as this app.',
      statusCode: 404,
    );
  }

  /// Picks the first document in [collection] that defines a usable base URL.
  Future<String?> _firstBaseUrlInCollection(
    String collection,
    GetOptions source,
  ) async {
    final qs = await _firestore.collection(collection).limit(25).get(source);
    for (final doc in qs.docs) {
      final url = _parseBaseUrl(doc.data());
      if (url != null) return url;
    }
    return null;
  }

  String? _parseBaseUrl(Map<String, dynamic>? data) {
    if (data == null) return null;
    final snake = data[_baseUrlFieldSnake];
    final camel = data[_baseUrlFieldCamel];
    final raw = (snake is String && snake.trim().isNotEmpty)
        ? snake
        : (camel is String && camel.trim().isNotEmpty)
            ? camel
            : null;
    if (raw == null) return null;
    var url = raw.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.isEmpty) return null;
    return url;
  }
}
