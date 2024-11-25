import path from "node:path"
import process from "node:process"
import { defineConfig } from "vite"

export default defineConfig({
  root: "pages",
  base: "/",
  publicDir: "../public",
  build: {
    outDir: "../dist",
    emptyOutDir: true,
    rollupOptions: {
      input: {
        'main':        path.resolve(__dirname, 'pages/index.html'),
        'links':       path.resolve(__dirname, 'pages/links/index.html'),
        'projects':    path.resolve(__dirname, 'pages/projects/index.html'),
        'articles':    path.resolve(__dirname, 'pages/articles/index.html'),
        'hello-world': path.resolve(__dirname, 'pages/articles/hello-world/index.html'),
      },
    },
  },
  resolve: {
    alias: { 
      "/public": path.resolve(process.cwd(), "public"),
      "/scripts": path.resolve(process.cwd(), "scripts"),
    }
  },
})
