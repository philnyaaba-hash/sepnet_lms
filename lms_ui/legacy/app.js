// Course data - Single course with sub-courses and lessons
const courses = [
    {
        id: 1,
        title: "Complete Python Masterclass",
        description: "Master Python programming from beginner to advanced. This comprehensive course covers everything you need to know to become a proficient Python developer.",
        category: "Programming",
        duration: "36h 25m",
        totalLessons: 3,
        progress: 33,
        instructor: "Python Academy",
        thumbnail: "https://res.cloudinary.com/dwsl2ktt2/image/upload/v1790259229/Screenshot_24_o1pbnb.png",
        subCourses: [
            {
                id: 1,
                title: "Career Development",
                description: "Learn how Python can advance your career",
                lessons: [
                    {
                        id: 1,
                        title: "Advancing Your Career with Python",
                        duration: "12h 30m",
                        cloudinaryId: "01._Advancing_your_career_with_Python_gxiqvb",
                        completed: true
                    }
                ]
            },
            {
                id: 2,
                title: "Python Fundamentals",
                description: "Master the core concepts of Python programming",
                lessons: [
                    {
                        id: 2,
                        title: "Demystifying Python - SEPNET",
                        duration: "8h 45m",
                        cloudinaryId: "01._Demystifying_Python_SEPNET_taeg1m",
                        completed: false
                    },
                    {
                        id: 3,
                        title: "Starting with Python",
                        duration: "15h 20m",
                        cloudinaryId: "02._Starting_with_Python_axpavj",
                        completed: false
                    }
                ]
            }
        ]
    }
];

// Cloudinary configuration
const cloudinaryConfig = {
    cloudName: 'dwsl2ktt2',
    secure: true,
    thumbnailOffset: 3
};

// Announcements - NGO updates, class schedules and notices
const announcements = [
    {
        id: 1,
        title: "Welcome to the Sepnet Learning Platform",
        date: "2026-09-20",
        tag: "General",
        body: "We are excited to launch our online learning platform! All enrolled students can now access Python course videos anytime, anywhere. Start with the Complete Python Masterclass and track your progress as you learn."
    },
    {
        id: 2,
        title: "New Cohort Enrollment Open",
        date: "2026-09-18",
        tag: "Enrollment",
        body: "Enrollment for the next Python training cohort is now open. Seats are limited — message us on WhatsApp (+233 54 198 8383) to reserve your spot. Scholarships are available for eligible students."
    },
    {
        id: 3,
        title: "Weekly Live Q&A Sessions",
        date: "2026-09-15",
        tag: "Schedule",
        body: "Join our mentors every Saturday at 10:00 AM GMT for a live Q&A session. Bring your questions about the course material, projects, or your tech career path."
    }
];

// Downloadable resources - set url to a Cloudinary file link to enable download.
// Leave url as '' to show "Coming soon".
const resources = [
    {
        id: 1,
        title: "Python Basics Cheat Sheet",
        description: "Quick reference for syntax, data types and common operations.",
        type: "PDF",
        lesson: "Starting with Python",
        url: ""
    },
    {
        id: 2,
        title: "Course Slides - Demystifying Python",
        description: "All slides from the Demystifying Python sessions.",
        type: "PDF",
        lesson: "Demystifying Python - SEPNET",
        url: ""
    },
    {
        id: 3,
        title: "Practice Exercises",
        description: "Hands-on exercises with solutions to reinforce each lesson.",
        type: "ZIP",
        lesson: "Complete Python Masterclass",
        url: ""
    },
    {
        id: 4,
        title: "Career Guide - Tech in Ghana",
        description: "How to build a career in technology: CV tips, interview prep and opportunities.",
        type: "PDF",
        lesson: "Advancing Your Career with Python",
        url: ""
    }
];

// Progress persistence (localStorage)
const PROGRESS_KEY = 'sepnetProgress';
const STUDENT_NAME_KEY = 'sepnetStudentName';
let completedLessons = [];

function lessonKey(courseId, lessonId) {
    return `${courseId}-${lessonId}`;
}

function initProgress() {
    const saved = localStorage.getItem(PROGRESS_KEY);
    if (saved === null) {
        // Seed storage from initial course data on first run
        completedLessons = [];
        courses.forEach(course => course.subCourses.forEach(sc => sc.lessons.forEach(l => {
            if (l.completed) completedLessons.push(lessonKey(course.id, l.id));
        })));
        saveProgress();
    } else {
        try {
            completedLessons = JSON.parse(saved) || [];
        } catch (e) {
            completedLessons = [];
        }
    }
    // Apply stored state to course data
    courses.forEach(course => course.subCourses.forEach(sc => sc.lessons.forEach(l => {
        l.completed = completedLessons.includes(lessonKey(course.id, l.id));
    })));
    courses.forEach(updateCourseProgress);
}

function saveProgress() {
    localStorage.setItem(PROGRESS_KEY, JSON.stringify(completedLessons));
}

function updateCourseProgress(course) {
    let total = 0, done = 0;
    course.subCourses.forEach(sc => sc.lessons.forEach(l => {
        total++;
        if (l.completed) done++;
    }));
    course.progress = total ? Math.round((done / total) * 100) : 0;
    course.totalLessons = total;
}

function toggleLessonComplete(course, lesson) {
    const key = lessonKey(course.id, lesson.id);
    const idx = completedLessons.indexOf(key);
    if (idx === -1) {
        completedLessons.push(key);
        lesson.completed = true;
    } else {
        completedLessons.splice(idx, 1);
        lesson.completed = false;
    }
    saveProgress();
    updateCourseProgress(course);
    renderCourses(courses);
    updateLessonStatusUI(key, lesson.completed);
    updateMarkCompleteButton();
}

function updateLessonStatusUI(key, completed) {
    const item = document.querySelector(`.lesson-item[data-key="${key}"]`);
    if (!item) return;
    const status = item.querySelector('.lesson-status');
    status.classList.toggle('completed', completed);
    status.textContent = completed ? '✓' : '▶';
}

let currentContext = null; // { course, lesson }

function updateMarkCompleteButton() {
    const btn = document.getElementById('markCompleteBtn');
    const text = document.getElementById('markCompleteText');
    if (!currentContext) {
        btn.style.display = 'none';
        return;
    }
    btn.style.display = 'inline-flex';
    const done = currentContext.lesson.completed;
    text.textContent = done ? 'Completed' : 'Mark as Complete';
    btn.classList.toggle('completed', done);
}

// Generate Cloudinary video thumbnail URL
function getVideoThumbnail(cloudinaryId, offset = 3) {
    return `https://res.cloudinary.com/${cloudinaryConfig.cloudName}/video/upload/so_${offset}/w_800,h_450,c_fill,q_auto,f_auto/${cloudinaryId}.jpg`;
}

let currentPlayer = null;

// Initialize app
document.addEventListener('DOMContentLoaded', () => {
    // Check authentication
    if (sessionStorage.getItem('sepnetAuthenticated') !== 'true') {
        window.location.href = 'login.html';
        return;
    }
    
    initProgress();
    renderCourses(courses);
    renderAnnouncements();
    renderResources();
    setupEventListeners();
    setupNavigation();
    setupThemeToggle();
    loadSavedTheme();
});

// Render courses
function renderCourses(coursesToRender) {
    const courseGrid = document.getElementById('courseGrid');
    courseGrid.innerHTML = '';

    coursesToRender.forEach((course, index) => {
        const courseCard = createCourseCard(course, index);
        courseGrid.appendChild(courseCard);
    });
}

// Create course card element
function createCourseCard(course, index) {
    const card = document.createElement('div');
    card.className = 'course-card';
    card.style.animationDelay = `${index * 0.05}s`;
    
    // Use custom thumbnail or generate from video
    const thumbnail = course.thumbnail || getVideoThumbnail(course.subCourses[0].lessons[0].cloudinaryId, cloudinaryConfig.thumbnailOffset);
    
    card.innerHTML = `
        <div class="course-thumbnail">
            <img src="${thumbnail}" alt="${course.title}" loading="lazy" />
            <div class="play-overlay">
                <div class="play-btn">
                    <svg viewBox="0 0 24 24">
                        <path d="M8 5v14l11-7z"/>
                    </svg>
                </div>
            </div>
        </div>
        <div class="course-content">
            <span class="course-category">${course.category}</span>
            <h3 class="course-title">${course.title}</h3>
            <p class="course-description">${course.description}</p>
            <div class="course-meta">
                <span class="meta-item">
                    <svg viewBox="0 0 16 16" fill="none">
                        <circle cx="8" cy="8" r="6" stroke="currentColor" stroke-width="1.5"/>
                        <path d="M8 4v4l3 3" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                    </svg>
                    ${course.duration}
                </span>
                <span class="meta-item">
                    <svg viewBox="0 0 16 16" fill="none">
                        <path d="M2 4h12v8H2V4z" stroke="currentColor" stroke-width="1.5"/>
                        <path d="M6 8h4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                    </svg>
                    ${course.totalLessons} lessons
                </span>
            </div>
            <div class="progress-bar">
                <div class="progress-fill" style="width: ${course.progress}%"></div>
            </div>
        </div>
    `;

    card.addEventListener('click', () => openCourseModal(course));
    return card;
}

// Open course modal with sub-courses and lessons
function openCourseModal(course) {
    const modal = document.getElementById('courseModal');
    const modalTitle = document.getElementById('courseModalTitle');
    const lessonList = document.getElementById('lessonList');

    modalTitle.textContent = course.title;
    lessonList.innerHTML = '';

    let lessonCounter = 0;

    // Render sub-courses with lessons
    course.subCourses.forEach((subCourse) => {
        // Sub-course header
        const subCourseHeader = document.createElement('div');
        subCourseHeader.className = 'subcourse-header';
        subCourseHeader.innerHTML = `
            <div class="subcourse-title">${subCourse.title}</div>
            <div class="subcourse-description">${subCourse.description}</div>
        `;
        lessonList.appendChild(subCourseHeader);

        // Lessons within sub-course
        subCourse.lessons.forEach((lesson) => {
            lessonCounter++;
            const lessonItem = document.createElement('div');
            lessonItem.className = 'lesson-item';
            lessonItem.dataset.key = lessonKey(course.id, lesson.id);
            lessonItem.innerHTML = `
                <div class="lesson-number">${lessonCounter}</div>
                <div class="lesson-info">
                    <div class="lesson-title">${lesson.title}</div>
                    <div class="lesson-duration">${lesson.duration}</div>
                </div>
                <div class="lesson-status ${lesson.completed ? 'completed' : ''}">
                    ${lesson.completed ? '✓' : '▶'}
                </div>
            `;
            lessonItem.addEventListener('click', () => playLesson(course, lesson, lessonCounter - 1));
            lessonList.appendChild(lessonItem);
        });
    });

    // Auto-play first lesson
    if (course.subCourses.length > 0 && course.subCourses[0].lessons.length > 0) {
        playLesson(course, course.subCourses[0].lessons[0], 0);
    }

    modal.classList.add('active');
    document.body.style.overflow = 'hidden';
}

// Play a specific lesson
function playLesson(course, lesson, index) {
    currentContext = { course, lesson };
    updateMarkCompleteButton();

    const videoContainer = document.getElementById('videoContainer');
    const currentLessonTitle = document.getElementById('currentLessonTitle');
    const videoDuration = document.getElementById('videoDuration');
    const videoDescription = document.getElementById('videoDescription');

    currentLessonTitle.textContent = lesson.title;
    videoDuration.textContent = lesson.duration;
    videoDescription.textContent = `${course.title} - ${lesson.title}`;

    // Highlight active lesson
    const lessonItems = document.querySelectorAll('.lesson-item');
    lessonItems.forEach((item, i) => {
        item.classList.toggle('active', i === index);
    });

    // Clear previous player
    videoContainer.innerHTML = '';

    // Create video element
    const videoElement = document.createElement('video');
    videoElement.id = 'cloudinary-video-player';
    videoElement.className = 'cld-video-player cld-fluid';
    videoElement.controls = true;
    videoContainer.appendChild(videoElement);

    // Initialize Cloudinary video player
    try {
        if (currentPlayer) {
            currentPlayer.dispose();
        }
        
        currentPlayer = cloudinary.videoPlayer('cloudinary-video-player', {
            cloudName: cloudinaryConfig.cloudName,
            controls: true,
            autoplay: false,
            muted: false,
            loop: false,
            preload: 'auto',
            fluid: true,
            responsive: true,
            skin: 'light',
            colors: {
                base: '#6366f1',
                accent: '#8b5cf6',
                text: '#ffffff'
            },
            fontFace: 'Inter',
            showLogo: false,
            logoImageUrl: '',
            info: {
                title: lesson.title,
                subtitle: course.title,
                description: `${course.title} - ${lesson.title}`
            },
            transformation: {
                width: 1920,
                height: 1080,
                crop: 'limit',
                quality: 'auto',
                fetch_format: 'auto'
            },
            posterOptions: {
                transformation: {
                    start_offset: cloudinaryConfig.thumbnailOffset,
                    width: 1920,
                    height: 1080,
                    crop: 'fill',
                    quality: 'auto',
                    fetch_format: 'auto'
                }
            },
            playbackRates: [0.5, 0.75, 1, 1.25, 1.5, 2],
            chaptersButton: true,
            seekButtons: true,
            floatingWhenNotVisible: 'right',
            publicId: lesson.cloudinaryId,
            // Ensure all controls are visible
            controlBar: true,
            playButton: true,
            volumeControl: true,
            fullscreenButton: true,
            progressControl: true,
            currentTimeDisplay: true,
            durationDisplay: true,
            remainingTimeDisplay: true,
            playbackRateMenuButton: true,
            qualitySelector: true
        });
    } catch (error) {
        console.error('Error initializing Cloudinary player:', error);
        videoContainer.innerHTML = `
            <div style="padding: 40px; text-align: center; color: #64748b;">
                <svg width="64" height="64" viewBox="0 0 24 24" fill="none" style="margin: 0 auto 16px;">
                    <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2"/>
                    <path d="M12 8v4M12 16h.01" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                </svg>
                <h3 style="margin-bottom: 8px; color: #1e293b;">Video Player Error</h3>
                <p>Please check your Cloudinary configuration</p>
            </div>
        `;
    }
}

// Close course modal
function closeCourseModal() {
    const modal = document.getElementById('courseModal');
    modal.classList.remove('active');
    document.body.style.overflow = '';
    currentContext = null;
    updateMarkCompleteButton();
    
    // Destroy player
    if (currentPlayer) {
        try {
            currentPlayer.dispose();
            currentPlayer = null;
        } catch (error) {
            console.error('Error disposing player:', error);
        }
    }
}

// Setup event listeners
function setupEventListeners() {
    // Logout button
    const logoutBtn = document.getElementById('logoutBtn');
    if (logoutBtn) {
        logoutBtn.addEventListener('click', () => {
            sessionStorage.removeItem('sepnetAuthenticated');
            window.location.href = 'login.html';
        });
    }

    // Mark lesson complete
    const markCompleteBtn = document.getElementById('markCompleteBtn');
    if (markCompleteBtn) {
        markCompleteBtn.addEventListener('click', () => {
            if (currentContext) {
                toggleLessonComplete(currentContext.course, currentContext.lesson);
            }
        });
    }

    // WhatsApp help modal
    const whatsappBtn = document.getElementById('whatsappBtn');
    const helpModal = document.getElementById('helpModal');
    const closeHelp = document.getElementById('closeHelp');
    const helpForm = document.getElementById('helpForm');

    if (whatsappBtn) {
        whatsappBtn.addEventListener('click', () => {
            helpModal.classList.add('active');
        });
    }

    if (closeHelp) {
        closeHelp.addEventListener('click', () => {
            helpModal.classList.remove('active');
        });
    }

    if (helpModal) {
        helpModal.addEventListener('click', (e) => {
            if (e.target === helpModal) {
                helpModal.classList.remove('active');
            }
        });
    }

    if (helpForm) {
        helpForm.addEventListener('submit', (e) => {
            e.preventDefault();
            sendToWhatsApp();
        });
    }

    // Close modal
    document.getElementById('closeCourseModal').addEventListener('click', closeCourseModal);
    document.getElementById('courseModal').addEventListener('click', (e) => {
        if (e.target.id === 'courseModal') {
            closeCourseModal();
        }
    });

    // Escape key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            closeCourseModal();
        }
    });

    // Search functionality
    const searchInput = document.getElementById('searchInput');
    searchInput.addEventListener('input', (e) => {
        const searchTerm = e.target.value.toLowerCase();
        const filteredCourses = courses.filter(course => 
            course.title.toLowerCase().includes(searchTerm) ||
            course.description.toLowerCase().includes(searchTerm) ||
            course.category.toLowerCase().includes(searchTerm)
        );
        renderCourses(filteredCourses);
    });
}

// Setup theme toggle
function setupThemeToggle() {
    const themeToggle = document.getElementById('themeToggle');
    
    themeToggle.addEventListener('click', () => {
        const isDark = document.body.classList.contains('dark-mode');
        
        if (isDark) {
            document.body.classList.remove('dark-mode');
            document.body.classList.add('light-mode');
        } else {
            document.body.classList.remove('light-mode');
            document.body.classList.add('dark-mode');
        }
        
        saveTheme();
    });
}

// Save theme preference
function saveTheme() {
    const isDark = document.body.classList.contains('dark-mode');
    localStorage.setItem('theme', isDark ? 'dark' : 'light');
}

// Load saved theme (default to dark)
function loadSavedTheme() {
    const savedTheme = localStorage.getItem('theme');
    // Default to dark mode if no preference saved
    if (savedTheme !== 'light') {
        document.body.classList.add('dark-mode');
    }
}

// Send help request to WhatsApp
function sendToWhatsApp() {
    const name = document.getElementById('helpName').value.trim();
    const subject = document.getElementById('helpSubject').value;
    const message = document.getElementById('helpMessage').value.trim();

    if (!name || !subject || !message) {
        alert('Please fill in all fields');
        return;
    }

    const phoneNumber = '233541988383';
    const whatsappMessage = `*Sepnet LMS Support Request*\n\n*Name:* ${name}\n*Subject:* ${subject}\n\n*Message:*\n${message}`;
    const encodedMessage = encodeURIComponent(whatsappMessage);
    const whatsappURL = `https://wa.me/${phoneNumber}?text=${encodedMessage}`;

    window.open(whatsappURL, '_blank');
    
    // Close modal and reset form
    document.getElementById('helpModal').classList.remove('active');
    document.getElementById('helpForm').reset();
}

// Page definitions
const pages = {
    courses: { id: 'coursesPage', title: 'My Courses', subtitle: 'Continue your learning journey' },
    announcements: { id: 'announcementsPage', title: 'Announcements', subtitle: 'News and updates from Sepnet' },
    resources: { id: 'resourcesPage', title: 'Resources', subtitle: 'Downloadable learning materials' },
    certificate: { id: 'certificatePage', title: 'Certificate', subtitle: 'Claim your completion certificate' },
    about: { id: 'aboutPage', title: 'About Sepnet', subtitle: 'Our mission and impact' }
};

// Setup navigation
function setupNavigation() {
    const navItems = document.querySelectorAll('.nav-item');
    const searchBox = document.querySelector('.search-box');

    navItems.forEach(item => {
        item.addEventListener('click', (e) => {
            e.preventDefault();
            const page = item.dataset.page;
            if (!pages[page]) return;

            navItems.forEach(nav => nav.classList.remove('active'));
            item.classList.add('active');

            document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
            document.getElementById(pages[page].id).classList.add('active');

            document.querySelector('.page-title').textContent = pages[page].title;
            document.querySelector('.page-subtitle').textContent = pages[page].subtitle;

            if (searchBox) {
                searchBox.style.display = page === 'courses' ? '' : 'none';
            }

            if (page === 'certificate') {
                renderCertificate();
            }
        });
    });
}

// Render announcements
function renderAnnouncements() {
    const list = document.getElementById('announcementsList');
    if (!list) return;
    list.innerHTML = '';

    announcements.forEach((a, i) => {
        const el = document.createElement('div');
        el.className = 'announcement-card';
        el.style.animationDelay = `${i * 0.05}s`;
        el.innerHTML = `
            <div class="announcement-top">
                <span class="announcement-tag tag-${a.tag.toLowerCase()}">${a.tag}</span>
                <span class="announcement-date">${formatDate(a.date)}</span>
            </div>
            <h3>${a.title}</h3>
            <p>${a.body}</p>
        `;
        list.appendChild(el);
    });
}

function formatDate(dateStr) {
    const d = new Date(dateStr);
    return d.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
}

// Render resources
function renderResources() {
    const list = document.getElementById('resourcesList');
    if (!list) return;
    list.innerHTML = '';

    resources.forEach((r, i) => {
        const el = document.createElement('div');
        el.className = 'resource-card';
        el.style.animationDelay = `${i * 0.05}s`;
        const available = !!r.url;
        el.innerHTML = `
            <div class="resource-icon type-${r.type.toLowerCase()}">${r.type}</div>
            <div class="resource-info">
                <h3>${r.title}</h3>
                <p>${r.description}</p>
                <span class="resource-lesson">${r.lesson}</span>
            </div>
            ${available
                ? `<a class="resource-download" href="${r.url}" target="_blank" rel="noopener" download>Download</a>`
                : `<span class="resource-soon">Coming soon</span>`}
        `;
        list.appendChild(el);
    });
}

// Render certificate page
function renderCertificate() {
    const panel = document.getElementById('certificatePanel');
    if (!panel) return;
    const course = courses[0];
    const savedName = localStorage.getItem(STUDENT_NAME_KEY) || '';

    if (course.progress < 100) {
        panel.innerHTML = `
            <div class="certificate-locked">
                <div class="certificate-lock-icon">
                    <svg width="40" height="40" viewBox="0 0 24 24" fill="none">
                        <rect x="5" y="11" width="14" height="9" rx="2" stroke="currentColor" stroke-width="1.5"/>
                        <path d="M8 11V7a4 4 0 018 0v4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                    </svg>
                </div>
                <h3>Certificate Locked</h3>
                <p>Complete all lessons in <strong>${course.title}</strong> to unlock your certificate.</p>
                <div class="progress-bar certificate-progress">
                    <div class="progress-fill" style="width: ${course.progress}%"></div>
                </div>
                <span class="certificate-progress-label">${course.progress}% complete</span>
            </div>
        `;
        return;
    }

    panel.innerHTML = `
        <div class="certificate-form">
            <label for="studentName">Your Full Name</label>
            <div class="certificate-form-row">
                <input type="text" id="studentName" placeholder="Enter your full name" value="${escapeHtml(savedName)}" />
                <button class="generate-cert-btn" id="generateCertBtn">Generate Certificate</button>
            </div>
        </div>
        <div id="certificateArea"></div>
    `;

    document.getElementById('generateCertBtn').addEventListener('click', generateCertificate);
    document.getElementById('studentName').addEventListener('keydown', (e) => {
        if (e.key === 'Enter') generateCertificate();
    });
    if (savedName) generateCertificate();
}

function generateCertificate() {
    const nameInput = document.getElementById('studentName');
    const name = nameInput.value.trim();
    if (!name) {
        nameInput.focus();
        nameInput.classList.add('input-error');
        setTimeout(() => nameInput.classList.remove('input-error'), 600);
        return;
    }
    localStorage.setItem(STUDENT_NAME_KEY, name);

    const course = courses[0];
    const area = document.getElementById('certificateArea');
    area.innerHTML = `
        <div class="certificate" id="printableCertificate">
            <div class="certificate-border">
                <img src="https://res.cloudinary.com/dwsl2ktt2/image/upload/v1790260220/sepnetghana_jjq8vj.jpg" alt="Sepnet" class="certificate-logo" />
                <div class="certificate-org">Sepnet</div>
                <h2 class="certificate-heading">Certificate of Completion</h2>
                <p class="certificate-presented">This certificate is proudly presented to</p>
                <div class="certificate-name">${escapeHtml(name)}</div>
                <p class="certificate-body">for successfully completing the course</p>
                <div class="certificate-course">${escapeHtml(course.title)}</div>
                <div class="certificate-footer">
                    <div class="certificate-field">
                        <div class="certificate-line">${new Date().toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' })}</div>
                        <div class="certificate-caption">Date Completed</div>
                    </div>
                    <div class="certificate-seal">★</div>
                    <div class="certificate-field">
                        <div class="certificate-line">Sepnet Academy</div>
                        <div class="certificate-caption">Authorized Signature</div>
                    </div>
                </div>
            </div>
        </div>
        <div class="certificate-actions no-print">
            <button class="print-cert-btn" id="printCertBtn">
                <svg width="18" height="18" viewBox="0 0 20 20" fill="none">
                    <path d="M6 8V3h8v5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                    <rect x="3" y="8" width="14" height="6" rx="1.5" stroke="currentColor" stroke-width="1.5"/>
                    <path d="M6 12h8v5H6v-5z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/>
                </svg>
                Print / Save as PDF
            </button>
        </div>
    `;

    document.getElementById('printCertBtn').addEventListener('click', () => window.print());
}

function escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}

// Utility function to format time
function formatTime(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
}

// Export for debugging
window.LMS = {
    courses,
    announcements,
    resources,
    cloudinaryConfig,
    renderCourses,
    openCourseModal,
    playLesson,
    closeCourseModal,
    toggleLessonComplete,
    generateCertificate
};