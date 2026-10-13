import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: {
    default: "Sepnet LMS",
    template: "%s | Sepnet LMS",
  },
  description:
    "Sepnet learning platform — free and affordable technology education for young people in Ghana.",
};

const themeScript = `(function(){try{var t=localStorage.getItem('theme');document.body.classList.add(t==='light'?'light-mode':'dark-mode');}catch(e){document.body.classList.add('dark-mode');}})();`;

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link
          rel="preconnect"
          href="https://fonts.gstatic.com"
          crossOrigin="anonymous"
        />
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap"
          rel="stylesheet"
        />
        <link
          rel="stylesheet"
          href="https://cdn.jsdelivr.net/npm/cloudinary-video-player@1.10.6/dist/cld-video-player.min.css"
        />
      </head>
      <body suppressHydrationWarning>
        <script dangerouslySetInnerHTML={{ __html: themeScript }} />
        {children}
      </body>
    </html>
  );
}
