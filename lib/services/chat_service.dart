import '../core/api/api_client.dart';
import '../core/api/api_response.dart';
import '../models/chat_message.dart';
import '../models/chat_thread.dart';

class ChatService {
  ChatService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ChatThread>> threads() async {
    final response = await _apiClient.dio.get('/chat/threads');
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => ChatThread.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<(ChatThread, List<ChatMessage>)> globalPreview() async {
    final response = await _apiClient.dio.get('/chat/global-preview');
    final data = response.data['data'] as Map<String, dynamic>;
    final thread = ChatThread.fromJson(data['thread'] as Map<String, dynamic>);
    final messages = (data['messages'] as List<dynamic>)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
    return (thread, messages);
  }

  Future<PaginatedResult<ChatMessage>> messages(String threadId, {int page = 1, int perPage = 20}) async {
    final response = await _apiClient.dio.get('/chat/threads/$threadId/messages', queryParameters: {
      'page': page,
      'per_page': perPage,
    });

    final data = (response.data['data'] as List<dynamic>)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = PaginatedMeta.fromJson(response.data['meta'] as Map<String, dynamic>);

    return PaginatedResult<ChatMessage>(data: data, meta: meta);
  }

  Future<ChatMessage> sendMessage(String threadId, String body) async {
    final response = await _apiClient.dio.post('/chat/threads/$threadId/messages', data: {'body': body});
    return ChatMessage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ChatThread> startDirectMessage(String userId) async {
    final response = await _apiClient.dio.post('/chat/users/$userId/dm');
    return ChatThread.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
