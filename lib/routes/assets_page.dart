



import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class AssetsPage extends StatefulWidget {
  const AssetsPage({Key? key, required this.htmlContent, required this.title}) : super(key: key);

  final String htmlContent;
  final String title;

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:  Text(widget.title),),
      drawer: mainMenu(),
      body: SingleChildScrollView(child: Html(data: widget.htmlContent)),

    );
  }

  Widget mainMenu () {

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(decoration: BoxDecoration(color: Colors.blue),child: Text("4training"),),
          ListTile(title: const Text("Tile 1"), onTap: (){},),
          ListTile(title: const Text("Tile 2"), onTap: (){},),
          ListTile(title: const Text("Tile 3"), onTap: (){},),
          ListTile(title: const Text("Close"), onTap: (){Navigator.pop(context);},),
        ],
      ),
    );

  }
}
