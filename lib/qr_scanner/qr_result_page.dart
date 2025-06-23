import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:work_line/services/firebase_service.dart';

class LoadingMessage extends StatefulWidget {
  const LoadingMessage({super.key});

  @override
  State<LoadingMessage> createState() => _LoadingMessageState();
}

class _LoadingMessageState extends State<LoadingMessage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotsAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _dotsAnimation = IntTween(begin: 0, end: 3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotsAnimation,
      builder: (context, child) {
        String dots = '.' * (_dotsAnimation.value + 1);
        return Text(
          'Ищем вашу деталь$dots',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }
}


class QrResultPage extends StatefulWidget {
  final String detailId;

  const QrResultPage({super.key, required this.detailId});

  @override
  QrResultPageState createState() => QrResultPageState();
}

class QrResultPageState extends State<QrResultPage> {
  Map<String, dynamic>? detailInfo;
  Map<String, dynamic>? templateInfo;
  final FirebaseService _firebaseService = FirebaseService();
  String? userDepartment;
  int currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDetailInfo();
    _loadUserDepartment();
  }

  Future<void> _loadDetailInfo() async {
    try {
      String splitDetailId = widget.detailId.split('|')[0];
      var detailData = await _firebaseService.getDetailInfo(splitDetailId);
      if (detailData != null) {
        var templateData = await _firebaseService.getTemplateInfo(detailData['template_id']);
        if (mounted) {
          setState(() {
            detailInfo = detailData;
            templateInfo = templateData;
            _updateCurrentStepIndex();
          });
        }
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке данных: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    }
  }

   Future<void> _loadUserDepartment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!mounted) return;
        setState(() {
          userDepartment = userDoc.data()?['department'];
        });
      } catch (e) {
        debugPrint('Error loading user department: $e');
      }
    } else {
      debugPrint('No current user');
    }
  }

  void _updateCurrentStepIndex() {
    if (detailInfo != null) {
      List<dynamic> steps = detailInfo?['steps'] ?? [];
      int nextStepIndex = steps.indexWhere((step) => step['status'] != 'Completed' && step['status'] != 'Defect');
      if (!mounted) return;
      setState(() {
        currentStepIndex = nextStepIndex != -1 ? nextStepIndex : steps.length;
      });
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Информация о детали"), backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: detailInfo == null || templateInfo == null
    ? const Center(child: LoadingMessage())
    : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Деталь ID: ${widget.detailId}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Текущий статус: ${detailInfo!['status'] ?? 'Не указан'}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            const Text("Этапы:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildStages(),
          ],
        ),
      ),

    );
  }

  Widget _buildStages() {
  if (templateInfo == null || templateInfo!['stages'] == null) {
    return const Center(child: Text("Нет этапов для отображения"));
  }

  List<dynamic> steps = detailInfo?['steps'] ?? [];

  return ListView.separated(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    itemCount: steps.length,
    separatorBuilder: (context, index) => const Divider(thickness: 1, height: 20), 
    itemBuilder: (context, index) {
      var step = steps[index];

      var stageName = step['stage_name'] ?? "Без названия";
      var isCompleted = step['status'] == 'Completed';
      var requiresOtkCheck = step['requires_otk_check'] ?? false;
      var employeeName = step['employee_name'] ?? "Неизвестный";
      var employeeNumber = step['employee_number'] ?? "Неизвестен";
      var status = step['status'] ?? "Не указан";
      

      List<dynamic> defectHistory = step['defect_history'] ?? [];
      Map<String, dynamic>? lastDefect = defectHistory.isNotEmpty ? defectHistory.last : null;

      var otkEmployeeName = lastDefect?['detected_by_name'] ?? "Неизвестный";
      var otkEmployeeNumber = lastDefect?['detected_by_number'] ?? "Неизвестен";

      var defectedEmployeeName = lastDefect?['defected_by_name'] ?? "Неизвестный";
      var defectedEmployeeNumber = lastDefect?['defected_by_number'] ?? "Неизвестен";

      var defectReason = lastDefect?['defect_reason'];

      if (!isCompleted && index != currentStepIndex) return const SizedBox();

      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.grey.shade300, blurRadius: 5, spreadRadius: 1),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stageName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: index == currentStepIndex ? FontWeight.bold : FontWeight.normal,
                color: index == currentStepIndex ? Colors.black : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                const SizedBox(width: 5),
                Text("Статус: $status", style: const TextStyle(fontSize: 14)),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.green),
                const SizedBox(width: 5),
                Text("Выполнил: $employeeName (№$employeeNumber)", style: const TextStyle(fontSize: 14)),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.security, size: 16, color: Colors.orange),
                const SizedBox(width: 5),
                Text("Проверка ОТК: ${requiresOtkCheck ? 'Требуется' : 'Не требуется'}", style: const TextStyle(fontSize: 14)),
              ],
            ),
            if (requiresOtkCheck && lastDefect != null) ...[
              const SizedBox(height: 10),
              Text("Последний брак:", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              Row(
                children: [
                  const Icon(Icons.engineering, size: 16, color: Colors.red),
                  const SizedBox(width: 5),
                  Text("Допустил: $defectedEmployeeName (№$defectedEmployeeNumber)", style: const TextStyle(color: Colors.red)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.verified, size: 16, color: Colors.blue),
                  const SizedBox(width: 5),
                  Text("Проверил: $otkEmployeeName (№$otkEmployeeNumber)", style: const TextStyle(color: Colors.blue)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.warning, size: 16, color: Colors.red),
                  const SizedBox(width: 5),
                  Text("Причина: $defectReason", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
            ],
            if (defectHistory.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.black),
                    tooltip: "История брака",
                    onPressed: () => _showDefectHistory(context, defectHistory),
                  ),
                ],
              ),
              SizedBox(height: 20,),
            if (!isCompleted && index == currentStepIndex)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text("Завершить", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => _showConfirmationDialog(widget.detailId, stageName, index, requiresOtkCheck, false),
                  ),
                  if (requiresOtkCheck)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.report_problem, color: Colors.white,),
                      label: const Text("Брак", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => _showConfirmationDialog(widget.detailId, stageName, index, requiresOtkCheck, true),
                    ),
                ],
              ),
          ],
        ),
      );
    },
  );
}


void _showDefectHistory(BuildContext context, List<dynamic> defectHistory) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "История брака",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: defectHistory.map((defect) {
                String detectedBy = defect['detected_by_name'] ?? "Неизвестный";
                String detectedByNumber = defect['detected_by_number'] ?? "Неизвестен";
                String defectedBy = defect['defected_by_name'] ?? "Неизвестный";
                String defectedByNumber = defect['defected_by_number'] ?? "Неизвестен";
                String reason = defect['defect_reason'] ?? "Не указана";

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "⚠️ Допустил брак: $defectedBy (№$defectedByNumber)",
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "🔍 Обнаружил ОТК: $detectedBy (№$detectedByNumber)",
                        style: const TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "📌 Причина: $reason",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 12, right: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              "Закрыть",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      );
    },
  );
}



  Future<void> _showConfirmationDialog(
  String detailId,
  String stageName,
  int stageIndex,
  bool requiresOtk,
  bool isDefect,
) async {
  final TextEditingController defectReasonController = TextEditingController();

 
  if (isDefect) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        "Отправить в брак?",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Вы уверены, что хотите отправить этот этап в брак?",
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: defectReasonController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: "Причина брака",
              labelStyle: const TextStyle(color: Colors.black),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade700),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade700, width: 2),
              ),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.only(bottom: 12, right: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            "Отмена",
            style: TextStyle(color: Colors.black),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            _showFinalDefectConfirmationDialog(
              detailId,
              stageName,
              stageIndex,
              defectReasonController.text,
            );
          },
          child: const Text("Подтвердить", style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
} else {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        "Завершить этап?",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: const Text(
        "Вы уверены, что хотите завершить этот этап?",
        style: TextStyle(fontSize: 14),
      ),
      actionsPadding: const EdgeInsets.only(bottom: 12, right: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            "Отмена",
            style: TextStyle(color: Colors.black),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            completeStage(
              detailId,
              stageName,
              stageIndex,
              requiresOtk,
              isDefect,
              "",
            );
          },
          child: const Text("Подтвердить", style: TextStyle(color: Colors.white),),
        ),
      ],
    ),
  );
}

}

Future<void> _showFinalDefectConfirmationDialog(
  String detailId,
  String stageName,
  int stageIndex,
  String defectReason,
) async {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Подтвердите отправку в брак"),
      content: const Text("Вы уверены, что хотите отправить этот этап в брак? Это действие необратимо."),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Отмена"),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            completeStage(detailId, stageName, stageIndex, true, true, defectReason);
          },
          child: const Text("Подтвердить"),
        ),
      ],
    ),
  );
}


  Future<void> completeStage(
  String detailId,
  String stageName,
  int stageIndex,
  bool requiresOtk,
  bool isDefect,
  String defectReason,
) async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final User? user = auth.currentUser;

  if (user == null) {
    debugPrint("Ошибка: пользователь не авторизован.");
    return;
  }

  final String userId = user.uid;
  try {
    final userDoc = await firestore.collection('users').doc(userId).get();

    final String user_first_name =  userDoc.data()?['first_name'] ?? '';
    final String last_name = userDoc.data()?['last_name'] ?? '';

    final String employeeName = '$last_name $user_first_name'.trim();
    final String employeeNumber = userDoc.data()?['employee_number'] ?? "Неизвестный номер";
    final String userRole = userDoc.data()?['role'] ?? 'employee';
    final String userDepartment = userDoc.data()?['department'] ?? 'employee';

    final docRef = firestore.collection('details').doc(detailId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      debugPrint("Ошибка: деталь не найдена.");
      return;
    }

    List<dynamic> steps = List.from(docSnapshot.data()?['steps'] ?? []);

    if (steps[stageIndex]['stage_name'] == stageName) {
      String currentStatus = steps[stageIndex]['status'] ?? '';

     
      String defectedById = steps[stageIndex]['employee_id'] ?? "";
      String defectedByName = steps[stageIndex]['employee_name'] ?? "";
      String defectedByNumber = steps[stageIndex]['employee_number'] ?? "";

      if (isDefect) {
        Map<String, dynamic> defectEntry = {
          "defect_reason": defectReason,
          "defect_timestamp": Timestamp.now(),  
          "detected_by_id": userId,
          "detected_by_name": employeeName,
          "detected_by_number": employeeNumber,
          "defected_by_id": defectedById,
          "defected_by_name": defectedByName,
          "defected_by_number": defectedByNumber
        };

        if (steps[stageIndex]['defect_history'] == null) {
          steps[stageIndex]['defect_history'] = [];
        }
        steps[stageIndex]['defect_history'].add(defectEntry);

        steps[stageIndex]['status'] = 'Waiting for repair';
      } else {
        if (currentStatus == 'Waiting for repair') {
          steps[stageIndex]['status'] = 'Waiting for OTK Check';
        } else if (currentStatus == 'Waiting for OTK Check' && (userRole == 'admin' || userDepartment == 'ОТК')) {
          steps[stageIndex]['status'] = 'Completed';
          steps[stageIndex]['completed_at'] = Timestamp.now();
        } else if (currentStatus != 'Completed') {
          steps[stageIndex]['status'] = requiresOtk ? 'Waiting for OTK Check' : 'Completed';
          if (!requiresOtk) {
            steps[stageIndex]['completed_at'] = Timestamp.now(); 
          }
        }

        steps[stageIndex]['employee_id'] = userId;
        steps[stageIndex]['employee_name'] = employeeName;
        steps[stageIndex]['employee_number'] = employeeNumber;
      }

      bool allCompleted = steps.every((step) => step['status'] == 'Completed');
      await docRef.update({
        'steps': steps,
        'status': allCompleted ? 'Completed' : 'In Progress',
      });

      debugPrint("Этап успешно обновлен.");
      await _loadDetailInfo();

      int nextStepIndex = steps.indexWhere((step) => step['status'] != 'Completed');
      if (nextStepIndex != -1) {
        if (!mounted) return;
        setState(() {
          currentStepIndex = nextStepIndex;
        });
      }
    } else {
      debugPrint("Ошибка: название этапа не совпадает.");
    }
  } catch (e) {
    debugPrint("Ошибка: $e");
  }
}

}