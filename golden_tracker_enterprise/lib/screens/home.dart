import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/http_request.dart' as http;
import '../widgets/index.dart';
import '../styles/index.dart';

import '../secret.dart';

const Map<String, String> kProjectNames = {
  'CC': 'City Clou',
  'ES': 'El Sol',
  'LV': 'La Vida',
  'PO': 'Park One',
};

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

  final DateTime _earliestDate = DateTime(2019);
  late DateTime _fromDate;
  late DateTime _toDate;
  List<String>? _selectedProjects;

  String? _selectedProject;

  List<Report> _salesReports = [];
  List<Report> _inventoryReports = [];
  List<Report> _priceReports = [];

  final List<SearchItem<String>> _projects = [
    SearchItem(title: 'All Projects', value: ''),
  ];

  final StreamController<List> _salesStreamController =
      StreamController<List>.broadcast();

  Stream<List> get _salesData => _salesStreamController.stream;

  final StreamController<List> _inventoryStreamController =
      StreamController<List>.broadcast();

  Stream<List> get _inventoryData => _inventoryStreamController.stream;

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
    if (!_salesStreamController.isClosed) {
      _salesStreamController.close();
    }

    if (!_inventoryStreamController.isClosed) {
      _inventoryStreamController.close();
    }
    super.dispose();
  }

  void _setProjects(List inventoryData) {
    Map<String, List<String>> projects = {};

    for (int i = 0; i < inventoryData.length; i++) {
      String crossCode = inventoryData[i]['cross_reference_code'].toString();
      String newProjCode = inventoryData[i]['code'];

      if (crossCode.isEmpty || !newProjCode.endsWith('UT')) {
        continue;
      }

      String proj = newProjCode.substring(0, 2);
      List? projCodes = projects[proj];

      if (projCodes == null) {
        projects[proj] = [newProjCode];
      } else if (!projCodes.contains(newProjCode)) {
        projects[proj]!.add(newProjCode);
      }
    }

    Iterable<String> keys = projects.keys;
    _projects.addAll(List.generate(
      projects.length,
      (i) {
        String proj = keys.elementAt(i);
        return SearchItem(
            title: kProjectNames[proj] ?? 'Unknown',
            value: projects[proj]!.join('|'));
      },
    ));
  }

  void _retrieveReports() async {
    final salesData = await _fetchSalesData();
    _salesReports = [
      SalesReport.monthlySales.generate(salesData, _fromDate, _toDate),
      SalesReport.yearlySalesOverall.generate(
        salesData,
        _earliestDate,
        DateTime.now(),
      ),
    ];

    _salesStreamController.sink.add(salesData);

    final inventoryData = await _fetchInventoryData();
    // _inventoryReports = [];

    if (_projects.length <= 1) {
      _setProjects(inventoryData);
    }

    _inventoryStreamController.sink.add(inventoryData);
  }

  Future<List> _fetchSalesData() async {
    final url = Uri.https(
      kEnvironmentVariables['noah_domain'],
      '/GT_NOAHAPI_${kAppEnvironment == 'prod' ? 'LIVE' : 'UAT'}/API/Get/RESBSalesReservationRpt',
    );

    String fromDate = _noahDateFormatter.format(_earliestDate);
    String toDate = _noahDateFormatter.format(DateTime.now());

    print('Projects: ${_selectedProjects?.join('|')}');

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
        'date_from': fromDate,
        'date_to': toDate,
        'location_filter': '',
        'rsv_ctrl_no_filter': '',
        'unit_filter': '',
        'project_filter': _selectedProject ?? '',
        'customer_filter': '',
        'seller_filter': '',
        'account_status_filter': '003|004|005|006|007|011|012|013|',
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

  Future<List> _fetchInventoryData() async {
    final url = Uri.https(
      kEnvironmentVariables['noah_domain'],
      '/GT_NOAHAPI_${kAppEnvironment == 'prod' ? 'LIVE' : 'UAT'}/API/Get/REIVUnitInventoryStatusRpt',
    );

    String toDate = _noahDateFormatter.format(DateTime.now());

    var inventory = await http.requestJson(
      url,
      method: http.RequestMethod.post,
      headers: {
        'apiKey': '$kNoahApiKey-REIVUnitInventoryStatusRpt',
        'secretkey': kNoahReportSecretKey,
        'access_token': widget.session.token,
      },
      body: {
        "as_of_date": toDate,
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

    return inventory['data']['Main'];
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
      onDateChanged: (date) => setState(() {
        _fromDate = date;
      }),
    );
  }

  Widget _toDateFieldBuilder({bool dropdown = true}) {
    return DateFormField(
      labelText: 'To',
      firstDate: _fromDate,
      lastDate: DateTime.now(),
      selectedDate: _toDate,
      dropdown: dropdown,
      onDateChanged: (date) => setState(() {
        _toDate = date;
      }),
    );
  }

  PreferredSize _filterHeaderBuilder(BuildContext context, Layout layout) {
    return PreferredSize(
      preferredSize: Size(
        double.infinity,
        layout.deviceType.isDesktop ? 56 : 112,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flex(
              direction: Axis.horizontal,
              children: [
                Flexible(
                  child: SelectFormField<String>(
                    label: 'Project',
                    items: _projects,
                    enableSearch: false,
                    onSelectItem: (item) {
                      print(item.value);
                      _selectedProject = item.value.isEmpty ? null : item.value;
                      print(_selectedProject);
                    },
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
        return ReportView(
          reports: _salesReports,
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
          onTap: (index) {
            _retrieveReports();
          },
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
