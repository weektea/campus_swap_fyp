🎨 Global Style Guideline (全局样式要求)
建议在 Figma AI 的每一次 Prompt 开头都带上这一段，确保整套 App 风格一致。
Style: Modern, clean, and minimalist mobile app UI. Eco-friendly campus theme.
Colors: Primary color is deep forest green (e.g., #005A43). Background is off-white or light warm beige. Text is dark gray for high readability. Shapes: Soft rounded corners for all input fields, buttons, and cards (border-radius: 12px). Typography: Clean sans-serif font (like Inter or Roboto), clear hierarchy.

📱 Prompt 1: UI 1.1 - Standard Login Screen
这是正常状态的登录界面，基于你早期原型的布局 。
Copy & Paste this into Figma AI:
Design a mobile login screen for a campus marketplace app called "Campus Swap". Use the Global Style (deep forest green primary color, rounded corners, clean sans-serif).
Layout & Elements:
Header: A simple leaf icon logo centered at the top. Below it, a bold title "Campus Swap" and a smaller subtitle "Trade Smarter, Live Greener".
Form Fields: Two input fields. The first is "Student ID" with an ID card icon inside the field. The second is "Password" with a lock icon on the left and a hide/show eye icon on the right. 3. Options: Below the password field, a "Remember Me" checkbox on the left , and a "Forgot Password?" text link on the right (colored in deep green). 4. Primary Action: A full-width, solid deep green button labeled "Login". 5. Footer: Centered text at the bottom saying "New to Campus Swap? Register Now" where "Register Now" is bold and clickable.

📱 Prompt 2: UI 1.1 - Banned / Suspended Alert State
这是触发状态机拦截时的 UI，展示覆盖在登录页上方的底部弹窗 (Bottom Sheet)。
Copy & Paste this into Figma AI:
Design a mobile UI showing an error state using a Bottom Sheet modal. Use the Global Style.
Layout & Elements:
Background: The login screen from the previous prompt, but covered with a 40% dark transparent overlay to indicate it's inactive.
Bottom Sheet: A white, rounded container sliding up from the bottom of the screen.
Modal Header: A prominent warning icon (red or dark yellow) centered at the top of the sheet, followed by a bold red title "Account Suspended".
Message Text: A brief explanation: "Your account has been restricted due to a violation of our community guidelines."
Data Card: A light gray rounded box containing two rows of data: "Reason: Fraudulent Activity" and "Unban Date: Dec 31, 2024".
Actions: Two full-width buttons. The top button is a solid deep green button labeled "Contact Support" (to appeal). The bottom button is a subtle, transparent text button labeled "Dismiss" or "Cancel".
🎨 Figma AI Prompt (UI 1.2 注册页)
拿着这段 Prompt 去 Figma AI 生成，它能精准理解你想要的“悬浮标签”风格：
Copy & Paste this into Figma AI:
Design a mobile registration screen for a campus marketplace app called "Campus Swap". Use the Global Style.
Layout & Elements:
Header: A top app bar with a left-facing arrow icon for "Back" and the title "Create Account" centered.
Form Fields (CRITICAL STYLE): All input fields MUST use the "Material Design Outlined Text Field with Floating Labels" style. The label (title) should sit directly on the top border of the input box like a fieldset legend, so it is never hidden when the user types.
The Fields:
"Full Name"
"University ID"
"Phone Number"
"Student Email". Show this specific field in an Error State: The outline is red, the typed text is "student@gmail.com", and there is small red helper text below saying "Must use a valid university email (.edu.my)".
"Password" (with a hide/show eye icon).
"Confirm Password".
Primary Action: A full-width, solid deep green button labeled "Register" fixed near the bottom. It should look disabled (slightly faded) because of the email error above.
🎨 升级版 Figma AI Prompt (UI 2.1 首页/推荐流)
我已经将隐藏滚动条和优化横向滑动的细节加进去了，你复制这段全新的 Prompt 去 Figma AI 生成：
Copy & Paste this into Figma AI:
Design a mobile home screen feed for a campus marketplace app called "Campus Swap". Use the Global Style (deep forest green primary color, rounded corners, clean sans-serif).
Layout & Elements:
Header: At the top, simple text "Welcome Back, Alex". Below it, a large, rounded search bar with a magnifying glass icon and the placeholder "Search books, electronics...". On the right side of the search bar, include an icon for advanced filters.
Categories (Horizontal Scroll without Scrollbar): Below the search, a horizontal scrolling row of pill-shaped buttons: "All" (active state, deep green), "Books", "Electronics", "Furniture". CRITICAL: Hide the horizontal scrollbar. Make the last button partially cut off at the edge of the screen to indicate it's scrollable.
Trending Section (Horizontal Carousel): A section title "🔥 Trending on Campus". Below it, a horizontal scrolling carousel of square product cards. CRITICAL: Hide the horizontal scrollbar. Make the last card partially cut off. Each card has an image of a laptop or bicycle, title, price, and a small tag saying "Highly Viewed".
Personalized Feed (Vertical Grid): A section title "✨ For You". Below it, a 2-column grid of product cards.
Product Card Design: Each card in the grid must feature: A square image of a used item (e.g., a chair or textbook), a heart icon in the top right corner, a bold price like "RM 45.00", a title "Wooden Chair", a condition tag "Good", and the seller's handle "@student_name" at the very bottom.
Bottom Navigation: A fixed bar at the bottom with 5 icons: Home (active), Chat, a prominent circular "+" button in the center for "Sell", Saved, and Profile.
🎨 Figma AI Prompt (UI 2.2 搜索与筛选面板)
你可以直接复制下面这段精心打磨的 Prompt 去 Figma AI 生成。它能完美还原带有复杂表单控件的弹窗：
Copy & Paste this into Figma AI:
Design a mobile UI showing an advanced filter panel using a Bottom Sheet modal for a campus marketplace app called "Campus Swap". Use the Global Style (deep forest green primary color, rounded corners, clean sans-serif).
Layout & Elements:
Background: A search results page visible in the background, covered by a 40% dark overlay.
Bottom Sheet Container: A white container with rounded top corners sliding up from the bottom, filling about 60% of the screen.
Modal Header: A small pill-shaped drag handle at the top center. Below it, a bold title "Filter & Sort" on the left, and a green text link "Reset" on the right.
Price Range Section (CRITICAL): A subtitle "Price Range (RM)". Below it, place two text input fields side-by-side: "Min: 0" and "Max: 150". Below the inputs, draw a dual-thumb range slider (a horizontal line with two circular handles). The line between the two handles should be highlighted in deep green.
Item Condition Section: A subtitle "Condition". Below it, a grid of pill-shaped tags: "Any" (Active state, solid deep green with a checkmark icon), "New", "Like New", "Good", "Fair", "Poor" (Inactive states, white background with a grey outline).
Sort By Section: A subtitle "Sort By". Below it, three radio button options stacked vertically: "Newest Listed" (selected state), "Price: Low to High", "Price: High to Low".
Footer Action: A fixed full-width, solid deep green button labeled "Apply Filters" at the very bottom of the sheet.
🎨 Figma AI Prompt (UI 3.1 发布商品页)
你可以直接复制这段 Prompt 扔给 Figma AI。为了让 AI 生成一张足够复杂且体现技术含量的图，我特意在 Prompt 里指定了展示 "For Rent" (租赁) 状态，因为这能展示最多的底层字段！
Copy & Paste this into Figma AI:
Design a mobile "New Listing" screen for a campus marketplace app called "Campus Swap". Use the Global Style (deep forest green primary color, rounded corners, clean sans-serif).
Layout & Elements (Top to Bottom):
Header: Title "New Listing" with a back icon.
Media Dropzone: Two dashed-border square boxes side-by-side. The first says "Add Photos (Max 9)" with a camera icon. The second says "Add Video (15s)" with a video icon.
Type Toggle: A full-width segmented control switch with two options: "For Sale" and "For Rent". CRITICAL: Show "For Rent" as the ACTIVE selected state (highlighted in deep green).
Base Fields (Use Floating Labels): > - "Title" (text input)
"Condition" (dropdown, showing "Good")
Rent-Specific Dynamic Fields (CRITICAL):
"Daily Rate (RM/day)". Place a small "✨ AI Suggestion" pill button right aligned above this input.
"Security Deposit (RM)"
"Max Rental Duration (Days)"
Description Area: A large, tall text area for "Description". Inside the bottom-right corner of this text area, place a prominent floating button labeled "✨ AI Auto-Write".
Footer Action: A full-width, solid deep green button "Publish Listing" fixed at the bottom.
🎨 Figma AI Prompt (UI 3.2 我的库存页)
这段 Prompt 特意要求 Figma AI 把重点放在 Tab 切换栏 和 Active 卡片的操作按钮 上。
Copy & Paste this into Figma AI:
Design a mobile "My Inventory" management dashboard for a campus marketplace app called "Campus Swap". Use the Global Style.
Layout & Elements:
Header: Title "My Inventory". In the top right corner, a plus "+" icon to add a new item. Below the title, a small summary text: "Total Earned: RM 350.00".
State Tabs: A full-width horizontal tab bar with three tabs: "Active" (currently selected, highlighted with an underline), "Reserved" (with a small notification dot), and "Suspended".
Inventory List (Vertical Scroll): Show two wide product cards stacked vertically. These represent the "Active" state.
Product Card Design (Wide Layout):
Left side: A square thumbnail of the item (e.g., a textbook or a lamp).
Right side (Top): Title "Calculus Textbook" and Price "RM 40.00".
Right side (Middle): Small gray text showing "👁️ 124 Views • ❤️ 12 Saves".
Right side (Bottom): Two outlined buttons side-by-side: "Edit" and "Delist".
Floating Action Button: In the bottom right corner of the screen, place a prominent circular floating action button (FAB) with a plus "+" icon, filled with the primary deep green color.
🎨 Figma AI Prompt (UI 3.3 编辑商品页 - 锁定演示版)
去 Figma AI 生成 UI 时，我强烈建议你生成 Locked (被锁定) 的状态。因为普通的表单很常见，但带有锁定逻辑的表单能立刻抓住评委的眼球，展现你的系统深度。
Copy & Paste this into Figma AI:
Design a mobile "Edit Listing" screen in a LOCKED state for a campus marketplace app called "Campus Swap". Use the Global Style.
Layout & Elements:
Header: Title "Edit Listing" with a back arrow icon.
Warning Banner (CRITICAL): Directly below the header, place a full-width banner with a soft yellow or light orange background. Inside, put a lock icon 🔒 and text: "Item Locked: An active transaction is in progress. Editing is disabled to protect buyer-seller integrity." Include a bold link "View Order".
Disabled Form Fields: Show a form that is filled out but visually disabled (greyed out backgrounds, lower opacity text).
A row of 3 uploaded photos (greyed out).
"Title" input containing "Calculus Textbook" (greyed out).
"Price (RM)" input containing "45.00" (greyed out).
"Description" text area containing "Used for one semester..." (greyed out).
Footer Action: Since editing is disabled, instead of a "Save" button, place a full-width, solid deep green button at the bottom labeled "View Ongoing Order".
🎨 Figma AI Prompt (UI 4.1 商品详情页 - 买家视角)
去 Figma AI 生成 UI 时，我们生成最标准、最好看的**“买家准备购买”**的状态。
Copy & Paste this into Figma AI:
Design a mobile "Product Details" screen for a campus marketplace app called "Campus Swap". Use the Global Style.
Layout & Elements (Top to Bottom):
Header: Transparent background. A left arrow icon for Back on the top left. On the top right, a Share icon and a Heart (Save) icon.
Hero Image: A large, high-quality, edge-to-edge image of a used wooden chair, taking up the top 35% of the screen.
Info Card (Overlapping the image slightly with rounded top corners):
A light green pill tag reading "FURNITURE" and grey text "70d ago" aligned right.
A massive, bold price "RM 55.00".
A bold product title "Vintage Wooden Chair".
A small tag "Condition: Good".
Seller Profile Row: A horizontal row with a circular avatar, the name "@student1", and a green checkmark indicating "Verified Student". Include a 5-star rating icon.
Description: Subtitle "Description". Text: "Furniture item available: Chair. Good condition. Pick up at the Main Library only. DM for details."
Dynamic Bottom Bar (CRITICAL): A fixed white footer at the very bottom containing two buttons side-by-side. The left button is "Chat" (white background, deep green border and text, 30% width). The right button is "Buy Now" (solid deep green background, white text, 70% width).
🎨 Figma AI Prompt (UI 4.2 租赁下单确认页)
去 Figma 生成时，我们直接生成最复杂的“租赁 (Rent)”场景，这样能把所有的 UI 控件（日期选择器、算账明细、安全面交点）一次性展现给评委看。
Copy & Paste this into Figma AI:
Design a mobile "Checkout / Confirm Order" screen for a campus marketplace app called "Campus Swap". Use the Global Style.
Layout & Elements (Top to Bottom):
Header: Title "Confirm Order" with a back arrow icon.
Concurrency Warning (CRITICAL): A full-width banner right below the header. Light orange background, dark orange text. Text: "⚡ High Demand: 2 other students are viewing this. Confirm now to lock the item."
Item Summary Card: A white rounded card containing a small square image of a textbook, title "Calculus Textbook", and the rate "RM 5.00 / day".
Meetup Location: A section titled "Select Safe Meetup Zone". Below it, a dropdown field showing "🛡️ Main Library" (include a small shield icon to denote safety).
Rental Period Section (CRITICAL): Title "Rental Duration". A row with two input-like fields side-by-side: "Start Date: Oct 12" and "End Date: Oct 15". Below this row, a small text saying "Duration: 3 Days".
Payment Breakdown Card: A grey rounded box showing the math:
Row 1: "Rental Fee (RM 5 x 3 days)" with value "RM 15.00" on the right.
Row 2: "Security Deposit (Refundable)" with value "RM 40.00" on the right.
Divider line.
Row 3: Bold text "Total Due Now" with value "RM 55.00" on the right.
Footer Action: A fixed white bar at the bottom. On the left, bold text "Total: RM 55.00". On the right, a solid deep green button "Confirm & Lock Item".

🎨 Figma AI Prompt (UI 4.3 订单列表页)
去 Figma AI 生成 UI 时，我们生成一个 "Sales (卖出)" 视角下的列表，展示两个不同状态的订单卡片。
Copy & Paste this into Figma AI:
Design a mobile "My Orders" screen for a campus marketplace app called "Campus Swap". Use the Global Style.
Layout & Elements:
Header: Title "My Orders" with a back arrow icon.
Role Tabs: Below the header, two equal-width tabs: "Purchases" and "Sales". Make the "Sales" tab active (bold text, deep green underline).
Order Card 1 (Action Required State): A white card with a subtle shadow.
Top row: Buyer's avatar and name "@johndoe" on the left. A blue pill-shaped badge "To Confirm" on the right.
Middle row: A small square image of a textbook, title "Calculus Textbook", and text "Total: RM 45.00".
Bottom row: Two buttons. Left is "Open Dispute" (red outline). Right is "Confirm Receipt" (solid deep green).
Order Card 2 (In Progress State): Another card below the first.
Top row: Buyer's avatar and name "@janedoe". An orange pill-shaped badge "Scheduled" on the right.
Middle row: Image of a desk lamp, title "Study Lamp", text "Total: RM 15.00".
Bottom row: Only one button "Chat with Buyer" (grey outline).

🎨 Figma AI Prompt (UI 4.4 订单状态流转台)
生成这张图时，我们选择生成最具冲突性、元素最丰富的场景：卖家视角的 To Confirm 状态。因为这张图里包含了进度条、凭证图、红色警告按钮和绿色确认按钮。把它放进你的论文，评委一眼就能看懂你的反欺诈逻辑。
Copy & Paste this into Figma AI:
Design a mobile "Order Details & Progression" workspace for a campus marketplace app called "Campus Swap". Use the Global Style.
Layout & Elements (Top to Bottom):
Header: Title "Order Details". Below it, small grey text "Order #TRX-9824".
Progression Stepper (CRITICAL): A horizontal timeline with 4 steps: "Pending" (greyed out check), "Scheduled" (greyed out check), "To Confirm" (Active step, highlighted in deep green with a glowing dot), and "Completed" (grey dot). Draw a line connecting them.
Action Banner: A light blue or light green alert box. Text: "Buyer has uploaded payment proof. Please verify your bank account before confirming."
Order Summary Card: White card with shadow. Image of a vintage chair, title "Wooden Chair", "Total: RM 55.00". Below that, a row with a shield icon "Meetup: Main Library".
Payment Evidence Zone (CRITICAL): A subtitle "Payment Proof". Below it, a rounded rectangle showing a mock bank transfer receipt image. Place a small magnifying glass icon on the image to indicate it can be enlarged.
Dynamic Footer: Fixed bottom bar with two buttons. Left button: "Open Dispute" (white background, bold red text and red border). Right button: "Confirm Receipt" (solid deep green background, white text). Make the right button slightly wider.
🎨 Figma AI Prompt (UI 4.5 双盲评价页)
去 Figma AI 生成 UI 时，我们生成**“正在撰写评价 (Drafting)”**的界面，强调那条保护用户隐私的 Trust Banner。
Copy & Paste this into Figma AI:
Design a mobile "Submit Review" screen for a campus marketplace app called "Campus Swap". Use the Global Style.
Layout & Elements (Top to Bottom):
Header: Title "Rate Experience" with a back arrow icon on the left.
Context Section: Centered at the top, a circular avatar profile picture. Below it, bold text "Rate @student1". Below that, smaller grey text "For: Vintage Wooden Chair".
Double-Blind Trust Banner (CRITICAL): A full-width rectangular banner with a soft blue/green background. Inside, place a shield icon 🛡️ and the text: "Double-Blind System: Your review is hidden and protected. It will only be published once both parties have submitted their feedback, ensuring 100% honest reviews."
Star Rating: 5 very large, interactive-looking stars. Show 4 of them filled with a gold/yellow color, and 1 empty outline star.
Quick Tags (Chip group): Below the stars, a row of pill-shaped tags: "Friendly" (selected/green), "Punctual" (selected/green), "Good Condition".
Review Text Area: A large text input box with the placeholder "Share more details about your experience...".
Footer Action: A fixed full-width, solid deep green button at the bottom labeled "🔒 Submit Securely".
这三个页面是连接买卖双方、促成交易的“润滑剂”！
在你早期的原型（第 6 页）中 ，聊天室 (UI 5.2) 只有一个最基础的输入框和文字气泡。但在真实的商业级二手平台中，聊天室不仅是聊天的工具，更是交易推进的控制台。尤其是你提到的 UC25 (安全面交点) 和 UC26 (深层链接推送)，必须通过非常现代化的 UI 组件（如富文本卡片、底部拓展面板）来呈现。
我们将这三个页面一气呵成地拿下来！

📱 UI 5.1: Chat Inbox (消息列表页)
这个页面的痛点是：校园二手交易中，一个人可能同时在买 3 样东西，卖 2 样东西。如果列表里只有对方的头像和名字，用户根本记不清在和谁聊什么。
核心设计规范:
Contextual Thread Items (带上下文的列表项): 每一个聊天会话卡片，除了显示对方头像、名字、最新一条消息和时间外，必须在右侧附带一个微小的商品缩略图。这样用户一眼就知道这个聊天是关于什么的。
Unread Badges: 醒目的未读消息红点提示。
🎨 Figma AI Prompt (UI 5.1 消息列表页)
Copy & Paste this into Figma AI:
Design a mobile "Chat Inbox" screen for a campus marketplace app called "Campus Swap". Use the Global Style (deep forest green primary color).
Layout & Elements:
Header: Title "Messages". Include a search bar below it with placeholder "Search chats...".
Chat List: A vertical list of conversation threads.
Thread Item Design (CRITICAL): Each row must have:
Far Left: Circular avatar of the user.
Middle-Left: Name "@student_buyer" and a preview text "Are you free to meet at 3 PM?".
Top-Right: Small timestamp "2m ago".
Far Right: A small square thumbnail image of the product being discussed (e.g., a textbook). Next to it, a small notification dot indicating unread messages.
Bottom Navigation: Include the standard 5-icon bottom bar, with the "Chat" icon active.


🎨 Figma AI Prompt (UI 5.2 聊天室)
Copy & Paste this into Figma AI:
Design a mobile "Chat Room" screen for a campus marketplace app. Use the Global Style.
Layout & Elements:
Header: Back arrow, Avatar, and name "@alex_24".
Sticky Context Banner: Right below the header, a thin fixed banner showing a tiny image of a wooden desk, the title "Wooden Desk", and "RM 80.00".
Chat Area (The Messages):
A grey text bubble on the left (from Alex): "Hi, can we meet at the library?"
A dark green text bubble on the right (from User): "Sure, I'll send the location pin."
Rich Media Bubble (CRITICAL): A large custom bubble on the right side representing a "Safe Meetup Zone". It should have a small map graphic, a location pin icon, text "Proposed Meetup: Main Library", and two buttons inside the bubble: "View on Map" and "Accept".
Input Area: At the bottom, a rounded text input field. On the left of the field, a circular "+" icon (for attachments). On the right, a "Send" icon.
🎨 Figma AI Prompt (UI 5.3 通知中心)
Copy & Paste this into Figma AI:
Design a mobile "Notifications Hub" screen for a campus marketplace app. Use the Global Style.
Layout & Elements:
Header: Title "Notifications" with a "Mark all as read" text link on the right.
Notification Items (Vertical List):
Item 1 (Action Required): Light orange background. Red alert icon ⚠️. Title "Action Required: Order #TRX-12". Text "The buyer has opened a dispute. Please review.". Right arrow icon >.
Item 2 (Transaction Update): White background. Green package icon 📦. Title "Payment Verified!". Text "Buyer uploaded proof. Tap to confirm receipt.". Right arrow icon >.
Item 3 (System): White background. Blue megaphone icon 📢. Title "Welcome to Campus Swap". Text "Complete your profile to get an Eco-Badge!". Right arrow icon >.
Styling: Unread notifications (like Item 1 & 2) should have a slightly bolder font and a small colored dot indicator.
🎨 Figma AI Prompt (UI 6.1 帮助中心与工单)
Copy & Paste this into Figma AI:
Design a mobile "Help Center & My Tickets" screen for a campus marketplace app. Use the Global Style.
Layout & Elements:
Header: Title "Help Center".
Self-Service Section: A large search bar "Search for help...". Below it, a 2x2 grid of quick-link cards: "Transactions", "Account", "Report User", "App Issues".
My Tickets Section: A bold subtitle "My Support Tickets". Below it, a vertical list of two ticket cards.
Ticket Card 1: Title "Reported Listing #882". Subtitle "Created 2 days ago". On the right side, a blue status pill reading "In Progress".
Ticket Card 2: Title "Refund not received". Subtitle "Created 1 week ago". On the right side, a green status pill reading "Resolved".
Floating Action Button: A large circular deep green button in the bottom right corner with a headset/support icon.
🎨 Figma AI Prompt (UI 6.2 争议/举报表单)
Copy & Paste this into Figma AI:
Design a mobile "Open Dispute / Report" form screen for a campus marketplace app. Use the Global Style.
Layout & Elements:
Header: Title "Open Dispute" with a back arrow.
Context Banner: A light grey rounded box showing "Target: Order #TRX-9824" and "Item: Calculus Textbook".
Reason Dropdown (Floating Label style): A select field labeled "Reason for Dispute". The selected value shown is "Item not as described".
Description Text Area: A tall input box labeled "Details of the issue". Placeholder: "Please explain what happened...".
Evidence Upload Zone (CRITICAL): A bold subtitle "Upload Evidence (Required)". Below it, a wide dashed-border box containing a camera icon and text "Tap to upload photos or screenshots of the item/chat". Inside the box, show one uploaded thumbnail image.
Footer Action: A fixed full-width button at the bottom. To emphasize the serious nature of a dispute, color the button a dark, serious color (deep green or dark grey), labeled "Submit Dispute for Moderation".
这已经是系统里最体现“用户归属感”和“平台价值观”的两个页面了！
在你早期的原型（第 10 页）中 ，你极其精妙地设计了 "My Eco-Impact" (我的环保贡献) 这个模块 。这在普通的二手平台里是绝对看不到的，它是你 "Trade Smarter, Live Greener" 标语的最佳具象化。
在架构师眼里，模块 7 (User Profile) 不仅仅是放头像的地方，它是用户的数字信誉档案 (Digital Identity)，而 UI 7.2 (Settings) 更是承载了你系统底层严密的账号生命周期管理 (UC05 注销账号)。
我们直接把这两个页面做到极致！

📱 UI 7.1: My Profile Dashboard (个人中心)
我们要把你原型里的“环保数据”放大，并结合前面设计的“双盲评价”系统，加入“信誉星级”。
核心设计规范:
Top Bar (顶部导航): 极其干净。左边无返回键（因为是底导的根级页面），右边放一个明显的 ⚙️ 齿轮图标（入口：跳转至 UI 7.2）。
Identity Header (身份展示区 - 增强信任感):
居中大头像 。
名字与学号 (如：Alex Chen / @alex_24) 。
Trust Badges (信任徽章): 绿色高亮的 Verified Student ，以及新增的星级评分 ⭐ 4.9 (12 Reviews)。
The "Eco-Impact" Hero Card (环保成就卡 - 核心亮点):
继承你原型的优良设计 ，但加入更强的视觉冲击力（渐变绿背景、微光效果）。
数据呈现：Items Reused: 5 和 CO2 Saved: 12.5 kg。
Navigation Menu (功能导航列表):
My Listings (我的商品 - 跳转 UI 3.2)
My Orders (我的订单 - 跳转 UI 4.3)
Saved Items (收藏夹)
Help Center & Support (帮助中心 - 跳转 UI 6.1)
🎨 Figma AI Prompt (UI 7.1 个人中心)
Copy & Paste this into Figma AI:
Design a mobile "My Profile" dashboard for a campus marketplace app called "Campus Swap". Use the Global Style.
Layout & Elements (Top to Bottom):
Header: Title "Profile". On the top right, a prominent gear icon ⚙️ for Settings.
Identity Section (Centered): A large circular user avatar. Below it, bold text "Alex Chen" and smaller text "@alex_24". Below the name, a row with two badges: a light green pill "✓ Verified Student" and a yellow text "⭐ 4.9 (12 Reviews)".
Eco-Impact Card (CRITICAL): A visually striking, wide card with a deep green gradient background and white text. Title "🌱 My Eco-Impact". Divide the card into two columns. Left column: large number "5", label "Items Reused". Right column: large number "12.5 kg", label "CO2 Saved".
Menu List: A vertical list of menu items with icons on the left and a chevron > on the right.
📦 "My Orders"
🏷️ "My Listings"
❤️ "Saved Items"
🎧 "Help & Support"
Bottom Navigation: The standard 5-icon bottom bar, with the "Profile" icon active.
🎨 Figma AI Prompt (UI 7.2 设置与注销页)
去 Figma 生成时，我们生成那个**带有拦截提示（Disabled）**的版本，这最能体现你的架构深度！
Copy & Paste this into Figma AI:
Design a mobile "Account Settings" screen for a campus marketplace app. Use the Global Style.
Layout & Elements:
Header: Title "Settings" with a back arrow icon.
General Section: Subtitle "General". A list of items: "Edit Profile", "Notification Preferences", "Linked Accounts".
Security Section: Subtitle "Security". A list of items: "Change Password", "Privacy Settings".
Danger Zone Section (CRITICAL): At the very bottom of the screen. Subtitle "Danger Zone" in a dark red color.
Disabled Delete Button: A full-width button labeled "Delete Account". The button should look DISABLED (grey background, light grey text).
Blocker Message: Directly below the disabled button, add small red warning text: "🔒 Cannot delete account: You have an active ongoing transaction. Please complete or cancel it first."
Log Out: A subtle text button at the very bottom "Log Out" (colored in grey).
🎨 Figma AI Prompt (UI 8.1 版主大盘)
(注意：Prompt 中我明确指定了 Desktop Web Dashboard)
Copy & Paste this into Figma AI:
Design a Desktop Web Dashboard for a "Moderator Portal" of a campus marketplace. Use a professional, clean UI style with a dark sidebar and light main area. Brand primary color is deep green.
Layout & Elements:
Left Sidebar: Dark background. App logo at the top. Menu items: "Dashboard" (active), "Reports", "Disputes", "Support Tickets", "My History".
Top Header: White background. A search bar, a notification bell, and the Moderator's avatar on the far right.
Top Content Area (Metric Cards): A row of 3 wide metric cards.
Card 1: "Pending Reports" with a large number "14" and a red upward trend arrow.
Card 2: "Open Disputes" with number "5".
Card 3: "My Locked Tasks" with number "2" and a green dot.
Bottom Content Area (Data Table): A large white panel titled "Recent Open Tasks".
Table Headers: "Ticket ID", "Type", "Target", "Submitted", "Status", "Action".
Row 1: "#REP-102", "Fake Item", "Listing: Wooden Chair", "2 hrs ago", a grey pill "Open", and a primary color button "Review".
Row 2: "#DIS-88", "Item not as described", "Order #TRX-99", "5 hrs ago", a blue pill "Locked (Alex)", button "Review" (greyed out).
🎨 Figma AI Prompt (UI 8.2 审核与分流工作区)
生成这张图时，我们重点强调“左右分屏”的证据查阅体验。
Copy & Paste this into Figma AI:
Design a Desktop Web "Moderator Triage Workspace" for a campus marketplace. Use a professional, clean UI style. Brand primary color is deep green.
Layout & Elements (Split-Pane Design):
Left Sidebar: Same dark sidebar as the previous dashboard prompt.
Top Header: Same white header, but below it add a full-width light green warning banner: "🔒 Ticket #REP-102 is currently locked by you."
Main Content (Two Columns):
Left Column (Evidence Viewer, 60% width): A white panel titled "Reported Content Snapshot". Show a detailed view of a reported "Vintage Chair" listing. Include the images, description, and seller profile. Below that, show the "Reporter's Claim: Item is completely broken, not as described." with an attached photo showing a broken chair leg.
Right Column (Decision Matrix, 40% width): A white panel titled "Moderation Terminal".
A dropdown labeled "Select Violation Category" (showing "Item Condition Misrepresented").
A text area for "Internal Mod Notes".
Action Buttons (CRITICAL): Two large buttons at the bottom. Left button is "Dismiss Report" (grey outline). Right button is "Uphold & Suspend Listing" (Solid Red color to indicate a punitive action).
🎨 Figma AI Prompt (UI 9.1 最终仲裁)
Copy & Paste this into Figma AI:
Design a Desktop Web "Admin Final Arbitration" dashboard for a campus marketplace. Professional and data-dense style.
Layout & Elements (Split-Pane):
Header & Context: Top bar with Admin avatar. Below it, a bright orange banner: "🔥 ESCALATED DISPUTE: Requires Admin Final Arbitration."
Left Panel (Evidence & History, 60%): Show the full timeline of the dispute. Include a grey box titled "Moderator Notes: Unable to verify item condition. Escalating to Admin." Below it, show buyer and seller chat logs.
Right Panel (God-Mode Action Terminal, 40%): A heavily structured action panel.
Section "Financial Resolution": Two large buttons side-by-side. Left is "Force Refund (Buyer)" (solid blue). Right is "Release Funds (Seller)" (solid green).
Section "Account Sanctions": A bold red area titled "Punitive Actions". A checkbox list: "Ban @student_seller", "Ban @student_buyer".
Action Button: A massive, dark red button at the bottom: "Execute Admin Decision".
🎨 Figma AI Prompt (UI 9.2 用户管理)
Copy & Paste this into Figma AI:
Design a Desktop Web "User Management" page for an Admin Portal. Clean, enterprise software style.
Layout & Elements:
Top Bar: Title "User Directory". On the right, a search bar and a "Filter by Status" dropdown.
Main Data Table: A wide table with columns: "User ID", "Name/Email", "Role", "Eco-Score", "Reports Against", "Status", "Actions".
Row 1: Active student, green status pill.
Row 2: Banned student, dark red status pill.
Slide-out Drawer (User Detail): On the right side of the screen, an overlay drawer showing details for the banned student.
Inside the drawer: User's profile photo, email.
A section called "Ban History": "Banned on Oct 12 for Fraud".
Drawer Footer: Two buttons. "Lift Ban (Unban)" (grey outline) and "Delete Account Permanently" (solid dark red).
🎨 Figma AI Prompt (UI 9.3 报表大盘)
Copy & Paste this into Figma AI:
Design a Desktop Web "Analytics & Reports Dashboard" for an Admin Portal. Enterprise SaaS style.
Layout & Elements:
Header: Title "System Metrics". Top right: A date range picker "Last 30 Days" and two buttons "Export PDF" and "Export CSV".
KPI Metrics Row: 4 square cards at the top.
Card 1: "Total Volume" -> "RM 45,200"
Card 2: "Active Users" -> "3,421"
Card 3 (Green accent): "Platform CO2 Saved" -> "1,250 kg"
Card 4 (Red accent): "Open Disputes" -> "14"
Charts Area: Below the KPIs, a two-column layout for charts.
Left Panel: A line chart showing "Daily Transactions" over a month, trending upwards.
Right Panel: A donut/pie chart showing "Listings by Category" (Books, Electronics, Furniture).
Styling: Use a light grey background for the page, white backgrounds for the cards, with subtle shadows. Professional, clean data visualization.
🎨 Figma AI Prompt (UI 9.4 备份与恢复)
Copy & Paste this into Figma AI:
Design a Desktop Web "Database Backup & Restore" settings page for an Admin Portal. IT Operations style.
Layout & Elements:
Header: Title "System Backup & Restore".
Status Card: A prominent box at the top. Green checkmark icon. Text: "System Healthy. Last automated backup completed at 03:00 AM." Right next to it, a large solid primary color button: "Trigger Manual Backup Now".
History Table: A table below titled "Backup History Logs".
Columns: "Timestamp", "Type" (Auto/Manual), "Size", "Status", "Action".
Rows: Show recent successful backups (green "Success" text).
Restore Action: In the "Action" column of the table, place a button "Restore Point". Make this button look like a secondary action.
Warning Modal (Overlaying the table): Show a dark red confirmation modal in the center of the screen. Title: "CRITICAL WARNING". Text: "Restoring this database will overwrite all current user and transaction data. This cannot be undone." Input field placeholder: "Type 'RESTORE' to confirm". Two buttons: "Cancel" and a red "Execute Restore".

