import 'package:flutter/material.dart';
import 'package:golden_tracker_enterprise/widgets/index.dart';
import '../entities/user.dart';
import '../styles/index.dart';

import '../widgets/responsive_layout.dart';
import '../widgets/session_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.title = 'Home Page'});
  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 3, vsync: this);
  final DateTime _earliestDate = DateTime(2018);

  late DateTime _fromDate;
  late DateTime _toDate;

  final List<SearchItem<String?>> _projects = [
    SearchItem(title: 'City Clou', value: 'CC'),
    SearchItem(title: 'El Sol', value: 'EL'),
    SearchItem(title: 'La Vida', value: 'LV'),
    SearchItem(title: 'Park One', value: 'PO'),
    SearchItem(title: 'All Projects', value: null),
  ];

  @override
  void initState() {
    _toDate = DateTime.now();
    _fromDate = _toDate.copyWith(
      year: (_toDate.month > 6) ? null : _toDate.year - 1,
      month: 1,
      day: 1,
    );
    super.initState();
  }

  PreferredSizeWidget _appBarBuilder(BuildContext context, Layout layout) {
    return AppBar(
      backgroundColor: kSecondaryContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shadowColor: Colors.black45,
      title: const Text('Live Progress Report'),
      centerTitle: false,
      bottomOpacity: 1.0,
      toolbarHeight: 56,
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.refresh),
        ),
        SizedBox(width: 12),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.download),
        ),
        SizedBox(width: 12),
      ],
      bottom: _filterHeaderBuilder(context, layout),
    );
  }

  Widget _fromDateFieldBuilder({bool dropdown = true}) {
    return DateFormField(
      labelText: 'From',
      firstDate: _earliestDate,
      lastDate: _toDate,
      selectedDate: _fromDate,
      dropdown: dropdown,
      onDateChanged: (date) {
        setState(() {
          _fromDate = date;
        });
      },
    );
  }

  Widget _toDateFieldBuilder({bool dropdown = true}) {
    return DateFormField(
      labelText: 'To',
      firstDate: _fromDate,
      lastDate: DateTime.now(),
      selectedDate: _toDate,
      dropdown: dropdown,
      onDateChanged: (date) {
        setState(() {
          _toDate = date;
        });
      },
    );
  }

  PreferredSize _filterHeaderBuilder(BuildContext context, Layout layout) {
    return PreferredSize(
      preferredSize:
          Size(double.infinity, layout.deviceType.isDesktop ? 56 : 112),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flex(
              direction: Axis.horizontal,
              children: [
                Flexible(
                  child: SelectFormField<String?>(
                    label: 'Project',
                    items: _projects,
                    enableSearch: false,
                    // filterItemsBuilder: (text) {
                    //   RegExp matchRegex = RegExp(text, caseSensitive: false);
                    //   return _projects
                    //       .where((proj) => matchRegex.hasMatch(proj.title));
                    // },
                  ),
                ),
                SizedBox(width: 12),
                if (layout.deviceType.isDesktop) ...[
                  Flexible(
                    child: _fromDateFieldBuilder(
                      dropdown: layout.deviceType.isDesktop,
                    ),
                  ),
                  SizedBox(width: 12),
                  Flexible(
                    child: _toDateFieldBuilder(
                      dropdown: layout.deviceType.isDesktop,
                    ),
                  ),
                ] else
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.keyboard_double_arrow_down),
                  ),
              ],
            ),
            if (!layout.deviceType.isDesktop) SizedBox(height: 16),
            if (!layout.deviceType.isDesktop)
              Flex(
                direction: Axis.horizontal,
                children: [
                  Flexible(
                    child: _fromDateFieldBuilder(
                      dropdown: layout.deviceType.isDesktop,
                    ),
                  ),
                  SizedBox(width: 12),
                  Flexible(
                    child: _toDateFieldBuilder(
                      dropdown: layout.deviceType.isDesktop,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _responsiveBuild(BuildContext context, Layout layout) {
    return Scaffold(
      appBar: _appBarBuilder(context, layout),
      persistentFooterAlignment: AlignmentDirectional.centerStart,
      persistentFooterButtons: [
        TabBar(
          controller: _tabController,
          isScrollable: !layout.deviceType.isDesktop,
          tabAlignment: layout.deviceType.isDesktop
              ? TabAlignment.fill
              : TabAlignment.center,
          labelPadding: EdgeInsets.symmetric(horizontal: 20),
          tabs: [
            Tab(text: 'Property Sales'),
            Tab(text: 'Inventory'),
            Tab(text: 'Price Trend'),
          ],
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Sales report
          SingleChildScrollView(
            child: Column(
              children: [Text('Property Sales Report')],
            ),
          ),
          // Inventory report
          SingleChildScrollView(
            child: Column(
              children: [Text('Inventory Report')],
            ),
          ),
          // Price Trend report
          SingleChildScrollView(
            child: Column(
              children: [Text('Price Trend Report')],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _responsiveBuild(context, ResponsiveLayout.layoutOf(context));
  }
}
