import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/chat_thread.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/skeleton.dart';
import 'chat_providers.dart';
import 'chat_thread_screen.dart';

class _ChatListCard extends StatelessWidget {
  const _ChatListCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.status == AuthStatus.authenticated) {
      return const _ChatThreadListView();
    }

    return const _GuestGlobalPreviewView();
  }
}

IconData _iconForThread(ChatThread thread) {
  if (thread.isOfficial) return Icons.campaign_outlined;
  if (thread.isGlobal) return Icons.public;
  if (thread.isRegion) return Icons.location_city_outlined;
  return Icons.person_outline;
}

class _ChatThreadListView extends ConsumerWidget {
  const _ChatThreadListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(chatThreadsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Grup Chat'),
              Tab(text: 'Chat Pribadi'),
            ],
          ),
        ),
        body: threadsAsync.when(
          data: (threads) {
            final groupThreads = threads.where((t) => !t.isDirectMessage).toList();
            final dmThreads = threads.where((t) => t.isDirectMessage).toList();

            return TabBarView(
              children: [
                _ThreadList(threads: groupThreads, emptyText: 'Belum ada grup chat.'),
                _ThreadList(threads: dmThreads, emptyText: 'Belum ada percakapan pribadi.'),
              ],
            );
          },
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (_, _) => Row(
              children: const [
                Skeleton(width: 48, height: 48, borderRadius: 24),
                SizedBox(width: 12),
                Expanded(child: Skeleton(height: 14)),
              ],
            ),
          ),
          error: (error, _) => Center(child: Text('Gagal memuat percakapan: $error')),
        ),
      ),
    );
  }
}

class _ThreadList extends ConsumerWidget {
  const _ThreadList({required this.threads, required this.emptyText});

  final List<ChatThread> threads;
  final String emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(chatThreadsProvider.future),
      child: threads.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(child: Text(emptyText)),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: threads.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final thread = threads[index];
                return _ChatListCard(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primary,
                    backgroundImage: thread.otherUser?.avatarUrl != null
                        ? NetworkImage(thread.otherUser!.avatarUrl!)
                        : null,
                    child: thread.otherUser?.avatarUrl == null ? Icon(_iconForThread(thread)) : null,
                  ),
                  title: thread.title,
                  subtitle: switch (thread.type) {
                    'official' => 'Informasi resmi Inovasi Online',
                    'global' => 'Obrolan seluruh pengguna',
                    'region' => 'Obrolan warga sekitar',
                    _ => 'Percakapan pribadi',
                  },
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatThreadScreen(
                        threadId: thread.id,
                        title: thread.title,
                        canPost: !thread.isOfficial,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _GuestGlobalPreviewView extends ConsumerWidget {
  const _GuestGlobalPreviewView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: _ChatListCard(
              leading: const CircleAvatar(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primary,
                child: Icon(Icons.public),
              ),
              title: 'GLOBAL - Grup Chat',
              subtitle: 'Obrolan seluruh pengguna',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _GuestGlobalMessagesScreen()),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Masuk untuk mengirim pesan dan mengakses chat wilayah serta percakapan pribadi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.push('/register'),
                          child: const Text('Daftar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.push('/login'),
                          child: const Text('Masuk'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestGlobalMessagesScreen extends ConsumerWidget {
  const _GuestGlobalMessagesScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewAsync = ref.watch(chatGlobalPreviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('GLOBAL - Grup Chat')),
      body: previewAsync.when(
        data: (result) {
          final (_, messages) = result;
          return Column(
            children: [
              Container(
                width: double.infinity,
                color: AppColors.surface,
                padding: const EdgeInsets.all(12),
                child: const Text(
                  'Masuk untuk mengirim pesan dan mengakses chat wilayah.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                ),
              ),
              Expanded(
                child: messages.isEmpty
                    ? const Center(child: Text('Belum ada pesan.'))
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    message.senderName ?? 'Pengguna',
                                    style: const TextStyle(
                                        fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                                  ),
                                  Text(message.body, style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: AppColors.surface,
                child: const Center(
                  child: Text('Masuk untuk ikut mengirim pesan', style: TextStyle(color: AppColors.mutedForeground)),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Gagal memuat chat: $error')),
      ),
    );
  }
}
