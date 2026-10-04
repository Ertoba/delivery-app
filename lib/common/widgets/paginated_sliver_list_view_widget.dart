import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/helper/responsive_helper.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

/// Sliver-emitting twin of [PaginatedListViewWidget]: identical scroll-to-paginate behaviour,
/// desktop "view more" button and upper/lower loaders — but builds its rows lazily through a
/// SliverList (only visible items are instantiated) instead of an eager shrinkWrap ListView.
///
/// Place it directly inside a CustomScrollView's `slivers` list, using the same ScrollController
/// the CustomScrollView uses. Pass `itemBuilder` + `itemCount` (and optionally `separatorBuilder`)
/// instead of a pre-built `productView`.
class PaginatedSliverListViewWidget extends StatefulWidget {
  final ScrollController scrollController;
  final Function(int? offset) onPaginate;
  final int? totalSize;
  final int? lastPage;
  final int? offset;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final bool enabledPagination;
  final bool showLoadingInUpper;
  const PaginatedSliverListViewWidget({super.key, required this.scrollController, required this.onPaginate, required this.totalSize, this.lastPage,
    required this.offset, required this.itemCount, required this.itemBuilder, this.separatorBuilder,
    this.enabledPagination = true, this.showLoadingInUpper = false});

  @override
  State<PaginatedSliverListViewWidget> createState() => _PaginatedSliverListViewWidgetState();
}

class _PaginatedSliverListViewWidgetState extends State<PaginatedSliverListViewWidget> {
  int? _offset;
  late List<int?> _offsetList;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _offset = 1;
    _offsetList = [1];

    widget.scrollController.addListener(() {
      if (widget.scrollController.position.pixels == widget.scrollController.position.maxScrollExtent
          && widget.totalSize != null && !_isLoading && widget.enabledPagination) {
        if(mounted && !ResponsiveHelper.isDesktop(context)) {
          _paginate();
        }
      }
    });
  }

  void _paginate() async {
    int pageSize = widget.lastPage ?? (widget.totalSize! / 10).ceil();
    if (_offset! < pageSize && !_offsetList.contains(_offset!+1)) {
      setState(() {
        _offset = _offset! + 1;
        _offsetList.add(_offset);
        _isLoading = true;
      });
      await widget.onPaginate(_offset);
      setState(() {
        _isLoading = false;
      });
    } else {
      if(_isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if(widget.offset != null) {
      _offset = widget.offset;
      _offsetList = [];
      for(int index=1; index<=widget.offset!; index++) {
        _offsetList.add(index);
      }
    }

    // Desktop hides the auto-loaders once the last page is reached (matches PaginatedListViewWidget).
    final bool hideLoaders = ResponsiveHelper.isDesktop(context)
        && (widget.totalSize == null || _offset! >= (widget.totalSize! / 10).ceil() || _offsetList.contains(_offset! + 1));

    return SliverMainAxisGroup(slivers: [
      SliverToBoxAdapter(child: _loader(context, upper: true, hide: hideLoaders)),

      (widget.separatorBuilder == null)
          ? SliverList(delegate: SliverChildBuilderDelegate(widget.itemBuilder, childCount: widget.itemCount))
          : SliverList(delegate: SliverChildBuilderDelegate(
              (context, index) => index.isEven
                  ? widget.itemBuilder(context, index ~/ 2)
                  : widget.separatorBuilder!(context, index ~/ 2),
              childCount: widget.itemCount == 0 ? 0 : widget.itemCount * 2 - 1,
            )),

      SliverToBoxAdapter(child: _loader(context, upper: false, hide: hideLoaders)),
    ]);
  }

  Widget _loader(BuildContext context, {required bool upper, required bool hide}) {
    if (hide) return const SizedBox();
    final bool showSpinner = upper ? (_isLoading && widget.showLoadingInUpper) : (_isLoading && !widget.showLoadingInUpper);
    return Center(child: Padding(
      padding: (_isLoading || ResponsiveHelper.isDesktop(context)) ? const EdgeInsets.all(Dimensions.paddingSizeSmall) : EdgeInsets.zero,
      child: showSpinner ? const CircularProgressIndicator()
          : (ResponsiveHelper.isDesktop(context) && widget.totalSize != null) ? InkWell(
              onTap: _paginate,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeLarge),
                margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  color: Theme.of(context).primaryColor,
                ),
                child: Text('view_more'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Colors.white)),
              ),
            ) : const SizedBox(),
    ));
  }
}
