import 'package:flutter/material.dart';
import 'package:pdf_master/src/component/app_bar.dart';
import 'package:pdf_master/src/core/pdf_controller.dart';
import 'package:pdf_master/src/core/pdf_ffi_api.dart' as ffi_api;
import 'package:pdf_master/src/utils/ctx_extension.dart';
import 'package:pdf_master/src/utils/log.dart';

class SearchState extends ChangeNotifier {
  List<ffi_api.SearchResult> _results = [];
  int _currentIndex = -1;
  bool _isSearching = false;
  String _searchText = '';
  Function(int pageIndex)? onPageChanged;

  List<ffi_api.SearchResult> get results => _results;

  int get currentIndex => _currentIndex;

  bool get isSearching => _isSearching;

  String get searchText => _searchText;

  int get totalResults => _results.length;

  bool get hasResults => _results.isNotEmpty;

  ffi_api.SearchResult? get currentResult {
    if (_currentIndex >= 0 && _currentIndex < _results.length) {
      return _results[_currentIndex];
    }
    return null;
  }

  void setResults(List<ffi_api.SearchResult> results, String searchText) {
    _results = results;
    _searchText = searchText;
    _currentIndex = results.isNotEmpty ? 0 : -1;
    _isSearching = false;
    notifyListeners();

    // 自动跳转到第一个结果
    if (_currentIndex >= 0 && onPageChanged != null) {
      onPageChanged!(_results[_currentIndex].pageIndex);
    }
  }

  void setSearching(bool searching) {
    _isSearching = searching;
    notifyListeners();
  }

  void nextResult() {
    if (_results.isNotEmpty && _currentIndex < _results.length - 1) {
      _currentIndex++;
      notifyListeners();

      // 跳转到下一个结果所在的页面
      if (onPageChanged != null) {
        onPageChanged!(_results[_currentIndex].pageIndex);
      }
    }
  }

  void previousResult() {
    if (_results.isNotEmpty && _currentIndex > 0) {
      _currentIndex--;
      notifyListeners();

      // 跳转到上一个结果所在的页面
      if (onPageChanged != null) {
        onPageChanged!(_results[_currentIndex].pageIndex);
      }
    }
  }

  void clear() {
    _results = [];
    _currentIndex = -1;
    _searchText = '';
    _isSearching = false;
    notifyListeners();
  }
}

class SearchToolBar extends StatefulWidget {
  final PdfController controller;
  final SearchState searchState;

  const SearchToolBar({super.key, required this.controller, required this.searchState});

  @override
  State<SearchToolBar> createState() => _SearchToolBarState();
}

class _SearchToolBarState extends State<SearchToolBar> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      widget.searchState.clear();
      return;
    }
    widget.searchState.setSearching(true);
    try {
      final results = await widget.controller.searchTextInDocument(query.trim());
      widget.searchState.setResults(results, query.trim());
    } catch (e) {
      widget.searchState.setSearching(false);
      Log.e("Search", "Failed to search text: $e");
    }
  }

  void _clearSearch() {
    _textController.clear();
    widget.searchState.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        widget.searchState.clear();
        widget.controller.editStateNotifier.value = PdfEditState.kNone;
      },
      child: PdfMasterAppBar(
        center: TextField(
          controller: _textController,
          textInputAction: TextInputAction.search,
          autofocus: true,
          maxLines: 1,
          textAlignVertical: TextAlignVertical.center,
          onSubmitted: _performSearch,
          onChanged: (value) {
            if (value.isEmpty) {
              _clearSearch();
            }
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: context.localizations['search'],
            contentPadding: EdgeInsets.zero,
            prefixIcon: IconButton(
              onPressed: () {
                widget.searchState.clear();
                widget.controller.editStateNotifier.value = PdfEditState.kNone;
              },
              icon: Icon(Icons.arrow_back),
            ),
            suffixIcon: _textController.text.isNotEmpty
                ? IconButton(onPressed: _clearSearch, icon: Icon(Icons.close))
                : null,
            border: InputBorder.none,
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent, width: 0)),
          ),
          cursorColor: Colors.grey,
        ),
      ),
    );
  }
}

class SearchBottomBar extends StatelessWidget {
  final PdfController controller;
  final SearchState searchState;

  const SearchBottomBar({super.key, required this.controller, required this.searchState});

  /// 获取搜索状态显示文本
  String _getDisplayText(BuildContext context) {
    if (searchState.isSearching) {
      return context.localizations['searching'];
    }

    if (searchState.hasResults) {
      return '${searchState.currentIndex + 1}/${searchState.totalResults}';
    }

    if (searchState.searchText.isNotEmpty) {
      return context.localizations['noResults'];
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.pdfTheme.appBarBackgroundColor,
        boxShadow: [BoxShadow(blurRadius: 10, spreadRadius: 0.1, color: context.pdfTheme.shadowColor)],
      ),
      child: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: searchState,
          builder: (context, child) {
            final canPrev = searchState.currentIndex > 0;
            final canNext = searchState.currentIndex < searchState.totalResults - 1;
            final displayText = _getDisplayText(context);

            return Row(
              children: [
                SizedBox(width: 24),
                Text(displayText, style: TextStyle(fontSize: 14)),
                Spacer(),
                IconButton(
                  onPressed: canPrev ? searchState.previousResult : null,
                  icon: Icon(Icons.keyboard_arrow_left),
                ),
                IconButton(onPressed: canNext ? searchState.nextResult : null, icon: Icon(Icons.keyboard_arrow_right)),
              ],
            );
          },
        ),
      ),
    );
  }
}
