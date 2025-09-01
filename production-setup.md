# Production Deployment Guide

## Option 1: Static Web Hosting (Recommended)

### Setup Steps:
1. **Install Tailwind CSS locally:**
   ```bash
   npm init -y
   npm install -D tailwindcss
   npx tailwindcss init
   ```

2. **Create tailwind.config.js:**
   ```js
   module.exports = {
     content: ["./src/**/*.{html,js}"],
     theme: { extend: {} },
     plugins: [],
   }
   ```

3. **Create input.css:**
   ```css
   @tailwind base;
   @tailwind components;
   @tailwind utilities;

   @layer components {
     .btn-primary {
       @apply bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors;
     }
     .btn-secondary {
       @apply bg-gray-200 text-gray-800 px-4 py-2 rounded-lg hover:bg-gray-300 focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 transition-colors;
     }
     .input-field {
       @apply w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent;
     }
   }
   ```

4. **Build CSS:**
   ```bash
   npx tailwindcss -i ./input.css -o ./dist/output.css --watch
   ```

5. **Update HTML:**
   ```html
   <link href="./dist/output.css" rel="stylesheet">
   <!-- Remove: <script src="https://cdn.tailwindcss.com"></script> -->
   ```

### Deployment Options:
- **Netlify**: Drag & drop dist folder
- **Vercel**: Connect GitHub repo
- **GitHub Pages**: Push to gh-pages branch
- **AWS S3 + CloudFront**: Upload static files

## Option 2: React Production Build

### Setup Steps:
1. **Convert to proper React app:**
   ```bash
   npx create-react-app storyline-exporter
   cd storyline-exporter
   npm install -D tailwindcss postcss autoprefixer
   npx tailwindcss init -p
   ```

2. **Move components to separate files:**
   - `src/components/VariableExplorer.jsx`
   - `src/components/FileUpload.jsx`
   - `src/utils/xmlParser.js`

3. **Build for production:**
   ```bash
   npm run build
   ```

4. **Deploy build folder** to hosting service

## Option 3: Electron Desktop App

### For offline/desktop use:
```bash
npm install -D electron
npm install -D electron-builder
```

## Security Considerations:
- All processing happens client-side
- No server required
- Files never leave user's browser
- HTTPS recommended for production domains

## Performance Optimizations:
- Minified CSS (~50KB vs 3MB CDN)
- Tree-shaking removes unused styles
- Better caching with versioned files
- Faster load times without external dependencies
