import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/http_request.dart' as http;
import '../widgets/index.dart';
import '../styles/index.dart';

import '../secret.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.session});
  final Session session;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  /// Controller for report tabs
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );

  final DateFormat _noahDateFormatter = DateFormat('MM/dd/yyyy');

  final DateTime _earliestDate = DateTime(2018);
  late DateTime _fromDate;
  late DateTime _toDate;
  List<String>? _selectedProjects;

  List _inventoryData = [];

  List<Report> _salesReports = [];
  List<Report> _invetoryReports = [];
  List<Report> _priceReports = [];

  final List<SearchItem<String?>> _projects = [
    SearchItem(title: 'City Clou', value: 'CC'),
    SearchItem(title: 'El Sol', value: 'EL'),
    SearchItem(title: 'La Vida', value: 'LV'),
    SearchItem(title: 'Park One', value: 'PO'),
    SearchItem(title: 'All Projects', value: null),
  ];

  final StreamController<List> _salesStreamController =
      StreamController<List>.broadcast();

  Stream<List> get _salesData => _salesStreamController.stream;

  @override
  void initState() {
    _toDate = DateTime.now();
    _fromDate = _toDate.copyWith(
      year: (_toDate.month > 6) ? null : _toDate.year - 1,
      month: 1,
      day: 1,
    );

    _retrieveReports();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _retrieveReports() async {
    final data = await _fetchSalesData();
    _salesReports = [
      ReportType.monthlySales.generate(data, _fromDate, _toDate)!
    ];

    _salesStreamController.sink.add(data);
  }

  Future<List> _fetchSalesData() async {
    final url = Uri.https(
      'noah.goldentopper.com',
      '/GT_NOAHAPI_UAT/API/Get/RESBSalesReservationRpt',
    );

    String fromFormat = _noahDateFormatter.format(_fromDate);
    String toFormat = _noahDateFormatter.format(_toDate);

    dynamic sales = await http.requestJson(
      url,
      method: http.RequestMethod.post,
      headers: {
        'apiKey': '$kNoahApiKey-RESBSalesReservationRpt',
        'secretkey': kNoahReportSecretKey,
        'access_token': widget.session.token,
      },
      body: {
        'date_filter': '4',
        'date_value': '',
        'date_from': fromFormat,
        'date_to': toFormat,
        'location_filter': '',
        'rsv_ctrl_no_filter': '',
        'unit_filter': '',
        'project_filter': (_selectedProjects?.join('|')) ?? '',
        'customer_filter': '',
        'seller_filter': '',
        'account_status_filter': '003|004|005|006|007|012|013',
        'with_payment': '1',
        'without_payment': ''
      },
    );

    sales = sales['data']['Main'] as List;

    sales.sort((a, b) {
      return a['reservation_date'].toString().compareTo(b['reservation_date']);
    });

    return sales;
  }

  void _fetchInventoryData() async {
    final url = Uri.https(
      'noah.goldentopper.com',
      '/GT_NOAHAPI_UAT/API/Get/REIVUnitInventoryStatusRpt',
    );

    String fromFormat = _noahDateFormatter.format(_fromDate);
    String toFormat = _noahDateFormatter.format(_toDate);

    var inventory = await http.requestJson(
      url,
      method: http.RequestMethod.post,
      headers: {
        'apiKey': '$kNoahApiKey-REIVUnitInventoryStatusRpt',
        'secretkey': kNoahReportSecretKey,
        'access_token': widget.session.token,
      },
      body: {
        "as_of_date": toFormat,
        "location": "",
        "project_filter": "",
        "tower_filter": "",
        "unit_filter": "",
        "inventory_type_filter": "",
        "inventory_group_filter": "",
        "inventory_class_filter": "",
        "item_status_filter": "",
        "record_status_filter": ""
      },
    );

    _inventoryData = inventory['data']['Main'];
    print(_inventoryData);
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
          onPressed: () => setState(() {
            _retrieveReports();
          }),
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
      onDateChanged: (date) => _fromDate = date,
    );
  }

  Widget _toDateFieldBuilder({bool dropdown = true}) {
    return DateFormField(
      labelText: 'To',
      firstDate: _fromDate,
      lastDate: DateTime.now(),
      selectedDate: _toDate,
      dropdown: dropdown,
      onDateChanged: (date) =>_toDate = date,
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

  Widget _salesReportBuilder(context, AsyncSnapshot<List> snapshot) {
    final sales = snapshot.data;

    if (snapshot.hasError) {
      return Center(child: Icon(Icons.error_outline));
    }

    ConnectionState state = snapshot.connectionState;

    switch (state) {
      case ConnectionState.none:
        return Center(child: Text('No data'));
      case ConnectionState.waiting:
        return Center(child: CircularProgressIndicator());
      default:
        return _SalesReportView(
          reports: [
            ReportType.monthlySales
                .generate(sales!, _fromDate, _toDate)!
          ],
          fromDate: _fromDate,
          toDate: _toDate,
        );
    }
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
        children: [
          // Sales report
          StreamBuilder<List>(
            stream: _salesData,
            builder: _salesReportBuilder,
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

enum SalesReport {
  monthlySales,
  totalMonthlySales;
}

class _SalesReportView extends StatelessWidget {
  _SalesReportView({
    required this.reports,
    required this.fromDate,
    required this.toDate,
    this.projectCode,
  });
  
  @override
  Key? get key => Key(Random().nextDouble().toString());

  final String? projectCode;
  final DateTime fromDate;
  final DateTime toDate;
  final List<Report> reports;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: Column(
          children: List.generate(reports.length, (i) {
            return reports[i].toGraphWidget();
          }),
        ),
      ),
    );
  }
}
