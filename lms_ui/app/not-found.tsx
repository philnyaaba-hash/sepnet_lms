import Link from "next/link";

export default function NotFound() {
  return (
    <div className="not-found">
      <h1>404</h1>
      <p>This page could not be found.</p>
      <Link href="/courses" className="generate-cert-btn">
        Back to courses
      </Link>
    </div>
  );
}
