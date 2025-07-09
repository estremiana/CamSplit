import 'item.dart';
import 'participant.dart';

class Bill {
  final int id;
  final String imageUrl;
  final double totalAmount;
  final String status;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Item> items;
  final List<Participant> participants;

  Bill({
    required this.id,
    required this.imageUrl,
    required this.totalAmount,
    required this.status,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.participants = const [],
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'],
      imageUrl: json['image_url'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      items: json['items'] != null 
          ? (json['items'] as List).map((item) => Item.fromJson(item)).toList()
          : [],
      participants: json['participants'] != null
          ? (json['participants'] as List).map((participant) => Participant.fromJson(participant)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'total_amount': totalAmount,
      'status': status,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'participants': participants.map((participant) => participant.toJson()).toList(),
    };
  }
} 