# Sepnet - Premium LMS ✨

A **lightweight**, **modern**, and **beautiful** Learning Management System with Cloudinary video integration.

## 🎨 Features

### Premium UI/UX
- ✨ **Modern Design** - Clean, minimalist interface with Inter font
- 🎭 **Smooth Animations** - Buttery 60fps transitions and micro-interactions
- 📱 **Fully Responsive** - Perfect on desktop, tablet, and mobile
- 🌈 **Gradient Accents** - Beautiful purple-to-blue gradients throughout
- 💫 **Hover Effects** - Engaging card lifts, glows, and transformations
- 🎯 **Active States** - Clear visual feedback for all interactions

### Cloudinary Video Player
- 🎬 **Full Controls** - Play, pause, volume, fullscreen, seek
- ⚡ **Adaptive Streaming** - Auto-optimized quality based on bandwidth
- 🔄 **Playback Speed** - 0.5x, 0.75x, 1x, 1.25x, 1.5x, 2x
- 📑 **Chapter Navigation** - Jump to specific sections
- 🎈 **Floating Player** - Continues playing when scrolled
- 🎨 **Custom Theme** - Matches your LMS branding

### Course Management
- 📚 **Course Cards** - Beautiful thumbnails with hover effects
- 📊 **Progress Tracking** - Visual progress bars with shimmer animation
- 🔍 **Live Search** - Instant filtering by title, description, category
- 🏷️ **Categories** - Color-coded course tags
- ⏱️ **Duration & Lessons** - Clear course metadata

### Dashboard
- 📈 **Statistics** - Enrolled courses, completed, learning time, certificates
- 🎯 **Goal Tracking** - Visual progress indicators
- 🏆 **Achievements** - Certificate counter

## 🚀 Quick Start

### 1. Open the LMS
Simply open `index.html` in your browser, or start a local server:

```bash
# Using PHP
cd C:\Users\TGNE\Desktop\lms_ui
php -S localhost:8000

# Using Python
python -m http.server 8000

# Using Node.js
npx http-server -p 8000
```

Then visit: **http://localhost:8000**

### 2. Configure Cloudinary

Your LMS is **already configured** with:
- **Cloud Name:** `dwsl2ktt2`
- **3 Python Courses** ready to play

### 3. Add More Videos

Edit `app.js` and add to the `courses` array:

```javascript
{
    id: 4,
    title: "Your Course Title",
    description: "Course description here",
    category: "Category",
    duration: "10h 30m",
    lessons: 40,
    progress: 0,
    instructor: "Instructor Name",
    cloudinaryId: "your-video-public-id",
    thumbnail: "https://your-image-url.jpg"
}
```

## 📁 File Structure

```
lms_ui/
├── index.html          # Main application (12KB)
├── styles.css          # Premium styles (15KB)
├── app.js             # Logic & Cloudinary integration (12KB)
├── README.md          # This file
└── CONFIG_EXAMPLE.js  # Configuration guide
```

**Total Size:** ~50KB (lightweight!)

## 🎨 Customization

### Change Colors
Edit CSS variables in `styles.css`:

```css
:root {
    --primary: #6366f1;      /* Main purple */
    --secondary: #8b5cf6;    /* Accent purple */
    --success: #10b981;      /* Green */
    --warning: #f59e0b;      /* Orange */
    --danger: #ef4444;       /* Red */
}
```

### Update Logo
Replace the SVG in `index.html` line 14-24.

### Modify Animations
Adjust timing in `styles.css`:
- `transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);`
- Change `0.4s` for faster/slower animations

## 🎯 UI Improvements Made

### Removed
- ❌ User profile section (no auth needed)
- ❌ Notification button
- ❌ Unnecessary UI clutter

### Enhanced
- ✅ **Sidebar** - Gradient background, better spacing, hover animations
- ✅ **Navigation** - Active indicator bar, smooth transitions
- ✅ **Header** - Larger typography, better search box
- ✅ **Stat Cards** - Gradient backgrounds, hover lift, top border animation
- ✅ **Course Cards** - Rounded corners, gradient borders, image zoom
- ✅ **Play Button** - Pulse animation, scale on hover
- ✅ **Progress Bars** - Shimmer effect, smoother transitions
- ✅ **Modal** - Better spacing, gradient header, rotating close button
- ✅ **Typography** - Bolder weights, better letter spacing
- ✅ **Shadows** - Layered, more realistic depth

## 🌟 Design Highlights

1. **Gradient Borders** - Course cards get a purple gradient border on hover
2. **Pulse Animation** - Play button has a subtle pulse effect
3. **Shimmer Effect** - Progress bars have an animated shine
4. **3D Lift** - Cards lift and scale on hover
5. **Smooth Easing** - All animations use cubic-bezier for natural motion
6. **Layered Shadows** - Multiple shadow layers for realistic depth
7. **Backdrop Blur** - Modal overlay has a frosted glass effect
8. **Color Transitions** - Icons change color on hover

## 📊 Browser Support

- ✅ Chrome/Edge (latest)
- ✅ Firefox (latest)
- ✅ Safari (latest)
- ✅ Mobile browsers

## 🔧 Cloudinary Setup

### Finding Your Video Public ID

1. Go to [Cloudinary Console](https://cloudinary.com/console)
2. Navigate to **Media Library**
3. Upload your video
4. Click on the video
5. Copy the **Public ID**

Example: `videos/my-course/lesson-1`

### Video URL Format

```
https://res.cloudinary.com/YOUR_CLOUD_NAME/video/upload/v1234567890/YOUR_PUBLIC_ID.mp4
```

Extract: `YOUR_PUBLIC_ID` (without .mp4 extension)

## 💡 Tips

- **Thumbnails**: Use high-quality images (800px+ width)
- **Progress**: Update the `progress` field (0-100) as users complete lessons
- **Search**: Works on title, description, and category
- **Performance**: Cloudinary auto-optimizes video quality

## 🎓 Next Steps (Optional Enhancements)

- [ ] Add user authentication
- [ ] Implement progress saving to database
- [ ] Add quiz/assessment features
- [ ] Create admin panel for course management
- [ ] Add certificate generation
- [ ] Implement discussion forums
- [ ] Add note-taking features
- [ ] Create mobile app version
- [ ] Add dark mode toggle
- [ ] Implement offline video download

## 📝 License

MIT License - Free to use for any project!

## 🆘 Support

- [Cloudinary Docs](https://cloudinary.com/documentation)
- [Video Player API](https://cloudinary.com/documentation/video_player_api_reference)

---

**Built with ❤️ for modern learning**

Enjoy your premium LMS! 🎉