import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:tswiri_database/collections/cataloged_container/cataloged_container.dart';
import 'package:tswiri_database/collections/container_type/container_type.dart';

class ContainerFilterWorker {
  final SendPort _sendPort;
  final ReceivePort _receivePort;
  final Map<int, Completer<Object?>> _activeRequests = {};
  int _idCounter = 0;
  bool _closed = false;

  final results = ValueNotifier<List<CatalogedContainer>>([]);

  Future<Object?> _sendCommand(ContainerIsolateCommand command) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;

    // Set the id of the command.
    _sendPort.send(command..id = id);
    return await completer.future;
  }

  static Future<ContainerFilterWorker> spawn() async {
    // Create a receive port and add its initial message handler.
    final initPort = RawReceivePort();
    final connection = Completer<(ReceivePort, SendPort)>.sync();
    initPort.handler = (initialMessage) {
      final commandPort = initialMessage as SendPort;
      connection.complete((
        ReceivePort.fromRawReceivePort(initPort),
        commandPort,
      ));
    };

    // Spawn the isolate.
    try {
      await Isolate.spawn(_startRemoteIsolate, (initPort.sendPort));
    } on Object {
      initPort.close();
      rethrow;
    }

    final (receivePort, sendPort) = await connection.future;

    return ContainerFilterWorker._(receivePort, sendPort);
  }

  ContainerFilterWorker._(this._receivePort, this._sendPort) {
    _receivePort.listen(_handleResponsesFromIsolate);
  }

  void _handleResponsesFromIsolate(dynamic message) {
    if (message is! ContainerIsolateResponse) return;
    final response = message;

    final completer = _activeRequests.remove(response.id)!;
    if (response is RemoteError) {
      completer.completeError(response);
    } else {
      completer.complete(response);
    }

    if (response is SearchResponse) {
      results.value = response.containers;
    }
  }

  static void _handleCommandsToIsolate(
    ReceivePort receivePort,
    SendPort sendPort,
    List<CatalogedContainer> containers,
  ) async {
    receivePort.listen((message) {
      if (message is! ContainerIsolateCommand) return;
      final command = message;

      try {
        if (command is SearchCommand) {
          final results = _filterContainers(command, containers);
          final response = SearchResponse(results, id: command.id);
          sendPort.send(response);
        } else if (command is UpdateCommand) {
          containers.clear();
          containers.addAll(command.containers);
          final response = RequestCompleted(id: command.id);
          sendPort.send(response);
        } else if (command is CloseCommand) {
          sendPort.send(RequestCompleted(id: command.id));
          receivePort.close();
        }
      } catch (e) {
        final error = RequestError(id: command.id, error: e.toString());
        sendPort.send(error);
      }
    });
  }

  static List<CatalogedContainer> _filterContainers(
    SearchCommand searchCommand,
    List<CatalogedContainer> containers,
  ) {
    final filteredContainers = List<CatalogedContainer>.from(containers);

    // Filter by container type.
    final containerTypes = searchCommand.containerTypes;
    if (containerTypes.isNotEmpty) {
      filteredContainers.removeWhere((element) {
        final type = element.typeUUID;
        return !containerTypes.any(
          (containerType) => containerType.uuid == type,
        );
      });
    }

    // Filter by keyword.
    final keyword = searchCommand.keyword.toLowerCase();
    final results = filteredContainers.where((container) {
      final name = container.name;
      if (name == null) return false;

      final lowerCaseName = name.toLowerCase();

      return lowerCaseName.contains(keyword);
    }).toList();

    return results;
  }

  static void _startRemoteIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    final containers = <CatalogedContainer>[];
    _handleCommandsToIsolate(receivePort, sendPort, containers);
  }

  void close() {
    if (!_closed) {
      _closed = true;
      _sendPort.send(CloseCommand());
      if (_activeRequests.isEmpty) _receivePort.close();
      debugPrint('--- port closed --- ');
    }
  }

  void updateIsolateData({
    required List<CatalogedContainer> containers,
    required List<ContainerType> containerTypes,
  }) async {
    final command = UpdateCommand(
      containers: containers,
      containerTypes: containerTypes,
    );
    final response = await _sendCommand(command);
    results.value = containers;
    debugPrint('response: $response');
  }

  void filter({
    required String keyword,
    required List<ContainerType> containerTypes,
  }) async {
    final command = SearchCommand(
      keyword: keyword,
      containerTypes: containerTypes,
    );

    final response = await _sendCommand(command);
    debugPrint('response: ${response.runtimeType}');
  }
}

/// Commands that can be sent to the isolate.
abstract class ContainerIsolateCommand {
  int id = 0;
}

class SearchCommand extends ContainerIsolateCommand {
  SearchCommand({
    required this.keyword,
    required this.containerTypes,
  });

  final String keyword;
  final List<ContainerType> containerTypes;
}

class UpdateCommand extends ContainerIsolateCommand {
  final List<CatalogedContainer> containers;
  final List<ContainerType> containerTypes;

  UpdateCommand({
    required this.containers,
    required this.containerTypes,
  });
}

class CloseCommand extends ContainerIsolateCommand {
  CloseCommand();
}

/// Responses that can be received from the isolate.
abstract class ContainerIsolateResponse {
  ContainerIsolateResponse({required this.id});
  final int id;
}

class SearchResponse extends ContainerIsolateResponse {
  final List<CatalogedContainer> containers;

  SearchResponse(this.containers, {required super.id});
}

class RequestCompleted extends ContainerIsolateResponse {
  String? message;

  RequestCompleted({
    required super.id,
    String? message,
  });
}

class RequestError extends ContainerIsolateResponse {
  final String error;
  RequestError({
    required super.id,
    required this.error,
  });
}
