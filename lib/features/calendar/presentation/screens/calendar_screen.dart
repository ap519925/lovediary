import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lovediary/l10n/app_localizations.dart';

class CalendarScreen extends StatefulWidget {
  final String? userId;
  final String? partnerId;

  const CalendarScreen({
    super.key,
    this.userId,
    this.partnerId,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _isLoading = false;

  // Events stored in Firestore
  Map<DateTime, List<Event>> _events = {};
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier([]);
    
    // Get current user ID
    _currentUserId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    
    if (_currentUserId != null) {
      _loadEventsForMonth(_focusedDay);
    }
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> _loadEventsForMonth(DateTime month) async {
    if (_isLoading || _currentUserId == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final Map<DateTime, List<Event>> monthEvents = {};
      
      // Load events for each day of the month
      final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
      
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(month.year, month.month, day);
        final events = await _getEventsForDate(date);
        if (events.isNotEmpty) {
          monthEvents[DateTime.utc(date.year, date.month, date.day)] = events;
        }
      }
      
      setState(() {
        _events = monthEvents;
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Event>> _getEventsForDate(DateTime date) async {
    if (_currentUserId == null) return [];
    
    try {
      final dateKey = _formatDateKey(date);
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId!)
          .collection('calendar_events')
          .doc(dateKey)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final events = data['events'] as List<dynamic>? ?? [];
        
        return events.map((event) => Event.fromMap(event)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting events for date: $e');
      return [];
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    final key = DateTime.utc(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null;
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.calendar ?? 'Calendar'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _selectedDay != null && _currentUserId != null ? _showAddEventDialog : null,
            tooltip: 'Add Event',
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<Event>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
              _loadEventsForMonth(focusedDay);
            },
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              selectedDecoration: BoxDecoration(
                color: Colors.pink,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.pinkAccent,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: Colors.pink,
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
              ),
              formatButtonTextStyle: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                if (value.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No events for this day',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to add an event',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final event = value[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12.0),
                        color: event.color.withOpacity(0.1),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: event.color,
                          child: const Icon(Icons.event, color: Colors.white),
                        ),
                        title: Text(
                          event.title,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          'Created: ${_formatDateTime(event.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteEvent(index),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog() {
    final TextEditingController controller = TextEditingController();
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text('Color:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Colors.blue,
                  Colors.red,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.pink,
                ].map((color) => GestureDetector(
                  onTap: () => setState(() => selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selectedColor == color
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty && _selectedDay != null) {
                  _addEvent(controller.text, selectedColor);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addEvent(String title, Color color) async {
    if (_selectedDay == null || _currentUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final event = Event(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        color: color,
        createdAt: DateTime.now(),
      );

      final dateKey = _formatDateKey(_selectedDay!);
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId!)
          .collection('calendar_events')
          .doc(dateKey);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
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
        }, SetOptions(merge: true));
      });

      // Update local cache
      final key = DateTime.utc(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
      if (_events[key] != null) {
        _events[key]!.add(event);
      } else {
        _events[key] = [event];
      }
      
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding event: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEvent(int index) async {
    if (_selectedDay == null || _currentUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dateKey = _formatDateKey(_selectedDay!);
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId!)
          .collection('calendar_events')
          .doc(dateKey);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          List<Map<String, dynamic>> events = 
              List<Map<String, dynamic>>.from(data['events'] ?? []);
          
          if (index >= 0 && index < events.length) {
            events.removeAt(index);
            
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

      // Update local cache
      final key = DateTime.utc(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
      if (_events[key] != null && index < _events[key]!.length) {
        _events[key]!.removeAt(index);
        if (_events[key]!.isEmpty) {
          _events.remove(key);
        }
      }
      
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting event: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class Event {
  final String id;
  final String title;
  final Color color;
  final DateTime createdAt;

  Event({
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

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
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
    return other is Event && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
