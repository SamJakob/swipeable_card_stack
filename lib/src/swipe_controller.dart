part of 'package:swipeable_card_stack/swipeable_card_stack.dart';

enum SwipeDirection { left, right, up, down }

enum SwipeableCardStackEventType { triggerSwipe, addCard, setSwipeEnabled }

/// Emitted by [SwipeableCardSectionController] whenever an event is
/// programmatically triggered. Generally intended to be listened to
/// by a [SwipeableCardStack], allowing for the stack to be controlled.
class SwipeableCardStackEvent<T> {
  final SwipeableCardStackEventType type;
  final T data;

  const SwipeableCardStackEvent._({required this.type, required this.data});

  static _triggerSwipe({required SwipeDirection direction}) => SwipeableCardStackEvent<SwipeDirection>._(
        type: SwipeableCardStackEventType.triggerSwipe,
        data: direction,
      );

  static _addCard({required Widget card}) => SwipeableCardStackEvent<Widget>._(
        type: SwipeableCardStackEventType.addCard,
        data: card,
      );

  static _setSwipeEnabled({required bool isEnabled}) => SwipeableCardStackEvent<bool>._(
        type: SwipeableCardStackEventType.setSwipeEnabled,
        data: isEnabled,
      );
}

/// Used to control a [SwipeableCardStack].
/// When passed as the controller to a [SwipeableCardStack], methods such as
/// [triggerSwipe], etc., may be called to programmatically perform actions
/// on the stack.
class SwipeableCardSectionController {
  StreamController<SwipeableCardStackEvent> _controller;
  bool _swipeEnabled;

  bool get swipeEnabled => _swipeEnabled;
  set swipeEnabled(bool value) {
    _swipeEnabled = value;
    _controller.sink.add(SwipeableCardStackEvent._setSwipeEnabled(isEnabled: value));
  }

  SwipeableCardSectionController({
    bool swipeEnabled = true,
  })  : _swipeEnabled = swipeEnabled,
        _controller = StreamController<SwipeableCardStackEvent>.broadcast();

  // Ensure that a broadcast controller exists before we attempt to register
  // a listener for it.
  void _ensureControllerInitialized() {
    if (_controller.isClosed) {
      _controller = StreamController<SwipeableCardStackEvent>.broadcast();
    }

    // Auto-close the controller if there are no more listeners.
    _controller.onCancel = () {
      if (!_controller.hasListener) _controller.close();
    };
  }

  StreamSubscription listen(void Function(SwipeableCardStackEvent)? onData) {
    _ensureControllerInitialized();
    return _controller.stream.listen(onData);
  }

  void triggerSwipe({required SwipeDirection direction}) {
    _controller.sink.add(SwipeableCardStackEvent._triggerSwipe(direction: direction));
  }

  void addCard(Widget card) {
    _controller.sink.add(SwipeableCardStackEvent._addCard(card: card));
  }
}
