import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],

  server: {
    host: true, // true に設定すると、LAN やパブリックアドレスを含むすべてのアドレスをリッスン
    port: 5173, // 開発サーバーが使用するポート番号
  },
  
})
