"""
Unit test for NLP Review Moderation module
"""
import sys
from nlp_moderator import analyze_review_text

test_cases = [
    {
        "text": "Great seller! The textbook was in perfect condition and very helpful.",
        "expected_toxic": False
    },
    {
        "text": "Item arrived on time, smooth transaction. Recommended!",
        "expected_toxic": False
    },
    {
        "text": "This seller is a fucking scammer and a liar! Total cheat, do not buy!",
        "expected_toxic": True
    },
    {
        "text": "Worst experience ever. Extremely rude, horrible, awful, terrible service, disgusting!",
        "expected_toxic": True
    },
    {
        "text": "Neutral transaction. Everything as expected.",
        "expected_toxic": False
    }
]

print("=== Running NLP Review Moderation Tests ===")
all_passed = True
for idx, tc in enumerate(test_cases, 1):
    res = analyze_review_text(tc["text"])
    passed = res["is_toxic"] == tc["expected_toxic"]
    status_icon = "[PASS]" if passed else "[FAIL]"
    print(f"\nTest {idx}: {status_icon}")
    print(f"  Input text: \"{tc['text']}\"")
    print(f"  Result: is_toxic={res['is_toxic']}, score={res['sentiment_score']}, label={res['sentiment_label']}")
    print(f"  Flag Reason: {res['flag_reason']}")
    if not passed:
        all_passed = False

if all_passed:
    print("\nALL NLP TESTS PASSED!")
    sys.exit(0)
else:
    print("\nSOME TESTS FAILED!")
    sys.exit(1)
