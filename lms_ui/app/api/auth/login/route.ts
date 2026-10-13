import { NextResponse } from "next/server";
import {
  SESSION_COOKIE,
  createSessionToken,
  isValidPin,
} from "@/lib/auth";

export async function POST(request: Request) {
  let pin: unknown;
  try {
    const body = await request.json();
    pin = body?.pin;
  } catch {
    return NextResponse.json(
      { ok: false, error: "Invalid request body" },
      { status: 400 }
    );
  }

  if (!isValidPin(pin)) {
    return NextResponse.json(
      { ok: false, error: "Invalid PIN. Please try again." },
      { status: 401 }
    );
  }

  const response = NextResponse.json({ ok: true });
  response.cookies.set(SESSION_COOKIE, createSessionToken(), {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: 60 * 60 * 24 * 7,
  });
  return response;
}
