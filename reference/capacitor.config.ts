import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.johnleeson.teampulse',
  appName: 'teampulse',
  webDir: 'dist', // Capacitor needs this placeholder even if we use a URL
  // server: {
  //   url: 'https://teampulse-app-kappa.vercel.app',
  //   cleartext: true, 
  //   // Add this to allow your auth provider to talk to the app
  //   allowNavigation: [
  //     '*.vercel.app',
  //     '*.supabase.co', // or your specific auth provider
  //     '*.google.com'
  //   ]
  // },
  //Add this block here:
  ios: {
    overrideUserAgent: 'TeamPulse-iOS-App'
  },
  plugins: {
    CapacitorCookies: {
      enabled: true
    }
  }
  // webDir: 'dist'
};

export default config;
