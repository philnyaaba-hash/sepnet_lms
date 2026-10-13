"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";

const PIN_LENGTH = 4;

export default function PinForm() {
  const router = useRouter();
  const inputsRef = useRef<Array<HTMLInputElement | null>>([]);
  const [digits, setDigits] = useState<string[]>(Array(PIN_LENGTH).fill(""));
  const [error, setError] = useState(false);
  const [loading, setLoading] = useState(false);
  const submittingRef = useRef(false);

  useEffect(() => {
    inputsRef.current[0]?.focus();
  }, []);

  const setDigit = (index: number, value: string) => {
    setDigits((prev) => {
      const next = [...prev];
      next[index] = value;
      return next;
    });
  };

  const submitPin = async (pin: string) => {
    if (pin.length !== PIN_LENGTH || submittingRef.current) {
      triggerError();
      return;
    }
    submittingRef.current = true;
    setLoading(true);
    setError(false);
    try {
      const res = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ pin }),
      });
      if (res.ok) {
        router.replace("/courses");
        router.refresh();
        return;
      }
      triggerError();
    } catch {
      triggerError();
    } finally {
      setLoading(false);
      submittingRef.current = false;
    }
  };

  const triggerError = () => {
    setError(true);
    setDigits(Array(PIN_LENGTH).fill(""));
    inputsRef.current.forEach((el) => el?.classList.remove("filled"));
    inputsRef.current[0]?.focus();
    window.setTimeout(() => setError(false), 3000);
  };

  const handleChange = (index: number, raw: string) => {
    const value = raw.replace(/\D/g, "").slice(-1);
    setDigit(index, value);
    const input = inputsRef.current[index];
    if (input) {
      input.classList.toggle("filled", Boolean(value));
      input.classList.remove("error");
    }
    if (value && index < PIN_LENGTH - 1) {
      inputsRef.current[index + 1]?.focus();
    }
    if (index === PIN_LENGTH - 1 && value) {
      const pin = digits.slice(0, PIN_LENGTH - 1).join("") + value;
      window.setTimeout(() => submitPin(pin), 250);
    }
  };

  const handleKeyDown = (
    index: number,
    e: React.KeyboardEvent<HTMLInputElement>
  ) => {
    if (e.key === "Backspace" && !digits[index] && index > 0) {
      e.preventDefault();
      setDigit(index - 1, "");
      inputsRef.current[index - 1]?.classList.remove("filled");
      inputsRef.current[index - 1]?.focus();
    }
    if (e.key === "ArrowLeft" && index > 0) {
      inputsRef.current[index - 1]?.focus();
    }
    if (e.key === "ArrowRight" && index < PIN_LENGTH - 1) {
      inputsRef.current[index + 1]?.focus();
    }
  };

  const handlePaste = (e: React.ClipboardEvent<HTMLInputElement>) => {
    e.preventDefault();
    const pasted = e.clipboardData.getData("text").trim();
    if (!/^\d{4}$/.test(pasted)) return;
    const next = pasted.split("");
    setDigits(next);
    inputsRef.current.forEach((el, i) => {
      if (el) {
        el.value = next[i];
        el.classList.add("filled");
      }
    });
    inputsRef.current[PIN_LENGTH - 1]?.focus();
    window.setTimeout(() => submitPin(pasted), 250);
  };

  return (
    <form
      id="loginForm"
      onSubmit={(e) => {
        e.preventDefault();
        submitPin(digits.join(""));
      }}
    >
      <div className="pin-input-section">
        <label className="pin-label">Enter 4-digit PIN</label>
        <div className="pin-container">
          {digits.map((digit, index) => (
            <input
              key={index}
              ref={(el) => {
                inputsRef.current[index] = el;
              }}
              type="password"
              className={`pin-digit${digit ? " filled" : ""}${error ? " error" : ""}`}
              value={digit}
              maxLength={1}
              pattern="[0-9]"
              inputMode="numeric"
              autoComplete={index === 0 ? "one-time-code" : "off"}
              aria-label={`PIN digit ${index + 1}`}
              disabled={loading}
              onChange={(e) => handleChange(index, e.target.value)}
              onKeyDown={(e) => handleKeyDown(index, e)}
              onPaste={handlePaste}
              required
            />
          ))}
        </div>
        <div className={`error-message${error ? " show" : ""}`} role="alert">
          Invalid PIN. Please try again.
        </div>
      </div>

      <button type="submit" className="login-button" disabled={loading}>
        {loading ? <span className="loading" aria-label="Checking" /> : "Unlock Access"}
      </button>
    </form>
  );
}
