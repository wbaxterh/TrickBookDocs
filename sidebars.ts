import type { SidebarsConfig } from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    'intro',
    {
      type: 'category',
      label: 'Engineering Standards',
      items: [
        'engineering/overview',
        'engineering/linting-formatting',
        'engineering/testing',
        'engineering/pre-commit-hooks',
        'engineering/error-handling',
        'engineering/logging',
        'engineering/code-quality',
      ],
    },
    {
      type: 'category',
      label: 'Architecture',
      items: [
        'architecture/overview',
        'architecture/repo-dependency-map',
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
      items: ['chrome-extension/overview', 'chrome-extension/data-model'],
    },
    {
      type: 'category',
      label: 'Features',
      items: [
        'features/overview',
        'features/trickbook',
        'features/spots',
        'features/homies',
        'features/media',
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
      label: 'Release Notes',
      items: ['releases/v2.0.0'],
    },
    {
      type: 'category',
      label: 'Roadmap',
      items: [
        'roadmap/priorities',
        'roadmap/gap-analysis',
        'roadmap/security-fixes',
        'roadmap/efficiency-improvements',
        'roadmap/chrome-extension-integration',
        'roadmap/mobile-app-rebuild',
        'roadmap/mobile-design-prompt',
      ],
    },
  ],
};

export default sidebars;
