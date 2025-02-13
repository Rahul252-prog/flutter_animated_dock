import 'package:flutter/material.dart';
import 'dart:ui';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurpleAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MacDock<String>(
              items: const [
                'assets/icons/App Icon Finder.png',
                'assets/icons/Apple Design Resources Bitmap.png',
                'assets/icons/Mail App Icon.png',
                'assets/icons/Swift Playgrounds App Icon.png',
                'assets/icons/System Preferences App Icon.png'
              ],
              builder: (item, scale) {
                return Center(
                  child: Image.asset(
                    item,
                    height: 150 * scale * 0.8,
                  ),
                );
              },
            ),
            const SizedBox(
              height: 32,
            ),
          ],
        ),
      ),
    );
  }
}

class MacDock<T extends Object> extends StatefulWidget {
  const MacDock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  final List<T> items;
  final Widget Function(T item, double scale) builder;

  @override
  State<MacDock<T>> createState() => MacDockState<T>();
}

class MacDockState<T extends Object> extends State<MacDock<T>> {
  late final List<T> items = widget.items.toList();
  int? _hoveredIndex;
  int? _draggedIndex;

  static const double baseSize = 72.0;
  static const double maxSize = 80.0;
  static const double nonHoverMaxSize = 52.0;
  static const double dragFeedbackScale = 0.6;

  double calculatedItemValue({
    required int index,
    required double initVal,
    required double maxVal,
    required double nonHoverMaxVal,
  }) {
    if (_hoveredIndex == null) {
      return initVal;
    }

    final distance = (_hoveredIndex! - index).abs();
    final itemsAffected = items.length;

    if (distance == 0) {
      return maxVal;
    } else if (distance == 1) {
      return lerpDouble(initVal, maxVal, 0.75)!;
    } else if (distance == 2) {
      return lerpDouble(initVal, maxVal, 0.5)!;
    } else if (distance < 3 && distance <= itemsAffected) {
      return lerpDouble(initVal, nonHoverMaxVal, .25)!;
    } else {
      return initVal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.black.withOpacity(0.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.asMap().entries.map((val) {
          final index = val.key;
          final item = val.value;

          final calculatedSize = calculatedItemValue(
            index: index,
            initVal: baseSize,
            maxVal: maxSize,
            nonHoverMaxVal: nonHoverMaxSize,
          );

          return DragTarget<T>(
            onAcceptWithDetails: (droppedItem) {
              setState(() {
                final draggedIndex = items.indexOf(droppedItem.data);
                if (draggedIndex != -1) {
                  items.removeAt(draggedIndex);
                  items.insert(index, droppedItem.data);
                }
                _draggedIndex = null;
              });
            },
            onWillAcceptWithDetails: (droppedItem) {
              setState(() {
                _hoveredIndex = index;
                _draggedIndex = items.indexOf(droppedItem.data);
              });
              return true;
            },
            onLeave: (_) {
              setState(() {
                _hoveredIndex = null;
                _draggedIndex = null;
              });
            },
            builder: (context, candidateData, rejectedData) {
              return Draggable<T>(
                data: item,
                feedback: Material(
                  color: Colors.transparent,
                  child: Transform.scale(
                    scale: dragFeedbackScale,
                    child: widget.builder(item, 1.0),
                  ),
                ),
                childWhenDragging: const PlaceholderWidget(),
                child: MouseRegion(
                  onEnter: (_) {
                    setState(() {
                      _hoveredIndex = index;
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      _hoveredIndex = null;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.identity()
                      ..translate(
                        0.0,
                        calculatedItemValue(
                          index: index,
                          initVal: 0,
                          maxVal: -10,
                          nonHoverMaxVal: -4,
                        ),
                        0.0,
                      ),
                    margin: EdgeInsets.only(
                      left: _draggedIndex != null
                          ? _hoveredIndex == index
                              ? 64
                              : 0
                          : 0,
                      right: _draggedIndex != null
                          ? _hoveredIndex == index && index == items.length - 1
                              ? 30
                              : 0
                          : 0,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: BoxConstraints(
                      minWidth: nonHoverMaxSize,
                      maxWidth: calculatedSize,
                      maxHeight: calculatedSize,
                    ),
                    child: widget.builder(item, 1.0),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

class PlaceholderWidget extends StatefulWidget {
  const PlaceholderWidget({super.key});

  @override
  State<PlaceholderWidget> createState() => _PlaceholderWidgetState();
}

class _PlaceholderWidgetState extends State<PlaceholderWidget> {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 48, end: 0),
      builder: (BuildContext context, double value, Widget? child) {
        return SizedBox(
          width: value,
          height: value,
        );
      },
    );
  }
}
