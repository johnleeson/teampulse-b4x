import { createClient } from '@supabase/supabase-js';

// 1. Try to get them from the environment
// 2. If that fails, use the strings directly
const supabaseUrl = (import.meta as any).env.VITE_SUPABASE_URL || 'https://cadbpejpmbjgwftqwwud.supabase.co';
const supabaseAnonKey = (import.meta as any).env.VITE_SUPABASE_ANON_KEY || 'sb_publishable_i86hB5zujz8zEOLsvxyt2A_UrpkSoHR';

console.log("Checking Supabase Config...");

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
export const isSupabaseEnabled = true;

console.log("🚀 SUPABASE ACTIVE: Using " + (supabaseUrl.includes('cadb') ? "Hardcoded" : "Env") + " keys.");