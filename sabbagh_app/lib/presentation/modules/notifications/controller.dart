import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sabbagh_app/core/services/dio_client.dart';
import 'package:sabbagh_app/core/services/storage_service.dart';
import 'package:sabbagh_app/presentation/modules/notifications/repository.dart';

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String? body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString(),
      data: (json['data'] as Map?)?.cast<String, dynamic>(),
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  String get formattedTime => DateFormat('y-MM-dd HH:mm').format(createdAt);
}

class NotificationsController extends GetxController {
  late final NotificationRepository _repo;

  final RxList<AppNotification> notifications = <AppNotification>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isLoadingMore = false.obs;
  final int pageSize = 20;
  int _offset = 0;
  bool _hasMore = true;

  @override
  void onInit() {
    super.onInit();
    _repo = NotificationRepository(Get.find<DioClient>());
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    if (await Get.find<StorageService>().getToken() != null) {
      isLoading.value = true;
      _offset = 0;
      _hasMore = true;
      try {
        final res = await _repo.list(limit: pageSize, offset: _offset);
        final items =
            (res['data'] as List? ?? [])
                .cast<Map>()
                .map((e) => AppNotification.fromJson(e.cast<String, dynamic>()))
                .toList();
        notifications.assignAll(items);
        unreadCount.value = _calcUnread(items);
        _offset = items.length;
        _hasMore = items.length >= pageSize;
      } catch (_) {
        // Ignore errors (e.g., unauthenticated at app start)
        notifications.clear();
        unreadCount.value = 0;
        _offset = 0;
        _hasMore = false;
      } finally {
        isLoading.value = false;
      }
    }
  }

  Future<void> refreshList() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    try {
      await fetchInitial();
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || isLoadingMore.value) return;
    isLoadingMore.value = true;
    try {
      final res = await _repo.list(limit: pageSize, offset: _offset);
      final items =
          (res['data'] as List? ?? [])
              .cast<Map>()
              .map((e) => AppNotification.fromJson(e.cast<String, dynamic>()))
              .toList();
      notifications.addAll(items);
      unreadCount.value = _calcUnread(notifications);
      _offset += items.length;
      if (items.length < pageSize) _hasMore = false;
    } finally {
      isLoadingMore.value = false;
    }
  }

  int _calcUnread(Iterable<AppNotification> list) =>
      list.where((n) => !n.isRead).length;

  Future<void> markRead(String id) async {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index == -1 || notifications[index].isRead) return;
    // Optimistic UI update
    notifications[index] = AppNotification(
      id: notifications[index].id,
      type: notifications[index].type,
      title: notifications[index].title,
      body: notifications[index].body,
      data: notifications[index].data,
      isRead: true,
      createdAt: notifications[index].createdAt,
    );
    unreadCount.value = _calcUnread(notifications);
    try {
      final ok = await _repo.markRead(id);
      if (!ok) {
        // rollback if server failed
        notifications[index] = AppNotification(
          id: notifications[index].id,
          type: notifications[index].type,
          title: notifications[index].title,
          body: notifications[index].body,
          data: notifications[index].data,
          isRead: false,
          createdAt: notifications[index].createdAt,
        );
        unreadCount.value = _calcUnread(notifications);
      }
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    if (unreadCount.value == 0) return;
    final backup = notifications.toList();
    notifications.assignAll(
      notifications.map(
        (n) => AppNotification(
          id: n.id,
          type: n.type,
          title: n.title,
          body: n.body,
          data: n.data,
          isRead: true,
          createdAt: n.createdAt,
        ),
      ),
    );
    unreadCount.value = 0;
    try {
      await _repo.markAllRead();
    } catch (_) {
      notifications.assignAll(backup);
      unreadCount.value = _calcUnread(backup);
    }
  }

  Future<void> deleteById(String id) async {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    final removed = notifications.removeAt(index);
    unreadCount.value = _calcUnread(notifications);
    try {
      await _repo.deleteById(id);
    } catch (_) {
      notifications.insert(index, removed);
      unreadCount.value = _calcUnread(notifications);
    }
  }

  Future<void> deleteAll() async {
    final backup = notifications.toList();
    notifications.clear();
    unreadCount.value = 0;
    try {
      await _repo.deleteAll();
    } catch (_) {
      notifications.assignAll(backup);
      unreadCount.value = _calcUnread(backup);
    }
  }

  void clear() {
    notifications.clear();
    unreadCount.value = 0;
    _offset = 0;
    _hasMore = false;
  }
}
