"use client";

import { useState, type FormEvent } from "react";
import { WHATSAPP_NUMBER } from "@/lib/data";

const SUBJECTS = [
  "Course Access Issue",
  "Video Playback Problem",
  "Technical Support",
  "Account Help",
  "General Question",
  "Other",
];

export default function WhatsAppSupport() {
  const [open, setOpen] = useState(false);
  const [name, setName] = useState("");
  const [subject, setSubject] = useState("");
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    if (!name.trim() || !subject || !message.trim()) {
      setError("Please fill in all fields");
      return;
    }
    setError("");
    const text = `*Sepnet LMS Support Request*\n\n*Name:* ${name.trim()}\n*Subject:* ${subject}\n\n*Message:*\n${message.trim()}`;
    const url = `https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(text)}`;
    window.open(url, "_blank", "noopener");
    setOpen(false);
    setName("");
    setSubject("");
    setMessage("");
  }

  return (
    <>
      <div className="whatsapp-container">
        <div className="whatsapp-tooltip">DO YOU NEED ONE-ON-ONE SUPPORT?</div>
        <button
          className="whatsapp-float"
          type="button"
          onClick={() => setOpen(true)}
          aria-label="Get Help"
        >
          <svg width="32" height="32" viewBox="0 0 32 32" fill="none">
            <path
              d="M16 3C9.373 3 4 8.373 4 15c0 2.65.853 5.098 2.293 7.094L4 29l7.094-2.293A11.94 11.94 0 0016 27c6.627 0 12-5.373 12-12S22.627 3 16 3z"
              fill="currentColor"
            />
            <path
              d="M21.5 18.5c-.3-.15-1.77-.87-2.04-.97-.27-.1-.47-.15-.67.15-.2.3-.77.97-.94 1.17-.17.2-.35.22-.65.07-.3-.15-1.26-.46-2.4-1.48-.89-.79-1.49-1.77-1.66-2.07-.17-.3-.02-.46.13-.61.14-.14.3-.35.45-.52.15-.17.2-.3.3-.5.1-.2.05-.37-.02-.52-.08-.15-.68-1.63-.93-2.23-.24-.58-.49-.5-.67-.51h-.57c-.2 0-.52.07-.8.37-.27.3-1.04 1.02-1.04 2.5 0 1.47 1.07 2.89 1.22 3.09.15.2 2.11 3.22 5.11 4.52.71.31 1.27.49 1.71.63.72.23 1.37.2 1.89.12.57-.09 1.77-.72 2.02-1.42.25-.7.25-1.3.17-1.42-.07-.13-.27-.2-.57-.35z"
              fill="white"
            />
          </svg>
        </button>
      </div>

      <div
        className={`help-modal${open ? " active" : ""}`}
        onClick={(e) => {
          if (e.target === e.currentTarget) setOpen(false);
        }}
      >
        <div className="help-modal-content">
          <div className="help-modal-header">
            <div className="help-icon">
              <svg width="32" height="32" viewBox="0 0 32 32" fill="none">
                <path
                  d="M16 3C9.373 3 4 8.373 4 15c0 2.65.853 5.098 2.293 7.094L4 29l7.094-2.293A11.94 11.94 0 0016 27c6.627 0 12-5.373 12-12S22.627 3 16 3z"
                  fill="#25D366"
                />
                <path
                  d="M21.5 18.5c-.3-.15-1.77-.87-2.04-.97-.27-.1-.47-.15-.67.15-.2.3-.77.97-.94 1.17-.17.2-.35.22-.65.07-.3-.15-1.26-.46-2.4-1.48-.89-.79-1.49-1.77-1.66-2.07-.17-.3-.02-.46.13-.61.14-.14.3-.35.45-.52.15-.17.2-.3.3-.5.1-.2.05-.37-.02-.52-.08-.15-.68-1.63-.93-2.23-.24-.58-.49-.5-.67-.51h-.57c-.2 0-.52.07-.8.37-.27.3-1.04 1.02-1.04 2.5 0 1.47 1.07 2.89 1.22 3.09.15.2 2.11 3.22 5.11 4.52.71.31 1.27.49 1.71.63.72.23 1.37.2 1.89.12.57-.09 1.77-.72 2.02-1.42.25-.7.25-1.3.17-1.42-.07-.13-.27-.2-.57-.35z"
                  fill="white"
                />
              </svg>
            </div>
            <h2>How can we help?</h2>
            <p>Send us a message and we&apos;ll respond as soon as possible</p>
            <button
              className="close-help"
              type="button"
              onClick={() => setOpen(false)}
              aria-label="Close help dialog"
            >
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                <path
                  d="M6 18L18 6M6 6l12 12"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                />
              </svg>
            </button>
          </div>

          <form onSubmit={handleSubmit}>
            <div className="help-form-group">
              <label htmlFor="helpName">Your Name</label>
              <input
                id="helpName"
                type="text"
                placeholder="Enter your name"
                required
                value={name}
                onChange={(e) => setName(e.target.value)}
              />
            </div>

            <div className="help-form-group">
              <label htmlFor="helpSubject">Subject</label>
              <select
                id="helpSubject"
                required
                value={subject}
                onChange={(e) => setSubject(e.target.value)}
              >
                <option value="">Select a topic</option>
                {SUBJECTS.map((s) => (
                  <option key={s} value={s}>
                    {s}
                  </option>
                ))}
              </select>
            </div>

            <div className="help-form-group">
              <label htmlFor="helpMessage">Message</label>
              <textarea
                id="helpMessage"
                rows={4}
                placeholder="Describe your issue or question..."
                required
                value={message}
                onChange={(e) => setMessage(e.target.value)}
              />
            </div>

            {error && (
              <p className="form-error" role="alert">
                {error}
              </p>
            )}

            <button type="submit" className="send-whatsapp-btn">
              <svg width="20" height="20" viewBox="0 0 32 32" fill="none">
                <path
                  d="M16 3C9.373 3 4 8.373 4 15c0 2.65.853 5.098 2.293 7.094L4 29l7.094-2.293A11.94 11.94 0 0016 27c6.627 0 12-5.373 12-12S22.627 3 16 3z"
                  fill="currentColor"
                />
              </svg>
              Send via WhatsApp
            </button>
          </form>
        </div>
      </div>
    </>
  );
}
