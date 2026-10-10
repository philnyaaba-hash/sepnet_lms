import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:skillbridge_python_lab/core/errors/app_exception.dart';
import 'package:skillbridge_python_lab/features/exercises/exercise.dart';
import 'package:skillbridge_python_lab/features/submissions/submission.dart';
import 'lms_client.dart';
import 'lms_models.dart';

/// Supplies the current bearer token. Implemented per environment (for example
/// backed by platform secure storage, or by an LMS-issued session). No secret is
/// ever hard-coded in the app.
abstract class AuthTokenProvider {
  Future<String?> getToken();

  /// Called when the server rejects the token, so the app can clear it and
  /// prompt the learner to sign in again.
  Future<void> onUnauthorized();
}

/// Simple provider for development against a token supplied at build time.
class StaticTokenProvider implements AuthTokenProvider {
  StaticTokenProvider(this._token);
  String? _token;

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> onUnauthorized() async => _token = null;
}

/// Real HTTP adapter for the SkillBridge LMS.
///
/// The concrete endpoint paths below are the *proposed* contract; confirm them
/// against the LMS API specification before production use. Until then the app
/// uses [MockLmsClient]. See `docs/LMS_INTEGRATION.md`.
///
/// Contract used:
///   GET  {base}/me
///   GET  {base}/exercises
///   GET  {base}/exercises/{id}
///   POST {base}/submissions           (Idempotency-Key: `<submissionId>`)
///   GET  {base}/submissions/{id}
///   GET  {base}/progress
///   GET  {base}/achievements
class HttpLmsClient implements LmsClient {
  HttpLmsClient({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 15),
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final AuthTokenProvider tokenProvider;
  final Duration timeout;
  final http.Client _http;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, String>> _headers({bool idempotencyKey = false, String? key}) async {
    final token = await tokenProvider.getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (idempotencyKey && key != null) 'Idempotency-Key': key,
    };
  }

  Future<dynamic> _send(
    Future<http.Response> Function() request, {
    Set<int> okCodes = const {200, 201},
  }) async {
    http.Response response;
    try {
      response = await request().timeout(timeout);
    } on TimeoutException catch (e) {
      throw NetworkException('The server took too long to respond.', cause: e);
    } catch (e) {
      throw NetworkException('We could not reach the server.', cause: e);
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      await tokenProvider.onUnauthorized();
      throw const AuthenticationException();
    }
    if (response.statusCode == 404) {
      throw const NotFoundException();
    }
    if (!okCodes.contains(response.statusCode)) {
      throw LmsException(
        'The server returned an error (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  @override
  Future<LearnerIdentity> getCurrentLearner() async {
    final json = await _send(
      () async => _http.get(_uri('/me'), headers: await _headers()),
    );
    return LearnerIdentity.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<List<Exercise>> fetchExercises() async {
    final json = await _send(
      () async => _http.get(_uri('/exercises'), headers: await _headers()),
    );
    final list = (json as Map<String, dynamic>)['exercises'] as List<dynamic>? ?? const [];
    return list
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<Exercise> fetchExercise(String exerciseId) async {
    final json = await _send(
      () async => _http.get(_uri('/exercises/$exerciseId'), headers: await _headers()),
    );
    return Exercise.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<SubmissionReceipt> submitSolution(Submission submission) async {
    final json = await _send(
      () async => _http.post(
        _uri('/submissions'),
        headers: await _headers(idempotencyKey: true, key: submission.id),
        body: jsonEncode(submission.toApiJson()),
      ),
    );
    return SubmissionReceipt.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<SubmissionReceipt> getSubmissionStatus(String submissionId) async {
    final json = await _send(
      () async => _http.get(_uri('/submissions/$submissionId'), headers: await _headers()),
    );
    return SubmissionReceipt.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<LearnerProgress> fetchProgress() async {
    final json = await _send(
      () async => _http.get(_uri('/progress'), headers: await _headers()),
    );
    return LearnerProgress.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<List<Achievement>> fetchAchievements() async {
    final json = await _send(
      () async => _http.get(_uri('/achievements'), headers: await _headers()),
    );
    final list = (json as Map<String, dynamic>)['achievements'] as List<dynamic>? ?? const [];
    return list
        .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
