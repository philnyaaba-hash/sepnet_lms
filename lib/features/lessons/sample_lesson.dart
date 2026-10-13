import 'lesson_models.dart';

/// Original sample lesson used until the LMS supplies real content.
const sampleLesson = Lesson(
  id: 'sample-how-python-works',
  title: 'How Python Works',
  xpOffered: 10,
  steps: [
    ReadStep(paragraphs: [
      'Python is like a helpful translator. You write instructions in simple words, and Python turns them into steps a computer can follow.',
      'Python reads your code from the top to the bottom, one line at a time. It finishes line one before it looks at line two.',
      'Let us watch it happen.',
    ]),
    CodeWalkStep(
      title: 'Watch Python read this code',
      lines: [
        CodeLine(
          code: 'name = "Ama"',
          note: 'Python stores the text "Ama" in a box called name.',
        ),
        CodeLine(
          code: 'print("Hello,", name)',
          note: 'print shows words on the screen. Python looks inside name and uses what it finds.',
          output: 'Hello, Ama',
        ),
        CodeLine(
          code: 'print("Welcome to SkillBridge!")',
          note: 'Python moves down to the next line and prints this message.',
          output: 'Welcome to SkillBridge!',
        ),
      ],
    ),
    QuizStep(
      question: 'In what order does Python read your code?',
      options: [
        'Top to bottom, one line at a time',
        'Bottom to top',
        'In a random order',
        'All lines at the same moment',
      ],
      correctIndex: 0,
      explanation:
          'Python starts at the first line and works downward, one line at a time.',
    ),
    QuizStep(
      question: 'What does print() do?',
      options: [
        'Deletes a file',
        'Shows something on the screen',
        'Saves your program',
        'Closes the app',
      ],
      correctIndex: 1,
      explanation: 'print() displays text or values so you can see them.',
    ),
  ],
);
