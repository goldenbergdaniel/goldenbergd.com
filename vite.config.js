import path from "node:path"
import process from "node:process"
import { defineConfig } from "vite"

export default defineConfig({
  root: "pages",
  base: "/",
  publicDir: "../public",
  build: {
    outDir: "../dist",
      rollupOptions: {
      input: {
        'main':        path.resolve(__dirname, 'pages/index.html'),
        'articles':    path.resolve(__dirname, 'pages/articles/index.html'),
        'projects':    path.resolve(__dirname, 'pages/projects/index.html'),
        'undead-west': path.resolve(__dirname, 'pages/projects/undead-west/index.html'),
      },
    },
  },
  resolve: {
    alias: { 
      "/src": path.resolve(process.cwd(), "src"),
    }
  },
})
