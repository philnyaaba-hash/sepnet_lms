import type { Metadata } from "next";
import { resources } from "@/lib/data";

export const metadata: Metadata = {
  title: "Resources",
};

export default function ResourcesPage() {
  return (
    <div className="content-area page active">
      <div className="section-header">
        <h2>Learning Resources</h2>
      </div>
      <p className="page-note">
        Downloadable materials to support your lessons — PDFs, code files and
        practice exercises.
      </p>
      <div className="resources-list">
        {resources.map((r, i) => {
          const available = Boolean(r.url);
          return (
            <div
              className="resource-card"
              key={r.id}
              style={{
                animationDelay: `${i * 0.05}s`,
                opacity: undefined,
              }}
            >
              <div className={`resource-icon type-${r.type.toLowerCase()}`}>
                {r.type}
              </div>
              <div className="resource-info">
                <h3>{r.title}</h3>
                <p>{r.description}</p>
                <span className="resource-lesson">{r.lesson}</span>
              </div>
              {available ? (
                <a
                  className="resource-download"
                  href={r.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  download
                >
                  Download
                </a>
              ) : (
                <span className="resource-soon">Coming soon</span>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
