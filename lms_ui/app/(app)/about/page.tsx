import type { Metadata } from "next";
import { LOGO_URL, WHATSAPP_NUMBER } from "@/lib/data";

export const metadata: Metadata = {
  title: "About Sepnet",
};

const WHATSAPP_TEXT = encodeURIComponent(
  "Hello Sepnet! I would like to know more about your work."
);

export default function AboutPage() {
  return (
    <div className="content-area page active">
      <div className="about-hero">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={LOGO_URL} alt="Sepnet Ghana" className="about-logo" />
        <h2>Sepnet</h2>
        <p className="about-tagline">
          Impacting lives through technology education in Ghana
        </p>
      </div>

      <div className="about-section">
        <h3>Our Mission</h3>
        <p>
          Sepnet is a non-profit organization dedicated to bridging the digital
          divide in Ghana. We believe every young person deserves access to
          quality technology education — regardless of their background or
          circumstances. Through free and affordable training programs, we equip
          students with practical digital skills that open doors to careers,
          entrepreneurship and opportunity.
        </p>
      </div>

      <div className="about-section">
        <h3>What We Do</h3>
        <div className="about-cards">
          <div className="about-card">
            <div className="about-card-icon">💻</div>
            <h4>Tech Training</h4>
            <p>
              Hands-on courses in programming, digital skills and emerging
              technologies for beginners and beyond.
            </p>
          </div>
          <div className="about-card">
            <div className="about-card-icon">🎓</div>
            <h4>Mentorship</h4>
            <p>
              One-on-one guidance from experienced professionals who care about
              each student&apos;s journey.
            </p>
          </div>
          <div className="about-card">
            <div className="about-card-icon">🌍</div>
            <h4>Community Impact</h4>
            <p>
              Outreach programs bringing technology education to underserved
              communities across Ghana.
            </p>
          </div>
        </div>
      </div>

      <div className="about-section">
        <h3>Our Impact</h3>
        <div className="impact-stats">
          <div className="impact-stat">
            <div className="impact-number">500+</div>
            <div className="impact-label">Students Trained</div>
          </div>
          <div className="impact-stat">
            <div className="impact-number">20+</div>
            <div className="impact-label">Workshops Held</div>
          </div>
          <div className="impact-stat">
            <div className="impact-number">10+</div>
            <div className="impact-label">Communities Reached</div>
          </div>
        </div>
        <p className="impact-note">
          Impact figures are updated as our programs grow.
        </p>
      </div>

      <div className="about-section about-contact">
        <h3>Get Involved</h3>
        <p>
          Whether you want to learn, volunteer, partner or support our mission —
          we&apos;d love to hear from you.
        </p>
        <a
          href={`https://wa.me/${WHATSAPP_NUMBER}?text=${WHATSAPP_TEXT}`}
          target="_blank"
          rel="noopener noreferrer"
          className="about-contact-btn"
        >
          <svg width="20" height="20" viewBox="0 0 32 32" fill="none">
            <path
              d="M16 3C9.373 3 4 8.373 4 15c0 2.65.853 5.098 2.293 7.094L4 29l7.094-2.293A11.94 11.94 0 0016 27c6.627 0 12-5.373 12-12S22.627 3 16 3z"
              fill="currentColor"
            />
          </svg>
          Chat with us on WhatsApp
        </a>
      </div>
    </div>
  );
}
