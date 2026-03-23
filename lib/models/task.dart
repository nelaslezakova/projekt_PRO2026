import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String subject;
  final String note;
  final String priority; // low, medium, high
  final bool isDone;
  final Timestamp createdAt;
  final Timestamp? dueDate;

  Task({
    required this.id,
    required this.title,
    required this.subject,
    required this.note,
    required this.priority,
    required this.isDone,
    required this.createdAt,
    required this.dueDate,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      subject: data['subject'] ?? '',
      note: data['note'] ?? '',
      priority: data['priority'] ?? 'medium',
      isDone: data['isDone'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      dueDate: data['dueDate'],
    );
  }
}