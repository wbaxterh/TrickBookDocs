#!/usr/bin/env node

/**
 * Combined PDF Generator for TrickBook Documentation
 * Generates a single PDF containing all documentation
 */

const { mdToPdf } = require('md-to-pdf');
const fs = require('fs');
const path = require('path');

const DOCS_DIR = path.join(__dirname, '..', 'docs');
const OUTPUT_DIR = path.join(__dirname, '..', 'pdf-exports');
const OUTPUT_FILE = path.join(OUTPUT_DIR, 'TrickBook-Documentation-Complete.pdf');

// Order of sections for combined PDF
const SECTION_ORDER = [
  'intro.md',
  'architecture/overview.md',
  'architecture/tech-stack.md',
  'architecture/data-flow.md',
  'backend/overview.md',
  'backend/api-endpoints.md',
  'backend/authentication.md',
  'backend/database.md',
  'backend/security.md',
  'mobile/overview.md',
  'mobile/navigation.md',
  'mobile/state-management.md',
  'mobile/api-integration.md',
  'mobile/build-configuration.md',
  'deployment/app-store.md',
  'deployment/google-play.md',
  'deployment/backend.md',
  'deployment/ci-cd.md',
  'roadmap/priorities.md',
  'roadmap/security-fixes.md',
  'roadmap/efficiency-improvements.md'
];

const PDF_CONFIG = {
  stylesheet: [
    'https://cdnjs.cloudflare.com/ajax/libs/github-markdown-css/5.2.0/github-markdown.min.css'
  ],
  css: `
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      max-width: 800px;
      margin: 0 auto;
      padding: 20px;
    }
    h1 { color: #4A90D9; border-bottom: 2px solid #4A90D9; padding-bottom: 10px; page-break-before: always; }
    h1:first-of-type { page-break-before: avoid; }
    h2 { color: #2563a8; }
    code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; }
    pre { background: #1e1e1e; color: #d4d4d4; padding: 16px; border-radius: 6px; overflow-x: auto; }
    pre code { background: none; padding: 0; }
    table { border-collapse: collapse; width: 100%; margin: 16px 0; }
    th, td { border: 1px solid #ddd; padding: 8px 12px; text-align: left; }
    th { background: #4A90D9; color: white; }
    blockquote { border-left: 4px solid #4A90D9; margin: 0; padding-left: 16px; color: #666; }
    .page-break { page-break-after: always; }
    .toc { margin: 20px 0; }
    .toc a { text-decoration: none; color: #4A90D9; }
    .cover-page { text-align: center; padding: 100px 20px; }
    .cover-page h1 { font-size: 48px; border: none; color: #4A90D9; }
    .cover-page p { font-size: 18px; color: #666; }
  `,
  pdf_options: {
    format: 'A4',
    margin: {
      top: '25mm',
      bottom: '25mm',
      left: '20mm',
      right: '20mm'
    },
    printBackground: true,
    displayHeaderFooter: true,
    headerTemplate: `
      <div style="font-size: 10px; width: 100%; text-align: center; color: #999; padding: 0 20px;">
        TrickBook Documentation
      </div>
    `,
    footerTemplate: `
      <div style="font-size: 10px; width: 100%; text-align: center; color: #999;">
        Page <span class="pageNumber"></span> of <span class="totalPages"></span>
      </div>
    `
  }
};

function stripFrontmatter(content) {
  // Remove YAML frontmatter
  return content.replace(/^---[\s\S]*?---\n*/m, '');
}

async function main() {
  console.log('\nGenerating combined PDF documentation...\n');

  // Ensure output directory exists
  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }

  // Build combined markdown
  let combinedContent = `
<div class="cover-page">

# TrickBook

## Technical Documentation

Mobile App & Backend Platform

---

*Generated: ${new Date().toLocaleDateString()}*

</div>

<div class="page-break"></div>

## Table of Contents

${SECTION_ORDER.map((file, i) => {
  const name = file.replace('.md', '').replace('/', ' - ').replace(/-/g, ' ');
  const title = name.charAt(0).toUpperCase() + name.slice(1);
  return `${i + 1}. ${title}`;
}).join('\n')}

<div class="page-break"></div>

`;

  for (const file of SECTION_ORDER) {
    const filePath = path.join(DOCS_DIR, file);

    if (fs.existsSync(filePath)) {
      console.log(`  Adding: ${file}`);
      const content = fs.readFileSync(filePath, 'utf-8');
      const cleanContent = stripFrontmatter(content);
      combinedContent += cleanContent + '\n\n---\n\n';
    } else {
      console.log(`  ⚠ Missing: ${file}`);
    }
  }

  // Write temporary combined markdown
  const tempFile = path.join(OUTPUT_DIR, '_combined.md');
  fs.writeFileSync(tempFile, combinedContent);

  // Generate PDF
  console.log('\n  Generating PDF...');

  try {
    const pdf = await mdToPdf({ path: tempFile }, PDF_CONFIG);

    if (pdf) {
      fs.writeFileSync(OUTPUT_FILE, pdf.content);
      console.log(`\n✓ Generated: ${OUTPUT_FILE}`);
    }
  } catch (error) {
    console.error('Error generating PDF:', error.message);
  }

  // Clean up temp file
  fs.unlinkSync(tempFile);

  console.log('');
}

main().catch(console.error);
