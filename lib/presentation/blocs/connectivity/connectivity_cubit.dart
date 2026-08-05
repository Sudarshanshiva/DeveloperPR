import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/network_info.dart';

class ConnectivityCubit extends Cubit<bool> {
  final NetworkInfo networkInfo;
  StreamSubscription<bool>? _subscription;

  ConnectivityCubit({required this.networkInfo}) : super(true) {
    _init();
  }

  Future<void> _init() async {
    final connected = await networkInfo.isConnected;
    emit(connected);
    _subscription = networkInfo.onConnectivityChanged.listen((isOnline) {
      emit(isOnline);
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
