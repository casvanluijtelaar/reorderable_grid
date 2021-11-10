import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reorderable_grid/reorderable_grid.dart';

void main() {
  testWidgets('negative itemCount should assert', (WidgetTester tester) async {
    final List<int> items = <int>[1, 2, 3];
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (BuildContext outerContext, StateSetter setState) {
          return CustomScrollView(
            slivers: <Widget>[
              SliverReorderableGrid(
                itemCount: -1,
                onReorder: (int fromIndex, int toIndex) {
                  setState(() {
                    if (toIndex > fromIndex) {
                      toIndex -= 1;
                    }
                    items.insert(toIndex, items.removeAt(fromIndex));
                  });
                },
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                ),
                itemBuilder: (BuildContext context, int index) {
                  return SizedBox(
                    height: 100,
                    child: Text('item ${items[index]}'),
                  );
                },
              ),
            ],
          );
        },
      ),
    ));
    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets('zero itemCount should not build widget',
      (WidgetTester tester) async {
    final List<int> items = <int>[1, 2, 3];
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (BuildContext outerContext, StateSetter setState) {
          return CustomScrollView(
            slivers: <Widget>[
              SliverFixedExtentList(
                itemExtent: 50.0,
                delegate: SliverChildListDelegate(<Widget>[
                  const Text('before'),
                ]),
              ),
              SliverReorderableGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                ),
                itemCount: 0,
                onReorder: (int fromIndex, int toIndex) {
                  setState(() {
                    if (toIndex > fromIndex) {
                      toIndex -= 1;
                    }
                    items.insert(toIndex, items.removeAt(fromIndex));
                  });
                },
                itemBuilder: (BuildContext context, int index) {
                  return SizedBox(
                    height: 100,
                    child: Text('item ${items[index]}'),
                  );
                },
              ),
              SliverFixedExtentList(
                itemExtent: 50.0,
                delegate: SliverChildListDelegate(<Widget>[
                  const Text('after'),
                ]),
              ),
            ],
          );
        },
      ),
    ));

    expect(find.text('before'), findsOneWidget);
    expect(find.byType(SliverReorderableList), findsNothing);
    expect(find.text('after'), findsOneWidget);
  });


  testWidgets(
      'SliverReorderableGrid, items inherit DefaultTextStyle, IconTheme',
      (WidgetTester tester) async {
    const Color textColor = Color(0xffffffff);
    const Color iconColor = Color(0xff0000ff);

    TextStyle getIconStyle() {
      return tester
          .widget<RichText>(
            find.descendant(
              of: find.byType(Icon),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style!;
    }

    TextStyle getTextStyle() {
      return tester
          .widget<RichText>(
            find.descendant(
              of: find.text('item 0'),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style!;
    }

    // This SliverReorderableGrid has just one item: "item 0".
    await tester.pumpWidget(
      TestGrid(
        items: List<int>.from(<int>[0]),
        textColor: textColor,
        iconColor: iconColor,
      ),
    );
    expect(tester.getTopLeft(find.text('item 0')), Offset.zero);
    expect(getIconStyle().color, iconColor);
    expect(getTextStyle().color, textColor);

    // Dragging item 0 causes it to be reparented in the overlay. The item
    // should still inherit the IconTheme and DefaultTextStyle because they are
    // InheritedThemes.
    final TestGesture drag =
        await tester.startGesture(tester.getCenter(find.text('item 0')));
    await tester.pump(kPressTimeout);
    await drag.moveBy(const Offset(0, 50));
    await tester.pump(kPressTimeout);
    expect(tester.getTopLeft(find.text('item 0')), const Offset(0, 0));
    expect(getIconStyle().color, iconColor);
    expect(getTextStyle().color, textColor);

    // Drag is complete, item 0 returns to where it was.
    await drag.up();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('item 0')), Offset.zero);
    expect(getIconStyle().color, iconColor);
    expect(getTextStyle().color, textColor);
  });


  testWidgets(
      'ReorderableGrid supports items with nested list views without throwing layout exception.',
      (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/83224.
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            // Ensure there is always a top padding to simulate a phone with
            // safe area at the top. If the nested list doesn't have the
            // padding removed before it is put into the overlay it will
            // overflow the layout by the top padding.
            data: MediaQuery.of(context)
                .copyWith(padding: const EdgeInsets.only(top: 50)),
            child: child!,
          );
        },
        home: Scaffold(
          appBar: AppBar(title: const Text('Nested Lists')),
          body: ReorderableGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
            ),
            itemCount: 10,
            itemBuilder: (BuildContext context, int index) {
              return ReorderableGridDragStartListener(
                index: index,
                key: ValueKey<int>(index),
                child: Column(
                  children: <Widget>[
                    ListView(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      children: const <Widget>[
                        Text('Other data'),
                        Text('Other data'),
                        Text('Other data'),
                      ],
                    ),
                  ],
                ),
              );
            },
            onReorder: (int oldIndex, int newIndex) {},
          ),
        ),
      ),
    );

    // Start gesture on first item.
    final TestGesture drag = await tester
        .startGesture(tester.getCenter(find.byKey(const ValueKey<int>(0))));
    await tester.pump(kPressTimeout);

    // Drag enough for move to start.
    await drag.moveBy(const Offset(0, 50));
    await tester.pumpAndSettle();

    // There shouldn't be a layout overflow exception.
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'SliverReorderableGrid - properly animates the drop at starting position in a reversed list',
      (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/84625
    final List<int> items = List<int>.generate(8, (int index) => index);

    Future<void> pressDragRelease(Offset start, Offset delta) async {
      final TestGesture drag = await tester.startGesture(start);
      await tester.pump(kPressTimeout);
      await drag.moveBy(delta);
      await tester.pumpAndSettle();
      await drag.up();
      await tester.pump();
    }

    // The TestGrid is 800x600 SliverReorderableList with 8 items 800x100 each.
    // Each item has a text widget with 'item $index' that can be moved by a
    // press and drag gesture. For this test we are reversing the order so
    // the first item is at the bottom.
    await tester.pumpWidget(TestGrid(items: items, reverse: true));

    expect(tester.getTopLeft(find.text('item 0')), const Offset(0, 400));
    expect(tester.getTopLeft(find.text('item 1')), const Offset(200, 400));

    // Drag item 0 downwards off the edge and let it snap back. It should
    // smoothly animate back up.
    await pressDragRelease(
        tester.getCenter(find.text('item 0')), const Offset(0, 50));
    expect(tester.getTopLeft(find.text('item 0')), const Offset(0, 400));
    expect(tester.getTopLeft(find.text('item 1')), const Offset(200, 400));

    // After the first several frames we should be moving closer to the final position,
    // not further away as was the case with the original bug.
    await tester.pump(const Duration(milliseconds: 10));
    expect(tester.getTopLeft(find.text('item 0')).dy, lessThan(450));

    // Sample the middle (don't use exact values as it depends on the internal
    // curve being used).
    await tester.pump(const Duration(milliseconds: 125));
    expect(tester.getTopLeft(find.text('item 0')).dy, lessThan(450));

    // Wait for it to finish, it should be back to the original position
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('item 0')), const Offset(0, 400));
  });

  group('ReorderableGridDragStartListener', () {
    testWidgets('It should allow the item to be dragged when enabled is true',
        (WidgetTester tester) async {
      const int itemCount = 5;
      int onReorderCallCount = 0;
      final List<int> items =
          List<int>.generate(itemCount, (int index) => index);

      void handleReorder(int fromIndex, int toIndex) {
        onReorderCallCount += 1;
        if (toIndex > fromIndex) {
          toIndex -= 1;
        }
        items.insert(toIndex, items.removeAt(fromIndex));
      }

      // The list has five elements of height 100
      await tester.pumpWidget(
        MaterialApp(
          home: ReorderableGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
            ),
            itemCount: itemCount,
            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                key: ValueKey<int>(items[index]),
                height: 100,
                child: ReorderableGridDragStartListener(
                  index: index,
                  child: Text('item ${items[index]}'),
                ),
              );
            },
            onReorder: handleReorder,
          ),
        ),
      );

      // Start gesture on first item
      final TestGesture drag =
          await tester.startGesture(tester.getCenter(find.text('item 0')));
      await tester.pump(kPressTimeout);

      // Drag enough to move down the first item
      await drag.moveBy(const Offset(0, 50));
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();

      expect(onReorderCallCount, 1);
      expect(items, orderedEquals(<int>[1, 0, 2, 3, 4]));
    });

    testWidgets('It should allow the item to be dragged when enabled is true',
        (WidgetTester tester) async {
      const int itemCount = 5;
      int onReorderCallCount = 0;
      final List<int> items =
          List<int>.generate(itemCount, (int index) => index);

      void handleReorder(int fromIndex, int toIndex) {
        onReorderCallCount += 1;
        if (toIndex > fromIndex) {
          toIndex -= 1;
        }
        items.insert(toIndex, items.removeAt(fromIndex));
      }

      // The list has five elements of height 100
      await tester.pumpWidget(
        MaterialApp(
          home: ReorderableGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
            ),
            itemCount: itemCount,
            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                key: ValueKey<int>(items[index]),
                height: 100,
                child: ReorderableGridDragStartListener(
                  index: index,
                  enabled: false,
                  child: Text('item ${items[index]}'),
                ),
              );
            },
            onReorder: handleReorder,
          ),
        ),
      );

      // Start gesture on first item
      final TestGesture drag =
          await tester.startGesture(tester.getCenter(find.text('item 0')));
      await tester.pump(kLongPressTimeout);

      // Drag enough to move down the first item
      await drag.moveBy(const Offset(0, 150));
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();

      expect(onReorderCallCount, 0);
      expect(items, orderedEquals(<int>[0, 1, 2, 3, 4]));
    });
  });

  group('ReorderableGridDelayedDragStartListener', () {
    testWidgets('It should allow the item to be dragged when enabled is true',
        (WidgetTester tester) async {
      const int itemCount = 5;
      int onReorderCallCount = 0;
      final List<int> items =
          List<int>.generate(itemCount, (int index) => index);

      void handleReorder(int fromIndex, int toIndex) {
        onReorderCallCount += 1;
        if (toIndex > fromIndex) {
          toIndex -= 1;
        }
        items.insert(toIndex, items.removeAt(fromIndex));
      }

      // The list has five elements of height 100
      await tester.pumpWidget(
        MaterialApp(
          home: ReorderableGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
            ),
            itemCount: itemCount,
            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                key: ValueKey<int>(items[index]),
                height: 100,
                child: ReorderableGridDelayedDragStartListener(
                  index: index,
                  child: Text('item ${items[index]}'),
                ),
              );
            },
            onReorder: handleReorder,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start gesture on first item
      final TestGesture drag =
          await tester.startGesture(tester.getCenter(find.text('item 0')));
      await tester.pump(kLongPressTimeout);

      // Drag enough to move down the first item
      await drag.moveBy(const Offset(0, 50));
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();

      expect(onReorderCallCount, 1);
      expect(items, orderedEquals(<int>[1, 0, 2, 3, 4]));
    });

    testWidgets('It should allow the item to be dragged when enabled is true',
        (WidgetTester tester) async {
      const int itemCount = 5;
      int onReorderCallCount = 0;
      final List<int> items =
          List<int>.generate(itemCount, (int index) => index);

      void handleReorder(int fromIndex, int toIndex) {
        onReorderCallCount += 1;
        if (toIndex > fromIndex) {
          toIndex -= 1;
        }
        items.insert(toIndex, items.removeAt(fromIndex));
      }

      // The list has five elements of height 100
      await tester.pumpWidget(
        MaterialApp(
          home: ReorderableGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
            ),
            itemCount: itemCount,
            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                key: ValueKey<int>(items[index]),
                height: 100,
                child: ReorderableDelayedDragStartListener(
                  index: index,
                  enabled: false,
                  child: Text('item ${items[index]}'),
                ),
              );
            },
            onReorder: handleReorder,
          ),
        ),
      );

      // Start gesture on first item
      final TestGesture drag =
          await tester.startGesture(tester.getCenter(find.text('item 0')));
      await tester.pump(kLongPressTimeout);

      // Drag enough to move down the first item
      await drag.moveBy(const Offset(0, 50));
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();

      expect(onReorderCallCount, 0);
      expect(items, orderedEquals(<int>[0, 1, 2, 3, 4]));
    });
  });
}

class TestGrid extends StatefulWidget {
  const TestGrid({
    Key? key,
    this.textColor,
    this.iconColor,
    this.proxyDecorator,
    required this.items,
    this.reverse = false,
    this.crossAxisCount = 4,
  }) : super(key: key);

  final List<int> items;
  final Color? textColor;
  final Color? iconColor;
  final ReorderItemProxyDecorator? proxyDecorator;
  final bool reverse;
  final int crossAxisCount;

  @override
  State<TestGrid> createState() => _TestGridState();
}

class _TestGridState extends State<TestGrid> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: DefaultTextStyle(
          style: TextStyle(color: widget.textColor),
          child: IconTheme(
            data: IconThemeData(color: widget.iconColor),
            child: StatefulBuilder(
              builder: (BuildContext outerContext, StateSetter setState) {
                final List<int> items = widget.items;
                return CustomScrollView(
                  reverse: widget.reverse,
                  slivers: <Widget>[
                    SliverReorderableGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: widget.crossAxisCount,
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        return Container(
                          key: ValueKey<int>(items[index]),
                          height: 100,
                          color: items[index].isOdd ? Colors.red : Colors.green,
                          child: ReorderableDragStartListener(
                            index: index,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('item ${items[index]}'),
                                const Icon(Icons.drag_handle),
                              ],
                            ),
                          ),
                        );
                      },
                      itemCount: items.length,
                      onReorder: (int fromIndex, int toIndex) {
                        setState(() {
                          if (toIndex > fromIndex) {
                            toIndex -= 1;
                          }
                          items.insert(toIndex, items.removeAt(fromIndex));
                        });
                      },
                      proxyDecorator: widget.proxyDecorator,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
