 # :white_square_button: Reorderable Grid

[![Pub Version](https://img.shields.io/pub/v/reorderable_grid?label=version&style=flat-square)](https://pub.dev/packages/reorderable_grid/changelog)
[![Likes](https://badges.bar/reorderable_grid/likes)](https://pub.dev/packages/reorderable_grid/score)
[![Pub points](https://badges.bar/reorderable_grid/pub%20points)](https://pub.dev/packages/reorderable_grid/score) 
[![Pub](https://img.shields.io/github/stars/casvanluijtelaar/reorderable_grid)](https://github.com/casvanluijtelaar/reorderable_grid)
[![codecov](https://codecov.io/gh/casvanluijtelaar/reorderable_grid/branch/master/graph/badge.svg?token=V047CJZ1RU)](https://codecov.io/gh/casvanluijtelaar/reorderable_grid)


A full reorderable grid implemention similar to Flutters Reorderable_List. with full `ReorderableGridView`, `ReorderableGrid` and `SliverReorderableGrid` implementations



<p align="center">
  <img src="https://github.com/casvanluijtelaar/reorderable_grid/blob/master/assets/example.gif?raw=true" alt="gif showing basic usage" width="600"/>
<p\>

## :hammer: How it works 
`ReorderableGridView` is a drop in replacement for the existing `GridView` and adds an `onReorder` callback that provides the original and new index of the reordered item.

``` dart
/// create a new list of data
final items = List<int>.generate(40, (index) => index);

/// when the reorder completes remove the list entry from its old position
/// and insert it at its new index
void _onReorder(int oldIndex, int newIndex) {
setState(() {
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
});
}

@override
Widget build(BuildContext context) {
return MaterialApp(
    home: Scaffold(
      body: ReorderableGridView.extent(
        maxCrossAxisExtent: 250,
        onReorder: _onReorder,
        childAspectRatio: 1,
        children: items.map((item) {
          /// map every list entry to a widget and assure every child has a 
          /// unique key
          return Card(
            key: ValueKey(item),
            child: Center(
            child: Text(item.toString()),
            ),
          );
        }).toList(),
      ),
    ),
);
}
```

`ReorderableGrid` provides all the constructors and parameters the normal `GridView` has. The package also includes:
  * `ReorderableGridView`, which is a prebuild Material-ish implementation of the grid. 
  * `ReorderableGrid`, A barebones widget that allows you to customize the grid however you want
  * `SliverReorderableGrid`, a reorderable grid sliver for custom scroll implementations


## :wave: Get Involved

If this package is useful to you please :thumbsup: on [pub.dev](https://pub.dev/packages/reorderable_grid) and :star: on [github](https://github.com/casvanluijtelaar/reorderable_grid). If you have any Issues, recommendations or pull requests I'd love to see them!