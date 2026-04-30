// Sentiment & category enums for the in-app feedback router.
// 3-button sentiment vote: happy → Apple's review prompt;
// neutral/unhappy → a category-aware feedback form whose row
// lands in app_feedback (private to us).

enum FeedbackSentiment { happy, neutral, unhappy }

enum FeedbackCategory { bug, featureRequest, general }

extension FeedbackCategoryX on FeedbackCategory {
  /// Server-side enum value (snake_case to match the DB constraint).
  String get dbValue => switch (this) {
        FeedbackCategory.bug => 'bug',
        FeedbackCategory.featureRequest => 'feature_request',
        FeedbackCategory.general => 'general',
      };

  /// User-facing chip label.
  String get label => switch (this) {
        FeedbackCategory.bug => 'bug',
        FeedbackCategory.featureRequest => 'feature idea',
        FeedbackCategory.general => 'just vibes',
      };
}

extension FeedbackSentimentX on FeedbackSentiment {
  String get dbValue => switch (this) {
        FeedbackSentiment.happy => 'happy',
        FeedbackSentiment.neutral => 'neutral',
        FeedbackSentiment.unhappy => 'unhappy',
      };
}
