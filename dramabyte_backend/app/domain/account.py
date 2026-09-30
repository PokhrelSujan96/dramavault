from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class Preferences:
    marketing: bool
    analytics: bool
    personalization: bool


class AccountError(Exception):
    pass
