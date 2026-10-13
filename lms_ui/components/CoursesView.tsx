"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import CourseCard from "./CourseCard";
import { useSearch } from "./SearchContext";
import {
  courseStats,
  loadCompletedLessons,
} from "@/lib/progress";
import type { Course } from "@/types";

interface CoursesViewProps {
  courses: Course[];
}

export default function CoursesView({ courses }: CoursesViewProps) {
  const router = useRouter();
  const { query } = useSearch();
  const [completed, setCompleted] = useState<string[]>([]);

  useEffect(() => {
    setCompleted(loadCompletedLessons(courses));
  }, [courses]);

  const completedSet = useMemo(() => new Set(completed), [completed]);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return courses;
    return courses.filter(
      (course) =>
        course.title.toLowerCase().includes(q) ||
        course.description.toLowerCase().includes(q) ||
        course.category.toLowerCase().includes(q)
    );
  }, [courses, query]);

  function openCourse(course: Course) {
    const first = course.subCourses[0]?.lessons[0];
    const params = first ? `?lesson=${first.id}` : "";
    router.push(`/learn/${course.id}${params}`);
  }

  return (
    <div className="content-area page active">
      <div className="section-header">
        <h2>Continue Learning</h2>
      </div>

      {filtered.length === 0 ? (
        <div className="empty-state">
          <p>No courses match “{query}”.</p>
        </div>
      ) : (
        <div className="course-grid">
          {filtered.map((course, index) => {
            const stats = courseStats(course, completedSet);
            return (
              <CourseCard
                key={course.id}
                course={course}
                progress={stats.progress}
                totalLessons={stats.total}
                index={index}
                onOpen={openCourse}
              />
            );
          })}
        </div>
      )}
    </div>
  );
}
