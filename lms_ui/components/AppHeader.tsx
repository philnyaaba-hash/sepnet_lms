"use client";

import { usePathname } from "next/navigation";
import { useSearch } from "./SearchContext";

const PAGE_META: Record<
  string,
  { title: string; subtitle: string; search?: boolean }
> = {
  "/courses": {
    title: "My Courses",
    subtitle: "Continue your learning journey",
    search: true,
  },
  "/announcements": {
    title: "Announcements",
    subtitle: "News and updates from Sepnet",
  },
  "/resources": {
    title: "Resources",
    subtitle: "Downloadable learning materials",
  },
  "/certificate": {
    title: "Certificate",
    subtitle: "Claim your completion certificate",
  },
  "/about": {
    title: "About Sepnet",
    subtitle: "Our mission and impact",
  },
  "/learn": {
    title: "Course Player",
    subtitle: "Watch, learn and track your progress",
  },
};

interface AppHeaderProps {
  onMenuToggle: () => void;
}

export default function AppHeader({ onMenuToggle }: AppHeaderProps) {
  const pathname = usePathname();
  const { query, setQuery } = useSearch();

  const meta =
    PAGE_META[pathname] ||
    (pathname.startsWith("/learn")
      ? PAGE_META["/learn"]
      : { title: "Sepnet", subtitle: "Learning Management System" });

  return (
    <header className="header">
      <div className="header-left">
        <button
          className="menu-toggle"
          type="button"
          onClick={onMenuToggle}
          aria-label="Toggle navigation menu"
        >
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
            <path
              d="M4 6h16M4 12h16M4 18h16"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            />
          </svg>
        </button>
        <div>
          <h1 className="page-title">{meta.title}</h1>
          <p className="page-subtitle">{meta.subtitle}</p>
        </div>
      </div>
      <div className="header-right">
        {meta.search && (
          <div className="search-box">
            <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
              <circle cx="8" cy="8" r="6" stroke="currentColor" strokeWidth="1.5" />
              <path
                d="M13 13L16 16"
                stroke="currentColor"
                strokeWidth="1.5"
                strokeLinecap="round"
              />
            </svg>
            <input
              type="text"
              placeholder="Search courses..."
              id="searchInput"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
            />
          </div>
        )}
      </div>
    </header>
  );
}
