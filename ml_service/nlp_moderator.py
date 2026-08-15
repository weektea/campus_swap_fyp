"""
NLP Review Moderation Module for Campus Swap
Analyzes review sentiment and detects toxic, abusive, profanity, or review bombing comments.
Uses vaderSentiment for lightweight, fast sentiment polarity calculation and a curated lexical toxicity rule engine.
"""

from typing import Dict, Any, List, Optional
import re

try:
    from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
    _analyzer = SentimentIntensityAnalyzer()
except ImportError:
    _analyzer = None

# Curated list of toxic, profane, scam allegations, harassment, and abusive keywords
TOXIC_KEYWORDS = {
    # Profanity / Slurs / Harassment
    "fuck", "fucking", "shit", "bitch", "bastard", "asshole", "idiot", "moron",
    "stupid", "dumb", "scum", "loser", "trash", "crap", "bullshit", "dick",
    "cunt", "piss", "slut", "whore",
    # Fraud / Scam / Hostile accusations
    "scammer", "scam", "fraud", "thief", "cheat", "cheater", "liar",
    "robbed", "fake", "stole", "steal", "con artist",
    # Threats / Violence
    "kill", "die", "harm", "punch", "threat", "attack", "destroy"
}

def analyze_review_text(text: Optional[str]) -> Dict[str, Any]:
    """
    Analyzes input text for sentiment score and toxic/abusive patterns.

    Args:
        text (str): The review comment string.

    Returns:
        dict: {
            "is_toxic": bool,
            "sentiment_score": float,
            "sentiment_label": str,
            "compound": float,
            "flag_reason": Optional[str]
        }
    """
    if not text or not text.strip():
        return {
            "is_toxic": False,
            "sentiment_score": 0.0,
            "sentiment_label": "Neutral",
            "compound": 0.0,
            "flag_reason": None
        }

    clean_text = text.strip()
    lower_text = clean_text.lower()

    # 1. Lexical Keyword / Profanity Inspection
    words = set(re.findall(r'\b[a-z0-9_-]+\b', lower_text))
    matched_toxic = words.intersection(TOXIC_KEYWORDS)

    # 2. VADER Sentiment Polarity Analysis
    compound = 0.0
    if _analyzer is not None:
        scores = _analyzer.polarity_scores(clean_text)
        compound = round(scores.get("compound", 0.0), 4)
    else:
        # Fallback simple rule if analyzer is not initialized
        neg_count = sum(1 for w in words if w in matched_toxic)
        compound = -0.5 if neg_count > 0 else 0.1

    sentiment_score = compound

    # Determine Sentiment Label
    if compound >= 0.05:
        sentiment_label = "Positive"
    elif compound <= -0.05:
        sentiment_label = "Negative"
    else:
        sentiment_label = "Neutral"

    # Toxicity Threshold Evaluation
    # Toxic if:
    # - Matched explicit abusive/toxic words
    # - OR compound sentiment is severely negative (<= -0.40)
    is_toxic = False
    flag_reason = None

    if matched_toxic:
        is_toxic = True
        matched_str = ", ".join(sorted(list(matched_toxic))[:4])
        flag_reason = f"Abusive / profane terms detected: [{matched_str}]"
    elif compound <= -0.40:
        is_toxic = True
        flag_reason = f"Highly negative sentiment score ({compound})"

    return {
        "is_toxic": is_toxic,
        "sentiment_score": sentiment_score,
        "sentiment_label": sentiment_label,
        "compound": compound,
        "flag_reason": flag_reason
    }
