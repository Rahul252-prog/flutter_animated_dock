import 'dart:math';
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
  List<String> appIcons = [
    'assets/icons/App Icon Finder.png',
    'assets/icons/Apple Design Resources Bitmap.png',
    'assets/icons/Mail App Icon.png',
    'assets/icons/Swift Playgrounds App Icon.png',
    'assets/icons/System Preferences App Icon.png'
  ];

  int? selectedIndex;
  int? hoveredIndex;
  Map<int, Offset> iconOffsets = {};
  final GlobalKey _dockKey = GlobalKey();
  final GlobalKey _scaffoldKey = GlobalKey();
  String? draggedIcon;

  // Hover animation logic
  double getScale(int index) {
    if (hoveredIndex == null || selectedIndex != null) return 1.0;
    final distance = (index - hoveredIndex!).abs();
    return 1.0 + 0.3 / (distance + 1);
  }

  double getTranslateX(int index) {
    if (hoveredIndex == null || selectedIndex != null) return 0.0;
    final distance = index - hoveredIndex!;
    if (distance == 0) return 0.0;
    final direction = distance.sign.toDouble();
    final maxTranslation = 35.0;
    return direction * maxTranslation * pow(0.6, distance.abs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.deepPurpleAccent,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedContainer(
          key: _dockKey,
          duration: Duration(milliseconds: 300),
          padding: EdgeInsets.all(10),
          margin: EdgeInsets.only(bottom: 30),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(30),
          ),
          width: appIcons.length * 100.0,
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
                        childWhenDragging: Container(),
                        onDragStarted: () {
                          setState(() {
                            selectedIndex = index;
                            draggedIcon = appIcons[index];
                            appIcons.removeAt(index);
                            hoveredIndex =
                                null; // Reset hover when dragging starts
                          });
                        },

                        onDragUpdate: (details) {

                          final RenderBox scaffoldBox =
                              _scaffoldKey.currentContext?.findRenderObject()
                                  as RenderBox;
                          final Offset globalPosition = details.globalPosition;
                          final Rect scaffoldRect = Rect.fromPoints(
                              scaffoldBox.localToGlobal(Offset.zero),
                              scaffoldBox.localToGlobal(Offset(
                                  scaffoldBox.size.width,
                                  scaffoldBox.size.height)));

                          if (!scaffoldRect.contains(globalPosition)) {

                            draggedIcon = appIcons[index];

                            appIcons.insert(index, draggedIcon!);

                            // Handle dragging outside if needed
                          }
                        },
                        onDragEnd: (details) {
                          print('asdasd');
                          setState(() {
                            if (draggedIcon != null) {
                              appIcons.insert(selectedIndex!, draggedIcon!);
                              draggedIcon = null;
                            }
                            selectedIndex = null;
                          });
                        },
                        child: DragTarget<int>(
                          onWillAccept: (data) => true,
                          onAccept: (draggedIndex) {

                            setState(() {
                              if (draggedIcon != null) {
                                appIcons.insert(index, draggedIcon!);
                                draggedIcon = null;
                              }
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
                                final direction =
                                    selectedIndex! < index ? -1 : 1;
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
                            final scale = getScale(index);
                            final translateX = getTranslateX(index);

                            return AnimatedContainer(
                              height: 90,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeOutExpo,
                              transform: Matrix4.identity()
                                ..translate(translateX, 0)
                                ..translate(0.0, (1 - scale) * 40)
                                ..scale(scale),
                              alignment: Alignment.bottomCenter,
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
      ),
    );
  }
}
