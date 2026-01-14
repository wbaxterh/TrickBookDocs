import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    'intro',
    {
      type: 'category',
      label: 'Architecture',
      items: [
        'architecture/overview',
        'architecture/tech-stack',
        'architecture/data-flow',
      ],
    },
    {
      type: 'category',
      label: 'Backend',
      items: [
        'backend/overview',
        'backend/api-endpoints',
        'backend/authentication',
        'backend/database',
        'backend/security',
      ],
    },
    {
      type: 'category',
      label: 'Mobile App',
      items: [
        'mobile/overview',
        'mobile/navigation',
        'mobile/state-management',
        'mobile/api-integration',
        'mobile/build-configuration',
      ],
    },
    {
      type: 'category',
      label: 'Chrome Extension',
      items: [
        'chrome-extension/overview',
        'chrome-extension/data-model',
      ],
    },
    {
      type: 'category',
      label: 'Deployment',
      items: [
        'deployment/app-store',
        'deployment/google-play',
        'deployment/backend',
        'deployment/ci-cd',
      ],
    },
    {
      type: 'category',
      label: 'Roadmap',
      items: [
        'roadmap/priorities',
        'roadmap/security-fixes',
        'roadmap/efficiency-improvements',
        'roadmap/chrome-extension-integration',
      ],
    },
  ],
};

export default sidebars;
