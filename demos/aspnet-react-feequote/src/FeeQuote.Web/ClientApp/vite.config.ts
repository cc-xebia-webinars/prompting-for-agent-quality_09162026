import react from "@vitejs/plugin-react";
import { defineConfig } from "vitest/config";

// The app is served by FeeQuote.Web under /app/, so assets are emitted with
// that prefix and the build lands directly in the web project's wwwroot.
export default defineConfig({
  base: "/app/",
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      "/api": "http://localhost:5080",
    },
  },
  build: {
    outDir: "../wwwroot/app",
    emptyOutDir: true,
  },
  test: {
    environment: "jsdom",
    setupFiles: ["./src/setupTests.ts"],
  },
});
