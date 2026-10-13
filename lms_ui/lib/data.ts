import type { Announcement, Course, ResourceItem } from "@/types";

export const courses: Course[] = [
  {
    id: 1,
    title: "Python Quick Start",
    description:
      "Get a fast-paced introduction to learning Python in this approachable, beginner-friendly course.",
    category: "Programming",
    duration: "1h 47m",
    totalLessons: 3,
    progress: 33,
    instructor: "Lavanya Vijayan",
    level: "Beginner",
    thumbnail:
      "https://res.cloudinary.com/dwsl2ktt2/image/upload/v1790259229/Screenshot_24_o1pbnb.png",
    subCourses: [
      {
        id: 1,
        title: "Career Development",
        description: "Learn how Python can advance your career",
        lessons: [
          {
            id: 1,
            title: "Advancing Your Career with Python",
            duration: "12h 30m",
            cloudinaryId: "01._Advancing_your_career_with_Python_gxiqvb",
            completed: true,
          },
        ],
      },
      {
        id: 2,
        title: "Python Fundamentals",
        description: "Master the core concepts of Python programming",
        lessons: [
          {
            id: 2,
            title: "Demystifying Python - SEPNET",
            duration: "8h 45m",
            cloudinaryId: "01._Demystifying_Python_SEPNET_taeg1m",
            completed: false,
          },
          {
            id: 3,
            title: "Starting with Python",
            duration: "15h 20m",
            cloudinaryId: "02._Starting_with_Python_axpavj",
            completed: false,
          },
        ],
      },
    ],
  },
];

export const announcements: Announcement[] = [
  {
    id: 1,
    title: "Welcome to the Sepnet Learning Platform",
    date: "2026-09-20",
    tag: "General",
    body: "We are excited to launch our online learning platform! All enrolled students can now access Python course videos anytime, anywhere. Start with the Complete Python Masterclass and track your progress as you learn.",
  },
  {
    id: 2,
    title: "New Cohort Enrollment Open",
    date: "2026-09-18",
    tag: "Enrollment",
    body: "Enrollment for the next Python training cohort is now open. Seats are limited — message us on WhatsApp (+233 54 198 8383) to reserve your spot. Scholarships are available for eligible students.",
  },
  {
    id: 3,
    title: "Weekly Live Q&A Sessions",
    date: "2026-09-15",
    tag: "Schedule",
    body: "Join our mentors every Saturday at 10:00 AM GMT for a live Q&A session. Bring your questions about the course material, projects, or your tech career path.",
  },
];

export const resources: ResourceItem[] = [
  {
    id: 1,
    title: "Python Basics Cheat Sheet",
    description: "Quick reference for syntax, data types and common operations.",
    type: "PDF",
    lesson: "Starting with Python",
    url: "",
  },
  {
    id: 2,
    title: "Course Slides - Demystifying Python",
    description: "All slides from the Demystifying Python sessions.",
    type: "PDF",
    lesson: "Demystifying Python - SEPNET",
    url: "",
  },
  {
    id: 3,
    title: "Practice Exercises",
    description: "Hands-on exercises with solutions to reinforce each lesson.",
    type: "ZIP",
    lesson: "Complete Python Masterclass",
    url: "",
  },
  {
    id: 4,
    title: "Career Guide - Tech in Ghana",
    description:
      "How to build a career in technology: CV tips, interview prep and opportunities.",
    type: "PDF",
    lesson: "Advancing Your Career with Python",
    url: "",
  },
];

export const WHATSAPP_NUMBER = "233541988383";

export const LOGO_URL =
  "https://res.cloudinary.com/dwsl2ktt2/image/upload/v1790260220/sepnetghana_jjq8vj.jpg";

export const LOGIN_BG_URL =
  "https://res.cloudinary.com/dwsl2ktt2/image/upload/v1790260777/33a26a57-85c4-49a7-bb1f-a0c9664e51cc_gyodd3.jpg";

export function getCourse(id: number): Course | undefined {
  return courses.find((c) => c.id === id);
}

export function countLessons(course: Course): number {
  return course.subCourses.reduce((sum, sc) => sum + sc.lessons.length, 0);
}
