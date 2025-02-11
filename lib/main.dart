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

  // Animation controllers for smooth transitions
  late List<AnimationController> scaleControllers;
  late List<Animation<double>> scaleAnimations;

  @override
  void initState() {
    super.initState();
    // Initialize animation controllers for each icon
    scaleControllers = List.generate(
      appIcons.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 200),
        vsync: this,
      ),
    );

    // Create scale animations for each icon
    scaleAnimations = scaleControllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutCubic,
        ),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in scaleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Calculate scale based on dragging and hovering state
  double getScaleForIndex(int index) {
    if (selectedIndex != null) {
      // Slight zoom for other items during dragging
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
        duration: Duration(milliseconds: 200),
        height: 120,
        margin: EdgeInsets.only(bottom: 30),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(30),
        ),
        width: hoveredIndex != null
            ? (appIcons.length * 130.0)
            : (appIcons.length * 120.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / appIcons.length;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(appIcons.length, (index) {
                return MouseRegion(
                  onEnter: (_) {
                    setState(() {
                      hoveredIndex = index;
                      for (int i = 0; i < appIcons.length; i++) {
                        final distance = (index - i).abs();
                        if (distance <= 1) {
                          scaleControllers[i].forward();
                        }
                      }
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      if (hoveredIndex == index) {
                        hoveredIndex = null;
                        for (var controller in scaleControllers) {
                          controller.reverse();
                        }
                      }
                    });
                  },
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
                            appIcons[index],
                            height: 100,
                            width: 100,
                          ),
                        ),
                      ),
                      childWhenDragging: SizedBox.shrink(),
                      onDragStarted: () {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      onDragEnd: (details) {
                        setState(() {
                          selectedIndex = null;
                          hoveredIndex = null;
                          iconOffsets.clear();
                          dragOffset = null;
                        });
                      },
                      child: DragTarget<int>(
                        onWillAccept: (data) => true,
                        onAccept: (draggedIndex) {
                          setState(() {
                            final draggedIcon = appIcons[draggedIndex];
                            appIcons.removeAt(draggedIndex);
                            appIcons.insert(index, draggedIcon);
                            hoveredIndex = null;
                            iconOffsets.clear();
                          });
                        },
                        onMove: (DragTargetDetails<int> details) {
                          final RenderBox box =
                              context.findRenderObject() as RenderBox;
                          final localPosition =
                              box.globalToLocal(details.offset);

                          if (localPosition.dx >= 0 &&
                              localPosition.dx <= constraints.maxWidth) {
                            setState(() {
                              dragOffset = localPosition;
                              hoveredIndex = index;

                              if (selectedIndex != null &&
                                  selectedIndex != index) {
                                final direction =
                                    selectedIndex! < index ? -1 : 1;
                                for (int i = 0; i < appIcons.length; i++) {
                                  if (i == selectedIndex) {
                                    iconOffsets[i] = Offset.zero;
                                  } else if ((selectedIndex! < index &&
                                          i > selectedIndex! &&
                                          i <= index) ||
                                      (selectedIndex! > index &&
                                          i < selectedIndex! &&
                                          i >= index)) {
                                    iconOffsets[i] =
                                        Offset(direction * itemWidth, 0);
                                  } else {
                                    iconOffsets[i] = Offset.zero;
                                  }
                                }
                              }
                            });
                          }
                        },
                        onLeave: (data) {
                          setState(() {
                            hoveredIndex = null;
                            iconOffsets.clear();
                          });
                        },
                        builder: (context, candidateData, rejectedData) {
                          final bool isHovered = hoveredIndex == index;
                          final bool isDragging = selectedIndex != null;

                          return AnimatedBuilder(
                            animation: scaleAnimations[index],
                            builder: (context, child) {
                              final matrix = Matrix4.identity();

                              // Apply position offset for dragging
                              matrix.translate(iconOffsets[index]?.dx ?? 0.0);

                              // Apply vertical translation for hover/drag
                              if (selectedIndex == index) {
                                matrix.translate(0.0, -20.0);
                                // Ensure dragged item is on top
                                matrix.setEntry(3, 2, 0.01);
                              } else if (isHovered) {
                                matrix.translate(0.0, -1.0);
                              }

                              // Apply scale based on dragging and hover state
                              final scale = getScaleForIndex(index);
                              matrix.scale(scale);

                              return Transform(
                                transform: matrix,
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 0),
                                  child: Container(
                                    height: 85,
                                    width: 85,
                                    alignment: Alignment.center,
                                    child: Visibility(
                                        visible: selectedIndex != index,
                                        child: Image.asset(appIcons[index])),
                                  ),
                                ),
                              );
                            },
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
