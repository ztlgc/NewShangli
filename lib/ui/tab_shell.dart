import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'pages/person_list_page.dart';
import 'pages/record_home_page.dart';
import 'pages/settings_home_page.dart';
import 'pages/stats_page.dart';

import 'app_icons.dart';

import 'app_layout.dart';

/// 主界面外壳。
///
/// 负责承载四个一级页面（记录 / 关系 / 统计 / 设置），并在最上层悬浮常驻
/// 底部导航栏。点击导航栏时只切换 [IndexedStack] 的当前页，导航栏本身保持
/// 挂载，不会像原先 `replaceRoot` 那样整页重建刷新；页面状态也能保留。
class MainTabShell extends StatefulWidget {
  const MainTabShell({super.key, this.initialIndex = 0})
    : assert(initialIndex >= 0 && initialIndex < 4);

  final int initialIndex;

  @override
  State<MainTabShell> createState() => _MainTabShellState();
}

class _MainTabShellState extends State<MainTabShell> {
  late int _activeIndex;
  final ValueNotifier<bool> _navHidden = ValueNotifier<bool>(false);

  late final List<Widget> _pages = const <Widget>[
    RecordHomePage(),
    PersonListPage(),
    StatsPage(),
    SettingsHomePage(),
  ];

  @override
  void initState() {
    super.initState();
    _activeIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _navHidden.dispose();
    super.dispose();
  }

  void _switchTo(int index) {
    if (index == _activeIndex) return;
    setState(() => _activeIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return TabShellScope(
      navHidden: _navHidden,
      child: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(index: _activeIndex, children: _pages),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom:
                MediaQuery.viewPaddingOf(context).bottom +
                AppLayout.floatingNavigationInset,
            child: ValueListenableBuilder<bool>(
              valueListenable: _navHidden,
              builder: (context, hidden, _) {
                return AnimatedOpacity(
                  opacity: hidden || MediaQuery.viewInsetsOf(context).bottom > 0
                      ? 0
                      : 1,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut,
                  child: IgnorePointer(
                    ignoring:
                        hidden || MediaQuery.viewInsetsOf(context).bottom > 0,
                    child: FBottomNavigationBar(
                      index: _activeIndex,
                      onChange: _switchTo,
                      children: const [
                        FBottomNavigationBarItem(
                          icon: Icon(AppIcons.bookOpen),
                          label: Text('记录'),
                        ),
                        FBottomNavigationBarItem(
                          icon: Icon(AppIcons.users),
                          label: Text('关系'),
                        ),
                        FBottomNavigationBarItem(
                          icon: Icon(AppIcons.chartNoAxesCombined),
                          label: Text('统计'),
                        ),
                        FBottomNavigationBarItem(
                          icon: Icon(AppIcons.settings2),
                          label: Text('设置'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 供一级页面向外壳报告“是否需要隐藏悬浮导航栏”。
///
/// 例如记录页 / 关系页进入多选模式时会显示页内操作栏，此时需要隐藏悬浮栏，
/// 避免底部出现两层栏。页面独立运行（如测试）时该作用域不存在，调用为空操作。
class TabShellScope extends InheritedWidget {
  const TabShellScope({
    super.key,
    required this.navHidden,
    required super.child,
  });

  final ValueNotifier<bool> navHidden;

  static TabShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabShellScope>();

  static void setNavHidden(BuildContext context, {required bool hidden}) {
    maybeOf(context)?.navHidden.value = hidden;
  }

  @override
  bool updateShouldNotify(TabShellScope oldWidget) =>
      navHidden != oldWidget.navHidden;
}
