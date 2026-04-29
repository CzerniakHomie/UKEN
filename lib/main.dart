import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        //Zadanie 1
        appBar: AppBar(
          title: Text("KrakFlow"),
        ),
        //Zadanie 3
        body: Center(
          //Zadanie 2
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("KrakFlow"),           //
              Text("Organizacja studiów"), //
              Text("Dzisiejsze zadania"),  //
            ],
          ),
        ),
      ),
    );
  }
}