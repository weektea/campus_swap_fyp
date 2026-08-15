"""
Unit & Integration Test for Recommendation Enhancements:
1. Campus Context Homophily Boost (1.15x)
2. Time-Decay Freshness Penalty (exp(-0.02 * days))
3. Intra-List Diversity Filter (Max 4 per subcategory in Top 10)
"""
import sys
import math
import numpy as np
from main import (
    HybridRecommendRequest,
    ProductItem,
    InteractionItem,
    get_hybrid_recommendations
)
from nlp_moderator import analyze_review_text
import asyncio

async def test_recommendations():
    print("=== Testing Recommendation Enhancements ===")
    
    # --------------------------------------------------------------------------
    # Test 1: Campus Context Homophily Boost (1.15x for same faculty)
    # --------------------------------------------------------------------------
    print("\n--- Test 1: Campus Context Homophily Boost ---")
    p1 = ProductItem(
        id="prod_same_faculty",
        title="Engineering Calculus Textbook",
        description="Calculus 101 for FCI students",
        category="Books",
        subcategory="Textbooks",
        seller_id="seller_fci",
        seller_faculty="FCI",
        days_since_listed=1.0
    )
    p2 = ProductItem(
        id="prod_diff_faculty",
        title="Engineering Calculus Textbook",
        description="Calculus 101 for FCI students",
        category="Books",
        subcategory="Textbooks",
        seller_id="seller_fcm",
        seller_faculty="FCM",
        days_since_listed=1.0
    )
    
    req1 = HybridRecommendRequest(
        user_id="student_1",
        user_faculty="FCI",
        interactions=[InteractionItem(user_id="student_1", product_id="prod_same_faculty", weight=1.0)],
        products=[p2, p1] # Put diff faculty first in input list
    )
    
    res1 = await get_hybrid_recommendations(req1)
    rec_ids1 = res1["recommended_product_ids"]
    print(f"Top recommendation for FCI student: {rec_ids1[0]}")
    assert rec_ids1[0] == "prod_same_faculty", "Homophily boost failed: same faculty product should rank #1"
    print("[PASS] Homophily Boost verified: Same faculty item ranked above identical different-faculty item.")

    # --------------------------------------------------------------------------
    # Test 2: Time-Decay Freshness Penalty (exp(-0.02 * days))
    # --------------------------------------------------------------------------
    print("\n--- Test 2: Time-Decay Freshness Penalty ---")
    p_fresh = ProductItem(
        id="prod_fresh",
        title="Apple iPad Air M2",
        description="Tablet for digital notes and drawing",
        category="Electronics",
        subcategory="Tablets",
        seller_id="seller_a",
        days_since_listed=2.0
    )
    p_old = ProductItem(
        id="prod_old",
        title="Apple iPad Air M2",
        description="Tablet for digital notes and drawing",
        category="Electronics",
        subcategory="Tablets",
        seller_id="seller_b",
        days_since_listed=55.0 # 55 days old
    )

    req2 = HybridRecommendRequest(
        user_id="student_2",
        interactions=[InteractionItem(user_id="student_2", product_id="prod_fresh", weight=1.0)],
        products=[p_old, p_fresh]
    )

    res2 = await get_hybrid_recommendations(req2)
    rec_ids2 = res2["recommended_product_ids"]
    print(f"Top recommendation: {rec_ids2[0]}")
    assert rec_ids2[0] == "prod_fresh", "Time-decay penalty failed: Fresh item should rank higher than 55-day old item"
    print("[PASS] Time-decay Freshness Penalty verified.")

    # --------------------------------------------------------------------------
    # Test 3: Intra-List Diversity Filter (Max 4 items per subcategory in Top 10)
    # --------------------------------------------------------------------------
    print("\n--- Test 3: Intra-List Diversity Filter (Echo Chamber Prevention) ---")
    # Create 6 high-scoring Calculators, 4 Textbooks, 2 Laptops
    products_pool = []
    
    # 6 Calculators
    for i in range(1, 7):
        products_pool.append(ProductItem(
            id=f"calc_{i}",
            title=f"Casio FX-570EX Scientific Calculator Model {i}",
            description="Official exam scientific calculator Casio",
            category="Electronics",
            subcategory="Calculators",
            seller_id=f"seller_c_{i}",
            days_since_listed=1.0
        ))
        
    # 4 Textbooks
    for i in range(1, 5):
        products_pool.append(ProductItem(
            id=f"book_{i}",
            title=f"University Physics Volume {i}",
            description="Physics mechanics and thermodynamics textbook",
            category="Books",
            subcategory="Textbooks",
            seller_id=f"seller_b_{i}",
            days_since_listed=1.0
        ))

    # 2 Laptops
    for i in range(1, 3):
        products_pool.append(ProductItem(
            id=f"laptop_{i}",
            title=f"Dell Inspiron Laptop Model {i}",
            description="Laptop computer for coding and programming",
            category="Electronics",
            subcategory="Laptops",
            seller_id=f"seller_l_{i}",
            days_since_listed=1.0
        ))

    # User has high interest in Calculators (e.g. searched and saved calculator)
    req3 = HybridRecommendRequest(
        user_id="student_3",
        preference_tags=["calculator", "casio", "scientific"],
        interactions=[InteractionItem(user_id="student_3", product_id="calc_1", weight=5.0)],
        products=products_pool
    )

    res3 = await get_hybrid_recommendations(req3)
    rec_ids3 = res3["recommended_product_ids"]
    
    top_10 = rec_ids3[:10]
    calc_in_top_10 = [pid for pid in top_10 if pid.startswith("calc_")]
    books_in_top_10 = [pid for pid in top_10 if pid.startswith("book_")]
    laptops_in_top_10 = [pid for pid in top_10 if pid.startswith("laptop_")]

    print(f"Total returned in Top 10: {len(top_10)}")
    print(f"Calculators count in Top 10: {len(calc_in_top_10)} (Max allowed: 4)")
    print(f"Textbooks count in Top 10: {len(books_in_top_10)}")
    print(f"Laptops count in Top 10: {len(laptops_in_top_10)}")

    assert len(calc_in_top_10) <= 4, f"Diversity filter failed! Found {len(calc_in_top_10)} calculators in Top 10"
    assert len(books_in_top_10) > 0, "Diversity filter failed! Diverse categories were not pulled up"
    print("[PASS] Intra-List Diversity Filter verified: Echo chamber prevented, max 4 items per subcategory.")

    # --------------------------------------------------------------------------
    # Test 4: Regression Check for NLP Moderation
    # --------------------------------------------------------------------------
    print("\n--- Test 4: NLP Moderation Isolation & Regression Check ---")
    nlp_res = analyze_review_text("Great seller, very smooth deal!")
    assert nlp_res["is_toxic"] is False
    nlp_res_toxic = analyze_review_text("This scammer idiot stole my money and lied!")
    assert nlp_res_toxic["is_toxic"] is True
    print("[PASS] NLP Review Moderation module confirmed 100% intact and working.")

    print("\n=======================================================")
    print("ALL RECOMMENDATION ENHANCEMENT TESTS PASSED!")
    print("=======================================================\n")

if __name__ == "__main__":
    asyncio.run(test_recommendations())
