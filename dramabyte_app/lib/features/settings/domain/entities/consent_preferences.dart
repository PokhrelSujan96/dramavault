import 'package:equatable/equatable.dart';

enum ConsentPurpose { marketing, analytics, personalization }

final class ConsentPreferences extends Equatable {
  const ConsentPreferences({
    this.marketing = false,
    this.analytics = false,
    this.personalization = false,
  });

  final bool marketing;
  final bool analytics;
  final bool personalization;

  bool isGranted(ConsentPurpose purpose) => switch (purpose) {
    ConsentPurpose.marketing => marketing,
    ConsentPurpose.analytics => analytics,
    ConsentPurpose.personalization => personalization,
  };

  ConsentPreferences copyWithPurpose(ConsentPurpose purpose, bool granted) {
    return ConsentPreferences(
      marketing: purpose == ConsentPurpose.marketing ? granted : marketing,
      analytics: purpose == ConsentPurpose.analytics ? granted : analytics,
      personalization: purpose == ConsentPurpose.personalization
          ? granted
          : personalization,
    );
  }

  @override
  List<Object> get props => [marketing, analytics, personalization];
}
