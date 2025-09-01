# Storyline Variable Exporter

Extract, analyze, and manage variables from Articulate Storyline .story files.

## 🚀 Live Demo

**Deployed at:** https://storyline-variable-exporter.vercel.app

## ✨ Features

- **Variable Extraction**: Parse .story files to extract all variables
- **Usage Analysis**: Find where variables are used in slides and JavaScript
- **CSV Export**: Export variables with usage data
- **Modern UI**: Clean interface with filtering and sorting
- **Browser-Based**: No server required - runs entirely in your browser

## 🎯 Quick Start

1. Visit the live demo or open `index.html` locally
2. Upload your .story file
3. View variables in the explorer
4. Export to CSV for documentation

## 📁 File Structure

- `index.html` - Main application (deployment-ready)
- `apps/web/test.html` - Development version with full features
- `.gitignore` - Git ignore rules
- `github-setup.md` - Deployment instructions

## 🔧 Technical Stack

- **React 18** with Babel standalone
- **Tailwind CSS** for styling
- **JSZip** for .story file processing
- **DOMParser** for XML parsing
- **100% Client-Side** - no backend required

## 🚀 Deployment

### Vercel (Recommended)
1. Fork this repository
2. Connect to Vercel
3. Deploy with default settings

### Local Development
```bash
# No build required - just open in browser
open index.html
```

## 📝 License

MIT - Feel free to use and modify
