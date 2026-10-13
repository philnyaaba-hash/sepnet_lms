# SkillBridge Python Lab: Detailed UI Specification

Layout, navigation, spacing and behaviour follow the reference screenshots screen by screen. These are NOT copied: the app name, mascot, illustrations, icon artwork, and all lesson/marketing text. Use "SkillBridge", an original mascot, original icons and original wording. Reference app screenshots were of a dark-themed Python learning app.

## A. Global style
- Background: very dark navy (about #1B1E27). Cards: slightly lighter navy with a 2 px lighter-navy outline.
- Primary: bright blue (about #0F8BFF) for main buttons, active nodes, links, progress fill.
- Buttons: full width, height about 56-60, corner radius about 20, ALL CAPS with wide letter-spacing, and a thicker darker bottom edge to look "pressable" (3D). Disabled state: dimmed blue with greyed text. Pressing moves the button down 2-3 px.
- Outlined cards/options use the same thick bottom-edge treatment.
- Text: white for main, grey (#9AA5B8) for secondary. Body 18-20 sp in lessons, 16 sp elsewhere. Rounded sans-serif font.
- Status bar and Android 3-button navigation are visible; screens use safe areas.
- Minimal animation: progress bar fill, speech-bubble text typing, node glow, button press.

## B. Welcome screen
- Top centre: app wordmark in blue, wide letter-spaced (about y=18% of screen).
- Centre: large mascot illustration (about 250 px tall), waving.
- Below mascot: white 2-line tagline, centred ("Learn Python for free with simple, bite-sized lessons").
- Bottom: filled blue "START LEARNING" button, then below it a text-only "I AM AN EXISTING USER" (white, caps, no border).

## C. Onboarding (shared layout)
- Top row: white back chevron on the left, then a thin (about 10 px) fully rounded progress bar spanning the width. Track is light grey; fill is blue with a soft glossy highlight. Fill grows with each step.
- Steps 2-5 layout: mascot on the left (about 90 px) at about y=18%, with a speech bubble to its right (dark fill, 2 px outline, rounded 24, small tail pointing to the mascot). Bubble text types in letter by letter.
- Step 1 layout: bubble centred with a tail pointing down at a centred mascot.
- Bottom: full-width "CONTINUE" button, disabled (dim blue) until the step is answered.

Steps in order:
1. Greeting: "Hey there! Ready to master Python?" (mascot centred, Continue enabled).
2. "Why are you learning Python?" Five option cards stacked: icon at left, label, empty radio circle at right. Options: Just exploring, Boost my career, Just for fun, School stuff, Build my own things. Single select; selected card gets blue outline and filled radio.
3. "How much time can you spend a day?" Four cards: label at left ("5 min per day"), small caption and radio at right (Easygoing, Standard, Committed, Immersive): 5, 15, 30, 60 minutes.
4. "Want me to remind you to practice?" Centre: round dark-blue icon badge with a question mark, title "Smart Reminders", grey description, a dark "ALLOW" button with a green arrow on the right, and a plain "LATER" text link below. Tapping ALLOW dims the screen and shows the Android notification permission dialog (green "Allow" and "Don't allow" buttons). Request permission only when the learner taps Allow.
5. "Alright, you're all set! Let's dive in." Four feature rows, each with an icon at the left, bold white title, grey description: AI Tutor, Easy Lessons, Python editor (works offline), Quick Recaps. CONTINUE enters the app.
Progress bar is full on the last step.

## D. Join / Login bottom sheet
Appears over the dimmed home screen. Rounded top corners, small drag handle. Centred title ("Join SkillBridge"), grey subtitle, then outlined full-width buttons: SIGN IN WITH SKILLBRIDGE ACCOUNT (primary path; LMS login). Below: "Already have an account? LOG IN" with LOG IN in blue. Add Google or email sign-up only if the LMS supports them.

## E. Complete Profile bottom sheet
Handle, blue back chevron at left, centred title "Complete Profile", a dark rounded text field with a person icon and placeholder "Nickname", and a blue "FINISH" button. After finishing, the reward display (gems/coins) may update ONLY from the LMS response, never locally.

## F. Home (Learn tab)
- Top bar (thin bottom border): logo left; then three stats evenly spaced: grey flame + streak number, yellow lightning bolt + number, pink gem + number. Meaning for SkillBridge: streak days, XP, SkillCoins (bolt and gem meanings to be confirmed with SkillBridge). All values come from the LMS; show last-known values offline.
- Section card (full width, rounded 24, outlined, 3D bottom edge): small caps line "SECTION FOUNDATIONS", large white title "Unit 1: Python Kickstart".
- Divider line with centred small-caps label (the unit's name) interrupting it.
- A small dark tooltip pill "Start" above the first node, with a tiny pointer.
- Lesson path: a winding vertical path. Nodes are large rounded pentagon shapes (about 140 px) with a thick darker bottom edge. The path zigzags (centre, right, centre-right, left) with curved connector lines in dark grey. Current node: bright blue with a soft ring/glow and a white icon. Locked nodes: grey with a dim grey icon. Node icons: head with gear (theory), terminal window (practice), angle brackets (code), numbered list (quiz).
- Tapping the current node opens an inline blue rounded card below it with a pointer arrow: white pill tag (THEORY / PRACTICE / CODE / QUIZ), bold white title ("How Python Works"), one-line description, and a white pill button "START +10 XP" with blue text. The XP number is only what the lesson offers; the LMS grants it.
- The path scrolls vertically and continues into further units.

## G. Bottom navigation (shown on Home, Leaderboard, AI Tutor)
Five icon-only tabs on a dark bar with a top border: Home (house), Code (terminal window), Leaderboard (bar-stairs), AI Tutor (sparkles), More (blue filled circle with three dots). The selected tab sits inside a rounded blue outline box. No text labels, so each icon needs an accessibility label.

## H. Lesson player
- Top: X (close) at left, progress bar (blue fill on light track) in the middle, a yellow sparkle icon (ask the AI tutor) and a blue flag icon (report a problem) at right.
- Body: left-aligned white text, about 20 sp, line height about 1.6, big spacing between paragraphs. Content is revealed progressively: first paragraph appears, tapping CONTINUE adds the next below it (screens show 1 paragraph, then 2).
- Bottom: fixed full-width blue CONTINUE button. No bottom navigation inside lessons.
- Lesson text must be SkillBridge's own content from the LMS, cached offline.

## I. Python editor (Code tab opens full screen, no bottom nav)
- Row 1: white back arrow at the top left.
- Row 2: file tabs: "main.py" text tab, then a "+" icon (new file) and a folder icon (open/manage files).
- Row 3: file name at left ("main.py"), then Save (floppy icon, greyed when nothing to save), Undo, Redo (greyed when unavailable), and at right a rounded blue "Run" button with a play icon (switches to Stop while running).
- Editor: fills the rest of the screen, same dark background, blue line numbers, monospace code with syntax colours (keywords/functions in blue, strings in green). Default file contains a print("Hello, World!") example.
- To add (not visible in the reference): the shortcut bar above the keyboard (brackets, quotes, colon, equals, indent, operators), and an output console that slides up after Run showing output, red errors with plain-English explanation, status and duration.

## J. Leaderboard
- Centred caps title "LEADERBOARD". Below it, an outlined pill "REFRESHES IN 4D 6H 34M" in blue.
- Two tabs: "7 Days XP" and "All Time Streak"; the active tab is blue with a thick blue underline.
- Podium in order 2nd, 1st, 3rd (1st in the middle and tallest): circular avatar above each bar, nickname, XP total (e.g. 3.0K); a gold crown badge on first place. Bars are silver (2), gold (1), bronze (3) with large rank numerals.
- Below: ranked list rows (rounded dark cards): rank number in a circle, avatar, nickname, a flame with "2d streak", and the XP at right. Scrollable.
- Online only, opt-in, nickname + avatar only (no photos, no real names).

## K. AI Tutor
- Top row: rounded-square menu button (chat history) at left, centre pill dropdown with sparkle icon and "Auto" (model/mode), circular info button at right.
- Centre: blue pixel-style mascot, headline "Hey, let's learn Python" ("Python" in blue), grey subline "Ask anything: loops, errors, ideas, quizzes."
- 2 by 2 grid of quick-prompt cards (outlined, rounded, 3D edge), each with a coloured icon tile, bold title and grey subtitle: Explain loops, Quiz me, Fix my code, Challenge.
- Bottom: rounded input pill with placeholder text, a blue microphone icon, and a circular send button with an up arrow.
- Online only; AI calls go through a LMS backend with child-safety filtering. Mock until available.

## L. More menu
Bottom sheet that slides up over a dimmed current screen. Rows with a large icon at the left and white label, separated by thin lines: Profile, Notebook, Certificate, Summary (list continues, scrollable; add Settings, Help, Privacy and safety, Log out). The More tab icon shows a blue outline while open.

## M. Behaviour notes
- Android back button: closes sheets first, then steps back through screens; in lessons it asks before leaving.
- All tap targets at least 48 dp.
- Offline: show a small offline indicator in the top bar; features that need internet (leaderboard, AI tutor, login) show a friendly offline state instead of an error.
- Keep text scalable for accessibility and support screen readers on every icon-only control.
