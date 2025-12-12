import 'package:flutter/material.dart';

/// Arama yapılabilir dropdown widget
/// Build runner gerektirmez, saf Flutter widget
class SearchableDropdown<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) itemAsString;
  final T? selectedItem;
  final void Function(T?) onChanged;
  final String hintText;
  final String searchHintText;
  final bool enabled;
  final Widget Function(BuildContext, T)? itemBuilder;

  const SearchableDropdown({
    super.key,
    required this.items,
    required this.itemAsString,
    this.selectedItem,
    required this.onChanged,
    this.hintText = 'Seçiniz',
    this.searchHintText = 'Ara...',
    this.enabled = true,
    this.itemBuilder,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void didUpdateWidget(covariant SearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filteredItems = widget.items;
      _searchController.clear();
    }
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          final itemString = widget.itemAsString(item).toLowerCase();
          final searchQuery = query.toLowerCase();
          return itemString.contains(searchQuery);
        }).toList();
      }
    });
  }

  void _showSearchDialog() {
    _searchController.clear();
    _filteredItems = widget.items;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(widget.hintText),
              contentPadding: const EdgeInsets.all(16),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    // Arama kutusu
                    TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: widget.searchHintText,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setDialogState(() {
                                    _searchController.clear();
                                    _filteredItems = widget.items;
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          _filterItems(value);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Sonuç sayısı
                    if (_filteredItems.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Sonuç bulunamadı',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          '${_filteredItems.length} sonuç',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    
                    // Liste
                    if (_filteredItems.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            final isSelected = widget.selectedItem == item;
                            
                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.1),
                              leading: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: Theme.of(context).primaryColor,
                                    )
                                  : null,
                              title: widget.itemBuilder != null
                                  ? widget.itemBuilder!(context, item)
                                  : Text(widget.itemAsString(item)),
                              onTap: () {
                                widget.onChanged(item);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.enabled ? _showSearchDialog : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.enabled ? Colors.grey[400]! : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(12),
          color: widget.enabled ? Colors.white : Colors.grey[100],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.selectedItem != null
                    ? widget.itemAsString(widget.selectedItem as T)
                    : widget.hintText,
                style: TextStyle(
                  fontSize: 16,
                  color: widget.selectedItem != null
                      ? Colors.black87
                      : Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: widget.enabled ? Colors.grey[700] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

