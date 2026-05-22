--  Currency_UI — Ada binding to the NCurses C UI layer (ncurses_ui.c).
--
--  All display and input operations go through this package.  The C
--  implementation handles NCurses directly; this package converts Ada
--  strings to C strings and forwards each call.

package Currency_UI is

   --  Initialise NCurses and draw the initial chrome.
   procedure Initialize;

   --  Restore the terminal to its original state.
   procedure Cleanup;

   --  Display a space-separated list of currency codes in the header panel.
   procedure Set_Currencies (List : String);

   --  Append one formatted entry to the history panel.
   procedure Add_History_Entry (Item : String);

   --  Show LABEL, read a line from the user, and return it.
   function Prompt (Label : String) return String;

   --  Write LINE to the main panel (green, bold — conversion result).
   procedure Show_Result (Line : String);

   --  Write MSG to the main panel (red — validation or fetch error).
   procedure Show_Error (Msg : String);

   --  Replace the status bar text with MSG.
   procedure Show_Status (Msg : String);

   --  Erase the main panel and reset its output cursor.
   procedure Clear_Main;

   --  Prompt "Convert another? [y/n]" and return True for y/Y.
   function Ask_Continue return Boolean;

end Currency_UI;
