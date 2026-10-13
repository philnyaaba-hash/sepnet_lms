import { createHmac, timingSafeEqual } from "crypto";

export const SESSION_COOKIE = "sepnet_session";
const SESSION_MESSAGE = "sepnet-authenticated";
const SESSION_MAX_AGE_MS = 7 * 24 * 60 * 60 * 1000;
const DEV_SECRET = "sepnet-dev-secret-do-not-use-in-production";

function secret(): string {
  return process.env.LMS_SESSION_SECRET || DEV_SECRET;
}

export function expectedPin(): string {
  return process.env.LMS_PIN || "2115";
}

function sign(message: string): string {
  return createHmac("sha256", secret()).update(message).digest("hex");
}

function safeEqual(a: string, b: string): boolean {
  const bufA = Buffer.from(a, "utf8");
  const bufB = Buffer.from(b, "utf8");
  if (bufA.length !== bufB.length) return false;
  return timingSafeEqual(bufA, bufB);
}

export function createSessionToken(): string {
  const issuedAt = Date.now();
  return `${issuedAt}.${sign(`${SESSION_MESSAGE}:${issuedAt}`)}`;
}

export function isValidPin(pin: unknown): boolean {
  return typeof pin === "string" && pin.length === 4 && pin === expectedPin();
}

export function verifySessionToken(token: string | undefined | null): boolean {
  if (!token) return false;
  const [issuedRaw, signature] = token.split(".");
  if (!issuedRaw || !signature) return false;

  const issuedAt = Number.parseInt(issuedRaw, 10);
  if (!Number.isFinite(issuedAt)) return false;
  if (Date.now() - issuedAt > SESSION_MAX_AGE_MS) return false;

  return safeEqual(signature, sign(`${SESSION_MESSAGE}:${issuedAt}`));
}
