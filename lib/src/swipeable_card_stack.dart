part of 'package:swipeable_card_stack/swipeable_card_stack.dart';

typedef CardSwipedCallback = bool Function(SwipeDirection direction, Widget card);
typedef CardTappedCallback = void Function(Widget card);

class SwipeableCardStack extends StatefulWidget {
  /// Optionally, a controller that can be specified to allow programmatic control
  /// of the swipeable cards.
  final SwipeableCardSectionController? controller;

  /// The initial set of widgets (should be 3 widgets) to be rendered.
  final List<Widget> items;

  /// Executed when a card is swiped.
  final CardSwipedCallback? onCardSwiped;

  /// Executed when a card is tapped.
  final CardTappedCallback? onCardTapped;

  /// The multiplier for each card's width.
  /// Sets top, middle and bottom in that order.
  final Triple<double> cardWidthMultipliers;

  /// The multiplier for each card's height.
  /// Sets top, middle and bottom card in that order.
  final Triple<double> cardHeightMultipliers;

  /// Whether it should be possible to swipe a card upwards.
  final bool enableSwipeUp;

  /// Whether it should be possible to swipe a card downwards.
  final bool enableSwipeDown;

  /// The alignment of each card.
  final Triple<Alignment> cardAlignment;

  SwipeableCardStack({
    Key? key,
    this.controller,
    required BuildContext context,
    required this.items,
    this.onCardSwiped,
    this.onCardTapped,

    /// Like [cardWidthMultipliers], but sets all three at once.
    /// Will override [cardWidthMultipliers] if set.
    double? cardWidthMultiplier,

    /// Sets the multiplier of the screen width for each card.
    /// Will be overridden by [cardWidthMultiplier] if that is set.
    Triple<double> cardWidthMultipliers = const Triple.raw(0.9, 0.85, 0.8),

    /// Like [cardHeightMultipliers], but sets all three at once.
    /// Will override [cardHeightMultipliers] if set.
    double? cardHeightMultiplier,

    /// Sets the multiplier of the screen height for each card.
    /// Will be overridden by [cardHeightMultiplier] if that is set.
    Triple<double> cardHeightMultipliers = const Triple.raw(0.6, 0.55, 0.5),

    /// Can be set to false to prevent a card from being swiped up.
    this.enableSwipeUp = true,

    /// Can be set to false to prevent a card from being swiped down.
    this.enableSwipeDown = true,

    /// The alignment of each of the three cards.
    this.cardAlignment = const Triple.raw(Alignment(0.0, 1.0), Alignment(0.0, 0.8), Alignment(0.0, 0.0)),
  })  : cardWidthMultipliers = (cardWidthMultiplier != null ? Triple.from(cardWidthMultiplier) : null) ?? cardWidthMultipliers,
        cardHeightMultipliers = (cardHeightMultiplier != null ? Triple.from(cardHeightMultiplier) : null) ?? cardHeightMultipliers;

  @override
  _SwipeableCardStackState createState() => _SwipeableCardStackState();
}

class _SwipeableCardStackState extends State<SwipeableCardStack> with SingleTickerProviderStateMixin {
  StreamSubscription? _controllerStream;
  late AnimationController _animationController;

  Widget? nextCard;

  late Triple<Widget> cards;

  late Alignment frontCardAlign;
  double frontCardRot = 0.0;

  bool enableSwipe = true;

  @override
  void initState() {
    // If there is a controller, register a listener on it and save the subscription
    // in _controllerStream so it can be cancelled when this widget is no longer
    // needed.
    _controllerStream = widget.controller?.listen((event) {
      switch (event.type) {
        case SwipeableCardStackEventType.triggerSwipe:
          {
            _triggerSwipe(event.data as SwipeDirection);
            break;
          }
        case SwipeableCardStackEventType.addCard:
          {
            nextCard = event.data;
            break;
          }
        case SwipeableCardStackEventType.setSwipeEnabled:
          {
            if (mounted) {
              setState(() {
                this.enableSwipe = event.data;
              });
            }
            break;
          }
      }
    });

    // Load the initial cards.
    cards = Triple.fromList(widget.items);
    frontCardAlign = widget.cardAlignment.last;

    // Init the animation controller
    _animationController = AnimationController(duration: Duration(milliseconds: 200), vsync: this)
      ..addListener(() => setState(() {}))
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) changeCardsOrder();
      });

    super.initState();
  }

  @override
  void dispose() {
    _controllerStream?.cancel();
    super.dispose();
  }

  void _triggerSwipe(SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.up:
        frontCardAlign = Alignment(0.0, -0.001);
        break;
      case SwipeDirection.down:
        frontCardAlign = Alignment(0.0, 0.001);
        break;
      case SwipeDirection.left:
        frontCardAlign = Alignment(-0.001, 0.0);
        break;
      case SwipeDirection.right:
        frontCardAlign = Alignment(0.001, 0.0);
        break;
    }

    if (widget.onCardSwiped?.call(direction, cards.first) ?? true) {
      animateCards();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onCardTapped?.call(cards.first),
        child: IgnorePointer(
          ignoring: !enableSwipe,
          child: Stack(
            children: <Widget>[
              if (cards[2] != null) renderBackCard(),
              if (cards[1] != null) renderMiddleCard(),
              if (cards[0] != null) renderFrontCard(),
              // Prevent swiping if the cards are animating
              ((_animationController.status != AnimationStatus.forward))
                  ? SizedBox.expand(
                      child: GestureDetector(
                        // While dragging the first card
                        onPanUpdate: (DragUpdateDetails details) {
                          // Add what the user swiped in the last frame to the alignment of the card
                          setState(() {
                            frontCardAlign = Alignment(frontCardAlign.x + 20 * details.delta.dx / MediaQuery.of(context).size.width, frontCardAlign.y + 20 * details.delta.dy / MediaQuery.of(context).size.height);

                            frontCardRot = frontCardAlign.x; // * rotation speed;
                          });
                        },
                        // When releasing the first card
                        onPanEnd: (_) {
                          // If the front card was swiped far enough to count as swiped,
                          // determine the direction and process the swipe.
                          SwipeDirection? direction;

                          if (frontCardAlign.x > 3.0) {
                            direction = SwipeDirection.right;
                          } else if (frontCardAlign.x < -3.0) {
                            direction = SwipeDirection.left;
                          } else if (frontCardAlign.y < -3.0 && widget.enableSwipeUp) {
                            direction = SwipeDirection.up;
                          } else if (frontCardAlign.y > 3.0 && widget.enableSwipeDown) {
                            direction = SwipeDirection.down;
                          }

                          // If the card wasn't swiped enough in any direction, restore it to
                          // the initial position.
                          if (direction == null) {
                            setState(() {
                              frontCardAlign = widget.cardAlignment.last;
                              frontCardRot = 0.0;
                            });
                            return;
                          }

                          // Otherwise, animate the swipe completion.
                          if (widget.onCardSwiped?.call(direction, cards.first) ?? true) {
                            animateCards();
                          }
                        },
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

  Size computeSizeFor({required int index}) {
    return Size(
      MediaQuery.of(context).size.width * widget.cardWidthMultipliers[index],
      MediaQuery.of(context).size.height * widget.cardWidthMultipliers[index],
    );
  }

  Triple<Size> computeAllSizes() {
    return Triple.raw(computeSizeFor(index: 0), computeSizeFor(index: 1), computeSizeFor(index: 2));
  }

  Widget renderBackCard() {
    return Align(
      alignment: _animationController.status == AnimationStatus.forward ? CardsAnimation.backCardAlignmentAnim(_animationController, widget.cardAlignment).value : widget.cardAlignment[0],
      child: SizedBox.fromSize(
        size: _animationController.status == AnimationStatus.forward ? CardsAnimation.backCardSizeAnim(_animationController, computeAllSizes()).value : computeSizeFor(index: 0),
        child: cards[2],
      ),
    );
  }

  Widget renderMiddleCard() {
    return Align(
      alignment: _animationController.status == AnimationStatus.forward ? CardsAnimation.middleCardAlignmentAnim(_animationController, widget.cardAlignment).value : widget.cardAlignment[1],
      child: SizedBox.fromSize(
        size: _animationController.status == AnimationStatus.forward ? CardsAnimation.middleCardSizeAnim(_animationController, computeAllSizes()).value : computeSizeFor(index: 1),
        child: cards[1],
      ),
    );
  }

  Widget renderFrontCard() {
    return Align(
        alignment: _animationController.status == AnimationStatus.forward ? CardsAnimation.frontCardDisappearAlignmentAnim(_animationController, frontCardAlign).value : frontCardAlign,
        child: Transform.rotate(
          angle: (Math.pi / 180.0) * frontCardRot,
          child: SizedBox.fromSize(size: computeSizeFor(index: 0), child: cards[0]),
        ));
  }

  void changeCardsOrder() {
    setState(() {
      // Swap cards (back card becomes the middle card; middle card becomes the front card)
      cards = cards.shift(add: nextCard, backwards: false);
      nextCard = null;

      frontCardAlign = widget.cardAlignment.last;
      frontCardRot = 0.0;
    });
  }

  void animateCards() {
    _animationController.stop();
    _animationController.value = 0.0;
    _animationController.forward();
  }
}

class CardsAnimation {
  static alignmentSizeCurve(Animation<double> parent, {double offset = 0.0}) => CurvedAnimation(parent: parent, curve: Interval(0.2, 0.5, curve: Curves.easeIn));

  static Animation<Alignment> backCardAlignmentAnim(AnimationController parent, Triple<Alignment> cardAlignments) {
    return AlignmentTween(
      begin: cardAlignments[0],
      end: cardAlignments[1],
    ).animate(alignmentSizeCurve(parent, offset: 0.2));
  }

  static Animation<Size?> backCardSizeAnim(AnimationController parent, Triple<Size> cardSizes) {
    return SizeTween(
      begin: cardSizes[2],
      end: cardSizes[1],
    ).animate(alignmentSizeCurve(parent, offset: 0.2));
  }

  static Animation<Alignment> middleCardAlignmentAnim(AnimationController parent, Triple<Alignment> cardAlignments) {
    return AlignmentTween(
      begin: cardAlignments[1],
      end: cardAlignments[2],
    ).animate(alignmentSizeCurve(parent));
  }

  static Animation<Size?> middleCardSizeAnim(AnimationController parent, Triple<Size> cardSizes) {
    return SizeTween(
      begin: cardSizes[1],
      end: cardSizes[0],
    ).animate(alignmentSizeCurve(parent));
  }

  static Animation<Alignment> frontCardDisappearAlignmentAnim(AnimationController parent, Alignment beginAlign) {
    final animationInterval = CurvedAnimation(
      parent: parent,
      curve: Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    if (beginAlign.x == -0.001 || beginAlign.x == 0.001 || beginAlign.x > 3.0 || beginAlign.x < -3.0) {
      return AlignmentTween(
        begin: beginAlign,
        end: Alignment(
          // Has swiped to the left or right?
          beginAlign.x > 0 ? beginAlign.x + 30.0 : beginAlign.x - 30.0,
          0.0,
        ),
      ).animate(animationInterval);
    } else {
      return AlignmentTween(
        begin: beginAlign,
        end: Alignment(
          0.0,
          // Has swiped to the top or bottom?
          beginAlign.y > 0 ? beginAlign.y + 30.0 : beginAlign.y - 30.0,
        ),
      ).animate(animationInterval);
    }
  }
}
