import 'package:flutter/material.dart';

class AppNav {
  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(_route(page));
  }

  static Future<T?> replaceRoot<T>(BuildContext context, Widget page) {
    return Navigator.of(context)
        .pushAndRemoveUntil<T>(_route(page), (route) => false);
  }

  static PageRoute<T> _route<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        final slide = Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).animate(fade);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  static void pop(BuildContext context) => Navigator.of(context).maybePop();
}
