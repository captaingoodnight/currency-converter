--  Currency Converter — main entry point
--
--  This file contains only the top-level loop: prompt, fetch, display, repeat.
--  All business logic lives in separate compilation units:
--
--    Currency_Table   — supported currency codes, validation, display
--    Currency_Fetch   — live rate retrieval via curl / api.frankfurter.dev
--    Currency_Prompts — interactive user input with validation loop
--    Currency_History — rolling conversion history (GNAT SAS demo issues)

with Ada.Text_IO;             use Ada.Text_IO;
with Ada.Strings.Unbounded;   use Ada.Strings.Unbounded;
with Ada.Characters.Handling;
with Ada.Exceptions;
with Currency_Table;
with Currency_Fetch;
with Currency_Prompts;
with Currency_History;

procedure Currency_Converter is

   package Float_IO is new Ada.Text_IO.Float_IO (Float);

   From_Code  : Unbounded_String;
   To_Code    : Unbounded_String;
   Amount     : Float;
   Rate       : Float;
   Converted  : Float;
   Amt_Buf    : String (1 .. 30);
   Amt_Last   : Natural;
   Again_Buf  : String (1 .. 10);
   Again_Last : Natural;

begin
   Put_Line ("╔══════════════════════════════════╗");
   Put_Line ("║      Ada Currency Converter       ║");
   Put_Line ("╚══════════════════════════════════╝");
   New_Line;

   Currency_Table.Display_Currencies;

   loop
      --  Show history at the top of each conversion
      Currency_History.Print_History;

      --  1. Source currency
      From_Code :=
        To_Unbounded_String
          (Currency_Prompts.Prompt_Currency ("Source currency code : "));

      --  2. Amount
      loop
         Put ("Amount in " & To_String (From_Code) & "          : ");
         Get_Line (Amt_Buf, Amt_Last);
         begin
            Amount := Float'Value (Amt_Buf (1 .. Amt_Last));
            exit when Amount > 0.0;
            Put_Line ("  Amount must be greater than zero.");
         exception
            when Constraint_Error =>
               Put_Line ("  Please enter a valid positive number.");
         end;
      end loop;

      --  3. Target currency
      To_Code :=
        To_Unbounded_String
          (Currency_Prompts.Prompt_Currency ("Target currency code : "));

      New_Line;

      --  4. Same-currency short-circuit
      if To_String (From_Code) = To_String (To_Code) then
         Put ("  ");
         Float_IO.Put (Item => Amount, Fore => 1, Aft => 2, Exp => 0);
         Put (" " & To_String (From_Code) & " = ");
         Float_IO.Put (Item => Amount, Fore => 1, Aft => 2, Exp => 0);
         Put_Line (" " & To_String (To_Code));
         New_Line;
      else
         --  5. Fetch rate and display result
         Put_Line ("  Fetching live rate from api.frankfurter.dev …");
         New_Line;

         begin
            Rate      := Currency_Fetch.Fetch_Rate (To_String (From_Code),
                                                    To_String (To_Code));
            Converted := Amount * Rate;

            Put ("  ");
            Float_IO.Put (Item => Amount, Fore => 1, Aft => 2, Exp => 0);
            Put (" " & To_String (From_Code));
            Put (" = ");
            Float_IO.Put (Item => Converted, Fore => 1, Aft => 2, Exp => 0);
            Put_Line (" " & To_String (To_Code));
            New_Line;

            Put ("  (Rate: 1 " & To_String (From_Code) & " = ");
            Float_IO.Put (Item => Rate, Fore => 1, Aft => 6, Exp => 0);
            Put_Line (" " & To_String (To_Code) & ")");
            New_Line;

            Currency_History.Add_To_History
              (To_String (From_Code), To_String (To_Code),
               Amount, Converted, Rate);

         exception
            when E : others =>
               New_Line;
               Put_Line ("  Error: " & Ada.Exceptions.Exception_Message (E));
               New_Line;
         end;
      end if;

      --  6. Another conversion?
      Put ("Convert another? [y/n] : ");
      Get_Line (Again_Buf, Again_Last);
      New_Line;
      exit when Again_Last = 0
        or else Ada.Characters.Handling.To_Lower
                  (Again_Buf (Again_Buf'First)) /= 'y';
   end loop;

end Currency_Converter;