import 'package:flutter/material.dart';
import 'package:pdf_master/src/core/pdf_controller.dart';
import 'package:pdf_master/src/core/pdf_ffi_api.dart' as ffi_api;
import 'package:pdf_master/src/utils/ctx_extension.dart';

class TocState extends ChangeNotifier {
  List<ffi_api.TocItem>? _tocItems;
  bool _isLoading = false;
  int _currentPageIndex = 0;
  Function(int pageIndex)? onPageChanged;

  List<ffi_api.TocItem>? get tocItems => _tocItems;

  bool get isLoading => _isLoading;

  bool get hasToc => _tocItems != null && _tocItems!.isNotEmpty;

  int get currentPageIndex => _currentPageIndex;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setTocItems(List<ffi_api.TocItem> items) {
    _tocItems = items;
    _isLoading = false;
    notifyListeners();
  }

  void setCurrentPageIndex(int pageIndex) {
    if (_currentPageIndex != pageIndex) {
      _currentPageIndex = pageIndex;
      notifyListeners();
    }
  }

  void jumpToPage(int pageIndex) {
    if (pageIndex >= 0 && onPageChanged != null) {
      onPageChanged!(pageIndex);
    }
  }

  void clear() {
    _tocItems = null;
    _isLoading = false;
    _currentPageIndex = 0;
    notifyListeners();
  }

  bool isPageInTocItem(ffi_api.TocItem item, int pageIndex, int? nextPageIndex) {
    if (item.pageIndex < 0) return false;
    if (nextPageIndex != null && nextPageIndex >= 0) {
      return pageIndex >= item.pageIndex && pageIndex < nextPageIndex;
    }
    return pageIndex >= item.pageIndex;
  }

  ffi_api.TocItem? findCurrentTocItem(int pageIndex) {
    if (_tocItems == null || _tocItems!.isEmpty) return null;
    return _findCurrentTocItemRecursive(_tocItems!, pageIndex);
  }

  ffi_api.TocItem? _findCurrentTocItemRecursive(List<ffi_api.TocItem> items, int pageIndex) {
    ffi_api.TocItem? bestMatch;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final nextItem = i + 1 < items.length ? items[i + 1] : null;

      if (isPageInTocItem(item, pageIndex, nextItem?.pageIndex)) {
        bestMatch = item;

        if (item.children.isNotEmpty) {
          final childMatch = _findCurrentTocItemRecursive(item.children, pageIndex);
          if (childMatch != null) {
            bestMatch = childMatch;
          }
        }
        break;
      }
    }

    return bestMatch;
  }
}

void showTocBottomSheet(BuildContext context, PdfController controller, TocState tocState) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TocBottomSheet(controller: controller, tocState: tocState),
  );
}

class TocBottomSheet extends StatefulWidget {
  final PdfController controller;
  final TocState tocState;

  const TocBottomSheet({super.key, required this.controller, required this.tocState});

  @override
  State<TocBottomSheet> createState() => _TocBottomSheetState();
}

class _TocBottomSheetState extends State<TocBottomSheet> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _loadToc();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadToc() async {
    if (widget.tocState.tocItems != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentItem();
      });
      return;
    }

    widget.tocState.setLoading(true);
    try {
      final items = await widget.controller.getDocumentToc();
      widget.tocState.setTocItems(items);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentItem();
      });
    } catch (e) {
      widget.tocState.setLoading(false);
    }
  }

  void _scrollToCurrentItem() {
    if (!_scrollController.hasClients) return;

    final currentPage = widget.tocState.currentPageIndex;
    final currentTocItem = widget.tocState.findCurrentTocItem(currentPage);

    if (currentTocItem != null) {
      final itemKey = _getItemKey(currentTocItem);
      final keyContext = _itemKeys[itemKey]?.currentContext;

      if (keyContext != null) {
        Scrollable.ensureVisible(
          keyContext,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.3,
        );
      }
    }
  }

  String _getItemKey(ffi_api.TocItem item) {
    return '${item.title}_${item.pageIndex}_${item.level}';
  }

  bool get darkMode => context.pdfTheme.isDark;

  Color get currentChapterBg => Colors.blue.withValues(alpha: darkMode ? 0.5 : 0.1);

  Color get currentChapterTextColor => context.pdfTheme.textColor;

  Color get textColor => context.pdfTheme.textColor;

  Color? get pageIndexColor => darkMode ? Colors.white : Colors.grey[600];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.7,
      decoration: BoxDecoration(
        color: context.pdfTheme.appBarBackgroundColor,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      clipBehavior: Clip.hardEdge,
      child: ListenableBuilder(listenable: widget.tocState, builder: (context, child) => _buildContent()),
    );
  }

  Widget _buildContent() {
    if (widget.tocState.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (!widget.tocState.hasToc) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(context.localizations['noToc'], style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.tocState.tocItems!.length,
      itemBuilder: (context, index) {
        final item = widget.tocState.tocItems![index];
        final nextItem = index + 1 < widget.tocState.tocItems!.length ? widget.tocState.tocItems![index + 1] : null;
        return _buildTocItem(item, nextItem?.pageIndex);
      },
    );
  }

  Widget _buildTocItem(ffi_api.TocItem item, int? nextPageIndex) {
    final currentPage = widget.tocState.currentPageIndex;
    final currentTocItem = widget.tocState.findCurrentTocItem(currentPage);
    final isCurrentChapter = currentTocItem != null && _isSameTocItem(item, currentTocItem);

    // 为当前高亮项创建key
    final itemKey = _getItemKey(item);
    if (isCurrentChapter && !_itemKeys.containsKey(itemKey)) {
      _itemKeys[itemKey] = GlobalKey();
    }

    return Column(
      key: isCurrentChapter ? _itemKeys[itemKey] : null,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            if (item.pageIndex >= 0) {
              widget.tocState.jumpToPage(item.pageIndex);
              Navigator.pop(context);
            }
          },
          child: Container(
            color: isCurrentChapter ? currentChapterBg : Colors.transparent,
            padding: EdgeInsets.only(left: 16.0 + (item.level * 20.0), right: 16.0, top: 12.0, bottom: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: item.level == 0 ? FontWeight.w600 : FontWeight.normal,
                      color: isCurrentChapter ? currentChapterTextColor : textColor,
                    ),
                    maxLines: item.level == 0 ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 24),
                if (item.pageIndex >= 0)
                  Text(
                    '${item.pageIndex + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      color: pageIndexColor,
                      fontWeight: isCurrentChapter ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // 递归渲染子项
        if (item.children.isNotEmpty)
          ...item.children.asMap().entries.map((entry) {
            final childIndex = entry.key;
            final child = entry.value;
            final nextChild = childIndex + 1 < item.children.length ? item.children[childIndex + 1] : null;
            return _buildTocItem(child, nextChild?.pageIndex);
          }),
      ],
    );
  }

  bool _isSameTocItem(ffi_api.TocItem l, ffi_api.TocItem r) {
    return l.title == r.title && l.pageIndex == r.pageIndex && l.level == r.level;
  }
}
