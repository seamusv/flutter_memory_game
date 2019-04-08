import 'dart:async';
import 'dart:math';

import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_icons/flutter_icon_data.dart';

void main() => SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) => runApp(App()));

class App extends HookWidget {
	@override
	Widget build(BuildContext context) {
		SystemChrome.setEnabledSystemUIOverlays([]);
		return MaterialApp(title: 'Memory', theme: ThemeData(fontFamily: 'SigmarOne'), home: Home(), debugShowCheckedModeBanner: false);
	}
}

class Home extends HookWidget {
	@override
	Widget build(BuildContext context) {
		glow(Color c, double r) => [
			Shadow(offset: Offset(-r, -r), color: c),
			Shadow(offset: Offset(r, -r), color: c),
			Shadow(offset: Offset(r, r), color: c),
			Shadow(offset: Offset(-r, r), color: c)
		];

		gameButton(String title, int cols, int rows) {
			var deck = List.generate(54, (i) => i)
				..shuffle()
				..removeRange((cols * rows) ~/ 2, 54);
			deck = (deck + deck)..shuffle();
			return RaisedButton(
				padding: EdgeInsets.all(25),
				child: Text(title,
					style: TextStyle(
						color: Colors.blue,
						fontSize: 40,
						fontWeight: FontWeight.bold,
						shadows: glow(Colors.black, 3),
					)),
				onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Game(cols: cols, rows: rows, deck: deck))),
			);
		}

		return Scaffold(
			body: Container(
				padding: EdgeInsets.all(20.0),
				color: Colors.black,
				child: Column(
					mainAxisAlignment: MainAxisAlignment.spaceEvenly,
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						Center(
							child: Text("Memory",
								style: TextStyle(
									fontSize: 60.0, color: Colors.purple, fontWeight: FontWeight.bold, shadows: glow(Colors.grey[300], 3)))),
						gameButton("Easy", 3, 4),
						gameButton("Medium", 4, 5),
						gameButton("Hard", 5, 8),
						gameButton("Advanced", 6, 9),
					],
				),
			),
		);
	}
}

class Game extends HookWidget {
	Game({Key key, this.cols, this.rows, this.deck}) : super(key: key);
	final int cols;
	final int rows;
	final List<int> deck;
	var play = [];
	var over = [];
	var wins = [];

	board(BuildContext context) {
		var cell = (int r, int c) {
			var id = r * cols + c;
			var cb = (AnimationController ctrl) => () {
				if (wins.contains(id) || play.contains(id)) return;
				if (play.isEmpty || play.length == 1 && play[0] != id) {
					play.add(id);
					over.add(ctrl);
					ctrl.forward();
				} else
					return;
				if (play.length == 2) {
					if (deck[play[0]] != deck[id]) {
						Stream.periodic(Duration(milliseconds: 1500)).take(1).listen((_) {
							over[0].reverse();
							over[1].reverse();
							play = [];
							over = [];
						});
					} else {
						wins += play;
						play = [];
						over = [];
						if (wins.length == deck.length) Navigator.pop(context);
					}
				}
			};
			return Expanded(child: Card(id: deck[id], onTap: cb));
		};
		var brd = List.generate(rows, (r) => List.generate(cols, (c) => cell(r, c)))
			.map((cards) => Expanded(child: Row(children: cards, mainAxisAlignment: MainAxisAlignment.spaceEvenly)))
			.toList();
		return Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: brd);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(body: Container(color: Colors.purple, child: board(context)));
	}
}

class Card extends HookWidget {
	Card({Key key, this.id, this.onTap}) : super(key: key);
	final int id;
	final Function onTap;

	_card(bool front) => Container(
		padding: EdgeInsets.all(5),
		child: Container(
			decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(15.0)), color: Colors.white),
			padding: EdgeInsets.all(5),
			child: FittedBox(child: front ? Icon(FlutterIconData.octicons(61696 + id)) : Image.asset("back.png"))));

	@override
	Widget build(BuildContext context) {
		var ctrl = useAnimationController(duration: Duration(milliseconds: 500));
		var forwardTween = TweenSequence(<TweenSequenceItem<double>>[
			TweenSequenceItem(tween: Tween(begin: 0.0, end: pi / 2).chain(CurveTween(curve: Curves.linear)), weight: 50),
			TweenSequenceItem(tween: ConstantTween<double>(pi / 2), weight: 50)
		]).animate(ctrl);
		var backwardTween = TweenSequence(<TweenSequenceItem<double>>[
			TweenSequenceItem(tween: ConstantTween<double>(pi / 2), weight: 50),
			TweenSequenceItem(tween: Tween(begin: -pi / 2, end: 0.0).chain(CurveTween(curve: Curves.linear)), weight: 50)
		]).animate(ctrl);

		return GestureDetector(
			onTap: onTap(ctrl),
			child: AspectRatio(
				aspectRatio: 1,
				child: Stack(fit: StackFit.expand, children: [
					AnimationCard(animation: backwardTween, child: _card(true)),
					AnimationCard(animation: forwardTween, child: _card(false)),
				]),
			),
		);
	}
}
