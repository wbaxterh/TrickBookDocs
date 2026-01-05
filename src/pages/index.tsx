import type {ReactNode} from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';

import styles from './index.module.css';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <Heading as="h1" className="hero__title">
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/">
            Get Started
          </Link>
          <Link
            className="button button--outline button--secondary button--lg"
            style={{marginLeft: '1rem'}}
            to="/docs/deployment/google-play">
            Deploy to Google Play
          </Link>
        </div>
      </div>
    </header>
  );
}

type FeatureItem = {
  title: string;
  description: ReactNode;
  link: string;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'Architecture',
    description: (
      <>
        System design, technology stack, and data flow documentation
        for the TrickBook platform.
      </>
    ),
    link: '/docs/architecture/overview',
  },
  {
    title: 'Backend API',
    description: (
      <>
        Node.js Express API documentation including endpoints,
        authentication, database schema, and security.
      </>
    ),
    link: '/docs/backend/overview',
  },
  {
    title: 'Mobile App',
    description: (
      <>
        React Native + Expo mobile app documentation covering
        navigation, state management, and build configuration.
      </>
    ),
    link: '/docs/mobile/overview',
  },
  {
    title: 'Deployment',
    description: (
      <>
        Step-by-step guides for deploying to App Store, Google Play,
        and backend hosting platforms.
      </>
    ),
    link: '/docs/deployment/app-store',
  },
  {
    title: 'Security',
    description: (
      <>
        Current security status, vulnerabilities, and fixes
        required for production readiness.
      </>
    ),
    link: '/docs/backend/security',
  },
  {
    title: 'Roadmap',
    description: (
      <>
        Priority tasks, upcoming features, and efficiency
        improvements for faster development.
      </>
    ),
    link: '/docs/roadmap/priorities',
  },
];

function Feature({title, description, link}: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className="padding-horiz--md padding-vert--lg">
        <Heading as="h3">
          <Link to={link}>{title}</Link>
        </Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}

export default function Home(): ReactNode {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title="Documentation"
      description="Technical documentation for the TrickBook mobile app and platform">
      <HomepageHeader />
      <main>
        <HomepageFeatures />
      </main>
    </Layout>
  );
}
