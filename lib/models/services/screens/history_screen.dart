import 'package
/material.dart';

import '../models/models.dart';

class HistoryScreen extends StatefulWidget {

const HistoryScreen({super.key});

@override

State<HistoryScreen> createState() => _HistoryScreenState();

}

class _HistoryScreenState extends State<HistoryScreen> {

List<HistoryItem> history = [];

@override

Widget build(BuildContext context) {

return Scaffold(

appBar: AppBar(

title: const Text('📜 تاریخچه'),

centerTitle: true,

actions: [

if (history.isNotEmpty)

IconButton(

icon: const Icon(Icons.delete_sweep),

onPressed: () {

setState(() => history.clear());

ScaffoldMessenger.of(context).showSnackBar(

const SnackBar(content: Text('تاریخچه پاک شد')));

},

),

],

),

body: history.isEmpty

? Center(

child: Column(

mainAxisAlignment: MainAxisAlignment.center,

children: [

Icon(Icons.history, size: 64, color: Colors.grey400),

const SizedBox(height: 16),

Text('هنوز سوالی اسکن نشده',

style: TextStyle(color: Colors.grey600)),

],

),

)

: ListView.builder(

itemCount: history.length,

itemBuilder: (context, index) {

final item = history[index];

return Card(

margin:

const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

child: ExpansionTile(

title: Text(item.question.text,

maxLines: 2, overflow: TextOverflow.ellipsis),

subtitle: Text(item.subjectName),

trailing: const Icon(Icons.check_circle, color: Colors.green),

children: [

Padding(

padding: const EdgeInsets.all(16),

child: Column(

crossAxisAlignment: CrossAxisAlignment.start,

children: [

const Text('گزینه صحیح:',

style: TextStyle(fontWeight: FontWeight.bold)),

Text(item.answer.correctOptionText),

const SizedBox(height: 8),

const Text('توضیح:',

style: TextStyle(fontWeight: FontWeight.bold)),

Text(item.answer.explanation),

],

),

),

],

),

);

},

),

);

}

}

