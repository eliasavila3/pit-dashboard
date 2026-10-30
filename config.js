/* Pit dashboard settings for this deployment. Loaded by index.html before the app.
   The anon key is public by design: row-level security in supabase/schema.sql
   decides who can read and write. Never put the service role key here. */
window.PIT_CONFIG = {
  supabaseUrl: "https://YOUR-PROJECT.supabase.co",   // Project settings > API > Project URL
  supabaseAnonKey: "YOUR-ANON-KEY",                  // Project settings > API > anon public key
  boardUrl: ""                                       // where battery QR labels point; empty = this page's address
};
