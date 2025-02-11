import 'package:flutter/material.dart';
import 'package:golden_tracker_enterprise/widgets/bar_graph.dart';
import 'package:golden_tracker_enterprise/widgets/session_screen.dart';

import '../widgets/index.dart';
import '../styles/index.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.session});
  final Session session;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );

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

  // Future fetchSalesData(String accessToken) async {
  //   final url = Uri.https(
  //     'noah.goldentopper.com',
  //     '/GT_NOAHAPI_UAT/API/Get/RESBSalesReservationRpt',
  //   );
  //
  //   var salesData = await http.requestJson(
  //       url,
  //       method: http.RequestMethod.get,
  //       headers: {
  //         'apiKey': '$kNoahApiKey-RESBSalesReservationRpt',
  //         'secretkey': kNoahSecretKey,
  //         'access_token': accessToken,
  //       },
  //       body: {
  //         'date_filter': '4',
  //         'date_from': '01/01/2024',
  //         'date_to': '12/31/2024',
  //       }
  //   );
  //
  //   print('Sales: $salesData');
  // }

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
          _SalesReportView(),
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

class _SalesReportView extends StatelessWidget {
  const _SalesReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: Column(
          children: [
            // Text('Sales report'),
            BarGraph(
              title: 'Monthly Sales',
              data: BarGraphData(
                barGroups: [
                  BarGroup(
                    label: 'JAN',
                    barRods: [SolidBarRod(label: 'Sales', toY: 15)],
                  ),
                  BarGroup(
                    label: 'FEB',
                    barRods: [SolidBarRod(label: 'Sales', toY: 15)],
                  ),
                  BarGroup(
                    label: 'MAR',
                    barRods: [SolidBarRod(label: 'Sales', toY: 15)],
                  ),
                  BarGroup(
                    label: 'APR',
                    barRods: [SolidBarRod(label: 'Sales', toY: 15)],
                  ),
                  BarGroup(
                    label: 'JUN',
                    barRods: [SolidBarRod(label: 'Sales', toY: 15)],
                  ),
                ],
                legends: {'Sales': Colors.green},
              ),
            ),
            BarGraph(
              title: 'Daily Sales',
              data: BarGraphData(
                barGroups: [],
                legends: {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
