import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'shared/data.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  final loginInfo = LoginInfo();
  static const title = 'GoRouter Example: Redirection';

  // add the login info into the tree as app state that can change over time
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<LoginInfo>.value(
        value: loginInfo,
        child: Builder(builder: (context) {
          final _router = routerBuilder(context);

          return MaterialApp.router(
            routeInformationParser: _router.routeInformationParser,
            routerDelegate: _router.routerDelegate,
            title: title,
            debugShowCheckedModeBanner: false,
          );
        }),
      );
}

GoRouter routerBuilder(BuildContext context, [String? location]) => GoRouter(
      initialLocation: location ?? '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => HomeScreen(families: Families.data),
          routes: [
            GoRoute(
              path: 'family/:fid',
              builder: (context, state) => FamilyScreen(
                family: Families.family(state.params['fid']!),
              ),
              routes: [
                GoRoute(
                  path: 'person/:pid',
                  builder: (context, state) {
                    final family = Families.family(state.params['fid']!);
                    final person = family.person(state.params['pid']!);
                    return PersonScreen(family: family, person: person);
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
      ],

      // redirect to the login page if the user is not logged in
      redirect: (state) {
        final loginInfo = context.read<LoginInfo>();
        // if the user is not logged in, they need to login
        final loggedIn = loginInfo.loggedIn;
        final loggingIn = state.subloc == '/login';
        if (!loggedIn) return loggingIn ? null : '/login';

        // if the user is logged in but still on the login page, send them to
        // the home page
        if (loggingIn) return '/';

        // no need to redirect at all
        return null;
      },

      // changes on the listenable will cause the router to refresh it's route
      refreshListenable: context.read<LoginInfo>(),
    );

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(App.title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  // log a user in, letting all the listeners know
                  context.read<LoginInfo>().login('test-user');

                  // router will automatically redirect from /login to / using
                  // refreshListenable
                  //context.go('/');
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.families, Key? key}) : super(key: key);
  final List<Family> families;

  @override
  Widget build(BuildContext context) {
    final info = context.read<LoginInfo>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(App.title),
        actions: [
          IconButton(
            onPressed: info.logout,
            tooltip: 'Logout: ${info.userName}',
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: ListView(
        children: [
          for (final f in families)
            ListTile(
              title: Text(f.name),
              onTap: () => context.go('/family/${f.id}'),
            )
        ],
      ),
    );
  }
}

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({required this.family, Key? key}) : super(key: key);
  final Family family;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(family.name)),
        body: ListView(
          children: [
            for (final p in family.people)
              ListTile(
                title: Text(p.name),
                onTap: () => context.go('/family/${family.id}/person/${p.id}'),
              ),
          ],
        ),
      );
}

class PersonScreen extends StatelessWidget {
  const PersonScreen({required this.family, required this.person, Key? key})
      : super(key: key);

  final Family family;
  final Person person;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(person.name)),
        body: Text('${person.name} ${family.name} is ${person.age} years old'),
      );
}
