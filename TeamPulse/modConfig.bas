B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=12.80
@EndOfDesignText@
' TeamPulse app configuration — Supabase backend (from johnleeson/teampulse-app).
' Override URL/key via env-style placeholders if you fork; defaults match the web app.

Sub Process_Globals
	Public Const APP_NAME As String = "TeamPulse"
	Public Const PACKAGE_NAME As String = "com.teampulse.app"
	
	' Same project as teampulse-app (lib/supabase.ts)
	Public Const SUPABASE_URL As String = "https://cadbpejpmbjgwftqwwud.supabase.co"
	Public Const SUPABASE_ANON_KEY As String = "sb_publishable_i86hB5zujz8zEOLsvxyt2A_UrpkSoHR"
	
	Public Const COLOR_PRIMARY As Int = 0xFF0F172A
	Public Const COLOR_ACCENT As Int = 0xFF3B82F6
	Public Const COLOR_SUCCESS As Int = 0xFF10B981
	Public Const COLOR_DANGER As Int = 0xFFEF4444
	Public Const COLOR_MUTED As Int = 0xFF64748B
	Public Const COLOR_PITCH As Int = 0xFF166534
	Public Const COLOR_SURFACE As Int = 0xFFF8FAFC
	Public Const COLOR_CARD As Int = 0xFFFFFFFF
	Public Const COLOR_BORDER As Int = 0xFFE2E8F0
	Public Const COLOR_LIVE As Int = 0xFFEF4444
	Public Const COLOR_LIVE_BG As Int = 0xFFEFF6FF
	Public Const COLOR_CANCEL_BG As Int = 0xFFFEF2F2
	Public Const COLOR_CHIP As Int = 0xFFF1F5F9
	' Dark / live-feed surfaces
	Public Const COLOR_DARK_BG As Int = 0xFF0F172A
	Public Const COLOR_DARK_CARD As Int = 0xFF1E293B
	Public Const COLOR_DARK_CHIP As Int = 0xFF334155
	Public Const COLOR_DARK_TEXT As Int = 0xFFF8FAFC
	Public Const COLOR_DARK_MUTED As Int = 0xFF94A3B8
End Sub
