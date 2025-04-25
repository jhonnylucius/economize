import 'package:flutter/material.dart';

class ResponsiveScreen extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final FloatingActionButtonLocation floatingActionButtonLocation;

  const ResponsiveScreen({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    required this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final viewInsets = mediaQuery.viewInsets.bottom;

    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding + viewInsets),
          child: child,
        ),
      ),
      bottomNavigationBar:
          bottomNavigationBar != null
              ? Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: bottomNavigationBar,
              )
              : null,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
