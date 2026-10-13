// CONFIGURATION EXAMPLE
// Copy this configuration to app.js and update with your Cloudinary details

// Step 1: Get your Cloudinary cloud name from https://cloudinary.com/console
const cloudinaryConfig = {
    cloudName: 'demo', // Replace 'demo' with your actual cloud name
    secure: true
};

// Step 2: Upload videos to Cloudinary and get their public IDs
// Example: If you upload "lesson1.mp4", the public ID might be "lesson1" or "videos/lesson1"

// Step 3: Update the courses array with your video public IDs
const courses = [
    {
        id: 1,
        title: "Introduction to Web Development",
        description: "Learn the fundamentals of HTML, CSS, and JavaScript to build modern websites.",
        category: "Web Development",
        duration: "2h 15m",
        lessons: 12,
        progress: 0,
        instructor: "John Smith",
        cloudinaryId: "your-video-public-id-here", // Replace with actual Cloudinary public ID
        thumbnail: "https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=800&q=80"
    },
    {
        id: 2,
        title: "CSS Masterclass",
        description: "Master modern CSS including Flexbox, Grid, animations, and responsive design.",
        category: "Design",
        duration: "3h 30m",
        lessons: 18,
        progress: 0,
        instructor: "Jane Doe",
        cloudinaryId: "your-second-video-id", // Replace with actual Cloudinary public ID
        thumbnail: "https://images.unsplash.com/photo-1507721999472-8ed4421c4af2?w=800&q=80"
    }
];

// FINDING YOUR CLOUDINARY PUBLIC ID:
// 1. Log in to https://cloudinary.com/console
// 2. Go to "Media Library"
// 3. Upload your video
// 4. Click on the uploaded video
// 5. Copy the "Public ID" field
// Example: "videos/my-course/lesson-1"

// TEST WITH CLOUDINARY DEMO VIDEO:
// You can test with Cloudinary's demo video:
// cloudinaryId: "dog" (this is a public demo video)

// ADVANCED CONFIGURATION:
// You can also use full Cloudinary URLs:
// cloudinaryId: "https://res.cloudinary.com/your-cloud-name/video/upload/v1234567890/your-video-id"

console.log('Configuration loaded! Update app.js with your Cloudinary credentials.');