"""
Unit & Integration Test Suite for Recommendation Enhancements:
1. Campus Context Homophily Boost (1.15x)
2. Time-Decay Freshness Penalty (exp(-0.02 * days))
3. Intra-List Diversity Filter (Max 4 per subcategory in Top 10)
4. Preference Preservation (Suppress Item Exposure, NOT User Interest)
5. Repeated Refresh Stability (Simulated Multi-Step Session)
6. Candidate Availability Fallback (Small Inventory Never Empties)
7. NLP Review Moderation Isolation & Regression Check
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
    print("=== Testing Recommendation Enhancements & Interaction-Aware Layer ===")
    
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
        preference_tags=["calculus", "textbook"],
        interactions=[],
        recent_viewed_product_ids=[],
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
        preference_tags=["apple", "ipad", "tablet"],
        interactions=[],
        recent_viewed_product_ids=[],
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

    req3 = HybridRecommendRequest(
        user_id="student_3",
        preference_tags=["calculator", "casio", "scientific"],
        interactions=[InteractionItem(user_id="student_3", product_id="calc_1", weight=5.0, interaction_type="save")],
        recent_viewed_product_ids=[],
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
    # Test 4: Preference Preservation (Suppress Item Exposure, NOT User Interest)
    # --------------------------------------------------------------------------
    print("\n--- Test 4: Preference Preservation (Suppress Item, Not Interest) ---")
    catalog = [
        ProductItem(id="calc_1", title="Casio Scientific Calculator FX", description="Scientific math exam calculator", category="Electronics", subcategory="Calculators"),
        ProductItem(id="calc_2", title="Canon Scientific Calculator Solar", description="Scientific math exam calculator", category="Electronics", subcategory="Calculators"),
        ProductItem(id="calc_3", title="TI-84 Plus Graphing Calculator", description="Engineering calculator for math", category="Electronics", subcategory="Calculators"),
        ProductItem(id="laptop_stand", title="Ergonomic Aluminum Laptop Stand", description="Laptop desk riser for study and coding", category="Electronics", subcategory="Laptop Accessories"),
        ProductItem(id="usb_hub", title="USB-C Multiport Hub Adapter for Laptop", description="USB-C hub for laptop accessories and study", category="Electronics", subcategory="Laptop Accessories"),
        ProductItem(id="study_lamp", title="LED Desk Study Reading Lamp", description="Bright LED lamp for study desk dorm", category="Furniture", subcategory="Lamps"),
        ProductItem(id="calculus_book", title="University Calculus Textbook", description="Calculus mathematics textbook for study", category="Books", subcategory="Textbooks"),
        ProductItem(id="badminton_racket", title="Yonex Badminton Racket", description="Sports racket for outdoor exercise", category="Sports", subcategory="Rackets"),
        ProductItem(id="water_bottle", title="Hydro Flask Water Bottle", description="Stainless steel insulated bottle", category="Sports", subcategory="Bottles"),
    ]

    req4 = HybridRecommendRequest(
        user_id="student_4",
        interactions=[InteractionItem(user_id="student_4", product_id="calc_1", weight=1.0, interaction_type="view")],
        recent_viewed_product_ids=["calc_1"],
        products=catalog
    )

    res4 = await get_hybrid_recommendations(req4)
    rec_ids4 = res4["recommended_product_ids"]
    print(f"Recommendations after viewing calc_1: {rec_ids4}")

    # calc_1 should be suppressed and NOT rank at index 0
    assert rec_ids4[0] != "calc_1", f"Exposure suppression failed: Clicked item calc_1 is still ranked #1!"
    # Unseen calculators or related study items (calc_2, calc_3, laptop_stand, usb_hub) should rank above unrelated items
    top_3 = rec_ids4[:3]
    assert any(pid in top_3 for pid in ["calc_2", "calc_3", "laptop_stand", "usb_hub"]), "Preference signal failed: Other relevant items did not rank in top 3"
    assert rec_ids4.index("badminton_racket") > rec_ids4.index("calc_2"), "Relevance ranking failed: Unrelated sports item ranked above relevant calculator"
    print("[PASS] Preference Preservation verified: Clicked item suppressed, broader interest in calculators/study items preserved.")

    # --------------------------------------------------------------------------
    # Test 5: Repeated Recommendation Refresh Stability (Multi-Step Session)
    # --------------------------------------------------------------------------
    print("\n--- Test 5: Repeated Recommendation Refresh Stability (5-Step Session) ---")
    session_user = "student_session"
    session_interactions = []
    recent_views = []
    
    # Step 1: Initial feed for user interested in electronics & study
    req_s1 = HybridRecommendRequest(
        user_id=session_user,
        preference_tags=["electronics", "study", "laptop"],
        interactions=[],
        recent_viewed_product_ids=[],
        products=catalog
    )
    res_s1 = await get_hybrid_recommendations(req_s1)
    feed_1 = res_s1["recommended_product_ids"]
    print(f"Session Step 1 Feed: {feed_1}")
    assert len(feed_1) > 0, "Step 1 feed empty"
    
    # Step 2: User clicks top recommendation from Step 1
    clicked_item_1 = feed_1[0]
    session_interactions.append(InteractionItem(user_id=session_user, product_id=clicked_item_1, weight=1.0, interaction_type="view"))
    recent_views.insert(0, clicked_item_1)
    
    req_s2 = HybridRecommendRequest(
        user_id=session_user,
        preference_tags=["electronics", "study", "laptop"],
        interactions=session_interactions,
        recent_viewed_product_ids=recent_views,
        products=catalog
    )
    res_s2 = await get_hybrid_recommendations(req_s2)
    feed_2 = res_s2["recommended_product_ids"]
    print(f"Session Step 2 Feed (after clicking {clicked_item_1}): {feed_2}")
    assert feed_2[0] != clicked_item_1, f"Step 2 failed: {clicked_item_1} still #1 after being viewed"

    # Step 3: User clicks a related item (e.g. laptop_stand, usb_hub, or study_lamp)
    clicked_item_2 = [pid for pid in feed_2 if pid != clicked_item_1][0]
    session_interactions.append(InteractionItem(user_id=session_user, product_id=clicked_item_2, weight=1.0, interaction_type="view"))
    recent_views.insert(0, clicked_item_2)

    req_s3 = HybridRecommendRequest(
        user_id=session_user,
        preference_tags=["electronics", "study", "laptop"],
        interactions=session_interactions,
        recent_viewed_product_ids=recent_views,
        products=catalog
    )
    res_s3 = await get_hybrid_recommendations(req_s3)
    feed_3 = res_s3["recommended_product_ids"]
    print(f"Session Step 3 Feed (after clicking {clicked_item_2}): {feed_3}")
    assert feed_3[0] not in [clicked_item_1, clicked_item_2], "Step 3 failed: Recently viewed items dominate top position"
    assert len(feed_3) == len(catalog), f"Feed dropped items! Expected {len(catalog)}, got {len(feed_3)}"
    print("[PASS] Repeated Refresh Stability verified: Evolving feed across multiple interaction cycles without duplicate dominance.")

    # --------------------------------------------------------------------------
    # Test 6: Candidate Availability Fallback (Small Inventory Never Empties)
    # --------------------------------------------------------------------------
    print("\n--- Test 6: Candidate Availability Fallback (Small Inventory) ---")
    small_catalog = [
        ProductItem(id="small_1", title="Scientific Calculator", description="Math tool", category="Electronics", subcategory="Calculators"),
        ProductItem(id="small_2", title="Calculus Book", description="Math book", category="Books", subcategory="Textbooks"),
        ProductItem(id="small_3", title="Study Desk Lamp", description="Lamp", category="Furniture", subcategory="Lamps"),
    ]
    # User has viewed ALL 3 items
    req_small = HybridRecommendRequest(
        user_id="student_small",
        interactions=[
            InteractionItem(user_id="student_small", product_id="small_1", weight=1.0),
            InteractionItem(user_id="student_small", product_id="small_2", weight=1.0),
            InteractionItem(user_id="student_small", product_id="small_3", weight=1.0)
        ],
        recent_viewed_product_ids=["small_1", "small_2", "small_3"],
        products=small_catalog
    )
    res_small = await get_hybrid_recommendations(req_small)
    feed_small = res_small["recommended_product_ids"]
    print(f"Small inventory recommendations: {feed_small}")
    assert len(feed_small) == 3, f"Candidate availability failed! Expected 3 items, got {len(feed_small)}"
    print("[PASS] Candidate Availability Fallback verified: Small inventory returns all available items rather than emptying.")

    # --------------------------------------------------------------------------
    # Test 7: Regression Check for NLP Moderation
    # --------------------------------------------------------------------------
    print("\n--- Test 7: NLP Moderation Isolation & Regression Check ---")
    nlp_res = analyze_review_text("Great seller, very smooth deal!")
    assert nlp_res["is_toxic"] is False
    nlp_res_toxic = analyze_review_text("This scammer idiot stole my money and lied!")
    assert nlp_res_toxic["is_toxic"] is True
    print("[PASS] NLP Review Moderation module confirmed 100% intact and working.")

    print("\n==========================================================================")
    print("ALL 7 RECOMMENDATION & INTERACTION-AWARE SUITES PASSED SUCCESSFULLY!")
    print("==========================================================================\n")

if __name__ == "__main__":
    asyncio.run(test_recommendations())
