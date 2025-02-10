import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../entities/user.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({
    super.key,
    this.onCreateSession,
    this.onDeleteSession,
    this.onRefreshSession,
    required this.sessionLocalStorageName,
    required this.child,
  });

  final Widget child;
  final String sessionLocalStorageName;
  final void Function(Session session)? onRefreshSession;
  final void Function(Session session)? onCreateSession;
  final void Function(Session session)? onDeleteSession;

  @override
  State<SessionScreen> createState() => _SessionScreenState();

  static Session? sessionOf(BuildContext context) {
    final SessionProvider? inheritedContext =
        context.dependOnInheritedWidgetOfExactType<SessionProvider>();

    assert(
      inheritedContext != null,
      'No SessionProvider found in context',
    );

    return inheritedContext!.session;
  }

  static SessionProvider of(BuildContext context) {
    final SessionProvider? inheritedContext =
        context.dependOnInheritedWidgetOfExactType<SessionProvider>();

    assert(
      inheritedContext != null,
      'No SessionProvider found in context',
    );

    return inheritedContext!;
  }
}

class _SessionScreenState extends State<SessionScreen> {
  Session? _session;

  @override
  void initState() {
    super.initState();
  }

  void _updateSession(Session newSession) {
    if (_session == null) {
      setState(() => _session = newSession);
      widget.onCreateSession?.call(newSession);
    } else {
      setState(() => _session = newSession);
      widget.onRefreshSession?.call(newSession);
    }
  }

  void _deleteSession(Session session) {
    setState(() {
      _session = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SessionProvider(
      session: _session,
      createSession: _updateSession,
      refreshSession: _updateSession,
      deleteSession: _deleteSession,
      child: widget.child,
    );
  }
}

class SessionProvider extends InheritedWidget {
  const SessionProvider({
    super.key,
    required this.session,
    required this.createSession,
    required this.deleteSession,
    required this.refreshSession,
    required super.child,
  });

  final Session? session;
  final void Function(Session) refreshSession;
  final void Function(Session) createSession;
  final void Function(Session) deleteSession;

  static SessionProvider of(BuildContext context) {
    final SessionProvider? result =
        context.dependOnInheritedWidgetOfExactType<SessionProvider>();
    assert(result != null, 'No SessionProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(SessionProvider oldWidget) {
    return (oldWidget.session?.isExpired) ?? false;
  }
}

class Session {
  Session({
    required this.token,
    required this.user,
    this.expiresOn,
    this.autoRefresh = false,
  });

  final String token;
  final User user;
  final DateTime? expiresOn;
  final bool autoRefresh;

  static Session fromJson(Map<String, dynamic> json) {
    return Session(
      token: json['access_token'],
      user: EmployeeUser(
        id: json['id'],
        password: json['password'],
        firstName: json['first_name'],
        taxId: json['tad_id'],
        designation: json['designation'],
      ),
      expiresOn: DateTime.tryParse(json['expires_od'] ?? ''),
    );
  }

  bool get isExpired {
    if (expiresOn == null) {
      return false;
    }

    return DateTime.now().isAfter(expiresOn!);
  }
}
