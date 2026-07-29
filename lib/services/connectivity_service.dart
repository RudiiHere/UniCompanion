import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_service.dart';

class ConnectivityService {
  static ConnectivityService? _instance;
  static ConnectivityService get instance => _instance ??= ConnectivityService._();
  ConnectivityService._();

  final _connectivity = Connectivity();
  StreamSubscription? _subscription;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onlineStream => _controller.stream;


  final _syncedController = StreamController<void>.broadcast();
  Stream<void> get syncedStream => _syncedController.stream;


  bool _isConnected(ConnectivityResult result) =>
      result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet;

  void init() {
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = _isConnected(result);
      _controller.add(_isOnline);


      if (!wasOnline && _isOnline) {
        _drainOutbox();
      }
    });


    _connectivity.checkConnectivity().then((result) {
      _isOnline = _isConnected(result);
      _controller.add(_isOnline);
      if (_isOnline) _drainOutbox();
    });
  }

  Future<void> _drainOutbox() async {

    await Future.delayed(const Duration(seconds: 2));
    final didSync = await DatabaseService().drainOutbox();
    if (didSync) _syncedController.add(null);
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
    _syncedController.close();
  }
}