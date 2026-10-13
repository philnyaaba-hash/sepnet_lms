import type { Metadata } from "next";
import { announcements } from "@/lib/data";
import { formatDate } from "@/lib/format";

export const metadata: Metadata = {
  title: "Announcements",
};

export default function AnnouncementsPage() {
  return (
    <div className="content-area page active">
      <div className="section-header">
        <h2>Latest Updates</h2>
      </div>
      <div className="announcements-list">
        {announcements.map((a, i) => (
          <article
            className="announcement-card"
            key={a.id}
            style={{
              animationDelay: `${i * 0.05}s`,
              opacity: undefined,
            }}
          >
            <div className="announcement-top">
              <span
                className={`announcement-tag tag-${a.tag.toLowerCase()}`}
              >
                {a.tag}
              </span>
              <span className="announcement-date">{formatDate(a.date)}</span>
            </div>
            <h3>{a.title}</h3>
            <p>{a.body}</p>
          </article>
        ))}
      </div>
    </div>
  );
}
