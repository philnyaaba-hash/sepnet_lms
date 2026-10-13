import type { Course } from "@/types";

const PROGRESS_KEY = "sepnetProgress";
const STUDENT_NAME_KEY = "sepnetStudentName";

export function lessonKey(courseId: number, lessonId: number): string {
  return `${courseId}-${lessonId}`;
}

export function seedCompletedLessons(courses: Course[]): string[] {
  const keys: string[] = [];
  courses.forEach((course) =>
    course.subCourses.forEach((sc) =>
      sc.lessons.forEach((l) => {
        if (l.completed) keys.push(lessonKey(course.id, l.id));
      })
    )
  );
  return keys;
}

export function loadCompletedLessons(courses: Course[]): string[] {
  if (typeof window === "undefined") return seedCompletedLessons(courses);
  try {
    const saved = localStorage.getItem(PROGRESS_KEY);
    if (saved === null) {
      const seeded = seedCompletedLessons(courses);
      localStorage.setItem(PROGRESS_KEY, JSON.stringify(seeded));
      return seeded;
    }
    const parsed = JSON.parse(saved);
    return Array.isArray(parsed) ? parsed.filter((k) => typeof k === "string") : [];
  } catch {
    return [];
  }
}

export function saveCompletedLessons(keys: string[]): void {
  if (typeof window === "undefined") return;
  try {
    localStorage.setItem(PROGRESS_KEY, JSON.stringify(keys));
  } catch {
    /* storage unavailable */
  }
}

export function toggleCompletedLesson(keys: string[], key: string): string[] {
  return keys.includes(key) ? keys.filter((k) => k !== key) : [...keys, key];
}

export interface CourseStats {
  total: number;
  done: number;
  progress: number;
}

export function courseStats(
  course: Course,
  completed: Set<string> | string[]
): CourseStats {
  const set = completed instanceof Set ? completed : new Set(completed);
  let total = 0;
  let done = 0;
  course.subCourses.forEach((sc) =>
    sc.lessons.forEach((l) => {
      total++;
      if (set.has(lessonKey(course.id, l.id))) done++;
    })
  );
  return {
    total,
    done,
    progress: total ? Math.round((done / total) * 100) : 0,
  };
}

export function overallStats(
  courses: Course[],
  completed: Set<string> | string[]
): CourseStats {
  const set = completed instanceof Set ? completed : new Set(completed);
  let total = 0;
  let done = 0;
  courses.forEach((c) => {
    const s = courseStats(c, set);
    total += s.total;
    done += s.done;
  });
  return {
    total,
    done,
    progress: total ? Math.round((done / total) * 100) : 0,
  };
}

export function loadStudentName(): string {
  if (typeof window === "undefined") return "";
  try {
    return localStorage.getItem(STUDENT_NAME_KEY) || "";
  } catch {
    return "";
  }
}

export function saveStudentName(name: string): void {
  if (typeof window === "undefined") return;
  try {
    localStorage.setItem(STUDENT_NAME_KEY, name);
  } catch {
    /* storage unavailable */
  }
}
