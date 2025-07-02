// frontend/vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import mkcert from 'vite-plugin-mkcert';
import tsconfigPaths from 'vite-tsconfig-paths';

export default defineConfig({
  server: {
    https: true, // mkcert will handle certificates
    port: 3000
  },
  plugins: [
    react(),
    tsconfigPaths(),
    mkcert()
  ],
  define: {
    'process.env': {} // sometimes needed for Shopify Polaris or bridge
  }
});
