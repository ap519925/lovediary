part of 'ai_insights_bloc.dart';

abstract class AIInsightsState extends Equatable {
  const AIInsightsState();

  @override
  List<Object?> get props => [];
}

class AIInsightsInitial extends AIInsightsState {}

class AIInsightsLoading extends AIInsightsState {}

class AIInsightsGenerating extends AIInsightsState {}

class AIInsightsLoaded extends AIInsightsState {
  final List<AIInsightModel> insights;

  const AIInsightsLoaded(this.insights);

  @override
  List<Object?> get props => [insights];
}

class AIInsightGenerated extends AIInsightsState {
  final AIInsightModel insight;

  const AIInsightGenerated(this.insight);

  @override
  List<Object?> get props => [insight];
}

class MemoryLaneGenerated extends AIInsightsState {
  final MemoryLaneModel memory;

  const MemoryLaneGenerated(this.memory);

  @override
  List<Object?> get props => [memory];
}

class AIInsightMarkedAsRead extends AIInsightsState {
  final String insightId;

  const AIInsightMarkedAsRead(this.insightId);

  @override
  List<Object?> get props => [insightId];
}

class AIInsightsError extends AIInsightsState {
  final String message;

  const AIInsightsError(this.message);

  @override
  List<Object?> get props => [message];
}
