import { defineConfig, globalIgnores } from 'eslint/config';
import nextVitals from 'eslint-config-next/core-web-vitals';
import nextTypeScript from 'eslint-config-next/typescript';

export default defineConfig([
  ...nextVitals,
  ...nextTypeScript,
  {
    // PRISM uses mount effects to hydrate browser-only theme and preference state.
    'rules': {
      'react-hooks/set-state-in-effect': 'off',
    },
  },
  globalIgnores([
    '.next/**',
    'out/**',
    'site/**',
    'assets/**',
    'layouts/**',
    'resources/**',
    'static/**',
    'themes/**',
    'quarto-notes/**',
    'next-env.d.ts',
  ]),
]);
