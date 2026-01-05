#!/usr/bin/env node

/**
 * PDF Generator for TrickBook Documentation
 *
 * Usage:
 *   node scripts/generate-pdf.js                    # Generate all PDFs
 *   node scripts/generate-pdf.js docs/intro.md     # Generate single PDF
 *   node scripts/generate-pdf.js docs/backend/     # Generate section PDFs
 */

const { mdToPdf } = require('md-to-pdf');
const fs = require('fs');
const path = require('path');

const DOCS_DIR = path.join(__dirname, '..', 'docs');
const OUTPUT_DIR = path.join(__dirname, '..', 'pdf-exports');

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
    h1 { color: #4A90D9; border-bottom: 2px solid #4A90D9; padding-bottom: 10px; }
    h2 { color: #2563a8; }
    code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; }
    pre { background: #1e1e1e; color: #d4d4d4; padding: 16px; border-radius: 6px; overflow-x: auto; }
    pre code { background: none; padding: 0; }
    table { border-collapse: collapse; width: 100%; margin: 16px 0; }
    th, td { border: 1px solid #ddd; padding: 8px 12px; text-align: left; }
    th { background: #4A90D9; color: white; }
    blockquote { border-left: 4px solid #4A90D9; margin: 0; padding-left: 16px; color: #666; }
    .admonition { padding: 16px; margin: 16px 0; border-radius: 6px; }
    .admonition-danger { background: #fee; border-left: 4px solid #c00; }
    .admonition-warning { background: #fff3cd; border-left: 4px solid #ffc107; }
    .admonition-tip { background: #d4edda; border-left: 4px solid #28a745; }
  `,
  pdf_options: {
    format: 'A4',
    margin: {
      top: '20mm',
      bottom: '20mm',
      left: '15mm',
      right: '15mm'
    },
    printBackground: true,
    headerTemplate: `
      <div style="font-size: 10px; width: 100%; text-align: center; color: #999;">
        TrickBook Documentation
      </div>
    `,
    footerTemplate: `
      <div style="font-size: 10px; width: 100%; text-align: center; color: #999;">
        Page <span class="pageNumber"></span> of <span class="totalPages"></span>
      </div>
    `,
    displayHeaderFooter: true
  },
  marked_options: {
    headerIds: true,
    gfm: true
  }
};

async function generatePdf(inputPath, outputPath) {
  try {
    console.log(`  Converting: ${path.basename(inputPath)}`);

    const pdf = await mdToPdf({ path: inputPath }, PDF_CONFIG);

    if (pdf) {
      fs.writeFileSync(outputPath, pdf.content);
      console.log(`  ✓ Generated: ${path.basename(outputPath)}`);
      return true;
    }
  } catch (error) {
    console.error(`  ✗ Error converting ${inputPath}:`, error.message);
    return false;
  }
}

function getAllMarkdownFiles(dir, fileList = []) {
  const files = fs.readdirSync(dir);

  for (const file of files) {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);

    if (stat.isDirectory()) {
      getAllMarkdownFiles(filePath, fileList);
    } else if (file.endsWith('.md')) {
      fileList.push(filePath);
    }
  }

  return fileList;
}

async function main() {
  const args = process.argv.slice(2);

  // Ensure output directory exists
  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }

  let filesToProcess = [];

  if (args.length > 0) {
    // Process specific file or directory
    const targetPath = path.resolve(args[0]);

    if (fs.statSync(targetPath).isDirectory()) {
      filesToProcess = getAllMarkdownFiles(targetPath);
    } else {
      filesToProcess = [targetPath];
    }
  } else {
    // Process all docs
    filesToProcess = getAllMarkdownFiles(DOCS_DIR);
  }

  console.log(`\nGenerating PDFs for ${filesToProcess.length} files...\n`);

  let success = 0;
  let failed = 0;

  for (const file of filesToProcess) {
    const relativePath = path.relative(DOCS_DIR, file);
    const outputFileName = relativePath.replace(/\//g, '_').replace('.md', '.pdf');
    const outputPath = path.join(OUTPUT_DIR, outputFileName);

    const result = await generatePdf(file, outputPath);
    if (result) success++;
    else failed++;
  }

  console.log(`\n✓ Complete: ${success} succeeded, ${failed} failed`);
  console.log(`  Output directory: ${OUTPUT_DIR}\n`);
}

main().catch(console.error);
