import 'package:flutter/material.dart';

import '../../../core/utils/byte_formatter.dart';
import '../../../data/models/connection.dart';
import '../../../data/services/api/mihomo_api_service.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  final _apiService = MihomoApiService();
  List<Connection> _connections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    setState(() => _loading = true);
    try {
      _connections = await _apiService.getConnections();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _closeConnection(String id) async {
    await _apiService.closeConnection(id);
    await _loadConnections();
  }

  Future<void> _closeAll() async {
    await _apiService.closeAllConnections();
    await _loadConnections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('连接 (${_connections.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConnections,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _closeAll,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _connections.isEmpty
              ? const Center(child: Text('无活动连接'))
              : ListView.builder(
                  itemCount: _connections.length,
                  itemBuilder: (context, index) {
                    final conn = _connections[index];
                    return ListTile(
                      title: Text(
                        conn.metadata.host.isNotEmpty
                            ? conn.metadata.host
                            : conn.metadata.destinationIP,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${conn.chains.join(" → ")} | ↑${formatBytes(conn.upload)} ↓${formatBytes(conn.download)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _closeConnection(conn.id),
                      ),
                    );
                  },
                ),
    );
  }
}
