export interface Lesson {
  id: number;
  title: string;
  duration: string;
  cloudinaryId: string;
  completed?: boolean;
}

export interface SubCourse {
  id: number;
  title: string;
  description: string;
  lessons: Lesson[];
}

export interface Course {
  id: number;
  title: string;
  description: string;
  category: string;
  duration: string;
  totalLessons: number;
  progress: number;
  instructor: string;
  level?: string;
  thumbnail?: string;
  subCourses: SubCourse[];
}

export interface Announcement {
  id: number;
  title: string;
  date: string;
  tag: string;
  body: string;
}

export interface ResourceItem {
  id: number;
  title: string;
  description: string;
  type: string;
  lesson: string;
  url: string;
}

export interface FlatLesson {
  lesson: Lesson;
  subCourse: SubCourse;
  index: number;
}
