# GitHub + Vercel Deployment Guide

## Manual Setup Steps:

### 1. Create GitHub Repository
1. Go to https://github.com/new
2. Repository name: `storyline-variable-exporter`
3. Description: `Web app to extract and manage variables from Articulate Storyline .story files`
4. Make it Public (required for free Vercel)
5. Click "Create repository"

### 2. Upload Your Files
**Option A: GitHub Web Interface**
1. Click "uploading an existing file"
2. Drag your entire project folder
3. Commit message: "Initial commit - Storyline Variable Exporter"

**Option B: Git Commands** (if you have Git installed)
```bash
git init
git add .
git commit -m "Initial commit - Storyline Variable Exporter"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/storyline-variable-exporter.git
git push -u origin main
```

### 3. Deploy to Vercel
1. Go to https://vercel.com
2. Sign up with GitHub account
3. Click "New Project"
4. Import your `storyline-variable-exporter` repository
5. Framework Preset: "Other" (it's a static HTML file)
6. Root Directory: `apps/web` (where test.html is located)
7. Click "Deploy"

### 4. Configure Vercel Settings
- Build Command: Leave empty
- Output Directory: Leave empty  
- Install Command: Leave empty
- Root Directory: `apps/web`

### 5. Custom Domain (Optional)
- Add your domain in Vercel dashboard
- Update DNS records as instructed

## File Structure for Vercel:
```
storyline-variable-exporter/
├── apps/web/
│   ├── test.html          # Main app file
│   └── index.html         # Copy of test.html (Vercel default)
├── .gitignore
├── README.md
└── github-setup.md
```

## Production Optimizations:
1. Rename `test.html` to `index.html` for cleaner URLs
2. Add proper meta tags for SEO
3. Consider implementing the Tailwind CSS build process from production-setup.md
