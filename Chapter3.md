

Chapter 3

Methodology and Requirements Analysis
Methodology and Requirements Analysis
This chapter outlines the software development methodology and implementation requirements for the Smart Campus Second-Hand Trading Platform. It details the iterative approach used to develop the project, the technologies used to collect and obtain user requirements, the structured decomposition of functional and non-functional requirements, and the use of use case diagrams and data flow diagrams to model system requirements and demonstrate system architecture and user interactions.
Iterative Development Methodology
Iterative development methodologies use cyclic processes to establish a software product and iterate towards a better solution through multiple iterations, rather than trying to build the complete and final version of a software application at the initial release. Iterative development methodologies each have their own emphasis on software design, construction, and improvement. They may stress how to plan, design, build, and test, as well as the overall elements of each stage of the development lifecycle. Each time an iteration is produced, it improves on the last iteration by moving through the Software Development Lifecycle (SDLC), Planning, designing, building, coding and testing. As a result, with successive iterations on the original architecture base, the software application will evolve during subsequent iterations, ultimately resulting in a full-featured application. (Larman & Basili, 2003)
To put this method into practice, it is crucial to have a functional structure of the entire system before adding any detailed features to it. First Iterations concentrate on developing core components such as authentication and a simple database connection. Second Iterations concentrate on developing more detailed additions of those components such as User Interfaces as required. By completing the core design before adding additional logic and features, developers are able to create a foundationally sound architecture upon which they can subsequently develop specialized logic to meet the project’s goals. This helps minimize the chances of having a large integration fail occur during the project’s later stages.
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
In order to systematically record the results of observation and analysis, a large number of user reviews, transaction experiences and complaints were extracted from well-known public platforms frequently used by Malaysians, such as Carousell, Mudah.my, Xiaohongshu and Facebook Marketplace.
The observations do not reveal isolated events, but rather multi-dimensional, systemic friction patterns. These range from complex financial fraud and personal safety issues to platform algorithmic biases and logistical disputes. The raw qualitative data is categorized into specific vulnerability dimensions, thus empirically demonstrating the necessity of the proposed smart campus platform.
The comprehensive findings and their corresponding system implications are documented in Table 3.1 below.
Platform
Specific Vulnerability / Pain Point
Sample of Observed User Comments (Paraphrased & Translated)
Implication for Proposed System (Solution)
Carousell / Mudah.my
Phishing Links & Fake Customer Service
"Scammers ask for an email, send a fake 'Receive Money' link, and mimic a bank login. One even faked a customer service call to steal RM4,000."
Closed-Loop Payment Model: Implement an in-app non-escrow C2C model where payment intention is declared, but actual transfer happens offline, eliminating malicious external links.
Facebook / WhatsApp
Malicious APK & SMS Hijacking
"A 'furniture company' buyer agreed to my price easily and asked me to download an APK file via WhatsApp to pay a deposit. It was a malware attempt."
In-App Communication Only: Force all interactions into the secure In-App Messaging module to prevent third-party malware distribution.
Facebook Marketplace
The "Lalamove" Theft Scam
"The buyer rushed me to send my TV via Lalamove, promising to transfer money while testing it. They provided a fake address, and the TV was stolen."
Mandatory .edu.my Verification: Restrict access to verified campus identities only, making hit-and-run theft practically impossible to execute anonymously.
Xiaohongshu
Cross-State "Empty Parcel" Fraud
"Bought an iPhone from Penang with a 40% deposit to a 'company' account. Received a soft red packet 4 days later—a delay tactic for bank clearance."
Geographic Fencing: Restrict the trading radius purely to the university campus to encourage physical inspection and immediate handover.
Carousell
Overpayment & QR Scams
"Scammer claimed they accidentally transferred RM580 extra and asked for a refund, or sent a malicious QR code to scan."
Admin Dispute Resolution: Provide a direct line for users to flag suspicious transaction requests to the platform Administrator.
Facebook Marketplace
Physical Safety & Midnight Meetups
"A buyer insisted on picking up shoes at 12 AM midnight at a nearby plaza. I canceled out of fear of robbery."
Safe Zone Meetup Map: Create an interactive map of the campus within the chat that allows users to place pins in well-lit, university-established safe zones.
Carousell
Harassment & Creepy Behavior
"A buyer asked for 'try-on' pictures for clothing. After I sent them, their language became highly inappropriate and creepy."
Strict Suspension Protocol: Give administrators the authority to permanently ban anyone who has been reported for harassment or broken any of our community guidelines.
General Platforms
Privacy & Home Address Exposure
"Selling large items means giving my private condo address to strangers. It feels unsafe having random people come to my door."
Campus-Centric Logistics: Facilitate meetups within campus grounds rather than residential dorms to protect user privacy.
Carousell
Ghosting & Psychological Stress
"Scheduled a COD twice. The buyer read messages but didn't show up. Waiting alone made me feel stalked and unsafe."
Reputation & Review System: Implement a Mutual Review system to permanently mark the profiles of users with a history of ghosting or flaking.
Facebook / Mudah.my
Fake Profiles & Bait Pricing
"Saw a RM650 stroller listed for RM100 by a new 2025 account with a fake foreign profile picture. Obvious bait."
Institutional Traceability: Every profile is tied to a real student ID via institutional email, naturally filtering out bot accounts and overseas scammers.
Carousell / Xiaohongshu
Extreme Lowballing & Entitlement
"Listed an item for RM150, buyers demand RM80. For a RM20 item, they demand free doorstep delivery. Lots of likes, no serious buyers."
Formal 'Make Offer' Feature: Implement an Offer System to formalize negotiations, resolving almost all disputes without lengthy messages and outlining clear expectations for completing the transaction.
Shopee / Personal Sales
Platform Bias & Cyberbullying
"Refused to use Shopee because as a seller, buyers can easily claim 'item not received' and keep the item. The buyer then blackmailed and cursed me as a scammer online."
Peer-to-Peer Dispute Equality: Administrators will use objective chat logs as well as evidence from the meet-up between buyers and sellers, which will produce a fair and impartial outcome for all parties involved.
Carousell
Algorithmic Suppression
"If you don't actively hunt for 'likes' or constantly delete and re-upload listings, your items become completely invisible to buyers."
Smart Discovery & Personalized Feeds: Leverage a Machine Learning engine to automatically determine items that match a user's prior history, allowing sellers to have their items seen without needing to alter the algorithm.

Table 3.1: Extensive Qualitative Analysis of User Pain Points on Existing Public Platforms

Quantitative Survey via Online Questionnaires
Questionnaires are a highly structured raw data collection tool consisting of standardized prompts designed to gather quantitative information from a specific target population. The main reason for choosing structured questionnaires over other data collection methods in empirical software engineering research is that they can efficiently obtain detailed data from a large number of respondents across a wide geographical area (Ball, 2019). In particular, one of the main benefits of using structured questionnaires via the Internet is that the data collected will have been evaluated using a standardised set of questions. Therefore, all of the data collected from each respondent will have been obtained using the same standardised set of questions resulting in data being obtained from each respondent that can be mathematically identified as "same" or "similar". Another major benefit of using a questionnaire via the Internet is that respondents are given anonymity, which has been shown to reduce bias from interviewers and also encourages respondents to provide truthful information about sensitive matters such as being the victim of a financial scam (Braun et al., 2020).
To complement the qualitative data that have been collected through observational methodology, the quantitative survey uses online questionnaires via Google Forms to collect measurable empirical data. This method has been chosen because it is highly effective at obtaining a large and diverse sample size of university students across various age groups, academic study levels, and living arrangements. By surveying the actual target demographic, the project ensures that the proposed software features are grounded in statistical user demand rather than isolated developer assumptions.
The questionnaire is systematically designed to gather data across four primary sections utilizing a combination of dichotomous questions, multiple choice formats, and linear rating scales. The first dimension evaluates student demographics and their current resource trading behaviors. This section establishes the baseline by assessing their living arrangements, academic tenure, and preferred digital platforms for secondhand transactions. The second dimension directly measures user frustration metrics and validates the pain points identified during the earlier observational analysis. Utilizing multiple choice and dichotomous selections, respondents are asked to identify the specific types of online scams they have encountered, their primary safety concerns during physical meetups, and the logistical challenges they face when transporting heavy items.
The third dimension assesses the market acceptance of the proposed Smart Campus platform features utilizing a five point linear rating scale. It explicitly evaluates student willingness to adopt a closed trading ecosystem secured strictly by institutional email authentication. Furthermore, it gauges user interest in advanced technical integrations by asking respondents to rate the perceived helpfulness of a machine learning recommendation engine, a short term rental system, and an environmental sustainability dashboard. It also measures the importance of secure interaction tools such as an interactive campus map and an in app chat system. Finally, an optional open ended section is included to capture unstructured qualitative suggestions, ensuring no critical user requirements are overlooked. By aggregating this comprehensive statistical data, the project can confidently justify its core functional requirements based on validated user demand.
Quantitative Data Analysis and Feature Validation
To statistically validate the qualitative observations and definitively shape the system architecture, an online questionnaire was distributed to the target demographic. A total of 52 university students participated in the survey.
1. Demographics and Living Arrangements

Figure 3.1: Gender Distribution (Q1)

Figure 3.2: Age Group (Q2)

Figure 3.3: Current Level of Study (Q3)

Figure 3.4: Current Living Arrangement (Q4)
As shown in Figures 3.1 through 3.3, the sample is representative of the target users, with most of them being Bachelor's Degree students (61.5%) and aged between 22-25 years (46.2%). Importantly, based on Figure 3.4, 50% of respondents do not live on campus and rent off campus, while 17.3% live in a campus hostel. Therefore, there is a high demand for short term, budget-friendly supplies for all of the above.
2. Trading Habits and Platform Preferences

Figure 3.5: Primary Role in Second-hand Trading (Q5)

Figure 3.6: Most Frequently Used Platforms (Q6)

Figure 3.7: Most Sought-After Categories (Q7)
The balance between buyers and sellers shown in Figure 3.5 is the foundation for a healthy C2C marketing ecosystem. As a result of their residences, Figure 3.4, students mainly want to buy small furniture and appliances (50%) and electronics (42.3%) (see Figure 3.7). Although Xiaohongshu (73.1%) and Facebook Marketplace (51.9%) dominate all other current platforms (see Figure 3.6), an analysis of the friction experienced by users shows that these general-purpose apps have huge limitations.
3. Analysis of Security Deficits and Trust Barriers

Figure 3.8: Encounter Rate of Suspicious Activities (Q8)

Figure 3.9: Biggest Concerns in Online Trading (Q9)

Figure 3.10: Primary Reason Stopping Further Purchases (Q12)
Another major barrier is Trust. In Figure 3.8, the vast majority of respondents show that 86.5% of them have experienced (17.3%) or are concerned about suspicious activity (69.2%). All this helps to explain why fear of getting scammed is one of the primary reasons why students do not trade (40.4%) (see Figure 3.10). Figures 3.9 and 3.10 further indicate many users have additional concerns about privacy (44.2%) and personal safety (48.1%).
To statistically eliminate this fear, the proposed platform must operate as a closed, verified ecosystem. This directly validates the design of Identity Management, which enforces mandatory .edu.my verification, and Campus Communication, which provides secure In-App Messaging to protect phone numbers.
4. Discovery Challenges and Logistical Friction

Figure 3.11: Search Challenges on General Social Media (Q10)

Figure 3.12: Logistics and Delivery Friction for Bulky Items (Q11)
Trading today suffers from discoverability issues and logistical difficulties. As highlighted in Figure 3.11, 59.6% of users are faced with the hassle of "Unclear item conditions," while 38.5% complain about irrelevant lifestyle postings on platforms such as Xiaohongshu. This indicates a requirement for a Catalog & Inventory Administrative workflow with standardised data fields.
Furthermore, when purchasing bulky products (Figure 3.12), a substantial 40.4% chose to avoid purchasing bulky items completely because the logistics involved in getting them to their location were too challenging and the geographic dispersion of sellers (48.1% in Figure 3.11) was excessive. Based on this data, it is clear that establishing a campus centric geographic fence around product discoverability will facilitate local walkable meetups between buyers and sellers and eliminate high courier fees.
5. Evaluation of Proposed Features (Solution Validation)

Figure 3.13: Demand for .edu.my Verification (Q13)

Figure 3.14: Importance of In-App Chat for Privacy (Q18)

Figure 3.15: Importance of Mutual Rating System (Q19)

Figure 3.16: Willingness to use Interactive Safe Meetup Map (Q15)
The survey for the proposed system features received abundant endorsement from the respondents. They have rated Security and Safety very highly in priority. The most pertinent finding is that 94.2% of the respondents greatly appreciate an In-App Chat system to maintain their privacy from others having their WhatsApp numbers (Figure 3.14). Additionally, 88.4% valued being mutually rated as building confidence to use the system (Figure 3.15). Furthermore, 76.9% believe that they feel more secure using the system when only people with .edu.my emails are verified by the system (Figure 3.13). In addition, 77% of the respondents indicated that if there was a "Campus Map" showing designated safe meeting places they would be much more likely to meet offline (Figure 3.16).
This exceptionally high consensus statistically proves that Identity Management, Feedback System, and Communication & Safe Zones are not optional features, but absolute prerequisites for user adoption.

Figure 3.17: Helpfulness of Smart Recommendation System (Q14)

Figure 3.18: Interest in Eco-Friendly Tracking Dashboard (Q16)

Figure 3.19: Helpfulness of Short-Term Rental Feature (Q17)
Beyond basic security, users highly value utility and discovery. 84.6% of students found the "Short-Term Rental" feature highly beneficial for academic life (Figure 3.19), definitively justifying the integration of rental mechanics. To combat the catalog clutter identified earlier, 73% favor an ML-driven Smart Recommendation System (Figure 3.17). Finally, there is a solid interest in the Sustainability Dashboard (Figure 3.18), proving that eco-tracking can serve as an effective gamified incentive to promote the circular campus economy.
6. Overall Acceptance and Qualitative Suggestions

Figure 3.20: Overall Likelihood of Platform Adoption (Q20)

Figure 3.21: Open Feedback and User Suggestions (Q21)
The culmination of this research is reflected in Figure 3.20, where a staggering 92.3% of respondents indicated a high likelihood (rating 4 or 5) of adopting the proposed Smart Campus platform. There were zero outright rejections (rating 1).
Furthermore, the optional open feedback (Figure 3.21) organically mirrored the quantitative data. Respondents explicitly requested features such as "Make sure the trading zone is safe", "Detect fake buyers or scammers", and "Make sure buyers and sellers are students to reduce risk".
The empirical evidence gathered through both observational analysis and this comprehensive questionnaire unequivocally validates the proposed architectural blueprint. The integration of strict institutional verification, local geographic fencing, secure communication, and ML-assisted discovery directly and effectively resolves the documented market friction. The project is confirmed to possess a massive product-market fit within the university demographic.
Requirement Analysis
The system was initially designed with eight modules. However, during the Use Case development process, several overlapping and closely related functionalities were identified. To improve clarity and system organization, these functionalities were consolidated, resulting in a refined structure consisting of six modules.
Use Case Diagram

Figure 3.22: Overall Platform Use Case Diagram

Figure 3.23: Identity and Account Management Use Case Diagram

Figure 3.24: Catalog and Inventory Management Use Case Diagram

Figure 3.25: Item Discovery and Recommendation Use Case Diagram

Figure 3.26: Order Fulfillment and Feedback System Use Case Diagram

Figure 3.27: Campus Communication and Coordination Use Case Diagram

Figure 3.28: Platform Administration and Oversight Use Case Diagram
Use Case Description Table
Sub-System 1: Identity & Account Management
Use Case ID
UC01
Use Case Name
Register Account
Objectives
To securely create a new user profile while strictly ensuring the user is an active student via institutional email verification.
Actor / Activator
Student
Pre-condition
The user has downloaded the app and possesses a valid .edu.my email.
Basic Flows
Actor Action
System Response
Navigates to the registration screen and inputs personal details (Full Name, Student ID, Phone Number, Student Email) and securely sets a password.


2. Clicks the "Register" button.
3. Disables the submission button, displays a loading indicator, and validates all input formats (e.g., Student ID structure, phone number formatting, password complexity).


4. Verifies the email is not already registered, then triggers Verify Campus Email to dispatch a secure OTP.
5. Opens institutional email inbox, retrieves the verification code (OTP), and inputs it into the application.
6. Validates the OTP authenticity, activates the new account, displays a success confirmation, and routes the user to the Login screen.
   Alternative Flow
   A1: Invalid Input Format (Step 3)
   A1.1 Mandatory fields are left blank.

A1.2 Email domain is not .edu.my.

A1.3 Passwords do not match or fail to meet the required security complexity.

A1.4 Student ID or Phone Number format is structurally invalid.

The System halts the registration process and removes the loading indicator. Error message displays specific, non-intrusive error text directly below the violating input fields (e.g., "Student ID format invalid" or "Password must contain at least one number"). The system will retains all previously entered valid data and waits for the user to correct the specific mistakes.
A2: Email Already Exists (Step 4)
A2.1 The submitted student email is already tied to an active or suspended account.

The system halts the process and removes the loading indicator. Error message displays a system alert: "This email is already registered”. The system will retain all previously entered valid data and waits for the user to correct the specific mistakes.
A3: Invalid or Expired OTP (Step 6)
A3.1 The user enters the wrong OTP or the OTP has exceeded its time-to-live (e.g., 5 minutes).

The system rejects the activation attempt. Error message displays an alert: "Verification code is invalid or has expired". The system will clear the OTP input field and provides the user with a button to "Resend Verification Code".
Post-condition
A verified student account is successfully created, and the user profile is initialized in the database.

Table 3.2: UC01-Register Account

Use Case ID
UC02
Use Case Name
View User Profile and Reputation
Objectives
To view another user's public profile, including their aggregated trust score and active listings, to evaluate their reliability before trading.
Actor / Activator
Student
Pre-condition
The user is authenticated and clicks on a target user's avatar (e.g., from a chat log or product listing).
Basic Flows
Actor Action
System Response
1. Taps on a user's avatar or navigates to "My Profile".
2. Retrieves the target user's public metadata (Name, Join Date), aggregated reputation score, and active inventory.


3. Renders the full profile interface, displaying the star rating and available items.
   Alternative Flow
   A1: Target Account is Suspended or Deactivated (Step 2)
   A1.1 The target user has voluntarily deactivated their account or been banned by an Administrator.

The system halts the retrieval of inventory and reputation data. UI renders a restricted profile view with a greyed-out default avatar and show “Account Suspended / Unavailable”.
A2: Zero Transaction History (Step 2)
A2.1 The target user is a brand-new student with no completed trades and zero reviews.

The system skips the reputation calculation. Replaces the star rating section with a neutral placeholder: "New User: No ratings yet", preventing the system from displaying a misleading "0 stars" rating. The rest of the profile renders normally.
Post-condition
The user successfully views the profile details appropriate to the target account's current status.

Table 3.3: UC02-View User Profile and Reputation

Use Case ID
UC03
Use Case Name
View Sustainability Dashboard
Objectives
To calculate and visualize the user's personal environmental impact (e.g., carbon emissions saved) derived from their successful secondhand transactions, encouraging circular economy participation.
Actor / Activator
Student
Pre-condition
The user is authenticated and navigates to the "Sustainability" section within their personal profile.
Basic Flows
Actor Action
System Response
1. Taps on the "Sustainability Dashboard" tab/button.
2. Queries the database exclusively for the user's historical transactions marked with a Completed status.


3. Calculates aggregated environmental metrics (e.g., total estimated carbon footprint saved).


4. Renders the dashboard, displaying interactive charts, impact statistics, and unlocked eco-badges.
   Alternative Flow
   A1: Zero Completed Transactions (Step 2)
   A1.1 The user is new or has only Pending/Cancelled orders, resulting in no actual environmental impact yet.

The system halts the calculation engine to prevent displaying null or zero-value charts. UI renders a gamified "Empty State" interface (e.g., a greyed-out seedling graphic) with an encouraging prompt: "Your green journey starts here! Complete your first trade to unlock your impact”. The system will provide a prominent "Explore Items" Call-to-Action (CTA) button to redirect the user back to the marketplace feed.
A2: Analytics Retrieval Timeout (Step 3)
A2.1 The aggregation query takes too long or the backend analytics service experiences a temporary timeout due to poor network conditions.

The system aborts the live data calculation after a predefined timeout. UI displays a non-intrusive warning banner: "Live metrics temporarily unavailable". The system will load the most recently cached metrics from the local device storage (if available), or provides a "Tap to Retry" button to refresh the dashboard.
Post-condition
The user successfully views their environmental impact metrics or an appropriate educational prompt.

Table 3.4: UC03-View Sustainability Dashboard

Use Case ID
UC04
Use Case Name
Update Profile Data
Objectives
To securely update user profile details, avatar, and privacy setting.
Actor / Activator
Student
Pre-condition
The user is authenticated and on the "Edit Profile" screen.
Basic Flows
Actor Action
System Response
1. Accesses the "Edit Profile" interface.


2. Uploads a new avatar, edits text fields (Name, Bio), and sets privacy setting.


3. Clicks "Save Changes".
4. Validates text limits and image constraints (e.g., size, format).


5. Renames the image using a timestamp to prevent file conflicts.


6. Triggers Update Privacy Settings to apply visibility rules.


7. Saves changes to the database and refreshes the profile UI.
   Alternative Flow
   A1: Image Validation Fails (Step 4)
   A1.1 File exceeds 5MB or format is invalid.

The system halts the image upload. Error message displays an inline alert: "File too large (Max 5MB)" or "Invalid format". The system will retain valid text data and waits for a compliant image.
A2: Text Validation Fails (Step 4)
A2.1 Bio exceeds character limits or Name contains invalid symbols.

The system halts the saving process. Error message displays red text below the field (e.g., "Exceeds 150 characters"). The system will wait for the user to correct the text input.
Post-condition
The user's profile and privacy settings are successfully updated.

Table 3.5: UC04-Update Profile Data

Use Case ID
UC05
Use Case Name
Deactivate Account
Objectives
To allow users to securely soft-delete their profile while preventing evasion of active trading responsibilities.
Actor / Activator
Student
Pre-condition
The user is authenticated and accesses the "Account Settings" interface.
Basic Flows
Actor Action
System Response
1. Clicks "Deactivate Account".
2. Verifies the user has no active orders (Pending or Scheduled).


3. Displays a warning prompt requiring password confirmation.
   4.. Reads the warning and inputs the current password.


5.  Clicks "Confirm".
6. Validates the password.


7. Performs a "Soft Delete" (updates status to inactive).


8. Terminates the session, routes to Login.
   Alternative Flow
   A1: Active Orders Exist (Step 2)
   A1.1 The user has ongoing transactions or unresolved disputes.

The system halts the deactivation process before prompting for a password. Error message displays an alert modal: "Cannot deactivate: You have active orders or disputes". The system will prompts the user to resolve or cancel active orders before retrying.
A2: Invalid Password (Step 4)
A2.1 The user inputs the wrong password.

The system halts the deactivation process. Error message displays inline red text: "Incorrect password". The system will clear the password field and waits for another attempt.
Post-condition
The user's public profile is hidden (soft-deleted), but historical transaction data is securely retained.

Table 3.6: UC05-Deactivate Account

Use Case ID
UC06
Use Case Name
Manage User Account (Suspend & Reactivate)
Objectives
To suspend violating accounts or reactivate appealed accounts based on verified evidence.
Actor / Activator
Administrator
Pre-condition
The Administrator accesses the dashboard to handle an escalated report, dispute, or user appeal.
Basic Flows
Actor Action
System Response
1. Reviews the attached evidence (e.g., chat logs, reports) and selects the target user account.


2. Selects "Update Status" (Suspend/Reactivate) and inputs a justification note.


3. Clicks "Confirm Update".
4. Validates Administrator privileges.


5. Updates the account status in the database.


6. Logs the action for auditing and triggers a notification email to the student.
   Alternative Flow
   A1: Execute Suspension
   A1.1 The Admin changes status to Suspended due to severe policy violations.

The system terminates the user's active session. It automatically hides all active listings belonging to the user. UI renders the user's profile as "Unavailable" to others.
A2: Execute Reactivation
A2.1 The Admin changes status to Active after approving an appeal.

The system restores the user's login access and unhides the user's previously compliant listings.
A3: Appeal Rejection
A3.1 Admin reviews an appeal but maintains the ban.

The system keeps status as Suspended and sends a final rejection email explaining the decision.
Post-condition
The user's platform access and listings are restricted or restored based on the evidence review.

Table 3.7: UC06-Manage User Account

Sub-System 2: Catalog & Inventory Administration
Use Case ID
UC07
Use Case Name
Create Product Listing
Objectives
To allow sellers to publish items for sale or rent, assisted by an ML engine for faster data entry.
Actor / Activator
Student (Seller / Owner)
Pre-condition
The user is authenticated and opens the "Add New Listing" interface.
Basic Flows
Actor Action
System Response
1. Selects listing type ("For Sale" or "For Rent") and uploads multimedia (images/video).
2. Validates media limits and safety constraints, analyzes the images, and auto-populates the Category and Suggested Price.
3. Inputs a Product Title and clicks "Generate Description" (Optional).
4. Reads the Title and image context to draft the Description field.
5. 5. Reviews AI-generated content, manually edits fields if necessary, inputs pricing details (e.g., Deposit for rentals), and clicks "Publish".
6. Validates all mandatory fields, optimizes media (compresses and renames via timestamp).


7. Saves the listing to the database, and routes to "My Inventory".
   Alternative Flow
   A1: Missing Title for Generation (Step 3)
   A1.1 User clicks "Generate Description" but the Title field is empty.

The system halts the AI text generation. Error message displays an inline tooltip: "Please enter a Title first to generate a description". The system will wait for the user to input a Title before allowing generation.
A2: User Overrides AI Suggestions (Step 2 or 4)
A2.1 User is dissatisfied with the AI-generated Category, Suggested Price, or Description.

The system permits full manual editing of all auto-populated fields without restricting user control. UI keeps the text fields fully editable after generation. User deletes or overwrites the AI content with their own details and proceeds.
A3: Mandatory Fields Incomplete (Step 5)
A3.1 User clicks Publish but left mandatory fields (e.g., Title, Price) blank.

The system halts the publishing process. Error message highlights empty fields in red: "This field is required". The system prevents submission until the form is complete.
Post-condition
A new product or rental listing is successfully published and visible in the catalog.

Table 3.8: UC07-Create Product Listing

Use Case ID
UC08
Use Case Name
View My Inventory
Objectives
To allow sellers to monitor and manage their published listings across different transaction statuses.
Actor / Activator
Student (Seller / Owner)
Pre-condition
The user is authenticated and accesses the "My Inventory" tab.
Basic Flows
Actor Action
System Response
1. Navigates to the "My Inventory" dashboard.
2. Retrieves the user's listings from the database, categorized by their current lifecycle status.
3. Toggles status filters (e.g., Active, Reserved, Sold).


4. Selects a specific listing to manage.
5. Refreshes the display based on the selected filter.


6. Routes the user to the detailed management view for that specific item.
   Alternative Flow
   A1: Zero Listings (Step 2)
   A1.1 The user has never published an item.

The system halts the data retrieval for lists. UI renders a gamified empty state (e.g., an "Open your shop" graphic) with a text prompt: "You haven't listed anything yet". The system will provide a "Create Listing" button leading to UC-07.
A2: Listing Suspended by Moderator (Step 2)
A2.1 One or more listings were flagged and hidden by a Moderator (Link to UC-10/UC-12).

The system still displays the item to the owner, but greys it out. UI attaches a red "Suspended - Policy Violation" badge to the item. The system will disable the "Relist" or "Edit" functions for that specific item to enforce platform rules.
Post-condition
The user successfully views and filters their personal product catalog.

Table 3.9: UC08-View My Inventory

Use Case ID
UC09
Use Case Name
Update Listing Details
Objectives
To allow sellers to modify an active listing's details while preventing unauthorized changes during an ongoing transaction.
Actor / Activator
Student (Seller)
Pre-condition
The user is authenticated, views "My Inventory", and selects an item to edit.
Basic Flows
Actor Action
System Response
1. Clicks "Edit" on a specific listing.


2. Modifies textual details, pricing, or updates media files.


3. Clicks "Save Changes".
4. Verifies the listing's current status is Active.


5. Validates input formats and media constraints.


6. Updates the database and refreshes the inventory UI.
   Alternative Flow
   A1: Item is Currently Reserved (Step 4)
   A1.1 The item is tied to a Pending or Scheduled order.

The system halts the edit process to prevent transaction fraud. Error message displays an alert: "Cannot edit: This item is currently engaged in an active order". The system restricts the UI to "View Only" mode until the order is completed or cancelled.
A2: Validation Fails (Step 5)
A2.1 Inputs violate business rules (e.g., negative price, oversized image).

The system halts the save process. Error message highlights the specific invalid fields with inline error text. The system waits for the user to correct the inputs.
Post-condition
The listing details are successfully updated in the public catalog.

Table 3.10: UC09-Update Listing Details

Use Case ID
UC10
Use Case Name
Remove / Suspend Listing
Objectives
To remove an item from the catalog, either voluntarily by the Seller or forcefully by a Moderator, while preserving transaction integrity.
Actor / Activator
Student (Seller), Moderator
Pre-condition
The Actor accesses the target listing via the Inventory (Seller) or the Moderation Dashboard (Moderator).
Basic Flows
Actor Action
System Response
1. Clicks the "Remove" or "Suspend" button.


2. Confirms the prompt (Moderator inputs a violation reason).
3. Verifies the listing's current status (Active vs. Reserved).


4. [If Moderator & Reserved]: Automatically cancels the associated pending order and sends a system explanation to the Buyer.


5. Updates the item status (Deleted for Seller, Suspended for Moderator) and removes it from public search.


6. Refreshes the UI and logs the action.
   Alternative Flow
   A1: Seller Attempts to Remove Reserved Item (Step 3)
   A1.1 The Seller tries to delete an item that a buyer has already ordered.

The system halts the deletion process. Error message displays an alert: "Cannot delete: Please cancel the active order first". The system blocks the action, protecting the buyer's transaction record.
Post-condition
The listing is hidden from the marketplace. If suspended by a Moderator, any active order is safely cancelled.

Table 3.11: UC10-Remove / Suspend Listing

Use Case ID
UC11
Use Case Name
Report Listing
Objectives
To empower users to flag violating or fraudulent listings for moderation, maintaining platform safety.
Actor / Activator
Student (Buyer / Browser)
Pre-condition
The user is authenticated and viewing a specific product's details page.
Basic Flows
Actor Action
System Response
1. Opens the "More Options" menu and clicks "Report Listing".
2. Verifies the user has not exceeded the spam limit (max 3 reports per 10 mins), then displays the Report Form.
3. Selects a mandatory category (e.g., Scam, Fake, Prohibited Item), writes a mandatory description, optionally uploads evidence images (Max 3 JPG/PNG), and clicks "Submit".
4. Validates that all mandatory fields are filled.


5. Saves the report for Moderator review (UC-12), applies a "Local Hide" (hides the item only from the reporter's personal view), and shows a confirmation toast.
   Alternative Flow
   A1: Rate Limit Exceeded / Spam Prevention (Step 2)
   A1.1 User attempts to submit >3 reports within 10 minutes.

The system halts the report initialization to prevent system spam. Error message displays an alert: "You are submitting reports too quickly. Please try again later.". The system will block the action temporarily to cool down.
A2: Self-Reporting Attempt (Step 2)
A2.1 User attempts to report their own listing.

The system hides the "Report Listing" option entirely. If bypassed via direct link, system blocks submission with error: "You cannot report your own listing".
A3: Mandatory Fields Empty (Step 4)
A3.1 User clicks Submit but left the Category or Description blank.

The system halts the submission process. Error message highlights empty fields in red: "Please select a category and provide a description". The system will wait for the user to complete the form.
Post-condition
The violation report is logged for moderation, and the reported item is locally hidden from the reporter.

Table 3.12: UC11-Report Listing

Use Case ID
UC12
Use Case Name
Review Reported Listings
Objectives
To allow Moderators to investigate flagged items and enforce platform policies by either dismissing the report or executing a takedown.
Actor / Activator
Moderator
Pre-condition
The Moderator is authenticated and accesses the "Moderation Dashboard" (Report Queue).
Basic Flows
Actor Action
System Response
1. Selects a pending report ticket from the queue.
2. Retrieves and displays the reporter's evidence, the target listing details, and the seller's violation history side-by-side.
3. Analyzes the evidence, selects a verdict ("Uphold" or "Dismiss"), inputs a review note, and clicks "Submit Decision".
4. Processes the verdict, updates the report ticket status to Resolved, and executes the corresponding enforcement action.
   Alternative Flow
   A1: Verdict - Uphold Report (Violation Confirmed)
   A1.1 The Moderator determines the listing violates policies.

The system tiggers UC10: Remove / Suspend Listing to execute the takedown. The system will send a warning notification to the Seller and a "Thank You - Action Taken" notification to the Reporter.
A2: Verdict - Dismiss Report (False Alarm)
A2.1 The Moderator determines the listing is compliant (no violation).

The system clears the violation flag from the listing. The system will send a "Report Reviewed - No Action Taken" notification to the Reporter to close the feedback loop.
Post-condition
The report ticket is closed, and the targeted listing is either cleared or suspended based on the verdict.

Table 3.13: UC12-Review Reported Listings

Sub-System 3: Item Discovery & Smart Recommendation
Use Case ID
UC13
Use Case Name
Search and Filter Listings
Objectives
To allow buyers to efficiently discover items using keywords and optional dynamic filters.
Actor / Activator
Student (Buyer / Browser)
Pre-condition
The user accesses the platform's Home or Search interface.
Basic Flows
Actor Action
System Response
1. Inputs a keyword into the search bar or selects a specific Category.
2. Validates the search input, then provides a default list of recent items.
3. Applies optional filters (e.g., Condition: New/Good/Fair, inputs Min/Max Price) and clicks "Apply".
4. Validates filter logic (e.g., Min Price must be <= Max Price).


5. Queries the database for matches, strictly excluding listings with Suspended, Reserved, or Sold statuses to ensure all results are purchasable.


6. Renders the paginated search results (e.g., 20 items per page) to optimize loading speed.
   Alternative Flow
   A1: Zero Search Results (Step 5)
   A1.1 The specific combination of keywords and filters yields no active items.

The system halts the list rendering. UI renders a friendly empty state (e.g., "No exact matches found"). The system displays a "Clear Filters" button to reset the view and encourage broader browsing.
A2: Invalid Price Range Logic (Step 4)
A2.1 The user inputs a Minimum Price that is higher than the Maximum Price.

The system halts the search execution. Error message highlights the price input fields in red: "Min price cannot exceed Max price", The system will wait for the user to correct the numerical inputs.
Post-condition
The user is presented with a curated list of active items matching their search criteria.

Table 3.14: UC13-Search and Filter Listings

Use Case ID
UC14
Use Case Name
View Trending Discoveries
Objectives
To proactively engage users by displaying dynamically generated "Hot" categories and items based on platform activity metrics.
Actor / Activator
Student (Buyer / Browser)
Pre-condition
The user accesses the platform's "Home" or "Explore" dashboard.
Basic Flows
Actor Action
System Response
1. Navigates to the Home/Explore tab.
2. Aggregates recent platform metrics (e.g., most views, most saves) to calculate trending items and top categories, strictly filtering for Active status only.
3. Horizontally scrolls through the trending carousels or clicks a specific "Trending Category" tag.


4. Selects a specific trending item to view.
5. Routes the user to UC13 (Search Results for that category) or directly to the Item Details page.
   Alternative Flow
   A1: Cold Start / Insufficient Data (Step 2)
   A1.1 The platform lacks enough recent interaction data to calculate meaningful trends (e.g., during initial launch).

The system bypasses the complex algorithm and executes a fallback logic. UI renders a "Fresh on Campus" section, simply querying and displaying the most recently published Active listings. The system ensures the homepage is never empty.
A2: Clicked Item Becomes Unavailable (Step 5)
A2.1 User clicks a trending item, but it was just reserved or suspended milliseconds ago.

The system intercepts the routing process. Error message displays a toast: "Oops! This popular item is no longer available". The system will refresh the trending widget to remove the unavailable item.
Post-condition
The user successfully discovers and navigates to popular items or categories.

Table 3.15: UC14-View Trending Discoveries

Use Case ID
UC15
Use Case Name
Generate Personalized Feed
Objectives
To dynamically curate a personalized "For You" dashboard using an ML recommendation engine (Content-Based Filtering) based on user interaction history.
Actor / Activator
Student (Buyer)
Pre-condition
The user is authenticated and accesses the "For You" or "Recommended" tab.
Basic Flows
Actor Action
System Response
1. Navigates to the "For You" dashboard.
2. Retrieves the user's implicit feedback logs (e.g., recent search keywords, viewed categories).
4. Browses the grid and clicks on a specific listing.
3. Feeds data into the Content-Based Filtering algorithm and renders a paginated, personalized feed of Active items.


5. Routes the user to the Item Details interface.
   Alternative Flow
   A1: The Cold Start Problem (Step 2)
   A1.1 The user is new and has zero interaction history for the ML to analyze.

The system bypasses the ML computation. Trigger UC14 View Trending Discoveries as a fallback. UI renders trending/fresh items to safely populate the empty feed.
A2: ML Engine Timeout / Failure (Step 3)
A2.1 The backend recommendation API times out or fails to return data.

The system aborts the ML process to ensure app stability. The system falls back to querying the database for the most recently published Active listings. UI displays a chronological feed without interrupting the user experience.
A3: Refresh Feed (Step 4)
A3.1 The user pulls down to refresh the personalized feed.

The system recalculates and injects a randomized subset of relevant items. It prevents recommendation fatigue (Filter Bubble) and keeps the feed dynamic.
Post-condition
The user is presented with highly relevant items and successfully navigates to a listing.

Table 3.16: UC15-Generate Personalized Feed

Use Case ID
UC16
Use Case Name
View Listing Details
Objectives
To retrieve and display comprehensive listing information, seller details, and similar items, providing UI entry points for future actions.
Actor / Activator
Student (Buyer / Browser)
Pre-condition
The user clicks on a listing card from Search, Trending, or Feed.
Basic Flows
Actor Action
System Response
1. Clicks on a specific listing card.
2. Retrieves the item's multimedia, details, seller summary, and related Active items, rendering the Details UI with action buttons (Chat, Offer, Report).
3. Scrolls to view the full description, seller profile, and the "Similar Listings" section.


4. (Optional) Toggles the "Favorite" icon to save the item.
5. Updates the Wishlist database and visual state of the icon.
   Alternative Flow
   A1: Listing Unavailable (Step 2)
   A1.1 The item's status changed to Sold, Reserved, or Suspended milliseconds before the user clicked it.

The system halts the data retrieval. Error message displays an alert: "Oops! This listing is no longer available". The system will redirect the user back to the previous page.
A2: Owner View (Step 2)
A2.1 The user views a listing they created themselves.

The system modifies the interface for the owner. UI hides the "Chat", "Make Offer", "Report", and "Favorite" buttons to prevent illogical actions. The action will replace them with "Edit Listing" (UC09) and "Remove" (UC10) buttons.
Post-condition
The user successfully views the listing details and its available action buttons.

Table 3.17: UC16-View Listing Details
Sub-System 4: Order Fulfillment & Feedback System
Use Case ID
UC17
Use Case Name
Initiate Order / Rental Request
Objectives
To allow a user to propose a purchase or rental transaction via a dynamic form, while temporarily locking the item to prevent double-booking.
Actor / Activator
Student (Buyer / Renter)
Pre-condition
The user clicks "Make Offer" or "Rent Now" on an Active listing.
Basic Flows
Actor Action
System Response
1. Clicks the primary transaction button.
2. Verifies the listing is still Active and checks its Listing Type (Sale vs. Rental).
4. Inputs transaction details based on the form type (e.g., Price for Buy; Dates for Rent), selects meetup preferences, and clicks "Submit".
3. Renders a Dynamic Request Form: For sales, displays the "Price Offer" field. For rentals, displays "Start/End Date" pickers and auto-calculates the "Total Rent + Deposit".


5. Re-verifies listing status (Concurrency Check) and validates inputs (e.g., Dates).


6. Creates a Pending order record (capturing either sale price or rental duration/deposit).


6. Automatically updates the targeted item's status from Active to Reserved.


7. Triggers a push notification to the Seller and redirects the user to the Order Tracking page.
   Alternative Flow
   A1: Race Condition / Item Snipped (Step 5)
   A1.1 Another user successfully reserved the item moments before submission.

The system halts the order creation to prevent double-booking. Error message displays an alert: "Sorry, this item was just reserved by someone else". The system will redirect the user back to the updated Listing Details page.
A2: Invalid Rental Dates (Step 5)
A2.1 The user inputs a rental End Date that is earlier than the Start Date, or dates in the past.

The system halts the submission. Error message highlights the date pickers in red: "Invalid rental period selected". The system waits for the user to correct the dates.
Post-condition
A Pending order is created, the Seller is notified, and the item is globally locked as Reserved.

Table 3.18: UC17-Initiate Order / Rent Request

Use Case ID
UC18
Use Case Name
View My Orders
Objectives
To display a list of the user's active and past orders, allowing them to track transaction statuses.
Actor / Activator
Student
Pre-condition
The user is authenticated and navigates to the "Orders" page.
Basic Flows
Actor Action
System Response
1. Navigates to the "Orders" page.
2. Retrieves the user's order history from the database.


3. Rendering a list sorted by the most recent updates.
5. Scrolls through the list or applies a basic status filter (e.g., Pending, Completed).
4. Displays the current status of each order (e.g., Pending, Scheduled).
6. Clicks on a specific order card to view its details.
7. Routes the user to the Order Details interface.
   Alternative Flow
   A1: Zero Orders Found (Step 2)
   A1.1 The user has no active or past transactions.

The system halts the list rendering. UI renders a friendly empty state (e.g., "You don't have any orders yet."). The system provides a "Start Browsing" button routing back to the Home or Search page.
Post-condition
The user successfully tracks their order progress and navigates to a specific order for further details.

Table 3.19: UC18-View My Orders

Use Case ID
UC19
Use Case Name
Update Order Progression
Objectives
To securely advance an order through mutual confirmations, ensuring the Seller verifies the Buyer's payment before finalizing the transaction.
Actor / Activator
Student (Buyer or Seller)
Pre-condition
The user accesses a specific active order via the Order Dashboard.
Basic Flows
Actor Action
System Response
1. Views the order details and clicks the corresponding progression button.
2. Verifies the user's role and current order status.

[If Pending & Actor is Seller]: Updates status to Scheduled and skips to Step 6.
3. [If Buyer]: Uploads the cashless receipt (or checks the cash declaration) and clicks "Submit Payment".
4. Validates the proof and updates the order status from Scheduled to To Confirm. Notifies the Seller to check their account.
5. [If Seller]: Reviews the Buyer's payment proof, verifies actual receipt of funds/cash, and clicks "Confirm & Complete".
6. Updates the order status to Completed, permanently marks the Item as Sold, and logs the timestamp.
   Alternative Flow
   A1: Missing Proof (Step 4)
   A1.1 The Buyer fails to provide the required payment confirmation.

The system halts the submission. Error message displays an inline alert: "Please provide the payment proof". The system waits for the user to upload the image or check the box.
A2: Payment Not Received / Fake Proof (Step 5)
A2.1 The Seller reviews the proof but did not actually receive the money.

The system halts the completion process. UI provides a "Report Issue" button for the Seller. Triggers UC22 Flag Transaction for Dispute to freeze the order and summon a Moderator.
Post-condition
The order successfully advances based on mutual agreement. If completed, the item is marked as Sold.

Table 3.20: UC19-Update Order Progression

Use Case ID
UC20
Use Case Name
Submit Mutual Review
Objectives
To allow users to rate their transaction experience using a "Blind Review" system, ensuring honest feedback and preventing retaliatory ratings.
Actor / Activator
Student (Buyer or Seller)
Pre-condition
The order status is Completed, and the student has not yet reviewed this transaction.
Basic Flows
Actor Action
System Response
1. Clicks the "Leave Review" button on a completed order.
2. Verifies eligibility (ensures no duplicate reviews) and renders the Review Form.
3. Selects a mandatory star rating (1 to 5), inputs optional text feedback, and clicks "Submit".
4. Validates the input and saves the review locally with a Hidden status.


5. Checks if the counterparty has already submitted their review.


6. [If Both Submitted]: Changes both reviews to Published, recalculates both users' overall average ratings, and notifies them.
   Alternative Flow
   A1: Awaiting Counterparty (Step 5)
   A1.1 The user submits their review, but the other party hasn't reviewed yet.

The system halts publication to enforce the blind review policy. UI shows a success toast: "Review saved! It will be published once the other party reviews, or after 14 days". The system keeps the review hidden.
A2: Missing Star Rating (Step 4)
A2.1 The user attempts to submit the form without selecting a star rating.

The halts the submission. Error message highlights the star component in red: "Please select a rating from 1 to 5 stars". The system waits for the user to select a rating.
Post-condition
The review is recorded. If both parties have reviewed, the feedback is published on their respective public profiles.

Table 3.21: UC20-Submit Mutual Review

Use Case ID
UC21
Use Case Name
Cancel Active Order
Objectives
To allow users to abort an ongoing transaction gracefully, ensuring locked items are released back to the market while preventing cancellations during the payment-verification phase.
Actor / Activator
Student (Buyer or Seller)
Pre-condition
The user accesses a specific active order (Pending or Scheduled) via the Order Dashboard.
Basic Flows
Actor Action
System Response
1. Views the order details and clicks the "Cancel Order" button.
2. Verifies the order status is eligible for cancellation (must be Pending or Scheduled) and renders the Cancellation Reason prompt.
3. Selects a mandatory cancellation reason from a dropdown (e.g., "Change of mind", "Seller unresponsive") and clicks "Confirm Cancel".
4. Updates the Order status to Cancelled.


5. Reverts the associated Item's status from Reserved back to Active.


6. Logs the cancellation reason, notifies the counterparty, and refreshes the UI.
   Alternative Flow
   A1: Ineligible Status / Payment Pending (Step 2)
   A1.1 The user attempts to cancel, but the order has progressed to To Confirm (payment submitted) or Completed.

The system blocks the cancellation to prevent fraud. Error message displays an alert: "Order cannot be cancelled after payment is submitted. Please use the 'Report Issue' option". The system hides the Cancel button and routes the user to UC22 Flag Transaction for Dispute.
A2: Status Desync / Already Cancelled (Step 2)
A2.1 The counterparty cancelled the exact same order milliseconds earlier.

The system halts the cancellation process. Error message displays an alert: "This order has already been cancelled by the other party". The system refreshes the dashboard to reflect the updated Cancelled state.
Post-condition
The transaction is aborted, the counterparty is notified, and the item becomes available (Active) for other buyers again.

Table 3.22: UC21-Cancel Active Order

Use Case ID
UC22
Use Case Name
Flag Transaction for Dispute
Objectives
To allow users to formally escalate a problematic transaction, freezing the order status and submitting evidence for Moderator arbitration.
Actor / Activator
Student (Buyer or Seller)
Pre-condition
The user accesses a specific order that is either active or recently completed.
Basic Flows
Actor Action
System Response
1. Clicks the "Report Issue / Dispute" button on the order details page.
2. Verifies the order is eligible for a dispute (checks status and time window) and renders the Dispute Submission Form.
3. Selects a mandatory dispute reason (e.g., "Item not received", "Item damaged", "Fake payment proof"), writes a detailed description, uploads mandatory evidence images, and clicks "Submit Dispute".
4. Validates that all mandatory fields and evidence uploads are provided.


5. Updates the Order status to Disputed (freezing all further user actions).


6. Generates a new Dispute Ticket in the Moderator's queue UC23.


7. Triggers a high-priority warning notification to the counterparty and refreshes the UI.
   Alternative Flow
   A1: Missing Evidence / Details (Step 4)
   A1.1 The user attempts to submit without uploading photo evidence or selecting a reason.

The system halts the submission to prevent baseless claims. Error message highlights the missing fields: "Please provide a reason and upload photo/screenshot evidence to support your claim". The system waits for the user to complete the form.
A2: Protection Window Expired (Step 2)
A2.1 The user attempts to dispute an order that was marked Completed more than 3 days ago.

The system blocks the dispute initiation. Error message displays an alert: "The 3-day buyer/seller protection window for this transaction has expired". The system hides the Dispute button and suggests contacting the counterparty directly via Chat.
Post-condition
The order is frozen as Disputed, the counterparty is alerted, and the case is forwarded to a Moderator.

Table 3.23: UC22-Flag Transaction for Dispute

Use Case ID
UC23
Use Case Name
Handle Dispute (First Line)
Objectives
To perform initial triage on new dispute tickets, filter out baseless claims, and request counter-evidence from the defending party before any final arbitration.
Actor / Activator
Moderator (First Line Support)
Pre-condition
A user has submitted a dispute, creating a ticket with the status New.
Basic Flows
Actor Action
System Response
1. Accesses the Moderation Dashboard and selects a New dispute ticket.
2. Renders the "Dispute Workspace" (displaying the order details, the complainant's reason, and uploaded evidence side-by-side).
3. Evaluates the complainant's evidence and clicks "Request Counter-Evidence" to give the defending party a chance to respond.
4. Updates the dispute ticket status to Investigating (or Awaiting Seller/Buyer).


5. Sends an automated system notice to the defending party, requiring them to upload their proof within 48 hours.


6. Refreshes the Moderator's queue.
   Alternative Flow
   A1: Baseless / Invalid Dispute (Step 3)
   A1.1 The Moderator determines the claim is clearly invalid (e.g., complaining about a flaw that was explicitly stated in the item description).

The system aborts the evidence-gathering process. The Moderator clicks "Dismiss Dispute". The system updates the ticket to Closed (Invalid). Reverts the Order status from Disputed back to its previous state, releasing the freeze.
A2: Immediate Escalation (Step 3)
A2.1 The evidence shows a severe, clear-cut violation (e.g., undeniable proof of a scam or prohibited item).

The system bypasses the counter-evidence wait time. The Moderator clicks "Escalate to Final". The system triggers UC24 Arbitrate Dispute immediately to issue refunds or bans.
Post-condition
The ticket is either dismissed, escalated, or successfully transitions into the Investigating phase awaiting the other party's response.

Table 3.24: UC23-Handle Dispute (First Line)

Use Case ID
UC24
Use Case Name
Arbitrate Dispute (Final)
Objectives
To allow the Administrator to issue a final verdict on escalated disputes, enforcing platform policies through account penalties rather than direct financial routing.
Actor / Activator
Administrator
Pre-condition
A dispute ticket has been escalated to Final Arbitration, and all available evidence has been gathered.
Basic Flows
Actor Action
System Response
1. Accesses the Admin Dashboard and selects an Escalated dispute ticket.
2. Retrieves and displays the complete case history, including both parties' evidence, previous Moderator notes, and user violation histories.
3. Selects a final verdict ("Rule in favor of Buyer" or "Rule in favor of Seller"), selects an enforcement action (e.g., Warning, 7-Day Suspension, Permanent Ban), inputs a final remark, and clicks "Execute Verdict".
4. Updates the dispute ticket to Resolved.


5. Updates the targeted User's account status based on the selected penalty (e.g., changes user.status to Banned).


6. Resolves the frozen Order Status based on the verdict.


7. Sends the final, unappealable verdict notification to both parties and refreshes the dashboard.
   Alternative Flow
   A1: Verdict Favors Buyer (Seller Fault / Scam) (Step 6)
   A1.1 The Admin determines the Seller is at fault (e.g., fake item, no delivery).

The system executes a "Buyer Protection" workflow. Updates the Order status from Disputed to Cancelled (Refund Mandated). The system applies the selected penalty (e.g., Ban) to the Seller. The Buyer is instructed to report to campus authorities/police if the Seller refuses to manually refund.
A2: Verdict Favors Seller / Owner (Buyer Fault / Item Damaged) (Step 6)
A2.1 The Admin determines the Buyer is at fault (e.g., damaged rental item, fake payment proof).

The system executes a "Seller Protection" workflow. Updates the Order status from Disputed to Completed (Resolved). For rentals, officially records that the Owner is authorized to forfeit the deposit. The system applies the selected penalty (e.g., Warning/Suspension) to the Buyer.
Post-condition
The dispute is permanently closed, appropriate account penalties are applied, and the order is unfrozen into its final state.

Table 3.25: UC24-Flag Transaction for Dispute
Sub-System 5: Campus Communication & Coordination
Use Case ID
UC25
Use Case Name
Send In-App Message
Objectives
To enable real-time, context-aware communication between users, featuring the ability to share designated "Safe Meetup Zones" for secure offline transactions.
Actor / Activator
Student
Pre-condition
The user accesses the Chat interface via a specific Listing, an Order, or the Inbox.
Basic Flows
Actor Action
System Response
1. Opens the chat room with a specific user.
2. Loads the chat history and dynamically renders a Context Card (Listing/Order info) at the top of the UI.
3. Inputs text, attaches an image, OR clicks the "Safe Meetup" icon to select a predefined campus safe zone (e.g., Library, Guard House) from an in-app map/list. Clicks "Send".
4. Validates the input payload (e.g., ensures text is not empty, image size is within limits, or location coordinates are valid).


5. Persists the message in the database, pushes the payload to the Receiver via Notifications.


6. Renders the message in the Sender's UI as a text bubble, image, or interactive Map Card, marked with a Sent status.
   Alternative Flow
   A1: Network Failure / Timeout (Step 5)
   A1.1 The system fails to connect to the server or times out during sending.

The system halts the sending process. UI displays the message bubble with a red Failed to send icon. The system provides a "Tap to Retry" action for the user.
A2: Action Blocked / Suspended User (Step 2)
A2.1 The Sender attempts to message a user who is currently banned or suspended.

The system disables the chat input area. Error message displays an inline alert: "You cannot reply to this conversation. The user is no longer active". The system hides the keyboard and prevents submission.
A3: Location Service Denied (Step 3)
A3.1 The user tries to share a live location or open the map, but device location permissions are denied.

The system intercepts the map initialization. Error message prompts an OS-level alert: "Please enable location services to share meetup spots". The system allows the user to select from a static text list of safe zones instead.
Post-condition
The message or safe zone location is successfully saved, displayed, and routed to the Receiver.

Table 3.26: UC25-Send In-App Message

Use Case ID
UC26
Use Case Name
Receive System Notification
Objectives
To deliver real-time, actionable alerts (chat, order updates, disputes) to the user's device and seamlessly route them to the specific module via Deep Linking.
Actor / Activator
Student
Pre-condition
An internal system event (e.g., incoming message, order update) generates a notification payload directed at the user.
Basic Flows
Actor Action
System Response
2. Hears the alert or sees the banner/badge, and taps on the notification.
1. Generates a formatted Push Payload containing the message title, body, and a target_route_id (Deep Link). Pushes the payload to the user's device.
4. Interacts with the specific target page.
3. Intercepts the user's tap action, clears the notification badge, reads the target_route_id, and dynamically routes the user to the exact destination (e.g., Specific Chat Room, Order Details, or Dispute Workspace).
   Alternative Flow
   A1: App in Background / Device Locked (Step 1)
   A1.1 The payload arrives while the user is not actively using the app.

The system delegates display to the Operating System (OS). The OS renders a standard push notification banner on the lock screen or notification tray. The deep link remains intact for when the user taps it later.
A2: OS Notification Permissions Denied (Step 1)
A2.1 The user has disabled push notifications for the app in their phone settings.

The system bypasses OS-level push alerts (Silent Delivery). Saves the notification strictly to the "In-App Notification Center" database. Updates the red unread badge icon within the app's navigation bar for the user to discover manually.
A3: Invalid or Expired Deep Link (Step 3)
A3.1 The user taps a notification for an item/order that was deleted or resolved days ago.

The system halts the deep link routing to prevent crashes. Error message displays an in-app toast: "This content is no longer available or has been updated". The system routes the user safely to the generic "Notification Center" or Home screen.
Post-condition
The user is successfully alerted of the event and navigated to the relevant contextual screen.

Table 3.27: UC26-Receive System Notification

Use Case ID
UC27
Use Case Name
Submit Support Ticket
Objectives
To allow users to seek assistance from platform Moderators for non-transactional issues (e.g., account problems, bugs, general inquiries) via a structured ticketing system.
Actor / Activator
Student
Pre-condition
The user accesses the platform's "Help Center".
Basic Flows
Actor Action
System Response
1. Browses the Help Center (FAQs) and clicks the "Contact Support / Submit a Ticket" button.
2. Verifies the user has not exceeded the spam limit for active tickets, then renders the Support Ticket Form.
3. Selects a mandatory Issue Category (e.g., Account, Bug, Harassment, General), writes a subject and description, attaches optional screenshots, and clicks "Submit".
4. Validates that all mandatory fields are filled.


5. Generates a unique Ticket ID and saves the record to the database with the status Open.


6. Routes the ticket to the Moderator's queue, triggers a confirmation notification to the user, and redirects them to the "My Tickets" page.
   Alternative Flow
   A1: Mandatory Fields Empty (Step 4)
   A1.1 The user attempts to submit without selecting a category or providing a description.

The system halts the submission. Error message highlights the missing fields in red: "Please select a category and describe your issue". The system waits for the user to complete the form.
A2: Active Ticket Limit Reached (Step 2)
A2.1 The user already has 3 Open tickets pending in the system.

The system blocks the creation of a new ticket to prevent support spam. Error message displays an alert: "You have reached the maximum number of open tickets. Please wait for our team to resolve your current issues". The system redirects the user to view their existing tickets.
Post-condition
A new support ticket is created, assigned a unique ID, and placed in the Moderator's queue.

Table 3.28: UC27-Submit Support Ticket (Q&A)

Use Case ID
UC28
Use Case Name
Respond to Support Ticket
Objectives
To allow Moderators to review, reply to, and resolve user support inquiries through a structured dashboard, seamlessly bridging the backend ticketing system with the user's frontend Inbox.
Actor / Activator
Moderator (Support Staff)
Pre-condition
The Moderator accesses the Support Dashboard.
Basic Flows
Actor Action
System Response
1. Views the active ticket queue.
2. Retrieves the list of open tickets, visually flagging any tickets currently locked/being viewed by other Moderators.
3. Selects an available Open ticket.
4. Verifies the ticket is not locked by another session, applies a temporary lock for the current Moderator, and renders the Reply Form.
5. Reviews the issue, inputs a reply, selects a status (e.g., Resolved), and clicks "Send Reply".
6. Saves the reply, updates the ticket status, and injects the message into the user's frontend Inbox.


7. Releases the temporary lock and refreshes the queue.
   Alternative Flow
   A1: Ticket Collision / Already Handled (Step 4)
   A1.1 Another Moderator has just opened and started replying to the exact same ticket.

The system blocks the ticket access. Error message displays an alert: "This ticket is currently being handled by another Moderator". The system redirects the user back to the main queue to select a different ticket.
A2: Ticket Escalation (Step 5)
A2.1 The Moderator determines the issue requires Admin privileges (e.g., data deletion).

The system bypasses the user reply mechanism. Updates the ticket status to Escalated and transfers it to the Admin queue. Releases the lock and redirects the Moderator back to the dashboard to select another ticket.
Post-condition
The ticket is answered/escalated, the lock is released, and the user receives the reply.

Table 3.29: UC28-Respond to Support Ticket
Sub-System 6: Platform Administration & Oversight
Use Case ID
UC29
Use Case Name
Monitor System Metrics
Objectives
To provide a real-time dashboard for tracking key platform metrics. It highlights user activities, transaction volumes, and total carbon emissions saved.
Actor / Activator
Administrator
Pre-condition
The Administrator is authenticated and accesses the Admin Dashboard.
Basic Flows
Actor Action
System Response
1. Navigates to the "System Metrics" module.
2. Retrieves aggregated KPIs from the database and renders the default dashboard, prominently displaying the Total Carbon Saved alongside standard metrics.
3. Selects a specific date range or data filter, and clicks "Apply".
4. Queries the database using the new parameters, applies the Carbon Calculation Formula, and updates the charts dynamically.
   Alternative Flow
   A1: No Data Available (Step 2 or 4)
   A1.1 The Admin selects a filter with no transaction records.

The system skips chart generation. UI renders an empty state visual (e.g., "No data found") with values set to zero. The system allows the Admin to clear filters.
A2: Query Timeout (Step 4)
A2.1 The system attempts to process an overly large dataset (e.g., "All Time").

The system halts data visualization. Error message displays a toast: "Data retrieval timeout. Please narrow your search". The system prompts the Admin to select a shorter date range.
Post-condition
The Administrator successfully reviews the platform's operational and sustainability data.

Table 3.30: UC29-Monitor System Metrics

Use Case ID
UC30
Use Case Name
Generate Platform Report
Objectives
To allow the Administrator to compile and export formal platform performance and sustainability reports (PDF/CSV) based on a specified date range.
Actor / Activator
Administrator
Pre-condition
The Administrator is authenticated and accesses the Admin Web Portal.
Basic Flows
Actor Action
System Response
1. Navigates to the "Reports" module.
2. Renders the Report Generator form.
3. Selects a specific Date Range (e.g., Last Quarter, Academic Semester) and the Export Format (PDF or CSV), then clicks "Generate & Export".
4. Queries the database and aggregates the platform's data (transaction volumes, active users, total carbon saved) for the requested period.


5. Compiles the data into the selected file format and triggers a browser file download.


6. Displays a "Download Successful" toast notification.
   Alternative Flow
   A1: No Data Available (Step 4)
   A1.1 The query returns zero records for the selected date range.

The system halts document generation. Error message displays an alert: "No activity recorded for this period. Report not generated.". The system allows the Admin to adjust the date filter.
A2: Generation Timeout / File Too Large (Step 5)
A2.1 The server takes too long to compile a massive CSV file.

The system aborts the download process. Error message: Displays an alert: "Dataset too large. Please select a shorter date range (maximum 1 year).". The system prompts the Admin to narrow the search scope.
Post-condition
A comprehensive report file is successfully downloaded to the Administrator's local device.

Table 3.31: UC30-Generate Platform Report

Use Case ID
UC31
Use Case Name
Backup & Restore Data
Objectives
To provide the Administrator with a basic tool to download a copy of the system data and upload it for recovery purposes.
Actor / Activator
Administrator
Pre-condition
The Administrator accesses the "Data Management" page in the Admin Web Portal.
Basic Flows
Actor Action
System Response
1. Navigates to the Data Management page.
2. Renders the Backup/Restore UI with two primary buttons.
3. [For Backup]: Clicks "Download Backup".
4. Compiles the database records into a single file and triggers a browser download. (Process ends).
5. [For Restore]: Clicks "Upload Backup", selects a previously downloaded data file (e.g., JSON/SQL), and clicks "Confirm Restore".
6. Validates the uploaded file format.


7. Overwrites the database with the file's contents and displays a "Restore Successful" toast message.
   Alternative Flow
   A1: Invalid File Format (Step 6)
   A1.1 The Admin attempts to upload a non-data file (e.g., an image or PDF) for the restore process.

The system rejects the file upload. Error message displays an alert: "Invalid file type. Please upload a valid JSON or SQL backup file.". The system aborts the restore and waits for the correct file.
Post-condition
The system data is either successfully downloaded to the Admin's device or successfully restored from an uploaded file.

Table 3.32: UC31-Backup & Restore Data
Activity Diagram
Sub-System 1: Identity & Account Management

Figure 3.29: UC01-Register Account Activity Diagram

Figure 3.30: UC02-View User Profile & Reputation Activity Diagram

Figure 3.31: UC03-View Sustainability Dashboard Activity Diagram

Figure 3.32: UC04-Update Profile Data Activity Diagram

Figure 3.33: UC05-Deactivate Account Activity Diagram

Figure 3.34: UC06-Manage User Account Activity Diagram
Sub-System 2: Catalog & Inventory Administration

Figure 3.35: UC07-Create Product Listing Activity Diagram

Figure 3.36: UC08-View My Inventory Activity Diagram

Figure 3.37: UC09-Update Listing Details Activity Diagram

Figure 3.38: UC10-Remove / Suspend Listing Activity Diagram

Figure 3.39: UC11-Report Listing Activity Diagram

Figure 3.40: UC12-Review Reported Listings Activity Diagram
Sub-System 3: Item Discovery & Smart Recommendation

Figure 3.41: UC13-Search and Filter Listings Activity Diagram

Figure 3.42: UC14-View Trending Discoveries Activity Diagram

Figure 3.43: UC15-Generate Personalized Feed Activity Diagram

Figure 3.44: UC16-View Listing Details Activity Diagram
Sub-System 4: Order Fulfillment & Feedback System

Figure 3.45: UC17-Initiate Order / Rental Request Activity Diagram

Figure 3.46: UC18-View My Orders Activity Diagram

Figure 3.47: UC19-Update Order Progression Activity Diagram

Figure 3.48: UC20-Submit Mutual Review Activity Diagram

Figure 3.49: UC21-Cancel Active Order Activity Diagram

Figure 3.50: UC22-Flag Transaction for Dispute Activity Diagram

Figure 3.51: UC23-Handle Dispute (First Line) Activity Diagram

Figure 3.52: UC24-Arbitrate Dispute (Final) Activity Diagram
Sub-System 5: Campus Communication & Coordination

Figure 3.53: UC25-Send In-App Message Activity Diagram

Figure 3.54: UC26-Receive System Notification Activity Diagram

Figure 3.55: UC27-Submit Support Ticket Activity Diagram

Figure 3.56: UC28-Respond to Support Ticket Activity Diagram
Sub-System 6: Platform Administration & Oversight

Figure 3.57: UC29-Monitor System Metrics Activity Diagram

Figure 3.58: UC30-Generate Platform Report Activity Diagram

Figure 3.59: UC31-Backup & Restore Data Activity Diagram
Functional Requirement and Non-functional Requirement
Functional Requirement

Sub-System
Requirement ID
Use Case ID
Functional Requirement
SS-1: Identity & Profile
FR1.1
UC01
The system shall strictly validate user registration inputs, allowing only emails terminating in the approved university domain (e.g., .edu.my).


FR1.2
UC01
The system shall generate, dispatch, and verify One-Time Passwords (OTPs) via email for account activation and password recovery.


FR1.3
UC01
The system shall enforce strict client-side format validation for all registration fields (e.g., password complexity, university ID structure) before submitting data to the server.


FR1.4
UC01
The system shall automatically format localized phone numbers during user input to maintain standardized contact records.


FR1.5
UC02
The system shall visibly display individual reputation scores calculated dynamically from historical transaction reviews.


FR1.6
UC03
The system shall formulate and maintain a Sustainability Dashboard on user profiles, calculating equivalent "Carbon Savings" based on successful secondhand purchases.
SS-2: Catalog & Inventory
FR2.1
UC07, UC09
The system shall support the upload, compression, and cloud retrieval of multiple item images per product listing.


FR2.2
UC07
The system shall feature an automated image analysis capability to suggest relevant product categories based on uploaded photos.


FR2.3
UC07
The system shall provide a manual fallback mechanism for product categorization in the event that the automated image analysis service is unresponsive.


FR2.4
UC07, UC19, UC21
The system shall strictly manage inventory states, automatically transitioning items between Active, Reserved, and Sold based on order progression, and reverting to Active upon order cancellation.
SS-3: Discovery & ML Engine
FR3.1
UC13
The system shall implement a search engine supporting text-indexing for titles/descriptions and dynamic frontend filters (Category, Condition, Price Range).


FR3.2
UC14
The system shall process content item tags and user viewing history to generate relevance scores (e.g., Content-based filtering).


FR3.3
UC14
The system shall populate a personalized "For You" feed prioritizing active listings that possess the highest correlation scores with the authenticated user.


FR3.4
UC13
The system shall prioritize and display items in the personalized "For You" feed that have the highest correlation scores with the authenticated user profile.
SS-4: Order Fulfillment
FR4.1
UC17, UC19, UC21, UC22
The system shall execute a state machine for transactions utilizing distinct statuses: Pending, Scheduled, To Confirm, Completed, Cancelled, and Disputed.


FR4.2
UC17
The system shall render a Dynamic Order Form adapting to the Listing Type (Sale vs. Rental), automatically calculating rental durations and required deposits.


FR4.3
UC17
The system shall perform a backend Concurrency Check (Race Condition prevention) during order submission to ensure the item is still Active before creating the order.


FR4.4
UC19
The system shall enforce a mandatory Payment Proof mechanism, requiring image uploads for cashless transfers or explicit checkbox declarations for cash before marking an order as Completed.


FR4.5
UC20
The system shall implement a Blind Review mechanism, keeping submitted 1-5 star ratings and feedback hidden until both parties have reviewed, or until a 14-day timeout expires.
SS-5: Communication
FR5.1
UC25
The system shall generate context-aware chat rooms that dynamically embed an interactive "Context Card" representing the specific Listing or Order being discussed.


FR5.2
UC25
The system shall integrate a Location/Map component allowing users to securely select and share predefined "Safe Meetup Zones" within the chat interface.


FR5.3
UC26
The system shall dispatch real-time Push Notifications containing embedded Deep Links, seamlessly routing users to the specific chat room or order details page upon tapping.


FR5.4
UC27, UC28
The system shall manage support inquiries via asynchronous ticketing, applying Pessimistic Concurrency Locks to prevent multiple moderators from responding to the same ticket simultaneously.
SS-6: Admin Oversight
FR6.1
UC22, UC23, UC24
The system shall execute a dispute workflow that instantly freezes the order status and enforces account penalties (Warnings/Bans) rather than direct financial reversals, via a First-Line triage and Final Admin verdict.


FR6.2
UC29
The system shall aggregate platform metrics and calculate the Total Carbon Emissions Saved using predefined environmental conversion factors assigned to item categories.


FR6.3
UC30
The system shall compile aggregated platform data (transactions, active users, carbon metrics) and trigger a client-side download of a formatted report (PDF or CSV) based on Admin-specified date ranges.


FR6.4
UC31
The system shall provide a secure data management interface enabling the Administrator to export database snapshots (JSON/SQL) and upload files for manual data recovery.

Table 3.33: Functional Requirements
Non-functional Requirement

Quality Attribute
Requirement ID
Non-Functional Requirement
Security
NFR1.1
The system shall strictly utilize industry-standard cryptographic hashing and stateless JWT (JSON Web Tokens) for session management, ensuring unauthorized access is mathematically unfeasible.


NFR1.2
The system shall encrypt all In-App Messaging payloads (WSS/HTTPS) and structurally restrict the display of external contact numbers, enforcing communication within the .edu.my boundary.


NFR1.3
The system shall emphatically act only as an "Information Ledger" and shall not store, process, or route real-currency financial details (Credit Cards/Bank Acc), mitigating catastrophic financial data breaches.
Usability
NFR2.1
The system shall dynamically retain all valid user inputs (State Management) during a form submission failure, particularly for complex Listing Uploads and Dispute submissions.




The system shall intercept all raw backend database exceptions and translate them into actionable, user-friendly UI prompts (e.g., Toast notifications).




The system shall render the Interactive Safe Meetup Map with optimized touch-target sizes and intuitive mobile gestures (pinch-to-zoom, tap-to-pin) to ensure accessibility on all mobile device screens.
Performance
NFR3.1
The system shall execute standard catalog searches and render filtered results within 2 seconds, and resolve complex JSON responses from the ML Recommendation engine within 3 seconds under normal 4G/WiFi conditions.


NFR3.2
The system shall rigorously enforce referential integrity constraints to completely eliminate orphaned records, particularly safeguarding the Mutual Rating data.

Table 3.34: Non-Functional Requirements
Chapter Summary and Evaluation
This chapter successfully established the comprehensive architectural blueprint and system specifications for the proposed Smart Campus Second-Hand Trading Platform. The chapter commenced by justifying the Iterative Development Methodology, structuring the project into four distinct, risk-driven cycles to systematically integrate complex technologies like Flutter, Node.js, and a Python Machine Learning microservice. An empirical foundation was then laid through Observational Analysis of existing platforms and a Quantitative Survey of 52 target users. This research identified critical market frictions—specifically, severe security anxieties (86.5% fearing scams), privacy concerns (94.2% demanding in-app chat), and logistical hurdles. Driven directly by these insights, the system was logically decomposed, culminating in detailed Use Case Diagrams, 31 formalized Use Case Descriptions, and corresponding Activity Diagrams. Finally, these functional designs were translated into rigorous Functional Requirements (FR) and mapped to core Non-Functional Requirement (NFR) quality attributes focusing on Security, Usability, and Performance.
Based on thorough analysis, the new system design has established a deep data-driven connection between pre-existing user pain points, and therefore supports evidence of good product or market fit. Unlike traditional e-commerce models, this architecture has been designed to proactively remediate identified risk factors within the framework. The decision to enforce mandatory .edu.my registration and encrypted in-app messaging directly resolves the overwhelming user demand for privacy and verified identities. Furthermore, the integration of an "Interactive Safe Meetup Map" transforms a standard software usability metric into a physical safety feature, addressing the logistical hesitation expressed by 77% of respondents.
In order to ensure quality development of the platform’s three major functional components (i.e., transactions/security, machine learning based discovery and sustainability dashboard), the architectural scope for this project has been determined based on a practical engineering approach of limiting the initial implementation of these three components within a single campus minimum viable product (MVP) instead of potentially accelerating the overall implementation via multiple campuses. The functional specifications and theoretical requirements documented for these three components provide solid foundations for moving into the next phase of System Design. The next chapter will describe how the functional requirements will be converted to technical requirements to form the system architecture includes the required database structures.
