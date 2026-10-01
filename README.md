# Reorderable Grid — `onDrop` Extension

A small extension of the [`reorderable_grid`](https://github.com/casvanluijtelaar/reorderable_grid) Flutter package that exposes the end of a drag-and-drop operation independently from whether the item was actually reordered.

## Why this extension was needed

The package already provides an `onReorder` callback, but it is only triggered when the dragged item changes position.

In my project, [CoStock](https://github.com/DolBich/CoStock), I implemented automatic scrolling while dragging an item near the edge of the grid. The scroll starts when a drag begins and must always stop when the drag ends.

With the original API, this created an edge case:

```text
Drag starts
    ↓
Auto-scroll enabled
    ↓
Item is dropped at a different position
    → onReorder() fires → auto-scroll stops

Item is dropped at its original position
    → onReorder() does not fire
    → auto-scroll keeps running
```

To handle both cases, I added an `onDrop` callback that is invoked whenever the drag operation finishes, regardless of whether the item's position changed.

## The change

The package now supports:

```dart
ReorderableGrid(
  reorderStart: () => startAutoScroll(),
  onDrop: (oldIndex, newIndex) => stopAutoScroll(),
  onReorder: (oldIndex, newIndex) {
    // Update item order when the position actually changes.
  },
)
```

The resulting lifecycle is:

```text
Drag starts
    ↓
reorderStart
    ↓
Drag / auto-scroll
    ↓
Drop
    ├── onDrop(oldIndex, newIndex)    ← always called
    └── onReorder(oldIndex, newIndex) ← only when position changes
```

This keeps two different concerns separate:

- `onDrop` — the drag operation has ended;
- `onReorder` — the item's order has changed.

## Upstream contribution

The change was implemented as a focused modification to the original package and submitted upstream as a pull request:

**[Pull Request #48](https://github.com/casvanluijtelaar/reorderable_grid/pull/48)**

At the time of writing, the pull request is still awaiting maintainer response.

## Relation to CoStock

The extension was created specifically to support CoStock's drag-and-drop inventory/group organization and its automatic scrolling behavior during drag operations.

The implementation is intentionally small: rather than changing the package's existing reorder semantics, it adds a separate lifecycle callback for consumers that need to react to every completed drag operation.

## Tech Stack

- Dart
- Flutter
- Flutter widget / gesture lifecycle

## Notes

This repository is a focused fork/extension of the original `reorderable_grid` package rather than an independent UI application. The main purpose is to demonstrate a small upstream-oriented API improvement driven by a concrete requirement in another Flutter project.
