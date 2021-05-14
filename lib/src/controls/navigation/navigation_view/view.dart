import 'dart:ui' as ui;

import 'package:fluent_ui/fluent_ui.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

part 'body.dart';
part 'pane.dart';
part 'style.dart';

/// The default size used by the app top bar.
///
/// Value eyeballed from Windows 10 v10.0.19041.928
const double _kDefaultAppBarHeight = 31.0;

/// The NavigationView control provides top-level navigation
/// for your app. It adapts to a variety of screen sizes and
/// supports both top and left navigation styles.
///
/// ![](https://docs.microsoft.com/en-us/windows/uwp/design/controls-and-patterns/images/nav-view-header.png)
///
/// See also:
///   * [NavigationBody], a widget that implement fluent
///     transitions into [NavigationView]
///   * [NavigationPane], the pane used by [NavigationView],
///     that can be displayed either at the left and top
///   * [TabView], a widget similar to [NavigationView], useful
///     to display several pages of content while giving a user
///     the capability to rearrange, open, or close new tabs.
class NavigationView extends StatefulWidget {
  /// Creates a navigation view.
  const NavigationView({
    Key? key,
    this.appBar,
    this.pane,
    this.content = const SizedBox.shrink(),
    this.useAcrylic = true,
    // If more properties are added here, make sure to
    // add them to the automatic mode as well.
  }) : super(key: key);

  /// The app bar of the app.
  final NavigationAppBar? appBar;

  /// The navigation pane, that can be displayed either on the
  /// left, on the top, or above [content].
  final NavigationPane? pane;

  /// The content of the pane.
  ///
  /// Usually an [NavigationBody].
  final Widget content;

  /// Whether a [NoAcrylicBlurEffect] widget should be added to the tree
  final bool useAcrylic;

  @override
  NavigationViewState createState() => NavigationViewState();
}

class NavigationViewState extends State<NavigationView> {
  /// The scroll controller used to keep the scrolling state of
  /// the list view when the display mode is switched between open
  /// and compact, and even keep it for the minimal state.
  late ScrollController scrollController;

  /// The key used to animate between open and compact display mode
  final _panelKey = GlobalKey();

  /// The current display mode used by the automatic pane mode.
  /// This can not be changed
  PaneDisplayMode? currentDisplayMode;

  @override
  void initState() {
    super.initState();
    scrollController = widget.pane?.scrollController ?? ScrollController();
  }

  @override
  void didUpdateWidget(NavigationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pane?.scrollController != scrollController) {
      scrollController = widget.pane?.scrollController ?? scrollController;
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Widget _buildAcrylic(Widget child) {
    if (widget.useAcrylic) return child;
    return NoAcrylicBlurEffect(child: child);
  }

  @override
  Widget build(BuildContext context) {
    Widget appBar = () {
      if (widget.appBar != null) {
        return _buildAcrylic(_NavigationAppBar(
          appBar: widget.appBar!,
          displayMode: widget.pane?.displayMode ?? PaneDisplayMode.top,
        ));
      }
      return SizedBox.shrink();
    }();

    late Widget paneResult;
    if (widget.pane != null) {
      final pane = widget.pane!;
      if (pane.displayMode == PaneDisplayMode.top) {
        paneResult = Column(children: [
          appBar,
          _buildAcrylic(_TopNavigationPane(pane: pane)),
          Expanded(child: widget.content),
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

            late PaneDisplayMode autoDisplayMode;
            if (width <= 640) {
              autoDisplayMode = PaneDisplayMode.minimal;
            } else if (currentDisplayMode != null) {
              autoDisplayMode = currentDisplayMode!;
            } else if (width >= 1008) {
              autoDisplayMode = PaneDisplayMode.open;
            } else if (width > 640) {
              autoDisplayMode = PaneDisplayMode.compact;
            }

            assert(autoDisplayMode != PaneDisplayMode.auto);

            /// We display a new navigation view with the current display mode.
            /// We can do this because [autoDisplayMode] can never be `auto`,
            /// so it won't stack overflow (error).
            return NavigationView(
              appBar: widget.appBar,
              content: widget.content,
              useAcrylic: widget.useAcrylic,
              pane: NavigationPane(
                displayMode: autoDisplayMode,
                autoSuggestBox: pane.autoSuggestBox,
                autoSuggestBoxReplacement: pane.autoSuggestBoxReplacement,
                footerItems: pane.footerItems,
                header: pane.header,
                items: pane.items,
                key: pane.key,
                onChanged: pane.onChanged,
                selected: pane.selected,
                menuButton: pane.menuButton,
                scrollController: pane.scrollController,
                onDisplayModeRequested: (mode) {
                  setState(() => currentDisplayMode = mode);
                },
              ),
            );
          },
        );
      } else {
        switch (pane.displayMode) {
          case PaneDisplayMode.compact:
            paneResult = Column(children: [
              appBar,
              Expanded(
                child: Row(children: [
                  _buildAcrylic(
                    _CompactNavigationPane(pane: pane, paneKey: _panelKey),
                  ),
                  Expanded(child: widget.content),
                ]),
              ),
            ]);
            break;
          case PaneDisplayMode.open:
            paneResult = Column(children: [
              appBar,
              Expanded(
                child: Row(children: [
                  _buildAcrylic(
                    _OpenNavigationPane(pane: pane, paneKey: _panelKey),
                  ),
                  Expanded(child: widget.content),
                ]),
              ),
            ]);
            break;
          case PaneDisplayMode.minimal:
            paneResult = Column(children: [
              appBar,
              Expanded(
                child: ScaffoldPageParent(
                  paneButton: Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: PaneItem.buildPaneItemButton(
                      context,
                      PaneItem(
                        title: 'Open Navigation',
                        icon: Icon(Icons.menu),
                      ),
                      PaneDisplayMode.compact,
                      false,
                      () => _openMinimalOverlay(context),
                    ),
                  ),
                  child: widget.content,
                ),
              ),
            ]);
            break;
          default:
            paneResult = widget.content;
        }
      }
    } else {
      paneResult = widget.content;
    }
    return Container(
      color: FluentTheme.of(context).scaffoldBackgroundColor,
      child: _NavigationBody(
        displayMode: widget.pane?.displayMode,
        child: PrimaryScrollController(
          controller: scrollController,
          child: paneResult,
        ),
      ),
    );
  }

  void _openMinimalOverlay(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    assert(debugCheckHasOverlay(context));
    final theme = NavigationPaneThemeData.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) {
      return _buildAcrylic(PrimaryScrollController(
        controller: scrollController,
        child: Padding(
          padding: EdgeInsets.only(top: widget.appBar?.height ?? 0),
          child: _MinimalNavigationPane(
            pane: widget.pane!,
            animationDuration: theme.animationDuration ?? Duration.zero,
            entry: entry,
          ),
        ),
      ));
    });
    Overlay.of(context, debugRequiredFor: widget)!.insert(entry);
  }
}

/// The bar displayed at the top of the app. It can adapt itself to
/// all the display modes.
///
/// See also:
///   - [NavigationView]
///   - [NavigationPane]
///   - [PaneDisplayMode]
class NavigationAppBar {
  final Key? key;

  /// The widget at the beggining of the app bar, before [title].
  ///
  /// Typically the [leading] widget is an [Icon] or an [IconButton].
  ///
  /// If this is null and [automaticallyImplyLeading] is set to true, the
  /// view will imply an appropriate widget. If  the parent [Navigator] can
  /// go back, the app bar will use an [IconButton] that calls [Navigator.maybePop].
  ///
  /// See also:
  ///   * [automaticallyImplyLeading], that controls whether we should try to
  ///     imply the leading widget, if [leading] is null
  final Widget? leading;

  /// {@macro flutter.material.appbar.automaticallyImplyLeading}
  final bool automaticallyImplyLeading;

  /// Typically a [Text] widget that contains the app name.
  final Widget? title;

  /// A list of Widgets to display in a row after the [title] widget.
  ///
  /// Typically these widgets are [IconButton]s representing common
  /// operations.
  final Widget? actions;

  /// The height of the app bar. [_kDefaultAppBarHeight] is used by default
  final double height;

  const NavigationAppBar({
    this.key,
    this.leading,
    this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.height = _kDefaultAppBarHeight,
  });

  static Widget buildLeading(
    BuildContext context,
    NavigationAppBar appBar, [
    bool imply = true,
  ]) {
    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    final bool canPop = parentRoute?.canPop ?? false;
    late Widget widget;
    if (appBar.leading != null) {
      widget = Padding(
        padding: EdgeInsets.only(left: 12.0),
        child: appBar.leading,
      );
    } else if (appBar.automaticallyImplyLeading && imply) {
      widget = Container(
        width: _kCompactNavigationPanelWidth,
        child: IconButton(
          icon: Icon(Icons.arrow_back_sharp),
          onPressed: canPop ? () => Navigator.maybePop(context) : null,
          style: ButtonThemeData(
            margin: EdgeInsets.zero,
            scaleFactor: 1.0,
            decoration: (state) {
              if (state == ButtonStates.disabled) state = ButtonStates.none;
              return BoxDecoration(
                color:
                    ButtonThemeData.uncheckedInputColor(context.theme, state),
              );
            },
          ),
          iconTheme: (state) {
            return IconThemeData(
              size: 22.0,
              color: ButtonThemeData.buttonColor(context.theme, state),
            );
          },
        ),
      );
      if (canPop) widget = Tooltip(message: 'Back', child: widget);
    } else {
      return SizedBox.shrink();
    }
    widget = SizedBox(width: _kCompactNavigationPanelWidth, child: widget);
    return widget;
  }
}

class _NavigationAppBar extends StatelessWidget {
  const _NavigationAppBar({
    Key? key,
    required this.appBar,
    required this.displayMode,
  }) : super(key: key);

  final NavigationAppBar appBar;
  final PaneDisplayMode displayMode;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final theme = NavigationPaneThemeData.of(context);
    final leading = NavigationAppBar.buildLeading(
      context,
      appBar,
      displayMode != PaneDisplayMode.top,
    );
    final title = () {
      if (appBar.title != null)
        return AnimatedPadding(
          duration: theme.animationDuration ?? Duration.zero,
          curve: theme.animationCurve ?? Curves.linear,
          padding: EdgeInsets.only(
            left: displayMode == PaneDisplayMode.compact
                ? PageTopBar.horizontalPadding(context)
                : 12.0,
          ),
          child: DefaultTextStyle(
            style: FluentTheme.of(context).typography.caption!,
            child: appBar.title!,
          ),
        );
      else
        return SizedBox.shrink();
    }();
    late Widget result;
    switch (displayMode) {
      case PaneDisplayMode.top:
      case PaneDisplayMode.minimal:
        result = Acrylic(
          child: Row(children: [
            leading,
            title,
            if (appBar.actions != null)
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: appBar.actions!,
                ),
              ),
          ]),
        );
        break;
      case PaneDisplayMode.open:
        result = Row(children: [
          Acrylic(
            width: _kOpenNavigationPanelWidth,
            height: appBar.height,
            color: theme.backgroundColor,
            child: Row(children: [leading, title]),
          ),
          Expanded(child: appBar.actions ?? SizedBox()),
        ]);
        break;
      case PaneDisplayMode.compact:
        result = Row(children: [
          Acrylic(
            height: appBar.height,
            color: theme.backgroundColor,
            child: leading,
          ),
          title,
          Expanded(child: appBar.actions ?? SizedBox()),
        ]);
        break;
      default:
        return SizedBox.shrink();
    }
    return Container(height: appBar.height, child: result);
  }
}
