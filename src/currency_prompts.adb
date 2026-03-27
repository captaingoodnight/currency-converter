with Ada.Text_IO;             use Ada.Text_IO;
with Ada.Characters.Handling;
with Currency_Table;

package body Currency_Prompts is

   function Prompt_Currency (Prompt_Text : String) return String is
      Input : String (1 .. 10);
      Last  : Natural;
   begin
      loop
         Put (Prompt_Text);
         Get_Line (Input, Last);
         declare
            Upper : constant String :=
              Ada.Characters.Handling.To_Upper (Input (1 .. Last));
         begin
            if Currency_Table.Is_Valid_Currency (Upper) then
               return Upper;
            end if;
            Put ("  Unknown code """ & Input (1 .. Last) & """.");
            Put_Line ("  Enter one of the codes shown above.");
         end;
      end loop;
   end Prompt_Currency;

end Currency_Prompts;