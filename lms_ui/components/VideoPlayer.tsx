"use client";

import { useEffect, useRef } from "react";
import { cloudinaryConfig } from "@/lib/cloudinary";

const CVP_SRC =
  "https://cdn.jsdelivr.net/npm/cloudinary-video-player@1.10.6/dist/cld-video-player.min.js";

declare global {
  interface Window {
    cloudinary?: {
      videoPlayer: (
        element: string | HTMLVideoElement,
        options: Record<string, unknown>
      ) => { dispose: () => void };
    };
  }
}

interface VideoPlayerProps {
  publicId: string;
  title: string;
  subtitle: string;
}

function loadCvpScript(): Promise<void> {
  if (window.cloudinary) return Promise.resolve();
  const existing = document.querySelector<HTMLScriptElement>(
    `script[src="${CVP_SRC}"]`
  );
  if (existing) {
    return new Promise((resolve, reject) => {
      existing.addEventListener("load", () => resolve(), { once: true });
      existing.addEventListener("error", () => reject(new Error("CVP load failed")), {
        once: true,
      });
    });
  }
  return new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = CVP_SRC;
    script.async = true;
    script.onload = () => resolve();
    script.onerror = () => reject(new Error("CVP load failed"));
    document.body.appendChild(script);
  });
}

function getVideoSrc(publicId: string) {
  return `https://res.cloudinary.com/${cloudinaryConfig.cloudName}/video/upload/q_auto,f_auto/${publicId}.mp4`;
}

export default function VideoPlayer({ publicId, title, subtitle }: VideoPlayerProps) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const playerRef = useRef<{ dispose: () => void } | null>(null);
  const errorRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    let cancelled = false;

    async function init() {
      if (!videoRef.current) return;

      videoRef.current.src = getVideoSrc(publicId);
      videoRef.current.controls = true;
      videoRef.current.preload = "metadata";

      try {
        await loadCvpScript();
      } catch {
        if (errorRef.current) errorRef.current.hidden = false;
        return;
      }
      if (cancelled || !videoRef.current || !window.cloudinary) return;

      try {
        playerRef.current?.dispose();
      } catch {
        /* player already disposed */
      }

      try {
        playerRef.current = window.cloudinary.videoPlayer(videoRef.current, {
          cloudName: cloudinaryConfig.cloudName,
          controls: true,
          autoplay: false,
          muted: false,
          loop: false,
          preload: "metadata",
          fluid: true,
          responsive: true,
          skin: "dark",
          controlBar: {
            fullscreenToggle: true,
            remainingTimeDisplay: true,
            playToggle: true,
            progressControl: true,
            volumePanel: true,
            playbackRateMenuButton: true,
          },
          playbackRates: [0.5, 0.75, 1, 1.25, 1.5, 2],
          seekButtons: {
            forward: 10,
            backward: 10,
          },
          chaptersButton: true,
          bigPlayButton: true,
          nativeControls: false,
          colors: {
            base: "#a8543c",
            accent: "#c4826b",
            text: "#ffffff",
          },
          fontFace: "Inter",
          showLogo: false,
          info: {
            title,
            subtitle,
            description: `${subtitle} - ${title}`,
          },
          transformation: {
            width: 1920,
            height: 1080,
            crop: "limit",
            quality: "auto",
            fetch_format: "auto",
          },
          posterOptions: {
            transformation: {
              start_offset: cloudinaryConfig.thumbnailOffset,
              width: 1920,
              height: 1080,
              crop: "fill",
              quality: "auto",
              fetch_format: "auto",
            },
          },
          publicId,
        });
      } catch (error) {
        console.error("Error initializing Cloudinary player:", error);
        if (videoRef.current) {
          videoRef.current.controls = true;
        }
        if (errorRef.current) errorRef.current.hidden = true;
      }
    }

    init();

    return () => {
      cancelled = true;
      try {
        playerRef.current?.dispose();
      } catch {
        /* ignore */
      }
      playerRef.current = null;
    };
  }, [publicId, title, subtitle]);

  return (
    <div className="video-container">
      <video
        ref={videoRef}
        className="cld-video-player cld-fluid"
        controls
        playsInline
        preload="metadata"
        src={getVideoSrc(publicId)}
      />
      <div className="video-error" ref={errorRef} hidden>
        <svg width="64" height="64" viewBox="0 0 24 24" fill="none">
          <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="2" />
          <path
            d="M12 8v4M12 16h.01"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
          />
        </svg>
        <h3>Video Player Error</h3>
        <p>Please check your connection and try again.</p>
      </div>
    </div>
  );
}
