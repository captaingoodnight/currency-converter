with Ada.Characters.Handling;
with Currency_Table;
with Currency_UI;

package body Currency_Prompts is

   function Prompt_Currency (Prompt_Text : String) return String is
   begin
      loop
         declare
            Input : constant String := Currency_UI.Prompt (Prompt_Text);
            Upper : constant String :=
              Ada.Characters.Handling.To_Upper (Input);
         begin
            if Currency_Table.Is_Valid_Currency (Upper) then
               return Upper;
            end if;
            Currency_UI.Show_Error
              ("Unknown code """ & Input & """. Enter one of the codes shown.");
         end;
      end loop;
   end Prompt_Currency;

end Currency_Prompts;