import 'package:fluent_ui/fluent_ui.dart';

part 'pane.dart';

class NavigationView extends StatefulWidget {
  const NavigationView({Key? key, this.pane, this.content}) : super(key: key);

  final NavigationPane? pane;

  final Widget? content;

  @override
  _NavigationViewState createState() => _NavigationViewState();
}

class _NavigationViewState extends State<NavigationView> {
  PaneDisplayMode? currentDisplayMode;

  @override
  Widget build(BuildContext context) {
    if (widget.pane != null) {
      final pane = widget.pane!;
      if (pane.displayMode == PaneDisplayMode.top) {
        return Column(children: [
          _TopNavigationPane(pane: pane),
          if (widget.content != null) Expanded(child: widget.content!),
        ]);
      } else if (pane.displayMode == PaneDisplayMode.auto) {
        /// For more info on the adaptive behavior, see
        /// https://docs.microsoft.com/en-us/windows/uwp/design/controls-and-patterns/navigationview#adaptive-behavior
        ///
        /// (07/05/2021)
        ///
        /// When PaneDisplayMode is set to its default value of Auto, the adaptive behavior is to show:
        /// - An expanded left pane on large window widths (1008px or greater).
        /// - A left, icon-only, nav pane (compact) on medium window widths (641px to 1007px).
        /// - Only a menu button (minimal) on small window widths (640px or less).
        return LayoutBuilder(
          builder: (context, consts) {
            double width = consts.biggest.width;
            if (width.isInfinite) width = MediaQuery.of(context).size.width;
            if (width >= 1008) {
              currentDisplayMode = PaneDisplayMode.open;
            } else if (width > 640) {
              currentDisplayMode = PaneDisplayMode.compact;
            } else {
              currentDisplayMode = PaneDisplayMode.minimal;
            }
            return SizedBox();
          },
        );
      } else {
        switch (pane.displayMode) {
          case PaneDisplayMode.compact:
            return Row(children: [
              _CompactNavigationPane(pane: pane),
              if (widget.content != null) Expanded(child: widget.content!),
            ]);
          default:
        }
      }
    }
    return Container();
  }
}
