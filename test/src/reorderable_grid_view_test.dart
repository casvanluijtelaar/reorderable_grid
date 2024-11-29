import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reorderable_grid/reorderable_grid.dart';

void main() {
  const double itemHeight = 48.0;

  testWidgets(
    'ReorderableGridView.builder asserts on negative childCount',
    (WidgetTester tester) async {
      expect(
          () => ReorderableGridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                ),
                itemBuilder: (BuildContext context, int index) {
                  return const SizedBox();
                },
                itemCount: -1,
                onReorder: (int from, int to) {},
              ),
          throwsAssertionError);
    },
  );

  testWidgets(
    'ReorderableGridView.builder only creates the children it needs',
    (WidgetTester tester) async {
      final Set<int> itemsCreated = <int>{};
      await tester.pumpWidget(MaterialApp(
        home: ReorderableGridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
          ),
          itemBuilder: (BuildContext context, int index) {
            itemsCreated.add(index);
            return Text(index.toString(), key: ValueKey<int>(index));
          },
          itemCount: 1000,
          onReorder: (int from, int to) {},
        ),
      ));

      expect(itemsCreated, <int>{
        ...{0, 1, 2, 3, 4, 5, 6, 7, 8, 9},
        ...{10, 11, 12, 13, 14, 15, 16, 17, 18, 19},
      });
    },
  );

  testWidgets('Animation test when placing an item in place',
      (WidgetTester tester) async {
    const Key testItemKey = Key('Test item');
    final Widget reorderableGridView = ReorderableGridView.count(
      crossAxisCount: 4,
      scrollDirection: Axis.vertical,
      onReorder: (int oldIndex, int newIndex) {},
      children: const <Widget>[
        SizedBox(
          key: Key('First item'),
          height: itemHeight,
          child: Text('First item'),
        ),
        SizedBox(
          key: testItemKey,
          height: itemHeight,
          child: Text('Test item'),
        ),
        SizedBox(
          key: Key('Last item'),
          height: itemHeight,
          child: Text('Last item'),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        height: itemHeight * 10,
        child: reorderableGridView,
      ),
    ));

    Offset getTestItemPosition() {
      final RenderBox testItem =
          tester.renderObject<RenderBox>(find.byKey(testItemKey));
      return testItem.localToGlobal(Offset.zero);
    }

    // Before pick it up.
    final Offset startPosition = getTestItemPosition();

    // Pick it up.
    final TestGesture gesture =
        await tester.startGesture(tester.getCenter(find.byKey(testItemKey)));
    await tester.pump(kLongPressTimeout + kPressTimeout);
    expect(getTestItemPosition(), startPosition);

    // Put it down.
    await gesture.up();
    await tester.pump();
    expect(getTestItemPosition(), startPosition);

    // After put it down.
    await tester.pumpAndSettle();
    expect(getTestItemPosition(), startPosition);
  });

  testWidgets(
      'ReorderableGridView throws an error when key is not passed to its children',
      (WidgetTester tester) async {
    final Widget reorderableGridView = ReorderableGridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
      ),
      itemBuilder: (BuildContext context, int index) {
        return SizedBox(child: Text('Item $index'));
      },
      itemCount: 3,
      onReorder: (int oldIndex, int newIndex) {},
    );
    await tester.pumpWidget(
        MaterialApp(
          home: reorderableGridView,
        ),
        duration: const Duration(milliseconds: 100));

    final dynamic exception = tester.takeException();
    expect(exception, isNotNull);
  });

  testWidgets('Throws an error if no overlay present',
      (WidgetTester tester) async {
    final Widget reorderableList = ReorderableGridView.count(
      crossAxisCount: 4,
      children: const <Widget>[
        SizedBox(width: 100.0, height: 100.0, key: Key('C'), child: Text('C')),
        SizedBox(width: 100.0, height: 100.0, key: Key('B'), child: Text('B')),
        SizedBox(width: 100.0, height: 100.0, key: Key('A'), child: Text('A')),
      ],
      onReorder: (int oldIndex, int newIndex) {},
    );
    final Widget boilerplate = Localizations(
      locale: const Locale('en'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: SizedBox(
        width: 100.0,
        height: 100.0,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: reorderableList,
        ),
      ),
    );
    await tester.pumpWidget(boilerplate);

    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    expect(exception.toString(), contains('No Overlay widget found'));
    expect(
        exception.toString(),
        contains(
            'ReorderableGridView widgets require an Overlay widget ancestor'));
  });
}

class _Stateful extends StatefulWidget {
  // Ignoring the preference for const constructors because we want to test with regular non-const instances.
  // ignore:prefer_const_constructors_in_immutables
  _Stateful({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _StatefulState();
}

class _StatefulState extends State<_Stateful> {
  bool? checked = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48.0,
      height: 48.0,
      child: Material(
        child: Checkbox(
          value: checked,
          onChanged: (bool? newValue) => checked = newValue,
        ),
      ),
    );
  }
}
