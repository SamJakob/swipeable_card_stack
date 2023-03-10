import 'package:example/card_view.dart';
import 'package:flutter/material.dart';
import 'package:swipeable_card_stack/swipeable_card_stack.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int counter = 4;

  @override
  Widget build(BuildContext context) {
    //create a CardController
    SwipeableCardSectionController _cardController = SwipeableCardSectionController();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SwipeableCardStack(
            controller: _cardController,
            context: context,
            //add the first 3 cards
            items: [
              CardView(text: "First card"),
              CardView(text: "Second card"),
              CardView(text: "Third card"),
            ],
            onCardSwiped: (dir, widget) {
              //Add the next card
              if (counter <= 20) {
                _cardController.addCard(CardView(text: "Card $counter"));
                counter++;
              }

              if (dir == SwipeDirection.left) {
                print('onDisliked ${(widget as CardView).text}');
              } else if (dir == SwipeDirection.right) {
                print('onLiked ${(widget as CardView).text}');
              } else if (dir == SwipeDirection.up) {
                print('onUp ${(widget as CardView).text}');
              } else if (dir == SwipeDirection.down) {
                print('onDown ${(widget as CardView).text}');
              }

              return true;
            },
            enableSwipeUp: true,
            enableSwipeDown: true,
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  child: Icon(Icons.chevron_left),
                  onPressed: () => _cardController.triggerSwipe(direction: SwipeDirection.left),
                ),
                FloatingActionButton(
                  child: Icon(Icons.chevron_right),
                  onPressed: () => _cardController.triggerSwipe(direction: SwipeDirection.right),
                ),
                FloatingActionButton(
                  child: Icon(Icons.arrow_upward),
                  onPressed: () => _cardController.triggerSwipe(direction: SwipeDirection.up),
                ),
                FloatingActionButton(
                  child: Icon(Icons.arrow_downward),
                  onPressed: () => _cardController.triggerSwipe(direction: SwipeDirection.down),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
