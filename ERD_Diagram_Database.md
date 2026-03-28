# Campus Swap - Entity Relationship Diagram (ERD)

This is the text-based ERD (Entity Relationship Diagram) for your FYP project database. 
You can copy the code block below and paste it into any Mermaid-supported renderer (like **[mermaid.live](https://mermaid.live/)**, **Notion**, **Obsidian**, or **GitHub**) to instantly generate a beautiful visual diagram!

## Mermaid ERD Code:

```mermaid
erDiagram
    USERS ||--o{ PRODUCTS : "lists"
    USERS ||--o{ TRANSACTIONS : "buys/rents (buyer)"
    USERS ||--o{ TRANSACTIONS : "sells/leases (seller)"
    USERS ||--o{ REVIEWS : "writes"
    USERS ||--o{ REVIEWS : "receives"
    USERS ||--o{ MESSAGES : "sends"
    USERS ||--o{ MESSAGES : "receives"
    USERS ||--o{ NOTIFICATIONS : "gets"
    USERS ||--o{ SAVED_ITEMS : "saves"
    USERS ||--o{ USER_INTERACTIONS : "browses"
    USERS ||--o{ REPORTS : "files report"
    USERS ||--o{ DISPUTES : "opens dispute"
    USERS ||--o{ SUPPORT_TICKETS : "opens ticket"
    
    %% Moderator/Admin relationships
    USERS ||--o{ SUPPORT_TICKETS : "handles (moderator/admin)"
    USERS ||--o{ TICKET_REPLIES : "replies"
    
    CATEGORIES ||--o{ SUB_CATEGORIES : "has"
    CATEGORIES ||--o{ PRODUCTS : "categorizes"
    SUB_CATEGORIES ||--o{ PRODUCTS : "further categorizes"

    PRODUCTS ||--o{ TRANSACTIONS : "is sold/rented in"
    PRODUCTS ||--o{ SAVED_ITEMS : "is saved as"
    PRODUCTS ||--o{ USER_INTERACTIONS : "is viewed in"
    PRODUCTS ||--o{ REPORTS : "is reported"

    TRANSACTIONS ||--o{ REVIEWS : "has a"
    TRANSACTIONS ||--o{ DISPUTES : "is disputed in"

    SUPPORT_TICKETS ||--o{ TICKET_REPLIES : "has replies"
    SAFE_MEETUP_ZONES ||--o{ TRANSACTIONS : "serves as location"

    USERS {
        uuid id PK
        string full_name
        string email
        string password_hash
        string phone
        string university_id "Enforces .edu.my matching"
        string profile_image_url
        string bio "Max 150 chars"
        enum privacy_setting "Public, Private, etc."
        string role "Admin, Moderator, Student"
        boolean is_active "true or false"
        datetime deactivated_until "Null if active, timestamp for timed ban"
        string deactivation_reason
        float reputation_score "Aggregated from reviews"
        float total_carbon_saved "Calculated automatically"
        decimal balance
        datetime created_at
    }

    CATEGORIES {
        uuid id PK
        string name "e.g., Electronics, Furniture"
        string icon_url
        float carbon_conversion_factor "Used for sustainability dashboard"
    }

    SUB_CATEGORIES {
        uuid id PK
        uuid category_id FK
        string name "e.g., Phones, Laptops, Chairs"
    }

    PRODUCTS {
        uuid id PK
        uuid seller_id FK
        uuid category_id FK
        uuid sub_category_id FK
        string title
        text description
        decimal price "0 if rental"
        enum condition "New, Good, Fair, etc."
        json image_urls
        string video_url
        enum status "Active, Reserved, Sold, Suspended"
        enum type "Sale, Rent"
        decimal rental_deposit "Required if type=Rent"
        decimal rental_price_per_day
        int max_rental_duration "In days"
    }

    TRANSACTIONS {
        uuid id PK
        uuid product_id FK
        uuid buyer_id FK
        uuid seller_id FK
        uuid meetup_zone_id FK
        decimal amount "Final transaction amount"
        enum status "Pending, Scheduled, To Confirm, Completed, Cancelled, Disputed"
        string payment_proof_url "Uploaded by buyer"
        datetime rental_start_date "Null if Sale"
        datetime rental_end_date "Null if Sale"
        datetime created_at
    }

    REPORTS {
        uuid id PK
        uuid reporter_id FK
        uuid product_id FK
        enum violation_type "Spam, Scam, Fake, Prohibited"
        text description
        json evidence_urls
        enum status "Pending, In-Progress, Uphold, Dismissed"
        datetime created_at
    }

    DISPUTES {
        uuid id PK
        uuid transaction_id FK
        uuid complainant_id FK
        enum reason "Not Received, Damaged, Fraud, etc"
        text description
        json evidence_urls
        enum status "New, Investigating, Escalated, Resolved"
        uuid handled_by FK "Moderator/Admin User ID"
        datetime created_at
    }

    SUPPORT_TICKETS {
        uuid id PK
        uuid user_id FK
        enum category "Account, Bug, General"
        string subject
        text description
        json evidence_urls
        enum status "Open, Locked, Escalated, Resolved"
        uuid locked_by_moderator_id FK "Concurrency lock"
        datetime created_at
    }

    TICKET_REPLIES {
        uuid id PK
        uuid ticket_id FK
        uuid sender_id FK
        text content
        datetime sent_at
    }

    SAFE_MEETUP_ZONES {
        uuid id PK
        string name "e.g. Main Library, Guard House"
        float latitude
        float longitude
        string description
    }

    SAVED_ITEMS {
        uuid id PK
        uuid user_id FK
        uuid product_id FK
    }

    REVIEWS {
        uuid id PK
        uuid transaction_id FK
        uuid reviewer_id FK
        uuid reviewee_id FK
        int rating "1 to 5"
        text comment
        enum status "Hidden, Published"
    }

    MESSAGES {
        uuid id PK
        uuid sender_id FK
        uuid receiver_id FK
        uuid mapped_zone_id FK "Optional meetup pin"
        text content
        boolean is_read
        datetime sent_at "Exact date and time message was sent"
    }

    NOTIFICATIONS {
        uuid id PK
        uuid user_id FK
        string target_route_id "Deep link to chat/order"
        string title
        string body
        string type
        boolean is_read
    }

    USER_INTERACTIONS {
        uuid id PK
        uuid user_id FK
        uuid product_id FK
        string interaction_type "view, click, contact"
        float duration_seconds 
    }
```

### 💡 How to use this for your FYP report?
1. Copy the code above starting from `erDiagram`.
2. Go to [Mermaid Live Editor](https://mermaid.live/).
3. Paste it in the left panel.
4. You will instantly see the relationships mapped out visually. You can then download it as a PNG or SVG to paste into your Word/PDF thesis document!
