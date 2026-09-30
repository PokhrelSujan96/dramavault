from pydantic import BaseModel


class ReferralError(Exception):
    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


class ReferralSummary(BaseModel):
    code: str
    invited: int
    purchased: int
    earned: int
    redeemed: bool
    signup_reward: int
    purchase_reward: int
