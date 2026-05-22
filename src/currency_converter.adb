--  Currency Converter — main entry point
--
--  All display and input now goes through Currency_UI (NCurses / C layer).
--  Business logic lives in the same compilation units as before:
--
--    Currency_Table   — supported currency codes, validation
--    Currency_Fetch   — live rate retrieval via curl / api.frankfurter.dev
--    Currency_Prompts — currency-code prompt with validation loop
--    Currency_History — rolling conversion history (GNAT SAS demo issues)
--    Currency_UI      — Ada binding to the NCurses C UI (ncurses_ui.c)

with Ada.Text_IO;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;   use Ada.Strings.Unbounded;
with Ada.Exceptions;
with Currency_Table;
with Currency_Fetch;
with Currency_Prompts;
with Currency_History;
with Currency_UI;

procedure Currency_Converter is

   package Float_IO is new Ada.Text_IO.Float_IO (Float);

   From_Code : Unbounded_String;
   To_Code   : Unbounded_String;
   Amount    : Float;
   Rate      : Float;
   Converted : Float;

   --  Format a float to a trimmed decimal string (no exponent).
   function Fmt (F : Float; Aft : Natural := 2) return String is
      Buf : String (1 .. 30);
   begin
      Float_IO.Put (To => Buf, Item => F, Aft => Aft, Exp => 0);
      return Ada.Strings.Fixed.Trim (Buf, Ada.Strings.Left);
   end Fmt;

   --  Build the space-separated currency-code list for the header panel.
   function Currency_List return String is
      S : Unbounded_String;
   begin
      for I in Currency_Table.Currencies'Range loop
         Append (S, Currency_Table.Currencies (I).Code);
         if I < Currency_Table.Currencies'Last then
            Append (S, " ");
         end if;
      end loop;
      return To_String (S);
   end Currency_List;

begin
   Currency_UI.Initialize;
   Currency_UI.Set_Currencies (Currency_List);

   loop
      Currency_UI.Clear_Main;

      --  1. Source currency
      From_Code :=
        To_Unbounded_String
          (Currency_Prompts.Prompt_Currency ("Source currency : "));

      --  2. Amount
      loop
         declare
            Amt_Str : constant String :=
              Currency_UI.Prompt ("Amount in " & To_String (From_Code) & " : ");
         begin
            Amount := Float'Value (Amt_Str);
            exit when Amount > 0.0;
            Currency_UI.Show_Error ("Amount must be greater than zero.");
         exception
            when Constraint_Error =>
               Currency_UI.Show_Error ("Please enter a valid positive number.");
         end;
      end loop;

      --  3. Target currency
      To_Code :=
        To_Unbounded_String
          (Currency_Prompts.Prompt_Currency ("Target currency : "));

      --  4. Same-currency short-circuit
      if To_String (From_Code) = To_String (To_Code) then
         Currency_UI.Show_Result
           (Fmt (Amount) & " " & To_String (From_Code) &
            " = " & Fmt (Amount) & " " & To_String (To_Code));

      else
         --  5. Fetch rate and display result
         Currency_UI.Show_Status
           ("Fetching live rate from api.frankfurter.dev ...");

         begin
            Rate      := Currency_Fetch.Fetch_Rate (To_String (From_Code),
                                                    To_String (To_Code));
            Converted := Amount * Rate;

            Currency_UI.Show_Status ("");
            Currency_UI.Show_Result
              (Fmt (Amount) & " " & To_String (From_Code) &
               " = " & Fmt (Converted) & " " & To_String (To_Code));
            Currency_UI.Show_Result
              ("(Rate: 1 " & To_String (From_Code) &
               " = " & Fmt (Rate, 6) & " " & To_String (To_Code) & ")");

            --  Update Ada history (GNAT SAS demo) and the NCurses panel.
            Currency_History.Add_To_History
              (To_String (From_Code), To_String (To_Code),
               Amount, Converted, Rate);
            Currency_UI.Add_History_Entry
              (Fmt (Amount) & " " & To_String (From_Code) &
               " -> " & Fmt (Converted) & " " & To_String (To_Code));

         exception
            when E : others =>
               Currency_UI.Show_Status ("");
               Currency_UI.Show_Error
                 ("Error: " & Ada.Exceptions.Exception_Message (E));
         end;
      end if;

      --  6. Another conversion?
      exit when not Currency_UI.Ask_Continue;
   end loop;

   Currency_UI.Cleanup;

exception
   when others =>
      Currency_UI.Cleanup;
      raise;
end Currency_Converter;
