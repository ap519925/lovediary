part of 'ai_insights_bloc.dart';

abstract class AIInsightsEvent extends Equatable {
  const AIInsightsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAIInsights extends AIInsightsEvent {
  final String relationshipId;

  const LoadAIInsights(this.relationshipId);

  @override
  List<Object?> get props => [relationshipId];
}

class GenerateMoodAnalysis extends AIInsightsEvent {
  final String relationshipId;
  final List<String> recentMessages;
  final Map<String, dynamic> userBehaviorData;

  const GenerateMoodAnalysis({
    required this.relationshipId,
    required this.recentMessages,
    required this.userBehaviorData,
  });

  @override
  List<Object?> get props => [relationshipId, recentMessages, userBehaviorData];
}

class GenerateMemoryLane extends AIInsightsEvent {
  final String relationshipId;
  final DateTime targetDate;

  const GenerateMemoryLane({
    required this.relationshipId,
    required this.targetDate,
  });

  @override
  List<Object?> get props => [relationshipId, targetDate];
}

class GenerateDateSuggestion extends AIInsightsEvent {
  final String relationshipId;
  final String userLocation;
  final String partnerLocation;
  final Map<String, dynamic> preferences;

  const GenerateDateSuggestion({
    required this.relationshipId,
    required this.userLocation,
    required this.partnerLocation,
    required this.preferences,
  });

  @override
  List<Object?> get props => [relationshipId, userLocation, partnerLocation, preferences];
}

class GenerateConflictResolution extends AIInsightsEvent {
  final String relationshipId;
  final String conflictContext;
  final List<String> recentMessages;

  const GenerateConflictResolution({
    required this.relationshipId,
    required this.conflictContext,
    required this.recentMessages,
  });

  @override
  List<Object?> get props => [relationshipId, conflictContext, recentMessages];
}

class MarkInsightAsRead extends AIInsightsEvent {
  final String insightId;

  const MarkInsightAsRead(this.insightId);

  @override
  List<Object?> get props => [insightId];
}

class AnalyzeVoiceEmotion extends AIInsightsEvent {
  final String relationshipId;
  final String audioFilePath;
  final String callType; // 'voice' or 'video'

  const AnalyzeVoiceEmotion({
    required this.relationshipId,
    required this.audioFilePath,
    required this.callType,
  });

  @override
  List<Object?> get props => [relationshipId, audioFilePath, callType];
}

class GenerateCulturalGuide extends AIInsightsEvent {
  final String relationshipId;
  final String userCulture;
  final String partnerCulture;
  final String occasion; // 'holiday', 'birthday', 'anniversary', etc.

  const GenerateCulturalGuide({
    required this.relationshipId,
    required this.userCulture,
    required this.partnerCulture,
    required this.occasion,
  });

  @override
  List<Object?> get props => [relationshipId, userCulture, partnerCulture, occasion];
}
