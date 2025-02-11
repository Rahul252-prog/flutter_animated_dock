import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.deepPurpleAccent,
        body: AppDock(),
      ),
    );
  }
}

class AppDock extends StatefulWidget {
  @override
  _AppDockState createState() => _AppDockState();
}

class _AppDockState extends State<AppDock> with TickerProviderStateMixin {
  final List<String> appIcons = [
    'assets/icons/App Icon Finder.png',
    'assets/icons/Apple Design Resources Bitmap.png',
    'assets/icons/Mail App Icon.png',
    'assets/icons/Swift Playgrounds App Icon.png',
    'assets/icons/System Preferences App Icon.png'
  ];

  int? selectedIndex;
  int? hoveredIndex;
  Map<int, Offset> iconOffsets = {};
  Offset? dragOffset;
  final GlobalKey _dockKey = GlobalKey();

  double getScaleForIndex(int index) {
    if (selectedIndex != null) {
      return index == selectedIndex ? 1.0 : 1.05;
    }

    if (hoveredIndex == null) return 1.0;

    final distance = (hoveredIndex! - index).abs();
    if (distance == 0) return 1.2;
    if (distance == 1) return 1.1;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        key: _dockKey,
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.only(bottom: 30),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(30),
        ),
        width: hoveredIndex != null
            ? (appIcons.length * 110.0)
            : (appIcons.length * 100.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / appIcons.length;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(appIcons.length, (index) {
                final iconPath = appIcons[index];
                return MouseRegion(
                  key: ValueKey(iconPath),
                  onEnter: (_) => setState(() => hoveredIndex = index),
                  onExit: (_) => setState(() => hoveredIndex = null),
                  child: SizedBox(
                    width: itemWidth,
                    child: LongPressDraggable<int>(
                      delay: Duration(milliseconds: 200),
                      data: index,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: itemWidth,
                          height: 100,
                          alignment: Alignment.center,
                          child: Image.asset(
                            iconPath,
                            height: 100,
                            width: 100,
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.5,
                        child: Image.asset(iconPath),
                      ),
                      onDragStarted: () => setState(() => selectedIndex = index),
                      onDragEnd: (details) {
                        final RenderBox dockBox =
                        _dockKey.currentContext?.findRenderObject() as RenderBox;
                        final Offset dockPos = dockBox.localToGlobal(Offset.zero);
                        final Size dockSize = dockBox.size;
                        final Rect dockRect = Rect.fromLTWH(
                            dockPos.dx, dockPos.dy, dockSize.width, dockSize.height);

                        if (!dockRect.contains(details.offset)) {
                          setState(() => appIcons.removeAt(index));
                        }
                        setState(() {
                          selectedIndex = null;
                          hoveredIndex = null;
                          iconOffsets.clear();
                        });
                      },
                      child: DragTarget<int>(
                        onWillAccept: (data) => true,
                        onAccept: (draggedIndex) {
                          final draggedIcon = appIcons[draggedIndex];
                          setState(() {
                            appIcons.removeAt(draggedIndex);
                            appIcons.insert(index, draggedIcon);
                            hoveredIndex = null;
                          });
                        },
                        onMove: (details) {
                          final RenderBox box =
                          context.findRenderObject() as RenderBox;
                          final localPos = box.globalToLocal(details.offset);

                          setState(() {
                            hoveredIndex = index;
                            if (selectedIndex != null) {
                              final direction = selectedIndex! < index ? -1 : 1;
                              for (int i = 0; i < appIcons.length; i++) {
                                iconOffsets[i] = (selectedIndex! < index &&
                                    i > selectedIndex! &&
                                    i <= index) ||
                                    (selectedIndex! > index &&
                                        i < selectedIndex! &&
                                        i >= index)
                                    ? Offset(direction * itemWidth, 0)
                                    : Offset.zero;
                              }
                            }
                          });
                        },
                        onLeave: (data) => setState(() {
                          hoveredIndex = null;
                          iconOffsets.clear();
                        }),
                        builder: (context, candidateData, rejectedData) {
                          final scale = getScaleForIndex(index);
                          final translateY = selectedIndex == index ? -20.0 : 0.0;
                          final translateX = iconOffsets[index]?.dx ?? 0.0;

                          return AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            transform: Matrix4.identity()
                              ..translate(translateX, translateY)
                              ..scale(scale),
                            child: Container(
                              height: 85,
                              width: 85,
                              alignment: Alignment.center,
                              child: Image.asset(iconPath),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}