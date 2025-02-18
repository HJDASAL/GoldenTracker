import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:golden_tracker_enterprise/widgets/session_screen.dart';

import 'package:hive/hive.dart';
import '../local_entities/index.dart';
import 'package:go_router/go_router.dart';

import '../styles/colors.dart';
import '../widgets/index.dart';
import '../models/http_request.dart' as http;
import '../entities/user.dart';

import '../secret.dart';

/// Login Screen Widget
class LoginScreen extends StatefulWidget {

  const LoginScreen({
    super.key,
    required this.initialAuthorizedLocation,
    this.logOutUsername,
  });


  final String initialAuthorizedLocation;
  final String? logOutUsername;


  /// Create State for LoginScreen Widget
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// Login Screen Login State
class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  /// Initialize Sessions
  late final Box<HiveSession> _sessions;


  /// Initialize variables for Login
  String _username = '';
  String _password = '';
  bool _passwordVisible = false;
  bool _keepLoggedIn = false;
  bool _loading = false;

  /// Initialize State
  @override
  void initState() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _getSessionsBox(context);
    });

    super.initState();
  }

  @override
  void dispose() {
    // _sessions.close();
    super.dispose();
  }

  /// Set Session Box State
  void _getSessionsBox(BuildContext context) async {
    // check if session is still valid
    if (Hive.isBoxOpen('session')) {
      _sessions = Hive.box<HiveSession>('session');
      log('Session box already opened');
    } else {
      log('Opening Session box...');
      _sessions = await Hive.openBox<HiveSession>('session');
    }

    if (widget.logOutUsername != null) {
      String username = widget.logOutUsername!;
      _removeSession(username);

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Removed session for ${username.toUpperCase()}. See you again soon!',
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(12),
            hitTestBehavior: HitTestBehavior.translucent,
          ),
          snackBarAnimationStyle: AnimationStyle(
            curve: Curves.bounceIn,
            reverseCurve: Curves.bounceOut,
          ),
        );
      }
    } else {
      _checkExistingSession();
    }
  }

  /// Authenticates user given the credentials they entered.
  void _loginUser(BuildContext context) async {
    final url = Uri.https(
      kEnvironmentVariables['noah_domain'],
      '/GT_NOAHAPI_${kAppEnvironment == 'dev' ? 'UAT' : 'LIVE'}/API/Get/NOAHAuth',
    );

    var sessionData = await http.requestJson(
      url,
      method: http.RequestMethod.post,
      headers: {
        'apiKey': '$kNoahApiKey-NOAHAuth',
        'secretkey': kNoahSecretKey,
        'username': _username,
        'password': _password,
      },
    );

    /// Check if Session Status is Success and if Context is mounted
    if (sessionData['status'] != 200 && context.mounted) {
      log('Login unsuccessful. ${sessionData['message']}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login unsuccessful. ${sessionData['message']}'),
            margin: const EdgeInsets.all(12),
            dismissDirection: DismissDirection.vertical,
            behavior: SnackBarBehavior.floating,
          ),
          snackBarAnimationStyle: AnimationStyle(
            curve: Curves.bounceIn,
            reverseCurve: Curves.bounceOut,
          ),
        );
      }
      return;
    }

    /// Defining Session Data
    sessionData = sessionData['data'][0];

    log('$sessionData');

    /// Set Session Data on successful login
    Session session = Session(
      token: sessionData['access_token'],
      user: EmployeeUser(
        id: _username,
        password: _password,
        firstName: sessionData['name'],
        taxId: 'taxId',
        designation: 'designation',
      ),
      autoRefresh: _keepLoggedIn,
      expiresOn: DateTime.tryParse(sessionData['expires'] ?? ''),
    );


    /// Save and Start Session
    _saveSession(session);
    _startSession(session);
  }

  /// Redirects to [initialAuthorizedLocation]
  void _startSession(Session session) async {
    if (session.expiresOn == null) {
      log('Session for ${session.user.id} is valid indefinitely.');
    } else {
      log('Session for ${session.user.id} is valid for ${session.expiresOn!.difference(DateTime.now()).inSeconds} seconds.');
    }

    GoRouter.of(context).replace(
      widget.initialAuthorizedLocation,
      extra: {'session': session},
    );
  }

  /// Saves Session to Session Box
  void _saveSession(Session session) async {

    /// Define Previous Session
    HiveSession? prevSession = _sessions.get(session.user.id);

    /// If previous session is null save a new Session
    if (prevSession == null) {
      await _sessions.put(
        session.user.id,
        HiveSession(
          session.user.id,
          password: session.user.password,
          token: session.token,
          autoRefresh: session.autoRefresh,
          expiresOn: session.expiresOn,
        ),
      );

      log('New session saved.');
    } else if (session.expiresOn != prevSession.expiresOn) {
      /// Refresh Session Data if previous Session and new Session is not equal
      // prevSession.token = session.token;
      prevSession.autoRefresh = session.autoRefresh;
      prevSession.expiresOn = session.expiresOn;

      /// Save/Update Session
      prevSession.save();

      log('Updated session.');
    }
  }


  /// Checks if there is an existing Session
  void _checkExistingSession({String? username}) {
    log('Checking existing session...');


    /// If Session box is empty return no sessions saves
    if (_sessions.isEmpty) {
      log('No sessions saved.');
      return;
    }

    final HiveSession? session =
        (username == null) ? _sessions.getAt(0) : _sessions.get(username);


    /// Check if session has existing sessions
    if (session == null) {
      log('No existing sessions found.');
    } else if (session.isExpired && session.autoRefresh) {
      // create new session
      log('Session expired for ${session.username} on ${session.expiresOn}. Refreshing session...');
      _username = session.username;
      _password = session.password;
      _keepLoggedIn = true;

      _loginUser(context);
    } else if (session.isExpired) {
      log('Session expired for ${session.username} on ${session.expiresOn}');
      _removeSession(session.username);
    } else {
      _startSession(
        Session(
          token: session.token,
          expiresOn: session.expiresOn,
          autoRefresh: session.autoRefresh,
          user: EmployeeUser(
            id: session.username,
            password: session.password,
            firstName: session.username,
            taxId: 'taxId',
            designation: 'designation',
          ),
        ),
      );
    }
  }

  /// Remove Sessions from session box
  void _removeSession(String username) async {
    await _sessions.delete(username);
    log('Removed session for $username.');
  }

  /// Login Widget
  Widget _responsiveBuild(BuildContext context, Layout layout) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                stops: [0.0, 0.6, 1.0],
                colors: [kPrimary, kPrimaryContainer, kPrimary],
              ),
            ),
          ),
          // StreamBuilder<Map<String, dynamic>?>(stream: Stre, builder: builder)
          Center(
            child: _LoginFormCard(
              layout,
              formKey: _formKey,
              usernameFocusNode: _usernameFocusNode,
              passwordFocusNode: _passwordFocusNode,
              autofocusUsernameField: widget.logOutUsername == null,
              loading: _loading,
              onChangeUserName: (username) => setState(() {
                _username = username;
              }),
              onChangePassword: (password) => setState(() {
                _password = password;
              }),
              onSubmit: () {
                setState(() => _loading = true);
                if (_formKey.currentState!.validate()) {
                  _loginUser(context);
                }
                setState(() => _loading = false);
              },
              onValidateUserName: (username) {
                if (_usernameFocusNode.hasFocus ||
                    _passwordFocusNode.hasFocus) {
                  return null;
                } else if (username == null || username.isEmpty) {
                  return 'required';
                }
                return null;
              },
              onValidatePassword: (password) {
                if (_passwordFocusNode.hasFocus ||
                    _usernameFocusNode.hasFocus) {
                  return null;
                } else if (password == null || password.isEmpty) {
                  return 'required';
                }
                return null;
              },
              passwordVisible: _passwordVisible,
              togglePasswordVisibility: (visible) {
                setState(() => _passwordVisible = visible);
              },
              rememberUser: _keepLoggedIn,
              toggleRememberUserCheckbox: (remember) {
                setState(() => _keepLoggedIn = remember ?? false);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _responsiveBuild(context, ResponsiveLayout.of(context).layout);
  }
}


/// Login Form Card Widget
class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard(
    this.layout, {
    required this.formKey,
    required this.usernameFocusNode,
    required this.passwordFocusNode,
    required this.onChangeUserName,
    required this.onChangePassword,
    required this.onSubmit,
    this.passwordVisible = false,
    this.rememberUser = false,
    this.loading = false,
    this.autofocusUsernameField = false,
    this.onValidateUserName,
    this.onValidatePassword,
    this.togglePasswordVisibility,
    this.toggleRememberUserCheckbox,
  });

  final Layout layout;
  final GlobalKey<FormState> formKey;
  final FocusNode usernameFocusNode;
  final FocusNode passwordFocusNode;

  final bool loading;
  final bool autofocusUsernameField;

  final bool passwordVisible;
  final bool rememberUser;

  // Password Typing Events
  final void Function(String) onChangeUserName;
  final void Function(String) onChangePassword;
  final String? Function(String?)? onValidateUserName;
  final String? Function(String?)? onValidatePassword;

  // Password Toggle Events
  final void Function(bool)? togglePasswordVisibility;
  final void Function(bool?)? toggleRememberUserCheckbox;

  // Password Submit Event
  final void Function() onSubmit;

  // Initialize Form Builder
  Widget _formBuilder(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Image.asset('assets/images/gt-logo.png', width: 48),
              const SizedBox(width: 16),
              Wrap(
                direction: Axis.vertical,
                children: [
                  const Text('Welcome!'),
                  Text(
                    'Login',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 36),
          TextFormField(
            autofocus: autofocusUsernameField,
            focusNode: usernameFocusNode,
            enabled: true,
            textInputAction: TextInputAction.next,
            // inputFormatters: [UpperCaseTextFormatter()],
            decoration: InputDecoration(
              labelText: 'Username',
              alignLabelWithHint: true,
            ),
            onChanged: onChangeUserName,
            validator: onValidateUserName,
          ),
          const SizedBox(height: 20),
          TextFormField(
            focusNode: passwordFocusNode,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIconConstraints: BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              suffixIcon: SideFieldIcon(
                icon: Icon(
                  passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onTap: () => togglePasswordVisibility?.call(!passwordVisible),
              ),
            ),
            style: const TextStyle(letterSpacing: 2),
            autocorrect: false,
            obscureText: !passwordVisible,
            enableInteractiveSelection: false,
            enableSuggestions: false,
            scribbleEnabled: false,
            contextMenuBuilder: null,
            validator: onValidatePassword,
            onChanged: onChangePassword,
            onFieldSubmitted: (_) => onSubmit(),
            // onTap: () => formKey.currentState!.validate(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              direction: Axis.horizontal,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Checkbox(
                  // activeColor: kGoldShadow,
                  value: rememberUser,
                  onChanged: toggleRememberUserCheckbox,
                ),
                const Text('Keep logged in'),
              ],
            ),
          ),
          const SizedBox(height: 40),
          TextButton(
            onPressed: onSubmit,
            child: const Text('LOGIN'),
          ),
        ],
      ),
    );
  }

  /// Initialize Login Form Card Widget
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 64),
      elevation: 8,
      child: Container(
        padding: layout.deviceType.isMobile
            ? const EdgeInsets.all(28)
            : const EdgeInsets.symmetric(vertical: 28, horizontal: 48),
        width: kMobileBreakpoint,
        child: (loading) ? CircularProgressIndicator() : _formBuilder(context),
      ),
    );
  }
}
