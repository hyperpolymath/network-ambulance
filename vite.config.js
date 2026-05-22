// SPDX-License-Identifier: MPL-2.0
import { defineConfig } from "vite"

export default defineConfig({
  root: ".",
  publicDir: "public",
  build: {
    outDir: "dist",
    emptyOutDir: true,
    rollupOptions: {
      input: {
        main: "./index.html",
      },
    },
  },
  server: {
    port: 5173,
    strictPort: true,
  },
  clearScreen: false,
  envPrefix: ["VITE_", "TAURI_"],
})
