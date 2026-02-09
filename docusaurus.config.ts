import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'TrickBook Docs',
  tagline: 'Technical documentation for the TrickBook mobile app and platform',
  favicon: 'img/favicon.ico',

  future: {
    v4: true,
  },

  // Custom domain deployment via GitHub Pages
  url: 'https://docs.thetrickbook.com',
  baseUrl: '/',

  organizationName: 'wbaxterh',
  projectName: 'TrickBookDocs',
  trailingSlash: false,

  onBrokenLinks: 'throw',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  // Mermaid markdown support
  markdown: {
    mermaid: true,
  },

  // Add Mermaid theme
  themes: ['@docusaurus/theme-mermaid'],

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          editUrl: 'https://github.com/wbaxterh/TrickBookDocs/tree/main/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    image: 'img/trickbook-social-card.jpg',
    colorMode: {
      defaultMode: 'dark',
      respectPrefersColorScheme: true,
    },
    // Mermaid configuration
    mermaid: {
      theme: {
        light: 'neutral',
        dark: 'dark',
      },
    },
    navbar: {
      title: 'TrickBook',
      style: 'dark',
      logo: {
        alt: 'TrickBook Logo',
        src: 'img/TrickBookLogo.png',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Documentation',
        },
        {
          href: 'https://thetrickbook.com',
          label: 'Website',
          position: 'right',
        },
        {
          href: 'https://github.com/wbaxterh/TrickBookDocs',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Documentation',
          items: [
            {
              label: 'Getting Started',
              to: '/docs/',
            },
            {
              label: 'Architecture',
              to: '/docs/architecture/overview',
            },
            {
              label: 'Deployment',
              to: '/docs/deployment/app-store',
            },
          ],
        },
        {
          title: 'Repositories',
          items: [
            {
              label: 'Mobile App (TrickList)',
              href: 'https://github.com/wbaxterh/TrickBookFrontend',
            },
            {
              label: 'Backend API',
              href: 'https://github.com/wbaxterh/TrickBookBackend',
            },
          ],
        },
        {
          title: 'Links',
          items: [
            {
              label: 'App Store',
              href: 'https://apps.apple.com/app/trickbook',
            },
            {
              label: 'Website',
              href: 'https://thetrickbook.com',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} TrickBook. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'json', 'yaml'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
