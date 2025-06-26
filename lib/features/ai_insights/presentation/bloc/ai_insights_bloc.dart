import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lovediary/features/ai_insights/data/models/ai_insight_model.dart';

part 'ai_insights_event.dart';
part 'ai_insights_state.dart';

class AIInsightsBloc extends Bloc<AIInsightsEvent, AIInsightsState> {
  final FirebaseFirestore firestore;

  AIInsightsBloc({
    required this.firestore,
  }) : super(AIInsightsInitial()) {
    on<LoadAIInsights>(_onLoadAIInsights);
    on<GenerateMoodAnalysis>(_onGenerateMoodAnalysis);
    on<GenerateMemoryLane>(_onGenerateMemoryLane);
    on<GenerateDateSuggestion>(_onGenerateDateSuggestion);
    on<GenerateConflictResolution>(_onGenerateConflictResolution);
    on<MarkInsightAsRead>(_onMarkInsightAsRead);
    on<AnalyzeVoiceEmotion>(_onAnalyzeVoiceEmotion);
    on<GenerateCulturalGuide>(_onGenerateCulturalGuide);
  }

  Future<void> _onLoadAIInsights(
    LoadAIInsights event,
    Emitter<AIInsightsState> emit,
  ) async {
    emit(AIInsightsLoading());
    try {
      final snapshot = await firestore
          .collection('ai_insights')
          .where('relationshipId', isEqualTo: event.relationshipId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final insights = snapshot.docs
          .map((doc) => AIInsightModel.fromFirestore(doc))
          .toList();

      emit(AIInsightsLoaded(insights));
    } catch (e) {
      emit(AIInsightsError('Failed to load insights: ${e.toString()}'));
    }
  }

  Future<void> _onGenerateMoodAnalysis(
    GenerateMoodAnalysis event,
    Emitter<AIInsightsState> emit,
  ) async {
    emit(AIInsightsGenerating());
    try {
      // Analyze recent messages for mood patterns
      final prompt = '''
      Analyze the following relationship data for mood patterns and emotional insights:
      
      Recent Messages: ${event.recentMessages.join('\n')}
      User Behavior Data: ${event.userBehaviorData}
      
      Please provide:
      1. Overall mood assessment
      2. Any concerning patterns
      3. Positive highlights
      4. Suggestions for improvement
      
      Keep the response supportive and constructive.
      ''';

      // Placeholder AI analysis - will be replaced with actual AI integration
      final analysisText = _generateMoodAnalysisPlaceholder(event.recentMessages, event.userBehaviorData);

      final insight = AIInsightModel(
        id: '',
        relationshipId: event.relationshipId,
        type: 'mood_analysis',
        title: 'Relationship Mood Analysis',
        content: analysisText,
        metadata: {
          'messageCount': event.recentMessages.length,
          'analysisDate': DateTime.now().toIso8601String(),
        },
        createdAt: DateTime.now(),
        isRead: false,
        confidence: 0.8,
      );

      // Save to Firestore
      await firestore.collection('ai_insights').add(insight.toFirestore());

      emit(AIInsightGenerated(insight));
    } catch (e) {
      emit(AIInsightsError('Failed to generate mood analysis: ${e.toString()}'));
    }
  }

  Future<void> _onGenerateMemoryLane(
    GenerateMemoryLane event,
    Emitter<AIInsightsState> emit,
  ) async {
    emit(AIInsightsGenerating());
    try {
      // Get historical data from the target date
      final targetDate = event.targetDate;
      final startDate = targetDate.subtract(const Duration(days: 1));
      final endDate = targetDate.add(const Duration(days: 1));

      // Fetch messages and photos from that time period
      final messagesSnapshot = await firestore
          .collection('messages')
          .where('relationshipId', isEqualTo: event.relationshipId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThan: Timestamp.fromDate(endDate))
          .get();

      final photosSnapshot = await firestore
          .collection('photos')
          .where('relationshipId', isEqualTo: event.relationshipId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThan: Timestamp.fromDate(endDate))
          .get();

      if (messagesSnapshot.docs.isEmpty && photosSnapshot.docs.isEmpty) {
        emit(AIInsightsError('No memories found for this date'));
        return;
      }

      // Create memory lane entry
      final memory = MemoryLaneModel(
        id: '',
        relationshipId: event.relationshipId,
        title: 'Memory from ${targetDate.year}',
        description: 'On this day ${DateTime.now().difference(targetDate).inDays} days ago...',
        photoUrls: photosSnapshot.docs
            .map((doc) => doc.data()['url'] as String)
            .toList(),
        messageIds: messagesSnapshot.docs.map((doc) => doc.id).toList(),
        originalDate: targetDate,
        createdAt: DateTime.now(),
        metadata: {
          'messageCount': messagesSnapshot.docs.length,
          'photoCount': photosSnapshot.docs.length,
        },
      );

      // Save to Firestore
      await firestore.collection('memory_lane').add(memory.toFirestore());

      emit(MemoryLaneGenerated(memory));
    } catch (e) {
      emit(AIInsightsError('Failed to generate memory lane: ${e.toString()}'));
    }
  }

  Future<void> _onGenerateDateSuggestion(
    GenerateDateSuggestion event,
    Emitter<AIInsightsState> emit,
  ) async {
    emit(AIInsightsGenerating());
    try {
      final prompt = '''
      Generate personalized date suggestions for a long-distance couple:
      
      User Location: ${event.userLocation}
      Partner Location: ${event.partnerLocation}
      Preferences: ${event.preferences}
      
      Please suggest:
      1. Virtual date ideas they can do together online
      2. Local activities each person can do in their city
      3. Future in-person date ideas for when they meet
      4. Cultural experiences relevant to their locations
      
      Make suggestions specific to their locations and preferences.
      ''';

      // Placeholder date suggestions - will be replaced with actual AI integration
      final suggestionText = _generateDateSuggestionsPlaceholder(event.userLocation, event.partnerLocation, event.preferences);

      final insight = AIInsightModel(
        id: '',
        relationshipId: event.relationshipId,
        type: 'date_suggestion',
        title: 'Personalized Date Ideas',
        content: suggestionText,
        metadata: {
          'userLocation': event.userLocation,
          'partnerLocation': event.partnerLocation,
          'preferences': event.preferences,
        },
        createdAt: DateTime.now(),
        isRead: false,
        confidence: 0.9,
      );

      await firestore.collection('ai_insights').add(insight.toFirestore());
      emit(AIInsightGenerated(insight));
    } catch (e) {
      emit(AIInsightsError('Failed to generate date suggestions: ${e.toString()}'));
    }
  }

  Future<void> _onGenerateConflictResolution(
    GenerateConflictResolution event,
    Emitter<AIInsightsState> emit,
  ) async {
    emit(AIInsightsGenerating());
    try {
      final prompt = '''
      Provide gentle conflict resolution advice for a couple:
      
      Context: ${event.conflictContext}
      Recent Messages: ${event.recentMessages.join('\n')}
      
      Please provide:
      1. Understanding of both perspectives
      2. Communication strategies
      3. Steps to resolve the conflict
      4. Ways to prevent similar issues
      
      Be empathetic and focus on healthy communication.
      ''';

      // Placeholder conflict resolution - will be replaced with actual AI integration
      final adviceText = _generateConflictResolutionPlaceholder(event.conflictContext, event.recentMessages);

      final insight = AIInsightModel(
        id: '',
        relationshipId: event.relationshipId,
        type: 'conflict_resolution',
        title: 'Relationship Guidance',
        content: adviceText,
        metadata: {
          'conflictType': event.conflictContext,
          'messageCount': event.recentMessages.length,
        },
        createdAt: DateTime.now(),
        isRead: false,
        confidence: 0.7,
      );

      await firestore.collection('ai_insights').add(insight.toFirestore());
      emit(AIInsightGenerated(insight));
    } catch (e) {
      emit(AIInsightsError('Failed to generate conflict resolution: ${e.toString()}'));
    }
  }

  Future<void> _onMarkInsightAsRead(
    MarkInsightAsRead event,
    Emitter<AIInsightsState> emit,
  ) async {
    try {
      await firestore
          .collection('ai_insights')
          .doc(event.insightId)
          .update({'isRead': true});
      
      emit(AIInsightMarkedAsRead(event.insightId));
    } catch (e) {
      emit(AIInsightsError('Failed to mark insight as read: ${e.toString()}'));
    }
  }

  Future<void> _onAnalyzeVoiceEmotion(
    AnalyzeVoiceEmotion event,
    Emitter<AIInsightsState> emit,
  ) async {
    emit(AIInsightsGenerating());
    try {
      // This would integrate with voice analysis APIs
      // For now, we'll create a placeholder implementation
      final insight = AIInsightModel(
        id: '',
        relationshipId: event.relationshipId,
        type: 'voice_emotion',
        title: 'Voice Emotion Analysis',
        content: 'Voice emotion analysis feature coming soon. This will analyze tone and emotional patterns during calls.',
        metadata: {
          'callType': event.callType,
          'audioFile': event.audioFilePath,
        },
        createdAt: DateTime.now(),
        isRead: false,
        confidence: 0.6,
      );

      await firestore.collection('ai_insights').add(insight.toFirestore());
      emit(AIInsightGenerated(insight));
    } catch (e) {
      emit(AIInsightsError('Failed to analyze voice emotion: ${e.toString()}'));
    }
  }

  Future<void> _onGenerateCulturalGuide(
    GenerateCulturalGuide event,
    Emitter<AIInsightsState> emit,
  ) async {
    emit(AIInsightsGenerating());
    try {
      final prompt = '''
      Create a cultural guide for a cross-cultural couple:
      
      User Culture: ${event.userCulture}
      Partner Culture: ${event.partnerCulture}
      Occasion: ${event.occasion}
      
      Please provide:
      1. Cultural significance of the occasion
      2. Traditional ways to celebrate
      3. How to blend both cultures
      4. Gift ideas and customs
      5. Foods and activities to try
      
      Make it educational and respectful of both cultures.
      ''';

      // Placeholder cultural guide - will be replaced with actual AI integration
      final guideText = _generateCulturalGuidePlaceholder(event.userCulture, event.partnerCulture, event.occasion);

      final insight = AIInsightModel(
        id: '',
        relationshipId: event.relationshipId,
        type: 'cultural_guide',
        title: 'Cultural Guide: ${event.occasion}',
        content: guideText,
        metadata: {
          'userCulture': event.userCulture,
          'partnerCulture': event.partnerCulture,
          'occasion': event.occasion,
        },
        createdAt: DateTime.now(),
        isRead: false,
        confidence: 0.9,
      );

      await firestore.collection('ai_insights').add(insight.toFirestore());
      emit(AIInsightGenerated(insight));
    } catch (e) {
      emit(AIInsightsError('Failed to generate cultural guide: ${e.toString()}'));
    }
  }

  // Placeholder methods - will be replaced with actual AI integration
  String _generateMoodAnalysisPlaceholder(List<String> messages, Map<String, dynamic> behaviorData) {
    final messageCount = messages.length;
    final hasPositiveWords = messages.any((msg) => 
        msg.toLowerCase().contains('love') || 
        msg.toLowerCase().contains('happy') || 
        msg.toLowerCase().contains('excited'));
    
    return '''
🌟 Relationship Mood Analysis

📊 Overall Assessment: ${hasPositiveWords ? 'Positive' : 'Neutral'}
Based on $messageCount recent messages, your relationship shows healthy communication patterns.

💝 Positive Highlights:
• Regular communication frequency
• ${hasPositiveWords ? 'Expressions of affection detected' : 'Consistent messaging patterns'}
• Active engagement from both partners

💡 Suggestions:
• Continue sharing daily experiences
• Plan virtual date activities together
• Express appreciation more frequently

Note: This is a basic analysis. Full AI insights coming soon!
    ''';
  }

  String _generateDateSuggestionsPlaceholder(String userLocation, String partnerLocation, Map<String, dynamic> preferences) {
    return '''
💕 Personalized Date Ideas

🌐 Virtual Dates:
• Watch party for movies/shows
• Online cooking session together
• Virtual museum tours
• Play online games together
• Video call while stargazing

📍 Local Activities (${userLocation}):
• Visit local cafes and share photos
• Explore nearby parks or attractions
• Try new restaurants and describe the food
• Attend local events and livestream

📍 Local Activities (${partnerLocation}):
• Similar local exploration activities
• Cultural site visits with photo sharing
• Local food tastings with reviews

✈️ Future In-Person Ideas:
• Plan a weekend getaway
• Visit each other's favorite local spots
• Attend concerts or events together
• Take a cooking class together

Note: Personalized AI suggestions based on your preferences coming soon!
    ''';
  }

  String _generateConflictResolutionPlaceholder(String context, List<String> messages) {
    return '''
🤝 Relationship Guidance

💭 Understanding the Situation:
Every relationship faces challenges, and it's normal to have disagreements. What matters is how you work through them together.

🗣️ Communication Strategies:
• Listen actively to your partner's perspective
• Use "I" statements to express your feelings
• Take breaks if emotions get too high
• Focus on the issue, not personal attacks

🔧 Steps to Resolve:
1. Acknowledge both viewpoints
2. Find common ground
3. Compromise where possible
4. Agree on next steps together

🛡️ Prevention Tips:
• Regular check-ins about feelings
• Set boundaries and respect them
• Practice patience and empathy
• Celebrate small victories together

Remember: Every couple faces challenges. What makes relationships strong is working through them with love and respect.

Note: Personalized AI counseling based on your specific situation coming soon!
    ''';
  }

  String _generateCulturalGuidePlaceholder(String userCulture, String partnerCulture, String occasion) {
    return '''
🌍 Cultural Guide: ${occasion}

🎭 Cultural Significance:
Understanding and celebrating each other's cultural backgrounds strengthens your bond and creates beautiful shared experiences.

🎉 Traditional Celebrations:
• Learn about traditional customs from both cultures
• Share family traditions and their meanings
• Create new blended traditions together

🎁 Gift Ideas:
• Cultural items representing each heritage
• Books about each other's culture
• Traditional foods or cooking ingredients
• Art or music from both cultures

🍽️ Foods to Try:
• Traditional dishes from both cultures
• Cooking sessions to learn each other's recipes
• Exploring fusion cuisine together

🤝 Blending Cultures:
• Create new traditions that honor both backgrounds
• Learn basic phrases in each other's languages
• Share cultural stories and family history
• Plan visits to cultural centers or events

Note: Detailed cultural insights and personalized recommendations coming soon!
    ''';
  }
}
