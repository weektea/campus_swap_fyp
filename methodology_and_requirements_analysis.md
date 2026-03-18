Methodology and Requirements Analysis
This chapter outlines the software development methodology and implementation requirements for the Smart Campus Second-Hand Trading Platform. It details the iterative approach used to develop the project, the technologies used to collect and obtain user requirements, the structured decomposition of functional and non-functional requirements, and the use of use case diagrams and data flow diagrams to model system requirements and demonstrate system architecture and user interactions.
Iterative Development Methodology
Iterative development methodologies use cyclic processes to establish a software product and iterate towards a better solution through multiple iterations, rather than trying to build the complete and final version of a software application at the initial release. Iterative development methodologies each have their own emphasis on software design, construction, and improvement. They may stress how to plan, design, build, and test, as well as the overall elements of each stage of the development lifecycle. Each time an iteration is produced, it improves on the last iteration by moving through the Software Development Lifecycle (SDLC), Planning, designing, building, coding and testing. As a result, with successive iterations on the original architecture base, the software application will evolve during subsequent iterations, ultimately resulting in a full-featured application. (Larman & Basili, 2003)
To put this method into practice, it is crucial to have a functional structure of the entire system before adding any detailed features to it. First Iterations concentrate on developing core components such as authentication and a simple database connection. Second Iterations concentrate on developing more detailed additions of those components such as User Interfaces as required. By completing the core design before adding additional logic and features, developers are able to create a foundationally sound architecture upon which they can subsequently develop specialized logic to meet the project’s goals. This helps minimize the chances of having a large integration fail occur during the project’s later stages.

Figure 3.1: Iterative Development Methodology
The medium to long-term project development methodologies discussed in this paper are most commonly used for projects with lifecycles between 90 and 270 days. Projects that successfully employ these methodologies must possess certain characteristics. The overall objective must be clearly defined from the outset, but the technical steps to achieve that objective may involve uncertainty and high complexity (Sommerville, 2016). This Final Year Project perfectly matches these characteristics, as the timeframe spans across two academic semesters totaling approximately 210 days. Furthermore, while the end goal of building a secure campus trading platform is clear, the technical combination of a Flutter mobile frontend, a Node.js backend, and a Python Machine Learning microservice involves numerous implementation challenges. Therefore, the iterative model is an optimal fit. It provides a sufficient timeframe to tackle these technical complexities systematically, allowing the developer to experiment and stabilize one technology before integrating the next layer.
The Iterative model's key feature is the risk-driven cyclic refinement process that sets it apart from both Scrum and the Incremental Model, two other methodologies. While Scrum is more of a management framework while also placing a significant amount of focus on team communication and daily meetings, its use would be limited when applied to an individual academic project. The Incremental model is also focused on producing independent, time-complete modules or components, and does not provide the ability to examine, test, and enhance the same core feature multiple times until it achieves optimal performance (Pressman & Maxim, 2014).
In the context of this project, the Machine Learning recommendation engine utilizing Cosine Similarity requires continuous tuning and cannot be perfected in a single attempt. During the initial iteration, the algorithm may only perform basic text matching. Following system testing and performance evaluation, a subsequent iteration allows the developer to revisit the algorithm and adjust the mathematical thresholds to extract specific item tags more accurately. This built-in allowance for feedback, empirical testing, and continuous optimization ensures that difficult technical features are practically refined in real-world scenarios before the final system deployment.
Guidance for Iterative Development Methodology
The practical application of the iterative development method in this project is guided by a rigorously structured continuous development cycle plan. Rather than trying to create a full transaction system in one go, the transaction system will be developed in smaller, manageable projects (iterations). Each of these projects will be designed, built, and tested within defined timeframes, and will represent an independent project that has its own requirements, design, build, and testing. The use of this structured method of managing the development process will lead to a greater probability that the solutions produced will be stable and therefore will provide a stable base on which to build a more technologically complex solution.
To systematically construct the Smart Campus Second-Hand Trading Platform, the development guidance is divided into four primary iterative cycles:
Iteration 1: Core Architecture and Minimum Viable Product
The primary guidance for the initial cycle is to establish the fundamental system architecture. This phase focuses entirely on developing the baseline infrastructure, which includes implementing the secure institutional email authentication and the basic product listing functionalities. The goal is to encircle this first phase as a basis to build a Minimum Viable Product (MVP) using the Flutter framework and Node.js for the backend. The intent of this MVP is to confirm that basic data can be flowed into the database and the database is able to provide basic feedback prior to complex logic being added to the data.
Iteration 2: Interaction and Transaction Mechanics
Once the core structure is validated and tested, the developmental guidance shifts toward enhancing user connectivity and transaction state management. This second cycle integrates complex relational database operations using PostgreSQL to manage the progression of orders from pending to completed states. Additionally, it involves the programming of the secure in-app messaging module and the location-tagging features to facilitate safe campus meetups.
Iteration 3: Intelligence and Algorithmic Integration
The third iterative cycle focuses strictly on algorithmic complexity and system intelligence. The guidance here directs the deployment of the independent Python microservice. The Machine Learning recommendation engine is integrated into the stable platform. Because the basic listing and user profiles were completed in the first iteration, the developer can now exclusively dedicate this cycle to testing text tag extraction and tuning the Cosine Similarity mathematical thresholds without disrupting the existing application architecture.
Iteration 4: Advanced Modules and Sustainability Metrics
The final developmental cycle is guided toward supplementary business logic and system optimization. This iteration implements the rental module with the ability to accommodate dynamic data calculations (via dates) as well as the addition of the sustainability dashboard which implements the use of already captured transactional data to give users an estimate of their reduction of carbon emissions.
The project maintains total organizational oversight through the application of this established iterative framework, which will enable the thorough testing of all critical foundational components like data integrity, user verification, etc. through real-world testing scenarios before introducing any computationally intensive activities such as machine learning algorithms. This systematic progression greatly minimizes the risk of integration.
Benefit of Iterative Development Methodology
Using the Iterative Development Methodology provides many technical as well as project management benefits. This is extremely true when creating a system with complex algorithms and multiple platform frameworks integrated into one solution. The benefits from this methodology are directly correlated with the resulting quality of the software and successful implementation of the platform.
A primary benefit of this methodology is that it potentially allows for early risk mitigation via early verification of core system architectures. Rather than waiting to confirm the system will work together in final stages of development, critical infrastructure is constructed and evaluated during the early phases of development. To illustrate, the integration of the Flutter-Based Front-End and the Node.jS-based Back-End server and the PostgreSQL-based Database connectivity represents the first test cycle of this project. This early validation allows for the identification and mitigation of architectural defects like faulty database schema or insecure data routing prior to experiencing catastrophic failures in integration and needing to refactor significant portions of the code during later stages of development.
Furthermore, the iterative model provides essential adaptability for refining mathematical models and algorithmic logic. Developing a machine learning recommendation system is inherently an empirical process that requires continuous adjustments based on real data outputs, a requirement that rigid linear methodologies cannot easily accommodate. The implementation of the Content-Based Filtering engine utilizing Cosine Similarity requires multiple testing phases to calibrate how effectively text tags are extracted from user listings and mathematically matched against user profiles. The cyclic nature of this methodology allows the developer to revisit the Python microservice in subsequent iterations specifically to adjust similarity thresholds and tag weighting. This flexibility directly results in a highly accurate and personalized user discovery experience without disrupting the core application timeline.
Finally, this approach guarantees continuous quality assurance and significantly simplifies the software debugging process. Because comprehensive testing is conducted at the conclusion of every individual iteration, software defects are effectively isolated to the specific module that was most recently developed. If an asynchronous blocking issue occurs within the Node.js transaction management module, or a frame-rate rendering drop occurs within the Flutter user interface, the developer can pinpoint the exact code increment causing the problem. This continuous and localized testing cycle drastically reduces the accumulation of hidden technical debt and undocumented bugs. Ultimately, this ensures that the final Smart Campus platform adheres strictly to software quality management standards and delivers a highly reliable and secure trading environment for the university community.
Justification for use Iterative Development Methodology
The choice of using Iterative Development Method as a methodology can be demonstrated by comparing and contrasting well-established software engineering frameworks against the particular constraints of this project. The main constraints against this project are a single developer to perform the work, a relatively medium-sized development time frame of approximately 210 days, and a high level of technical uncertainty created by integrating a custom machine learning recommendation engine. It is necessary to develop a methodology that achieves a balance between the need for structured academic work products and technical flexibility so that there is a greater likelihood of developing a successful platform.
Traditional sequential framework, such as the Waterfall model, insist on complete upfront specifications and do not allow for any regression when beginning to implement the system (Sommerville, 2016). As such, the linear model is incompatible with developing machine learning models. For example, algorithms using Cosine Similarity must be adjusted regularly and empirically against actual database inputs to achieve optimal accuracy. A model that prohibits developers from adjusting their core logic at all will also guarantee an unsuccessful algorithm. Moreover, while Prototyping provides users with the ability to quickly create a visual user interface, it too often produces a temporary software architecture that lacks the secure back end necessary for institutional trading (Pressman & Maxim, 2014).
While more recent approaches to Agile have emphasized being flexible, the current iterations of Agile frameworks were predominantly designed for team environments. For example, both Scrum and RAD are designed for maximizing collaboration between team members, allowing for parallel execution, while allowing continuous communication with stakeholders regarding changing project requirements (Schwaber & Sutherland, 2020). However, this project is being executed solely by one developer under a specifically defined when compared to RAD requirements. Therefore, using Scrum tools introduces certain management processes, which can significantly increase project overhead. Additionally, the RAD tag require that multiple developers be able to work concurrently on separate pieces or components, thus making it impossible to utilize the RAD approach alone.
Structural approaches like the Incremental model and Component-Based Development (CBD) offer modular advantages but lack holistic adaptability. The Incremental model finalizes independent subsystems sequentially. However, building an intelligent marketplace requires the entire system architecture to be established broadly before global mathematical tuning can occur across different modules. The CBD model suffers from the same problem. It typically develops software products by assembling existing components rather than building custom logic to make them function as an integrated product (Sommerville, 2016). While this project uses well-known frameworks like Flutter, its contribution involves creating a user-specific Python microservice. Therefore, there will be requiring cyclic algorithmic refinement rather than just assembling components.
Ultimately, the Iterative Development Methodology provides the optimal architectural paradigm. Like Agile methods, Iterative Development facilitates the ability of developers to be flexible. However, that flexibility does not come with all of the overhead associated with team meetings and administration of team processes. The Iterative Development methodology allows a single developer to create the core of a Minimum Viable Product (MVP) and return to it later to incorporate more sophisticated features such as sustainability metrics and machine learning. The iterative refinement process creates a high-quality software product and supports the delivery of quality over time.
Requirements Gathering Techniques
Observational Analysis of User Behavior
Observation is a fundamental qualitative data collection technique used in software engineering and user experience design. It is primarily categorized into direct and indirect methods. Direct observational method uses live or real-time monitoring of a user while they are interacting with an application or system performing tasks. Indirect observational methods analyze artifacts, digital trails or footprints and historical records who have demonstrated specific behaviors without having direct interaction with subjects (Sekaran & Bougie, 2016). A primary benefit of observational research is that it is Ecologically Valid. Observational data provides researchers with information about how people actually behave in their natural environment and that it is far more meaningful than information obtained from a laboratory (Ciesielska et al., 2018). In addition to ecologically valid data, qualitative observational research can also provide new ideas for enhancing products that would be missed in a study that relies solely on quantitative data.
Applying this theory to the project, the primary technique employed is the indirect observational analysis of general public trading behaviors. Rather than relying on subjective assumptions, this method involves systematically monitoring digital footprints and user generated content across open trading channels such as Facebook Marketplace, Mudah.my, Carousell, and Xiaohongshu. While these platforms cater to the general public, they are frequently utilized by the university demographic for acquiring secondhand essentials. By analyzing shared experiences, scam exposure threads, and consumer complaint forums left by general users, critical operational failures inherent in open platforms are objectively identified.
The most severe pain point identified through this indirect observation is a profound lack of trust and physical security. A lack of robust identity verification has created an environment that allows malicious actors to perpetrate significant fraudulent activity on these frequently used open ecosystem platforms. Public complaints regarding fraudulent activity can be traced back to phishing, where the malicious actor poses as a buyer or that sends fake e-mails with fraudulent intent or malicious installation files for the purpose of processing the payment. Additionally, examining the digital traces left by users shows an extreme fear of safety in relationship to others and significant anxiety about their safety. Users frequently document experiences of buyers intentionally failing to appear at designated meeting spots or requesting late night collections. This generates significant distress regarding potential robberies or personal safety threats when dealing with completely unverified strangers.
The second critical observation involves algorithmic displacement and severe logistical friction. On social commerce and general listing platforms, feed algorithms require constant manual reposting for items to remain visible. Consequently, utilitarian listings for practical essentials like secondhand electronics or furniture are rapidly buried, leading to information overload and frustrating search experiences. Additionally, transaction reviews reveal a frequent geographic mismatch and courier exploitation. Users frequently report scenarios where buyers from different states demand complex shipping arrangements or use third party couriers to falsely claim heavy items without transferring funds. The logistical cost and high risk of courier based theft make cross state transactions economically unviable and highly stressful.
These indirect observations of general public platforms provide crucial and evidence based qualitative insights. They demonstrate that open trading environments are fundamentally unsafe and highly inefficient, making university students particularly vulnerable due to their limited financial resources and lack of personal transportation. These findings form the foundational justification for developing a strictly localized campus ecosystem. The documented prevalence of phishing scams and physical safety anxieties strongly justifies the implementation of a mandatory academic email verification system to establish a trusted user base. Simultaneously, the observed algorithmic displacement validates the necessity of a machine learning proactive recommendation engine to streamline product discovery. Finally, restricting transactions to physical campus grounds actively eliminates the geographic mismatch and courier fraud risks entirely.
Quantitative Survey via Online Questionnaires
Questionnaires are a highly structured raw data collection tool consisting of standardized prompts designed to gather quantitative information from a specific target population. The main reason for choosing structured questionnaires over other data collection methods in empirical software engineering research is that they can efficiently obtain detailed data from a large number of respondents across a wide geographical area (Ball, 2019). In particular, one of the main benefits of using structured questionnaires via the Internet is that the data collected will have been evaluated using a standardised set of questions. Therefore, all of the data collected from each respondent will have been obtained using the same standardised set of questions resulting in data being obtained from each respondent that can be mathematically identified as "same" or "similar". Another major benefit of using a questionnaire via the Internet is that respondents are given anonymity, which has been shown to reduce bias from interviewers and also encourages respondents to provide truthful information about sensitive matters such as being the victim of a financial scam (Braun et al., 2020).
To complement the qualitative data that have been collected through observational methodology, the quantitative survey uses online questionnaires via Google Forms to collect measurable empirical data. This method has been chosen because it is highly effective at obtaining a large and diverse sample size of university students across various age groups, academic study levels, and living arrangements. By surveying the actual target demographic, the project ensures that the proposed software features are grounded in statistical user demand rather than isolated developer assumptions.
The questionnaire is systematically designed to gather data across four primary sections utilizing a combination of dichotomous questions, multiple choice formats, and linear rating scales. The first dimension evaluates student demographics and their current resource trading behaviors. This section establishes the baseline by assessing their living arrangements, academic tenure, and preferred digital platforms for secondhand transactions. The second dimension directly measures user frustration metrics and validates the pain points identified during the earlier observational analysis. Utilizing multiple choice and dichotomous selections, respondents are asked to identify the specific types of online scams they have encountered, their primary safety concerns during physical meetups, and the logistical challenges they face when transporting heavy items.
The third dimension assesses the market acceptance of the proposed Smart Campus platform features utilizing a five point linear rating scale. It explicitly evaluates student willingness to adopt a closed trading ecosystem secured strictly by institutional email authentication. Furthermore, it gauges user interest in advanced technical integrations by asking respondents to rate the perceived helpfulness of a machine learning recommendation engine, a short term rental system, and an environmental sustainability dashboard. It also measures the importance of secure interaction tools such as an interactive campus map and an in app chat system. Finally, an optional open ended section is included to capture unstructured qualitative suggestions, ensuring no critical user requirements are overlooked. By aggregating this comprehensive statistical data, the project can confidently justify its core functional requirements based on validated user demand.

## 3.3 Requirement Analysis

Requirement analysis is a critical phase in the software development lifecycle that bridges the gap between the initial problem statements identified during the qualitative and quantitative research and the technical software design. The primary objective is to define exactly what the Smart Campus Second-Hand Trading Platform must do to satisfy the needs of its primary stakeholders.

As this is an individual project, the system is organized into eight functional modules to ensure a systematic development process. Each module represents a core functional area that the author is responsible for developing, integrating, and testing throughout the project lifecycle. To maintain a manageable workflow, the Smart Campus Second-Hand Trading Platform is decomposed into the following specialized modules:

| Module ID | Module Name | Primary Technical Tasks |
| :--- | :--- | :--- |
| **M1** | **User Management System** | Implementing campus email (`.edu.my`) verification, profile management, and reputation display. |
| **M2** | **Product Management System** | Developing the Smart Posting Assistant with multimedia support and status tracking. |
| **M3** | **Search & Browsing System** | Architecting search functionality with basic filters such as category, price, condition. |
| **M4** | **ML Recommendation System** | Developing recommendation logic based on item tags or history. |
| **M5** | **Transaction Management** | Building the order workflow (Order, Confirm, Complete) and receipt generation. |
| **M6** | **Rental System** | Implementing a date-picker for rental duration and fee calculation logic. |
| **M7** | **Interaction Features** | Developing a messaging system, favorite lists, and location tagging. |
| **M8** | **Analytics & Visualization** | Creating a Sustainability Dashboard for carbon savings and activity statistics. |

### 3.3.1 Use Case Diagram (Overall Platform)

An overall use case diagram provides a high-level visual representation of how users interact with the entire system to achieve specific goals. In the context of the Smart Campus platform, the system boundary encapsulates the mobile application and the backend services. The primary actors interacting with the system are the Student (acting as Buyer, Seller, or Renter) and the Administrator.

*(Note: Insert the generated **Overall Platform Use Case Diagram** image here. This diagram should show a bird's-eye view connecting the primary actors to the major modules without showing excessive detail).*

- **Student Actor Interactions (High-Level):**
  - Manage Account & Profile
  - Manage Product Listings (Sale/Rent)
  - Discover Products (Search & AI Recommendations)
  - Engage in Transactions & Messaging
  - Track Sustainability Metrics

- **Administrator Actor Interactions (High-Level):**
  - Monitor Platform Analytics
  - Manage Users & Resolve Disputes

### 3.3.2 Module-Specific Use Case Diagrams

To provide granular clarity, the system is further broken down into eight module-specific use case diagrams. These diagrams zoom into the specific functions handled within each specialized boundary.

*(Note: Insert the generated 8 individual module diagrams under their respective headings below).*

**Module 1 (M1): User Management System**
- **Actors:** Student
- **Use Cases:** Register Account, Verify `.edu.my` Email, Login, Edit Profile Data, Upload Avatar, View Reputation Score.

**Module 2 (M2): Product Management System**
- **Actors:** Student (Seller/Renter)
- **Use Cases:** Add Listing, Upload Multiple Images, Invoke AI Classification (via M4), Edit Listing Details, Delete Listing, Mark as Sold/Rented.

**Module 3 (M3): Search & Browsing System**
- **Actors:** Student (Buyer)
- **Use Cases:** Search by Keyword, Apply Category Filter, Apply Price/Condition Filter, Sort Results.

**Module 4 (M4): ML Recommendation System**
- **Actors:** System (ML Microservice), Student
- **Use Cases:** Generate ML Price Prediction (during M2), Analyze Image classification (during M2), Generate Personalized Feed (for Student).

**Module 5 (M5): Transaction Management**
- **Actors:** Student (Buyer), Student (Seller), Administrator
- **Use Cases:** Initiate Buy Request, Accept/Reject Request, Update to "Scheduled", Confirm Manual Payment (COD/Bank Transfer), Generate E-Receipt, Leave Review, Flag Transaction (Dispute), Resolve Dispute (Administrator).

**Module 6 (M6): Rental System**
- **Actors:** Student (Renter), Student (Owner)
- **Use Cases:** Select Rental Dates (Date-picker), Calculate Rental Fee (with Deposit), Submit Rental Request, Accept Rental Request.

**Module 7 (M7): Interaction Features**
- **Actors:** Student
- **Use Cases:** Send In-App Message, Receive Push Notification, Pin/View Meetup Location on Map, Toggle Favorite Listing, View Saved Items.

**Module 8 (M8): Analytics & Visualization**
- **Actors:** Student, Administrator
- **Use Cases:** View Personal Carbon Savings (Student), View System-wide Active Users (Administrator), View Total Transaction Volume (Administrator).

### 3.3.2 Use Case Description Table

To provide highly detailed specifications for the interactions shown in the use case diagram, the following use case description tables meticulously break down the typical flow of events for critical system functions across the modules.

**Use Case 1: Register Account (M1)**
| Use Case Attribute | Description |
| :--- | :--- |
| **Use Case Name** | Register Account and Verify Email |
| **Objectives** | To create a localized user account using a verified campus email. |
| **Actor** | Student |
| **Pre-conditions** | The user possesses a valid `.edu.my` institutional email address. |
| **Basic Flow** | **Actor Actions:**<br>1. Enters full name, `.edu.my` email, and password on the Registration screen.<br>3. Submits the form.<br>5. Clicks the verification link in the received email.<br><br>**System Responses:**<br>2. Validates the `.edu.my` domain syntax locally.<br>4. Generates an OTP token, saves it to the DB, and dispatches an email.<br>6. Verifies the token and sets the user status to "Active". |
| **Alternative Flows** | *A1. Invalid Domain:* System blocks registration and shows "Invalid Institutional Email" error.<br>*A2. Token Expired:* System prompts user to click "Resend Code" if 15 minutes have passed. |

**Use Case 2: User Login (M1)**
| Use Case Attribute | Description |
| :--- | :--- |
| **Use Case Name** | User Login |
| **Objectives** | To authenticate an existing user into the system. |
| **Actor** | Student, Administrator |
| **Pre-conditions** | The user possesses an active account in the system. |
| **Basic Flow** | **Actor Actions:**<br>1. Navigates to the Login screen.<br>2. Enters registered email and password.<br>3. Clicks "Login".<br><br>**System Responses:**<br>4. Queries the database and compares the hashed password.<br>5. Generates a JWT (JSON Web Token) for session management.<br>6. Granularly routes the user based on role (Student to Home, Admin to Web Panel). |
| **Alternative Flows** | *A1. Wrong Credentials:* System highlights the password field and displays "Incorrect email or password". |

**Use Case 3: Manage Profile Data (M1)**
| Use Case Attribute | Description |
| :--- | :--- |
| **Use Case Name** | Manage Profile Data |
| **Objectives** | To allow a user to update their personal avatar and biography. |
| **Actor** | Student |
| **Pre-conditions** | The Student is fully authenticated. |
| **Basic Flow** | **Actor Actions:**<br>1. Accesses the "Profile" tab.<br>2. Taps "Edit Profile" and uploads a new profile picture or alters their bio.<br>3. Taps "Save".<br><br>**System Responses:**<br>4. Uploads image to the storage bucket and retrieves the URL.<br>5. Updates the PostgreSQL `User` record.<br>6. Refreshes the UI to display the new information. |
| **Alternative Flows** | *A1. Image Payload Too Large:* System alerts the user to upload an image under 5MB. |

**Use Case 4: Post a Product with Smart Assistant (M2, M4)**
| Use Case Attribute | Description |
| :--- | :--- |
| **Use Case Name** | Post a Product with Smart Assistant |
| **Objectives** | To create a new product listing utilizing AI for automated field population. |
| **Actor** | Student (Seller) |
| **Pre-conditions** | The Seller's account is active and not suspended. |
| **Basic Flow** | **Actor Actions:**<br>1. Taps "Add Listing".<br>2. Uploads up to 9 item images.<br>3. Clicks "Analyze Image".<br>6. Reviews AI-suggested category and price.<br>7. Provides final details (Title, Condition) and taps "Submit".<br><br>**System Responses:**<br>4. Python microservice (M4) runs image classification over the payload.<br>5. Returns the top category prediction.<br>8. Saves the final metadata array into the M2 Product table. |
| **Alternative Flows** | *A1. AI Confidence Low:* System leaves fields blank and prompts the user to manually select the category. |

**Use Case 5: Edit/Delete Existing Listing (M2)**
| Use Case Attribute | Description |
| :--- | :--- |
| **Use Case Name** | Manage Existing Listing |
| **Objectives** | To remove or modify a previously created product post. |
| **Actor** | Student (Seller) |
| **Pre-conditions** | The user has active listings in the "My Posts" section. |
| **Basic Flow** | **Actor Actions:**<br>1. Opens "My Posts".<br>2. Selects an active listing and taps "Edit" or "Delete".<br>3. Confirms the deletion prompt.<br><br>**System Responses:**<br>4. Executes an SQL `UPDATE` or soft-delete `DELETE` command.<br>5. Removes the items from the public M3 discoverability pool. |
| **Alternative Flows** | *A1. Item Already in Transaction:* The system disables the "Delete" button if the item is currently "Scheduled" with a buyer. |

**Use Case 6: Search and Filter Products (M3)**
| Use Case Attribute | Description |
| :--- | :--- |
| **Use Case Name** | Search and Filter Products |
| **Objectives** | To quickly locate relevant items using text queries and strict attribute boundaries. |
| **Actor** | Student (Buyer) |
| **Pre-conditions** | The app possesses an active internet connection. |
| **Basic Flow** | **Actor Actions:**<br>1. Taps the search bar and types a keyword (e.g., "Calculus Textbook").<br>2. Adjusts the slider for maximum price and selects the "Books" category.<br>3. Taps "Apply Filters".<br><br>**System Responses:**<br>4. Triggers a backend query checking against the indexed Product table.<br>5. Returns a structured JSON list of matching items. |
| **Alternative Flows** | *A1. Zero Results:* GUI displays an empty graphic suggesting the removal of strict filters. |

**Use Case 7: Discover AI-Recommended Items (M4)**
| Use Case Attribute | Description |
| :--- | :--- |
| **Use Case Name** | Discover AI-Recommended Items |
| **Objectives** | To view a personalized scrollable feed based on historical user interactions. |
| **Actor** | Student |
| **Pre-conditions** | The user must have a history of clicking or favoring products within the platform. |
| **Basic Flow** | **Actor Actions:**<br>1. Navigates to the "Home" or "For You" tab.<br><br>**System Responses:**<br>2. Backend M4 system runs a cosine similarity calculation linking the user's past interaction categories against active global listings.<br>3. Sorts returning array by descending similarity confidence score.<br>4. Renders the feed to the user's UI smoothly. |
| **Alternative Flows** | *A1. Cold Start / No History:* System defaults to showing the most recently posted items (`ORDER BY created_at DESC`). |

**Use Case 8: Initiate Buy Request (M5)**
| Use Case Attribute | Description |
| :--- | :--- |
| **Use Case Name** | Initiate Buy Request |
| **Objectives** | To formally request to purchase a listed item. |
| **Actor** | Student (Buyer) |
| **Pre-conditions** | A product is tagged as "Sale" and "Available". |
| **Basic Flow** | **Actor Actions:**<br>1. Views a product page.<br>2. Taps "Initiate Order".<br>3. Confirms the summary popup (Price, Item Name).<br><br>**System Responses:**<br>4. Validates that the item hasn't been blocked simultaneously.<br>5. Creates a Pending `Transaction` record linking Buyer ID and Seller ID.<br>6. Sends a real-time push notification to the Seller. |
| **Alternative Flows** | *A1. Inventory Conflict:* System alerts the buyer, "This item just went out of stock". |

**Use Case 9: Accept Buy/Rent Request (M5)**
| Use Case Attribute | Description |
| :--- | :--- |
| **Use Case Name** | Accept Buy/Rent Request |
| **Objectives** | To confirm an incoming order and reserve the item for the buyer. |
| **Actor** | Student (Seller/Owner) |
| **Pre-conditions** | The transaction state is "Pending". |
| **Basic Flow** | **Actor Actions:**<br>1. Navigates to "My Orders" tab.<br>2. Reviews an incoming request.<br>3. Taps "Accept".<br><br>**System Responses:**<br>4. Modifies the Transaction State to "Scheduled".<br>5. Marks the associated M2 listing as reserved/unavailable temporarily.<br>6. Notifies the Buyer of the acceptance. |
| **Alternative Flows** | *A1. Reject Order:* The Seller taps "Reject"; the system logically cancels the transaction. |

**Use Case 10: Process Rental Request Booking (M6)**
| Use Case Attribute | Description |
| :--- | :--- |
| **Use Case Name** | Process Rental Request Booking |
| **Objectives** | To map out a calendar booking and calculate cumulative fees for a rental item. |
| **Actor** | Student (Renter) |
| **Pre-conditions** | The item is tagged purely as "Rent". |
| **Basic Flow** | **Actor Actions:**<br>1. Taps "Rent Now" on the detail page.<br>2. Interacts with the visual calendar to select a start and end date.<br>3. Taps "Confirm Booking".<br><br>**System Responses:**<br>4. Deducts dates to find duration.<br>5. Formula calculation: `(Duration * Base Daily Rate) + Security Deposit`.<br>6. Pushes the pending rental order to the Owner's queue via M5 logic. |
| **Alternative Flows** | *A1. Calendar Overlap:* Previously reserved dates are grayed out on the calendar block preventing invalid selections. |

**Use Case 11: In-App Messaging & Location Tagging (M7)**
| Use Case Attribute | Description |
| :--- | :--- |
| **Use Case Name** | In-App Messaging & Location Tagging |
| **Objectives** | To facilitate secure communication and physical meetup arrangements. |
| **Actor** | Student (Buyer), Student (Seller) |
| **Pre-conditions** | A chat channel is openly established via a product inquiry. |
| **Basic Flow** | **Actor Actions:**<br>1. Opens the localized Chat window.<br>2. Transmits text messages to negotiate specifics.<br>3. Taps the "Pin Location" icon.<br>5. Scrolls on the Google Maps overlay to pin a campus location.<br>6. Taps "Send Location".<br><br>**System Responses:**<br>4. Summons Map UI using integrated Maps API.<br>7. Websocket gateway emits the payload instantaneously to the receiver client.<br>8. Receiver UI renders a clickable mini-map directly in the chat bubble. |
| **Alternative Flows** | *A1. Network Disconnect:* Messages enter a local queue and display a "Pending/Clock" icon until connectivity resumes. |

**Use Case 12: Confirm Receipt and Complete Tradeoff (M5)**
| Use Case Attribute | Description |
| :--- | :--- |
| **Use Case Name** | Confirm Receipt and Complete Tradeoff |
| **Objectives** | To officially finalize a manual transaction and generate the system tracking receipt. |
| **Actor** | Student (Buyer) |
| **Pre-conditions** | The transaction is marked as "Scheduled". Both users meet physically. |
| **Basic Flow** | **Actor Actions:**<br>1. Inspects the item physically in person.<br>2. Transfers funds directly (via COD or Offline banking app).<br>3. Taps "Confirm Receipt" within the app UI.<br><br>**System Responses:**<br>4. Modifies the Transaction State to "Completed".<br>5. Automatically triggers the generation of a digital PDF E-Receipt.<br>6. Updates the M2 Product listing to officially "Sold" / frees the calendar slot for "Rent". |
| **Alternative Flows** | *A1. Buyer Cancels Offline:* The Buyer refuses the tradeoff; the Buyer actively taps "Cancel Order" in-app causing the item to return to "Available". |

**Use Case 13: Leave Transaction Review (M1, M5)**
| Use Case Attribute | Description |
| :--- | :--- |
| **Use Case Name** | Leave Transaction Review |
| **Objectives** | To update user reputation based on post-transaction experience. |
| **Actor** | Student |
| **Pre-conditions** | The target transaction has transitioned strictly to "Completed". |
| **Basic Flow** | **Actor Actions:**<br>1. Navigates to the completed order pane.<br>2. Clicks "Leave Feedback".<br>3. Submits a star rating (1-5) and an optional text summary.<br><br>**System Responses:**<br>4. Ingests the score into the Review database.<br>5. Recalculates the target user's aggregate Reputation Score (M1). |
| **Alternative Flows** | *A1. Rating Already Submitted:* GUI hides the feedback button preventing duplicate ballot entries for the identical transaction ID. |

**Use Case 14: Flag Transaction / Dispute (M5)**
| Use Case Attribute | Description |
| :--- | :--- |
| **Use Case Name** | Flag Transaction |
| **Objectives** | To escalate fraudulent behavior or a no-show to higher authorities. |
| **Actor** | Student |
| **Pre-conditions** | An active "Scheduled" or anomalous transaction exists. |
| **Basic Flow** | **Actor Actions:**<br>1. Taps "Report/Flag" on the active transaction.<br>2. Fills out a mandatory reason textbox explaining the incident.<br><br>**System Responses:**<br>3. Overrides transaction state from "Scheduled" to "Disputed".<br>4. Notifies the Administrator dashboard visually of a new ticket. |
| **Alternative Flows** | *A1. Accidental Flagging:* The user is prompted with a final "Are you sure?" modal before officially freezing the order pipeline. |

**Use Case 15: Administrator Resolves Dispute (M1, M5)**
| Use Case Attribute | Description |
| :--- | :--- |
| **Use Case Name** | Administrator Resolves Dispute |
| **Objectives** | To moderate conflicts and levy necessary reputation penalties without legally arbitrating money. |
| **Actor** | Administrator |
| **Pre-conditions** | A ticket exists within the Web Panel Dispute Queue. |
| **Basic Flow** | **Actor Actions:**<br>1. Logs into the React Web Panel.<br>2. Reviews systemic evidence: Chat transcripts, uploaded receipts.<br>3. Selects a moderation decision (e.g., Ban User, Deduct Reputation) and clicks "Resolve".<br><br>**System Responses:**<br>4. Cancels the "Disputed" transaction technically in the database.<br>5. Applies the M1 penalty to the violating node. |
| **Alternative Flows** | *A1. Baseless Report:* The Admin rules the flag invalid, marking the dispute "Dismissed" and reinstating the transaction to "Scheduled". |

## 3.4 Functional Requirement and Non-Functional Requirement

To ensure the system's architecture can physically support the detailed use cases across all eight proposed modules, the software requirements are meticulously categorized.

### 3.4.1 Functional Requirements

Functional requirements define the core behaviors and technical obligations that the platform must execute successfully, strictly correlated to the project's eight primary modules.

| Use Case ID | Requirement ID | Functional Requirement |
| :--- | :--- | :--- |
| UC1 | **FR-1.1** | The system shall strictly validate user registration inputs, allowing only emails terminating in `.edu.my`. |
| UC1 | **FR-1.2** | The system shall generate and verify OTPs (One-Time Passwords) delivered via email for account activation. |
| UC3, UC13 | **FR-1.3** | The system shall visibly display individual reputation scores calculated dynamically from historical transaction reviews. |
| UC4, UC5 | **FR-2.1** | The system shall support the upload, storage, and retrieval of up to 9 item images per listing. |
| UC4 | **FR-2.2** | The system shall integrate a Smart Posting Assistant that transmits images to an internal endpoint to receive an automated descriptive classification. |
| UC6 | **FR-3.1** | The system shall implement text-indexed search allowing queries based on product titles and descriptions. |
| UC6 | **FR-3.2** | The system shall provide dynamic filters in the frontend UI, including category dropdowns, condition toggles (New/Used), and a minimum/maximum price slider. |
| UC7 | **FR-4.1** | The system shall process content item tags and user viewing history to generate a mathematical similarity score (e.g., Cosine Similarity). |
| UC7 | **FR-4.2** | The system shall prioritize and display items in the Home Screen feed that have the highest correlation scores with the authenticated user profile. |
| UC8, UC9, UC12 | **FR-5.1** | The system shall handle a complete state machine for orders utilizing distinct statuses: Pending, Scheduled, Disputed, Completed, and Cancelled. |
| UC12 | **FR-5.2** | The system shall generate a digital receipt encompassing the timestamp, item name, buyer ID, and seller ID upon a status transition to `Completed`. |
| UC12 | **FR-5.3** | The system shall utilize a "manual confirmation model" for payments, logging the transaction data internally but forcing exact monetary exchanges to be processed completely externally via bank transfer or Cash on Delivery (COD). |
| UC14, UC15 | **FR-5.4** | The system shall provide a reputation-based reporting workflow, enabling users to flag fraudulent behaviors and empowering the Administrator to adjust trust scores or suspend offending accounts, entirely divorced from directly reimbursing the external financial losses. |
| UC10 | **FR-6.1** | The system shall render an interactive calendar allowing users to define start and end times to explicitly calculate borrowing periods. |
| UC10 | **FR-6.2** | The system shall calculate and output real-time price totals dynamically reflecting the date multiplied by the predefined rate, automatically adding any required rental deposit to the checkout summary. |
| UC11 | **FR-7.1** | The system shall support persistent, real-time 1-on-1 socket-driven (e.g., WebSockets/Socket.io) messaging between buyers and sellers. |
| UC11 | **FR-7.2** | The system shall integrate a Map-Based Location API (e.g., Google Maps) authorizing users to securely view and drop location pins for physical meetup tagging. |
| UC6 | **FR-7.3** | The system shall allow users to toggle a "Favorite" status on listings and retrieve a curated list of saved items. |
| UC8, UC9, UC11 | **FR-7.4** | The system shall utilize a central Push Notification mechanism to actively alert users to incoming chat messages and vital order status progressions. |
| UC12 | **FR-8.1** | The system shall formulate and maintain a Sustainability Dashboard on user profiles calculating equivalent "Carbon Savings" based on successful purchase queries. |
| UC15 | **FR-8.2** | The system shall aggregate system-wide backend analytics (daily active users, total successful trades) specifically formatted for the Administrator web panel view. |

### 3.4.2 Non-Functional Requirements

Non-functional requirements dictate the overall quality attributes—how well the system must execute the functional modules—serving as immutable architectural constraints.

| Quality Attribute | Requirement ID | Non-Functional Requirement |
| :--- | :--- | :--- |
| Security and Privacy | **NFR-1.1** | The system shall systematically hash user passwords utilizing algorithms like bcrypt prior to database insertion; raw passwords shall never be logged or stored. |
| Security and Privacy | **NFR-1.2** | The system shall utilize HTTPS/TLS cryptographic protocols for all node-to-node communications bridging the Flutter application, the Node.js API, and the Python microservice. |
| Security and Privacy | **NFR-1.3** | The system shall explicitly require Bearer JSON Web Tokens (JWT) for payload validation on stateless API endpoints modifying database states. |
| Security and Privacy | **NFR-1.4** | The system shall emphatically not store, process, or route real-currency financial details to actively avoid complex financial compliance limits; transactions fundamentally operate strictly as data ledgers. |
| Performance and Speed | **NFR-2.1** | The system shall compile the mobile application client to natively support hardware acceleration, rendering frame rates continuously at 60 FPS to prevent stuttering. |
| Performance and Speed | **NFR-2.2** | The system shall maintain a time-to-first-byte (TTFB) under 500 milliseconds on a stable LTE network for typical `SELECT` queries across M3 Search routes. |
| Performance and Speed | **NFR-2.3** | The system shall resolve requests and return JSON responses from the M4 Microservice classification and prediction pipeline within 3 seconds to maintain a seamless UX. |
| System Reliability | **NFR-3.1** | The system shall target an uptime SLA constraint of 99% across all interconnected modules, specifically tailored toward typical university operating daylight hours. |
| System Reliability | **NFR-3.2** | The system shall rigorously apply referential constraints (Foreign Keys with explicit cascade/restrict rules) in the PostgreSQL structure to completely eliminate orphaned records or transaction duplication issues. |
| Modular Maintainability | **NFR-4.1** | The system shall isolate core server processes (Node API, Python ML layer, PostgreSQL Database) utilizing Docker Compose standards `docker-compose.yml` to guarantee cross-OS environment parity. |
| Modular Maintainability | **NFR-4.2** | The system shall strictly mirror the M1-M8 logical separation in the physical directory architecture (e.g., specific controller files for transactions versus users) to allow scalable individual module updates. |
| Modular Maintainability | **NFR-4.3** | The system shall securely integrate third-party external APIs (like Location Maps) utilizing hidden environment variables (`.env`) to absolutely prevent public credential leakage. |

## 3.5 Out-of-Scope and Limitations

To maintain the optimal scope required for a single-developer academic constraint while focusing intensely on campus-specific peer-to-peer trading algorithms, the following explicit architectures are strictly declared as Out-of-Scope and represent known limitations of the current project design:

1. **External Logistics and Shipping**
The platform intentionally does not calculate shipping rates or integrate with third-party courier services such as PosLaju, J&T Express, or DHL. Cross-state mailing introduces courier fraud and severe logistical friction. Therefore, all platform transactions are mandated and assumed to be fulfilled exclusively via physical meetups at designated internal campus locations.

2. **Real-Currency Payment Gateway Integration**
To actively circumvent complex national financial compliance issues and PCI-DSS backend liability, the system intentionally lacks a live payment gateway (No Stripe, FPX, or internal E-Wallet limits). The platform applies a strict "manual confirmation model." While the platform provides a complete transaction lifecycle tracker (order recording, scheduled statuses, digital receipt generation), actual fiat currency processing occurs offline. Users conduct fund transfers through external Internet Banking applications or Cash-on-Delivery (COD). The platform acts solely as a trusted verifier and immutable record keeper, not a financial clearinghouse.

3. **Global Marketplace Access**
To enforce security, the application acts as a "walled garden" ecosystem. Public access is completely prevented. The service strictly restricts onboarding to verified university members holding an active `.edu.my` address. This limitation purposefully eliminates the general public to cut down standard phishing risks and foster high accountability networks.

4. **Legal Financial Arbitration**
The platform serves as an information intermediary only. While an Administrator can suspend accounts or negatively modify reputation scores for violations (such as no-shows reported via the Dispute system), the application provides zero formal legal arbitration or direct financial restitution for disputes. Users handle final financial dispute resolutions externally from the platform's direct code scope.