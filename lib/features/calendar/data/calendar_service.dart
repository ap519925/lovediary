import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lovediary/core/utils/logger.dart';

class CalendarService {
  static const String _tag = 'CalendarService';
  final FirebaseFirestore _firestore;
  final String _userId;
  final String? _partnerId;

  CalendarService({
    required FirebaseFirestore firestore,
    required String userId,
    String? partnerId,
  }) : _firestore = firestore, _userId = userId, _partnerId = partnerId;

  /// Get the shared calendar collection reference
  String get _calendarCollectionPath {
    if (_partnerId != null && _partnerId.isNotEmpty) {
      // Create a consistent shared calendar ID by sorting user IDs
      final sortedIds = [_userId, _partnerId]..sort();
      return 'shared_calendars/${sortedIds.join('_')}/events';
    } else {
      // Fallback to individual calendar
      return 'users/${_userId}/calendar_events';
    }
  }

  /// Get events for a specific date
  Future<List<CalendarEvent>> getEventsForDate(DateTime date) async {
    try {
      final dateKey = _formatDateKey(date);
      Logger.d(_tag, 'Getting events for date: $dateKey from path: $_calendarCollectionPath');
      
      final doc = await _firestore
          .collection(_calendarCollectionPath)
          .doc(dateKey)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final events = data['events'] as List<dynamic>? ?? [];
        
        return events.map((event) => CalendarEvent.fromMap(event)).toList();
      }
      
      return [];
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error getting events for date', e, stackTrace);
      return [];
    }
  }

  /// Add an event to a specific date
  Future<bool> addEvent(DateTime date, CalendarEvent event) async {
    try {
      final dateKey = _formatDateKey(date);
      Logger.d(_tag, 'Adding event to date: $dateKey to path: $_calendarCollectionPath');
      
      final docRef = _firestore
          .collection(_calendarCollectionPath)
          .doc(dateKey);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        List<Map<String, dynamic>> events = [];
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          events = List<Map<String, dynamic>>.from(data['events'] ?? []);
        }
        
        events.add(event.toMap());
        
        transaction.set(docRef, {
          'events': events,
          'lastUpdated': FieldValue.serverTimestamp(),
          'createdBy': _userId,
        }, SetOptions(merge: true));
      });
      
      Logger.i(_tag, 'Event added successfully');
      return true;
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error adding event', e, stackTrace);
      return false;
    }
  }

  /// Remove an event from a specific date
  Future<bool> removeEvent(DateTime date, int eventIndex) async {
    try {
      final dateKey = _formatDateKey(date);
      Logger.d(_tag, 'Removing event from date: $dateKey, index: $eventIndex from path: $_calendarCollectionPath');
      
      final docRef = _firestore
          .collection(_calendarCollectionPath)
          .doc(dateKey);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          List<Map<String, dynamic>> events = 
              List<Map<String, dynamic>>.from(data['events'] ?? []);
          
          if (eventIndex >= 0 && eventIndex < events.length) {
            events.removeAt(eventIndex);
            
            if (events.isEmpty) {
              transaction.delete(docRef);
            } else {
              transaction.update(docRef, {
                'events': events,
                'lastUpdated': FieldValue.serverTimestamp(),
              });
            }
          }
        }
      });
      
      Logger.i(_tag, 'Event removed successfully');
      return true;
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error removing event', e, stackTrace);
      return false;
    }
  }

  /// Get all events for a month
  Future<Map<DateTime, List<CalendarEvent>>> getEventsForMonth(DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);
      
      Logger.d(_tag, 'Getting events for month: ${month.year}-${month.month}');
      
      final Map<DateTime, List<CalendarEvent>> events = {};
      
      // Get all events for the month
      for (int day = 1; day <= endOfMonth.day; day++) {
        final date = DateTime(month.year, month.month, day);
        final dayEvents = await getEventsForDate(date);
        if (dayEvents.isNotEmpty) {
          events[date] = dayEvents;
        }
      }
      
      return events;
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error getting events for month', e, stackTrace);
      return {};
    }
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class CalendarEvent {
  final String id;
  final String title;
  final Color color;
  final DateTime createdAt;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.color,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'color': color.value,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      color: Color(map['color'] ?? Colors.blue.value),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  @override
  String toString() => title;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
