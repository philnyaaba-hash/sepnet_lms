"use client";

import { useEffect, useMemo, useState } from "react";
import {
  loadCompletedLessons,
  loadStudentName,
  overallStats,
  saveStudentName,
} from "@/lib/progress";
import { formatLongDate } from "@/lib/format";
import { LOGO_URL } from "@/lib/data";
import type { Course } from "@/types";

interface CertificateViewProps {
  courses: Course[];
}

export default function CertificateView({ courses }: CertificateViewProps) {
  const [completed, setCompleted] = useState<string[]>([]);
  const [name, setName] = useState("");
  const [certName, setCertName] = useState("");
  const [error, setError] = useState(false);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    setCompleted(loadCompletedLessons(courses));
    setName(loadStudentName());
    setReady(true);
  }, [courses]);

  const stats = useMemo(
    () => overallStats(courses, completed),
    [courses, completed]
  );
  const primaryCourse = courses[0];

  function generate() {
    const trimmed = name.trim();
    if (!trimmed) {
      setError(true);
      window.setTimeout(() => setError(false), 600);
      return;
    }
    saveStudentName(trimmed);
    setCertName(trimmed);
  }

  if (!ready) {
    return <div className="empty-state">Loading certificate…</div>;
  }

  if (stats.progress < 100 || !primaryCourse) {
    return (
      <div className="certificate-locked">
        <div className="certificate-lock-icon">
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none">
            <rect
              x="5"
              y="11"
              width="14"
              height="9"
              rx="2"
              stroke="currentColor"
              strokeWidth="1.5"
            />
            <path
              d="M8 11V7a4 4 0 018 0v4"
              stroke="currentColor"
              strokeWidth="1.5"
              strokeLinecap="round"
            />
          </svg>
        </div>
        <h3>Certificate Locked</h3>
        <p>
          Complete all lessons ({stats.done}/{stats.total}) to unlock your
          certificate.
        </p>
        <div className="progress-bar certificate-progress">
          <div className="progress-fill" style={{ width: `${stats.progress}%` }} />
        </div>
        <span className="certificate-progress-label">
          {stats.progress}% complete
        </span>
      </div>
    );
  }

  return (
    <>
      <div className="certificate-form">
        <label htmlFor="studentName">Your Full Name</label>
        <div className="certificate-form-row">
          <input
            type="text"
            id="studentName"
            placeholder="Enter your full name"
            value={name}
            className={error ? "input-error" : ""}
            onChange={(e) => setName(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") generate();
            }}
          />
          <button type="button" className="generate-cert-btn" onClick={generate}>
            Generate Certificate
          </button>
        </div>
      </div>

      {certName && (
        <>
          <div className="certificate" id="printableCertificate">
            <div className="certificate-border">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={LOGO_URL}
                alt="Sepnet"
                className="certificate-logo"
              />
              <div className="certificate-org">Sepnet</div>
              <h2 className="certificate-heading">Certificate of Completion</h2>
              <p className="certificate-presented">
                This certificate is proudly presented to
              </p>
              <div className="certificate-name">{certName}</div>
              <p className="certificate-body">
                for successfully completing the course
              </p>
              <div className="certificate-course">{primaryCourse.title}</div>
              <div className="certificate-footer">
                <div className="certificate-field">
                  <div className="certificate-line">{formatLongDate()}</div>
                  <div className="certificate-caption">Date Completed</div>
                </div>
                <div className="certificate-seal">★</div>
                <div className="certificate-field">
                  <div className="certificate-line">Sepnet Academy</div>
                  <div className="certificate-caption">Authorized Signature</div>
                </div>
              </div>
            </div>
          </div>
          <div className="certificate-actions no-print">
            <button
              type="button"
              className="print-cert-btn"
              onClick={() => window.print()}
            >
              <svg width="18" height="18" viewBox="0 0 20 20" fill="none">
                <path
                  d="M6 8V3h8v5"
                  stroke="currentColor"
                  strokeWidth="1.5"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
                <rect
                  x="3"
                  y="8"
                  width="14"
                  height="6"
                  rx="1.5"
                  stroke="currentColor"
                  strokeWidth="1.5"
                />
                <path
                  d="M6 12h8v5H6v-5z"
                  stroke="currentColor"
                  strokeWidth="1.5"
                  strokeLinejoin="round"
                />
              </svg>
              Print / Save as PDF
            </button>
          </div>
        </>
      )}
    </>
  );
}
