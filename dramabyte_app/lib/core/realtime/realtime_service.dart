import 'dart:async';

import 'package:dramabyte_app/core/config/app_config.dart';
import 'package:dramabyte_app/core/logging/app_logger.dart';
import 'package:dramabyte_app/core/network/token_refresher.dart';
import 'package:supabase/supabase.dart';

final class RealtimeService {
  RealtimeService(TokenRefresher refresher)
    : _client = SupabaseClient(
        AppConfig.supabaseUrl,
        AppConfig.supabaseAnonKey,
        accessToken: refresher.validAccessToken,
      ) {
    refresher.onRefreshed.listen(_client.realtime.setAuth);
  }

  final SupabaseClient _client;

  Stream<void> changes(String table, {String? column, String? userId}) {
    late final StreamController<void> controller;
    RealtimeChannel? channel;
    controller = StreamController<void>(
      onListen: () {
        channel = _client
            .channel('$table:${userId ?? 'all'}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: table,
              filter: column == null || userId == null
                  ? null
                  : PostgresChangeFilter(
                      type: PostgresChangeFilterType.eq,
                      column: column,
                      value: userId,
                    ),
              callback: (_) => controller.add(null),
            )
            .subscribe(
              (status, error) => AppLogger.debug(
                'Realtime $table',
                data: {'status': status.name, 'error': error?.toString()},
              ),
            );
      },
      onCancel: () async {
        final active = channel;
        if (active != null) await _client.removeChannel(active);
      },
    );
    return controller.stream;
  }
}
