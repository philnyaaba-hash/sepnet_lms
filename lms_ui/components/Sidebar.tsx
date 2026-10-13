"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { LOGO_URL } from "@/lib/data";
import ThemeToggle from "./ThemeToggle";

const NAV_ITEMS = [
  {
    href: "/courses",
    label: "My Courses",
    icon: (
      <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
        <path
          d="M3 5C3 3.89543 3.89543 3 5 3H15C16.1046 3 17 3.89543 17 5V15C17 16.1046 16.1046 17 15 17H5C3.89543 17 3 16.1046 3 15V5Z"
          stroke="currentColor"
          strokeWidth="1.5"
        />
        <path
          d="M7 7H13M7 10H13M7 13H10"
          stroke="currentColor"
          strokeWidth="1.5"
          strokeLinecap="round"
        />
      </svg>
    ),
  },
  {
    href: "/announcements",
    label: "Announcements",
    icon: (
      <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
        <path
          d="M16 8v4a2 2 0 01-2 2H6l-3 3V5l3 3h8a2 2 0 012 2v-2z"
          stroke="currentColor"
          strokeWidth="1.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
    ),
  },
  {
    href: "/resources",
    label: "Resources",
    icon: (
      <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
        <path
          d="M10 3v9m0 0l-3-3m3 3l3-3"
          stroke="currentColor"
          strokeWidth="1.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        <path
          d="M3 13v2a2 2 0 002 2h10a2 2 0 002-2v-2"
          stroke="currentColor"
          strokeWidth="1.5"
          strokeLinecap="round"
        />
      </svg>
    ),
  },
  {
    href: "/certificate",
    label: "Certificate",
    icon: (
      <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
        <circle cx="10" cy="8" r="5" stroke="currentColor" strokeWidth="1.5" />
        <path
          d="M7 12l-1 6 4-2 4 2-1-6"
          stroke="currentColor"
          strokeWidth="1.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
    ),
  },
  {
    href: "/about",
    label: "About Sepnet",
    icon: (
      <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
        <circle cx="10" cy="10" r="7.5" stroke="currentColor" strokeWidth="1.5" />
        <path
          d="M10 9v5M10 6.5h.01"
          stroke="currentColor"
          strokeWidth="1.5"
          strokeLinecap="round"
        />
      </svg>
    ),
  },
];

interface SidebarProps {
  open: boolean;
  onClose: () => void;
}

export default function Sidebar({ open, onClose }: SidebarProps) {
  const pathname = usePathname();
  const router = useRouter();

  function isActive(href: string): boolean {
    if (href === "/courses") {
      return pathname === "/courses" || pathname.startsWith("/learn");
    }
    return pathname === href;
  }

  async function handleLogout() {
    try {
      await fetch("/api/auth/logout", { method: "POST" });
    } finally {
      router.push("/login");
      router.refresh();
    }
  }

  return (
    <>
      {open && (
        <div className="sidebar-backdrop" onClick={onClose} aria-hidden="true" />
      )}
      <aside className={`sidebar${open ? " open" : ""}`}>
        <div className="sidebar-header">
          <Link href="/courses" className="logo" onClick={onClose}>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={LOGO_URL} alt="Sepnet" className="logo-image" />
            <span>Sepnet</span>
          </Link>
          <ThemeToggle />
        </div>

        <nav className="sidebar-nav" aria-label="Main navigation">
          {NAV_ITEMS.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={`nav-item${isActive(item.href) ? " active" : ""}`}
              onClick={onClose}
            >
              {item.icon}
              <span>{item.label}</span>
            </Link>
          ))}
        </nav>

        <div className="sidebar-footer">
          <button className="logout-btn" type="button" onClick={handleLogout}>
            <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
              <path
                d="M7 17H4C3.46957 17 2.96086 16.7893 2.58579 16.4142C2.21071 16.0391 2 15.5304 2 15V5C2 4.46957 2.21071 3.96086 2.58579 3.58579C2.96086 3.21071 3.46957 3 4 3H7"
                stroke="currentColor"
                strokeWidth="1.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
              <path
                d="M13 14L17 10L13 6"
                stroke="currentColor"
                strokeWidth="1.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
              <path
                d="M17 10H7"
                stroke="currentColor"
                strokeWidth="1.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
            <span>Logout</span>
          </button>
        </div>
      </aside>
    </>
  );
}
