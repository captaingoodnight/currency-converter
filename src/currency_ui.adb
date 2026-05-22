with Interfaces.C;         use Interfaces.C;
with Interfaces.C.Strings; use Interfaces.C.Strings;
with System;

package body Currency_UI is

   --------------------------------------------------------------------------
   --  C function imports
   --------------------------------------------------------------------------

   procedure C_Init;
   pragma Import (C, C_Init, "ui_init");

   procedure C_Cleanup;
   pragma Import (C, C_Cleanup, "ui_cleanup");

   procedure C_Set_Currencies (List : chars_ptr);
   pragma Import (C, C_Set_Currencies, "ui_set_currencies");

   procedure C_Add_History (Item : chars_ptr);
   pragma Import (C, C_Add_History, "ui_add_history_entry");

   procedure C_Prompt (Label  : chars_ptr;
                       Buf    : System.Address;
                       Maxlen : int);
   pragma Import (C, C_Prompt, "ui_prompt");

   procedure C_Show_Result (Line : chars_ptr);
   pragma Import (C, C_Show_Result, "ui_show_result");

   procedure C_Show_Error (Msg : chars_ptr);
   pragma Import (C, C_Show_Error, "ui_show_error");

   procedure C_Show_Status (Msg : chars_ptr);
   pragma Import (C, C_Show_Status, "ui_show_status");

   procedure C_Clear_Main;
   pragma Import (C, C_Clear_Main, "ui_clear_main");

   function C_Ask_Continue return int;
   pragma Import (C, C_Ask_Continue, "ui_ask_continue");

   --------------------------------------------------------------------------
   --  Ada wrappers
   --------------------------------------------------------------------------

   procedure Initialize is
   begin
      C_Init;
   end Initialize;

   procedure Cleanup is
   begin
      C_Cleanup;
   end Cleanup;

   procedure Set_Currencies (List : String) is
      S : chars_ptr := New_String (List);
   begin
      C_Set_Currencies (S);
      Free (S);
   end Set_Currencies;

   procedure Add_History_Entry (Item : String) is
      S : chars_ptr := New_String (Item);
   begin
      C_Add_History (S);
      Free (S);
   end Add_History_Entry;

   function Prompt (Label : String) return String is
      C_Label : chars_ptr  := New_String (Label);
      Buf     : char_array (0 .. 255) := (others => nul);
   begin
      C_Prompt (C_Label, Buf'Address, 254);
      Free (C_Label);
      return To_Ada (Buf, Trim_Nul => True);
   end Prompt;

   procedure Show_Result (Line : String) is
      S : chars_ptr := New_String (Line);
   begin
      C_Show_Result (S);
      Free (S);
   end Show_Result;

   procedure Show_Error (Msg : String) is
      S : chars_ptr := New_String (Msg);
   begin
      C_Show_Error (S);
      Free (S);
   end Show_Error;

   procedure Show_Status (Msg : String) is
      S : chars_ptr := New_String (Msg);
   begin
      C_Show_Status (S);
      Free (S);
   end Show_Status;

   procedure Clear_Main is
   begin
      C_Clear_Main;
   end Clear_Main;

   function Ask_Continue return Boolean is
   begin
      return C_Ask_Continue /= 0;
   end Ask_Continue;

end Currency_UI;
