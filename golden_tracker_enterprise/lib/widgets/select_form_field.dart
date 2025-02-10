import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:golden_tracker_enterprise/styles/index.dart';
import 'package:golden_tracker_enterprise/widgets/index.dart';

class SearchItem<T> {
  final String title;
  final T value;
  final String? description;
  bool selected = false;

  SearchItem({required this.title, required this.value, this.description});
}

class SelectFormField<T> extends StatefulWidget {
  const SelectFormField({
    super.key,
    this.label,
    this.initialValue,
    this.items = const [],
    this.allowMultiSelect = false,
    this.elevated = true,
    this.enableSearch = true,
    this.filterItemsBuilder,
    this.searchDelay,
    this.controller,
    this.focusNode,
    this.onSelectItem,
    this.decoration,
  });

  final InputDecoration? decoration;

  final T? initialValue;
  final List<SearchItem<T>> items;

  final FutureOr<Iterable<SearchItem<T>>> Function(String)? filterItemsBuilder;

  final void Function(SearchItem<T>)? onSelectItem;

  final String? label;
  final bool enableSearch;
  final bool elevated;
  final bool allowMultiSelect;
  final Duration? searchDelay;
  final FocusNode? focusNode;
  final TextEditingController? controller;

  @override
  State<SelectFormField> createState() => _SelectFormFieldState<T>();
}

class _SelectFormFieldState<T> extends State<SelectFormField> {
  late final FocusNode _focusNode;
  late final TextEditingController _textController;

  late List<SearchItem> _items;

  SearchItem? _selectedItem;

  late final InputDecoration _decoration;

  @override
  void initState() {
    _decoration = widget.decoration ?? kInputDecorationVariant;
    _items = widget.items;

    if (widget.initialValue != null) {
      try {
        _selectedItem = _items.firstWhere(
          (item) => item.value == widget.initialValue,
        );
      } catch (error) {
        log('No initial item selected, "${widget.initialValue}" not found.\n$error');
        _selectedItem = null;
      }
    }

    _textController = widget.controller ?? TextEditingController();
    if (_selectedItem != null) {
      setState(() => _textController.text = _selectedItem!.title);
    }

    _focusNode = widget.focusNode ?? FocusNode();

    super.initState();
  }

  // void _startSearchTimer(String searchText) async {
  //   _searchDelayTimer?.cancel();
  //
  //   if (searchText.isEmpty) {
  //     // not searching
  //     setState(() {
  //       _isLoading = false;
  //       _items.clear();
  //     });
  //     return;
  //   }
  //
  //   print('search not empty');
  //
  //   if (_selectedItem != null && searchText != _selectedItem!.headerText) {
  //     _selectedItem = null;
  //   }
  //
  //   setState(() {
  //     _isLoading = true;
  //     // _items.clear();
  //   });
  //
  //   if (widget.searchDelay == null) {
  //     _items = await widget.searchItemsBuilder(searchText);
  //     print(_items);
  //     setState(() => _isLoading = false);
  //     return;
  //   }
  //
  //   _items = await widget.searchItemsBuilder(searchText);
  //
  //   _searchDelayTimer = Timer(widget.searchDelay!, () {
  //     _controller.text = '';
  //     _controller.text = searchText;
  //     // _focusNode.requestFocus();
  //     setState(() => _isLoading = false);
  //
  //     print(List.generate(_items.length, (i) => _items[i].headerText));
  //   });
  // }

  Future<Iterable<SearchItem>> _filterItems(
    TextEditingValue textValue,
  ) async {
    if (widget.filterItemsBuilder == null) {
      return _items;
    }

    final filteredItems = (await widget.filterItemsBuilder!(textValue.text))
        as Iterable<SearchItem<T>>;

    return filteredItems;
  }

  Iterable<SearchItem> _optionsBuilder(TextEditingValue textValue) {
    if (_items.isNotEmpty || _textController.text.isEmpty) {
      return _items;
    }

    return [
      SearchItem(
        value: null,
        title: 'No items match "${_textController.text}".',
      )
    ];
  }

  void _onSelectItem(SearchItem item) {
    _textController.text = item.title;
    setState(() => _selectedItem = item);

    widget.onSelectItem?.call(item);
    _focusNode.unfocus();
  }

  Widget _optionsViewBuilder(
    double width,
    BuildContext context,
    void Function(SearchItem) onSelect,
    Iterable<SearchItem> options,
  ) {
    return Container(
      padding: EdgeInsets.only(top: 0.5),
      alignment: Alignment.topLeft,
      height: 250,
      child: Material(
        color: Colors.white,
        elevation: widget.elevated ? 4.0 : 0.0,
        shadowColor: Colors.black38,
        clipBehavior: Clip.none,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(8),
          ),
          side: BorderSide(
            color: kSurface,
            strokeAlign: BorderSide.strokeAlignCenter,
          ),
        ),
        child: SizedBox(
          width: width,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final SearchItem item = options.elementAt(index);
              return ListTile(
                onTap: (item.value == null) ? null : () => onSelect(item),
                title: Text(item.title),
                subtitle:
                    (item.description == null) ? null : Text(item.description!),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _fieldViewBuilder(
    BuildContext context,
    TextEditingController controller,
    FocusNode focusNode,
    void Function() onSubmit,
  ) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      readOnly: !widget.enableSearch,
      enableInteractiveSelection: !widget.enableSearch,
      textAlignVertical: TextAlignVertical.center,
      decoration: _decoration.copyWith(
        isDense: true,
        hintText: widget.label,
        labelText: (controller.text.isNotEmpty) ? widget.label : null,
        focusedBorder: (_items.isNotEmpty && _selectedItem == null) || (_selectedItem == null && controller.text.isNotEmpty)
            ? kInputBorderVariant.copyWith(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              )
            : null,
        suffixIcon: (controller.text.isEmpty)
            ? null
            : SideFieldIcon(
                icon: Icon(Icons.close),
                onTap: () {
                  _selectedItem = null;
                  setState(() => controller.text = '');
                },
              ),
      ),
      onTap: () {
        controller.text = controller.text;
      },
      onChanged: (text) {
        if (_selectedItem != null && _selectedItem?.title != text) {
          _selectedItem = null;
        }
        setState(() {
          //
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return RawAutocomplete<SearchItem>(
        textEditingController: _textController,
        focusNode: _focusNode,
        displayStringForOption: (item) => item.title,
        onSelected: _onSelectItem,
        optionsBuilder: _optionsBuilder,
        optionsViewBuilder: (context, onSelect, options) {
          return _optionsViewBuilder(
            constraints.biggest.width,
            context,
            onSelect,
            options,
          );
        },
        fieldViewBuilder: _fieldViewBuilder,
      );
    });
  }
}
