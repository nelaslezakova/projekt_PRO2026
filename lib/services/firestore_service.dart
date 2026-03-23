import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference tasks =
      FirebaseFirestore.instance.collection('tasks');

  Stream<QuerySnapshot> getTasksStream() {
    return tasks.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> addTask({
    required String title,
    required String subject,
    required String note,
    required String priority,
    required DateTime? dueDate,
  }) async {
    await tasks.add({
      'title': title,
      'subject': subject,
      'note': note,
      'priority': priority,
      'isDone': false,
      'createdAt': FieldValue.serverTimestamp(),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
    });
  }

  Future<void> updateTask({
    required String id,
    required String title,
    required String subject,
    required String note,
    required String priority,
    required DateTime? dueDate,
  }) async {
    await tasks.doc(id).update({
      'title': title,
      'subject': subject,
      'note': note,
      'priority': priority,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
    });
  }

  Future<void> toggleTask({
    required String id,
    required bool currentValue,
  }) async {
    await tasks.doc(id).update({
      'isDone': !currentValue,
    });
  }

  Future<void> deleteTask(String id) async {
    await tasks.doc(id).delete();
  }
}