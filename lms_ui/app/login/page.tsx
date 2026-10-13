import type { Metadata } from "next";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import PinForm from "@/components/PinForm";
import ThemeToggle from "@/components/ThemeToggle";
import { LOGO_URL } from "@/lib/data";
import { SESSION_COOKIE, verifySessionToken } from "@/lib/auth";

export const metadata: Metadata = {
  title: "Login",
};

export default async function LoginPage() {
  const store = await cookies();
  if (verifySessionToken(store.get(SESSION_COOKIE)?.value)) {
    redirect("/courses");
  }

  return (
    <div className="login-page">
      <div className="login-theme-toggle">
        <ThemeToggle />
      </div>

      <div className="login-container">
        <div className="logo-section">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <div className="logo">
            <img src={LOGO_URL} alt="Sepnet" />
          </div>
          <h1>Welcome to Sepnet</h1>
          <p>Enter your PIN to continue learning</p>
        </div>

        <PinForm />

        <div className="footer-text">
          Need help?{" "}
          <a href="https://wa.me/233541988383" target="_blank" rel="noopener">
            Contact Support
          </a>
        </div>
      </div>
    </div>
  );
}
