"use client";

import { useEffect, useState } from "react";

export default function ThemeToggle() {
  const [mounted, setMounted] = useState(false);
  const [isDark, setIsDark] = useState(true);

  useEffect(() => {
    setMounted(true);
    setIsDark(document.body.classList.contains("dark-mode"));
  }, []);

  function toggle() {
    const nextDark = !document.body.classList.contains("dark-mode");
    document.body.classList.toggle("dark-mode", nextDark);
    document.body.classList.toggle("light-mode", !nextDark);
    try {
      localStorage.setItem("theme", nextDark ? "dark" : "light");
    } catch {
      /* storage unavailable */
    }
    setIsDark(nextDark);
  }

  return (
    <button
      className="theme-toggle"
      onClick={toggle}
      aria-label="Toggle theme"
      type="button"
      suppressHydrationWarning
    >
      <svg
        className="sun-icon"
        width="20"
        height="20"
        viewBox="0 0 20 20"
        fill="none"
        aria-hidden="true"
      >
        <circle cx="10" cy="10" r="4" stroke="currentColor" strokeWidth="1.5" />
        <path
          d="M10 2v2M10 16v2M2 10h2M16 10h2M4.93 4.93l1.41 1.41M13.66 13.66l1.41 1.41M15.07 4.93l-1.41 1.41M6.34 13.66l-1.41 1.41"
          stroke="currentColor"
          strokeWidth="1.5"
          strokeLinecap="round"
        />
      </svg>
      <svg
        className="moon-icon"
        width="20"
        height="20"
        viewBox="0 0 20 20"
        fill="none"
        aria-hidden="true"
      >
        <path
          d="M17.5 10.5a7.5 7.5 0 11-8-8 6 6 0 008 8z"
          stroke="currentColor"
          strokeWidth="1.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
      {mounted ? null : <span className="sr-only">Toggle theme</span>}
    </button>
  );
}
