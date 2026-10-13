import type { Metadata } from "next";
import CertificateView from "@/components/CertificateView";
import { courses } from "@/lib/data";

export const metadata: Metadata = {
  title: "Certificate",
};

export default function CertificatePage() {
  return (
    <div className="content-area page active">
      <div className="section-header">
        <h2>Completion Certificate</h2>
      </div>
      <div id="certificatePanel">
        <CertificateView courses={courses} />
      </div>
    </div>
  );
}
