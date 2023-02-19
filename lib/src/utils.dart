part of 'package:swipeable_card_stack/swipeable_card_stack.dart';

class Triple<T> {
  final T? _firstElement;
  final T? _secondElement;
  final T? _thirdElement;

  Triple(this._firstElement, T? secondElement, T? thirdElement, {bool fillRemaining = false})
      : _secondElement = fillRemaining && _firstElement != null && secondElement == null ? _firstElement : secondElement,
        _thirdElement = fillRemaining && _firstElement != null && thirdElement == null ? secondElement : thirdElement;

  const Triple.raw(T? firstElement, T? secondElement, T? thirdElement)
      : _firstElement = firstElement,
        _secondElement = secondElement,
        _thirdElement = thirdElement;

  const Triple.from(T? element)
      : _firstElement = element,
        _secondElement = element,
        _thirdElement = element;

  Triple.fromList(List<T> items)
      : _firstElement = items.length > 0 ? items[0] : null,
        _secondElement = items.length > 1 ? items[1] : null,
        _thirdElement = items.length > 2 ? items[2] : null;

  bool any(bool Function(T? element) test) => test(_firstElement) || test(_secondElement) || test(_thirdElement);

  Triple<T> clone() => Triple<T>.raw(_firstElement, _secondElement, _thirdElement);

  Triple<R> cast<R>() => Triple<R>(_firstElement as R, _secondElement as R, _thirdElement as R);

  /// Shifts each element by one and returns the new [Triple]. By default, it shifts forwards,
  ///
  /// firstElement <- secondElement <- thirdElement
  /// (i.e., the second element becomes the first, the third becomes the second, etc.,)
  ///
  /// Alternatively, [backwards] may be set to true to shift in the opposite
  /// direction.
  ///
  /// [add] may be specified to
  Triple<T> shift({bool backwards = false, T? add}) {
    if (backwards) {
      return Triple<T>(add, _firstElement, _secondElement);
    } else {
      return Triple<T>(_secondElement, _thirdElement, add);
    }
  }

  T get first => _firstElement!;

  T get last => _thirdElement!;

  bool contains(Object? element) => _firstElement == element || _secondElement == element || _thirdElement == element;

  T? elementAt(int index) {
    switch (index) {
      case 0:
        return _firstElement!;
      case 1:
        return _secondElement!;
      case 2:
        return _thirdElement!;
      default:
        throw ArgumentError.value(index, "index", "Invalid index, must be less than or equal to 2.");
    }
  }

  bool every(bool Function(T? element) test) => test(_firstElement!) && test(_secondElement!) && test(_thirdElement!);

  List<T?> toList() => [_firstElement, _secondElement, _thirdElement];

  void forEach(void Function(T? element) handler) {
    handler(_firstElement);
    handler(_secondElement);
    handler(_thirdElement);
  }

  operator [](int index) {
    return elementAt(index);
  }
}
