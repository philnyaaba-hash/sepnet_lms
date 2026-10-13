import type { Metadata } from "next";
import { notFound } from "next/navigation";
import LearnView from "@/components/LearnView";
import { getCourse } from "@/lib/data";

export const metadata: Metadata = {
  title: "Course Player",
};

interface LearnPageProps {
  params: Promise<{ courseId: string }>;
  searchParams: Promise<{ lesson?: string }>;
}

export default async function LearnPage({ params, searchParams }: LearnPageProps) {
  const { courseId } = await params;
  const { lesson } = await searchParams;
  const id = Number.parseInt(courseId, 10);
  const course = Number.isNaN(id) ? undefined : getCourse(id);
  if (!course) notFound();

  const lessonId = lesson ? Number.parseInt(lesson, 10) : undefined;

  return (
    <LearnView
      course={course}
      initialLessonId={
        lessonId !== undefined && !Number.isNaN(lessonId) ? lessonId : undefined
      }
    />
  );
}
