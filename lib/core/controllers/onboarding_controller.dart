import 'package:flutter/foundation.dart';

class OnboardingController extends ChangeNotifier {
  OnboardingController({required this.pageCount});

  final int pageCount;
  int _page = 0;
  int _entrance = 0;

  int get page => _page;
  int get entrance => _entrance;
  bool get isLast => _page == pageCount - 1;

  void setPage(int page) {
    if (page == _page) return;
    _page = page;
    _entrance++;
    notifyListeners();
  }
}
