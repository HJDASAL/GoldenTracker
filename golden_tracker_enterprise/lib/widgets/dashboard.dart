import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../styles/colors.dart';

import '../models/screen.dart';
import '../widgets/index.dart';
import '../widgets/session_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({
    super.key,
    required this.navigationShell,
    required this.subScreens,
    required this.session,
  });

  final StatefulNavigationShell navigationShell;
  final List<Screen> subScreens;
  final Session session;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late int _currentSection;

  bool _extendSideBar = false;

  List<NavigationRailDestination> get _destinations {
    return List.generate(widget.subScreens.length, (i) {
      Screen screen = widget.subScreens[i];
      return NavigationRailDestination(
        icon: Icon(screen.icon ?? Icons.flag),
        padding: EdgeInsets.all(8.0),
        label: Text(screen.label ?? 'Section ${i + 1}'),
      );
    });
  }

  @override
  void initState() {
    String currentPath = GoRouter.of(context).state!.path ?? '/';

    _currentSection = widget.subScreens.indexWhere(
      (screen) => screen.path == currentPath,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Layout initialLayout = ResponsiveLayout.layoutOf(context);

      setState(() {
        _extendSideBar = initialLayout.deviceType.isDesktop;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _changeSection(int index) {
    GoRouter.of(context).go(
      widget.subScreens[index].path,
      extra: {'session': widget.session},
    );

    _currentSection = index;
    _scaffoldKey.currentState!.closeDrawer();
  }

  void _toggleSideBar({bool sideBarInDrawer = false}) {
    if (sideBarInDrawer) {
      if (!_extendSideBar || !_scaffoldKey.currentState!.isDrawerOpen) {
        _scaffoldKey.currentState!.openDrawer();
      } else {
        _scaffoldKey.currentState!.closeDrawer();
      }
    }

    setState(() {
      _extendSideBar = !_extendSideBar;
    });
  }

  /// Creates a message greeting depending on the time of day
  String _generateGreeting() {
    DateTime now = DateTime.now();
    int hours = now.hour;
    if (hours >= 4 && hours <= 12) {
      return 'Golden morning,';
    } else if (hours >= 12 && hours <= 16) {
      return 'Golden afternoon,';
    } else if (hours >= 16 && hours <= 20) {
      return 'Golden evening,';
    } else {
      return 'Great work and rest well,';
    }
  }

  Widget _navigationBarBuilder(bool extended) {
    return NavigationRail(
      leading: Container(
        padding: extended
            ? EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : EdgeInsets.only(bottom: 32, top: 8),
        alignment: Alignment.center,
        width: (extended) ? kMobileBreakpoint / 2 : 56,
        child: Row(
          // mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              extended ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            SizedBox.square(
              dimension: (extended) ? 52 : 36,
              child: Image.asset('assets/images/gt-logo.png'),
            ),
            if (extended) const SizedBox(width: 12),
            if (extended)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_generateGreeting()),
                  Text(
                    '${widget.session.user.shortName}!',
                    style: Theme.of(context).textTheme.titleLarge,
                    softWrap: true,
                  ),
                  // employee's first name
                ],
              ),
          ],
        ),
      ),
      extended: extended,
      indicatorShape: CircleBorder(),
      minWidth: 56,
      minExtendedWidth: kMobileBreakpoint / 2,
      indicatorColor: kPrimary,
      selectedLabelTextStyle: Theme.of(context)
          .textTheme
          .titleSmall!
          .copyWith(fontWeight: FontWeight.bold),
      unselectedLabelTextStyle: Theme.of(context).textTheme.titleSmall,
      elevation: 2,
      destinations: _destinations,
      selectedIndex: _currentSection,
      onDestinationSelected: _changeSection,
    );
  }

  Widget _userBarDrawerBuilder() {
    return Drawer(
      shape: RoundedRectangleBorder(),
      child: Flex(
        direction: Axis.vertical,
        children: [
          DrawerHeader(child: Text('User\'s Account')),
          Expanded(child: Text('Account details')),
          Padding(
            padding: EdgeInsets.all(12),
            child: TextButton(
              onPressed: () async {
                context.replace(
                  '/login',
                  extra: {'logOutUsername': widget.session.user.id},
                );
              },
              child: Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bodyBuilder(Layout layout) {
    return Material(
      elevation: 5,
      child: Flex(
        direction: Axis.vertical,
        children: [
          AppBar(
            leading: IconButton(
              onPressed: () => _toggleSideBar(
                sideBarInDrawer: !layout.deviceType.isDesktop,
              ),
              icon: RotatedBox(
                quarterTurns: 1,
                child: Icon(Icons.open_in_browser),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  _scaffoldKey.currentState!.openEndDrawer();
                },
                icon: CircleAvatar(child: Icon(Icons.person)),
              ),
            ],
          ),
          Expanded(child: widget.navigationShell),
        ],
      ),
    );
  }

  Widget _responsiveBuild(BuildContext context, Layout layout) {
    return Scaffold(
      key: _scaffoldKey,
      // account-specific details placed here
      endDrawer: _userBarDrawerBuilder(),
      drawer: (!layout.deviceType.isDesktop)
          ? AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: Drawer(
                shape: RoundedRectangleBorder(),
                elevation: 4,
                width: kMobileBreakpoint / 2,
                child: _navigationBarBuilder(true),
              ),
            )
          : null,
      onDrawerChanged: (isOpen) => setState(() {
        _extendSideBar = isOpen;
      }),
      body: Row(
        // direction: Axis.horizontal,
        children: [
          if (layout.deviceType.isDesktop)
            _navigationBarBuilder(_extendSideBar),
          Expanded(child: _bodyBuilder(layout)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _responsiveBuild(context, ResponsiveLayout.of(context).layout);
  }
}