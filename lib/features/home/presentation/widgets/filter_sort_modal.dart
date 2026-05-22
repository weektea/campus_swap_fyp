import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterSortModal extends StatefulWidget {
  final String initialSortBy;
  final int initialCategoryIndex;
  final String? initialCondition;
  final String initialListingType;
  final RangeValues initialPriceRange;
  final List<Map<String, dynamic>> categories;
  
  final Function({
    required String sortBy,
    required int categoryIndex,
    required String? condition,
    required String listingType,
    required RangeValues priceRange,
  }) onApply;

  const FilterSortModal({
    super.key,
    required this.initialSortBy,
    required this.initialCategoryIndex,
    required this.initialCondition,
    required this.initialListingType,
    required this.initialPriceRange,
    required this.categories,
    required this.onApply,
  });

  @override
  State<FilterSortModal> createState() => _FilterSortModalState();
}

class _FilterSortModalState extends State<FilterSortModal> {
  late String _sortBy;
  late int _categoryIndex;
  late String? _condition;
  late String _listingType;
  late RangeValues _priceRange;

  int _activeTabIndex = 0;
  final List<String> _tabs = [
    'Sort By',
    'Category',
    'Condition',
    'Listing Type',
    'Price'
  ];

  @override
  void initState() {
    super.initState();
    _sortBy = widget.initialSortBy;
    _categoryIndex = widget.initialCategoryIndex;
    _condition = widget.initialCondition;
    _listingType = widget.initialListingType;
    _priceRange = widget.initialPriceRange;
  }

  void _reset() {
    setState(() {
      _sortBy = 'newest';
      _categoryIndex = 0;
      _condition = null;
      _listingType = 'All';
      _priceRange = const RangeValues(0, 1000);
    });
  }

  void _apply() {
    widget.onApply(
      sortBy: _sortBy,
      categoryIndex: _categoryIndex,
      condition: _condition,
      listingType: _listingType,
      priceRange: _priceRange,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // 80% of screen height
    final height = MediaQuery.of(context).size.height * 0.8;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24), // Balance for centering
                Text(
                  'Filter & Sort',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          // Main Body Split View
          Expanded(
            child: Row(
              children: [
                // Left Column (Tabs)
                Container(
                  width: MediaQuery.of(context).size.width * 0.3,
                  color: Colors.grey[100],
                  child: ListView.builder(
                    itemCount: _tabs.length,
                    itemBuilder: (context, index) {
                      final isActive = _activeTabIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeTabIndex = index;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isActive ? Colors.white : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isActive ? primaryColor : Colors.transparent,
                                width: 4,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          child: Text(
                            _tabs[index],
                            style: GoogleFonts.outfit(
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive ? primaryColor : Colors.grey[700],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Right Column (Content)
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: IndexedStack(
                      index: _activeTabIndex,
                      children: [
                        _buildSortByContent(),
                        _buildCategoryContent(),
                        _buildConditionContent(),
                        _buildListingTypeContent(),
                        _buildPriceContent(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Sticky Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: OutlinedButton(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Reset',
                      style: GoogleFonts.outfit(color: Colors.grey[700], fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 7,
                  child: ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Apply',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Content Builders ---

  Widget _buildSortByContent() {
    final options = [
      {'label': 'Popularity', 'value': 'popular'},
      {'label': 'Newest', 'value': 'newest'},
      {'label': 'Price: High to Low', 'value': 'price_desc'},
      {'label': 'Price: Low to High', 'value': 'price_asc'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final opt = options[index];
        return RadioListTile<String>(
          value: opt['value']!,
          groupValue: _sortBy,
          onChanged: (val) => setState(() => _sortBy = val!),
          title: Text(opt['label']!, style: GoogleFonts.outfit(fontSize: 14)),
          activeColor: Theme.of(context).colorScheme.primary,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        );
      },
    );
  }

  Widget _buildCategoryContent() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.categories.length,
      itemBuilder: (context, index) {
        final cat = widget.categories[index];
        return RadioListTile<int>(
          value: index,
          groupValue: _categoryIndex,
          onChanged: (val) => setState(() => _categoryIndex = val!),
          title: Row(
            children: [
              Icon(cat['icon'], size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(cat['label'], style: GoogleFonts.outfit(fontSize: 14)),
            ],
          ),
          activeColor: Theme.of(context).colorScheme.primary,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        );
      },
    );
  }

  Widget _buildConditionContent() {
    final conditions = ['Brand New', 'Like New', 'Lightly Used', 'Well Used'];
    
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        CheckboxListTile(
          value: _condition == null,
          onChanged: (val) => setState(() => _condition = null),
          title: Text('Any Condition', style: GoogleFonts.outfit(fontSize: 14)),
          activeColor: Theme.of(context).colorScheme.primary,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        ...conditions.map((cond) => CheckboxListTile(
          value: _condition == cond,
          onChanged: (val) {
            setState(() {
              _condition = (val == true) ? cond : null;
            });
          },
          title: Text(cond, style: GoogleFonts.outfit(fontSize: 14)),
          activeColor: Theme.of(context).colorScheme.primary,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          controlAffinity: ListTileControlAffinity.leading,
        ))
      ],
    );
  }

  Widget _buildListingTypeContent() {
    final types = ['All', 'Sale', 'Rent'];
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: types.length,
      itemBuilder: (context, index) {
        final type = types[index];
        return RadioListTile<String>(
          value: type,
          groupValue: _listingType,
          onChanged: (val) => setState(() => _listingType = val!),
          title: Text(type, style: GoogleFonts.outfit(fontSize: 14)),
          activeColor: Theme.of(context).colorScheme.primary,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        );
      },
    );
  }

  Widget _buildPriceContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price Range', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RM ${_priceRange.start.round()}', style: GoogleFonts.outfit(color: Colors.grey[700])),
              Text('RM ${_priceRange.end.round()}', style: GoogleFonts.outfit(color: Colors.grey[700])),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 1000,
            divisions: 20,
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            labels: RangeLabels(
              'RM ${_priceRange.start.round()}', 
              'RM ${_priceRange.end.round()}'
            ),
            onChanged: (values) {
              setState(() {
                _priceRange = values;
              });
            },
          ),
        ],
      ),
    );
  }
}
