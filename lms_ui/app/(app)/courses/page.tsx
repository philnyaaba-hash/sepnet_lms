import type { Metadata } from "next";
import CoursesView from "@/components/CoursesView";
import { courses } from "@/lib/data";

export const metadata: Metadata = {
  title: "My Courses",
};

export default function CoursesPage() {
  return <CoursesView courses={courses} />;
}
