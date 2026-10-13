"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import VideoPlayer from "./VideoPlayer";
import {
  courseStats,
  lessonKey,
  loadCompletedLessons,
  saveCompletedLessons,
  toggleCompletedLesson,
} from "@/lib/progress";
import type { Course, FlatLesson, Lesson } from "@/types";

interface LearnViewProps {
  course: Course;
  initialLessonId?: number;
}

function flattenLessons(course: Course): FlatLesson[] {
  const flat: FlatLesson[] = [];
  let index = 0;
  course.subCourses.forEach((subCourse) => {
    subCourse.lessons.forEach((lesson) => {
      flat.push({ lesson, subCourse, index });
      index++;
    });
  });
  return flat;
}

export default function LearnView({ course, initialLessonId }: LearnViewProps) {
  const router = useRouter();
  const flat = useMemo(() => flattenLessons(course), [course]);
  const firstLessonId = flat[0]?.lesson.id;

  const [currentId, setCurrentId] = useState<number>(
    initialLessonId && flat.some((f) => f.lesson.id === initialLessonId)
      ? initialLessonId
      : (firstLessonId ?? 0)
  );
  const [completed, setCompleted] = useState<string[]>([]);

  useEffect(() => {
    setCompleted(loadCompletedLessons([course]));
  }, [course]);

  const completedSet = useMemo(() => new Set(completed), [completed]);
  const stats = courseStats(course, completedSet);

  const currentEntry = flat.find((f) => f.lesson.id === currentId);
  const currentLesson: Lesson | undefined = currentEntry?.lesson;

  function selectLesson(lessonId: number) {
    setCurrentId(lessonId);
    router.replace(`/learn/${course.id}?lesson=${lessonId}`, { scroll: false });
  }

  function toggleComplete() {
    if (!currentLesson) return;
    const key = lessonKey(course.id, currentLesson.id);
    const next = toggleCompletedLesson(completed, key);
    setCompleted(next);
    saveCompletedLessons(next);
  }

  if (!currentLesson) {
    return (
      <div className="content-area page active">
        <div className="empty-state">
          <p>This course has no lessons yet.</p>
          <Link href="/courses" className="generate-cert-btn">
            Back to courses
          </Link>
        </div>
      </div>
    );
  }

  const isDone = completedSet.has(lessonKey(course.id, currentLesson.id));

  return (
    <div className="learn-page">
      <div className="learn-toolbar">
        <Link href="/courses" className="learn-back">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
            <path
              d="M15 18l-6-6 6-6"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
          All courses
        </Link>
        <div className="learn-progress">
          <div className="progress-bar">
            <div
              className="progress-fill"
              style={{ width: `${stats.progress}%` }}
            />
          </div>
          <span className="learn-progress-label">
            {stats.done}/{stats.total} lessons · {stats.progress}%
          </span>
        </div>
      </div>

      <div className="course-detail-layout">
        <div className="lesson-sidebar">
          <h3>Course Content</h3>
          <div className="lesson-list">
            {course.subCourses.map((subCourse) => (
              <div key={subCourse.id}>
                <div className="subcourse-header">
                  <div className="subcourse-title">{subCourse.title}</div>
                  <div className="subcourse-description">
                    {subCourse.description}
                  </div>
                </div>
                {subCourse.lessons.map((lesson) => {
                  const entry = flat.find((f) => f.lesson.id === lesson.id);
                  const key = lessonKey(course.id, lesson.id);
                  const done = completedSet.has(key);
                  const active = lesson.id === currentId;
                  return (
                    <button
                      type="button"
                      key={lesson.id}
                      className={`lesson-item${active ? " active" : ""}`}
                      onClick={() => selectLesson(lesson.id)}
                    >
                      <div className="lesson-number">
                        {(entry?.index ?? 0) + 1}
                      </div>
                      <div className="lesson-info">
                        <div className="lesson-title">{lesson.title}</div>
                        <div className="lesson-duration">{lesson.duration}</div>
                      </div>
                      <div className={`lesson-status${done ? " completed" : ""}`}>
                        {done ? "✓" : "▶"}
                      </div>
                    </button>
                  );
                })}
              </div>
            ))}
          </div>
        </div>

        <div className="video-section">
          <VideoPlayer
            key={currentLesson.cloudinaryId}
            publicId={currentLesson.cloudinaryId}
            title={currentLesson.title}
            subtitle={course.title}
          />
          <div className="video-info">
            <div className="video-info-header">
              <h3>{currentLesson.title}</h3>
              <button
                type="button"
                className={`complete-lesson-btn${isDone ? " completed" : ""}`}
                onClick={toggleComplete}
              >
                <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                  <path
                    d="M3 8.5l3 3 7-7"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
                <span>{isDone ? "Completed" : "Mark as Complete"}</span>
              </button>
            </div>
            <div className="video-meta">
              <span className="meta-item">
                <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                  <circle cx="8" cy="8" r="6" stroke="currentColor" strokeWidth="1.5" />
                  <path
                    d="M8 4v4l3 3"
                    stroke="currentColor"
                    strokeWidth="1.5"
                    strokeLinecap="round"
                  />
                </svg>
                <span>{currentLesson.duration}</span>
              </span>
              <span className="meta-item">
                <strong>Author:</strong>&nbsp;{course.instructor}
              </span>
              {course.level && (
                <span className="meta-item">
                  <strong>Level:</strong>&nbsp;{course.level}
                </span>
              )}
            </div>
            <div className="video-description">
              {course.title} — {currentEntry?.subCourse.title}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
