// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class ManageStagesPage extends StatefulWidget {
//   const ManageStagesPage({super.key});

//   @override
//   ManageStagesPageState createState() => ManageStagesPageState();
// }

// class ManageStagesPageState extends State<ManageStagesPage> {
//   final TextEditingController _stageNameController = TextEditingController();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<void> _addStage() async {
//     String stageName = _stageNameController.text.trim();
//     if (stageName.isNotEmpty) {
//       await _firestore.collection('stage_templates').add({'name': stageName});
//       _stageNameController.clear();
//     }
//   }

//   Future<void> _deleteStage(String id) async {
//     await _firestore.collection('stage_templates').doc(id).delete();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Управление этапами"),
//         backgroundColor: Colors.black,
//         foregroundColor: Colors.white,
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _stageNameController,
//                     decoration: const InputDecoration(labelText: "Название этапа"),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.add, color: Colors.blueAccent),
//                   onPressed: _addStage,
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore.collection('stage_templates').snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 var stages = snapshot.data!.docs;
//                 return ListView.builder(
//                   itemCount: stages.length,
//                   itemBuilder: (context, index) {
//                     var stage = stages[index];
//                     return Card(
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       elevation: 4,
//                       child: ListTile(
//                         title: Text(stage['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                         trailing: IconButton(
//                           icon: const Icon(Icons.delete, color: Colors.redAccent),
//                           onPressed: () => _deleteStage(stage.id),
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }