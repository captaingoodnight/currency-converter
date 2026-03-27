with Ada.Text_IO; use Ada.Text_IO;

package body Currency_Table is

   function Is_Valid_Currency (Code : String) return Boolean is
   begin
      if Code'Length /= 3 then
         return False;
      end if;
      for I in Currencies'Range loop
         if Currencies (I).Code = Code then
            return True;
         end if;
      end loop;
      return False;
   end Is_Valid_Currency;

   procedure Display_Currencies is
      Cols : constant := 3;
      Col  : Natural  := 0;
   begin
      Put_Line ("Supported currencies:");
      Put_Line (String'(1 .. 66 => '-'));
      for I in Currencies'Range loop
         declare
            Entry_Str : constant String :=
              Currencies (I).Code & "  " &
              To_String (Currencies (I).Name);
            Padded    : String (1 .. 22) := (others => ' ');
            Len       : constant Natural :=
              Natural'Min (Entry_Str'Length, Padded'Length);
         begin
            Padded (1 .. Len) := Entry_Str (Entry_Str'First ..
                                             Entry_Str'First + Len - 1);
            Put ("  " & Padded);
         end;
         Col := Col + 1;
         if Col = Cols then
            New_Line;
            Col := 0;
         end if;
      end loop;
      if Col /= 0 then
         New_Line;
      end if;
      Put_Line (String'(1 .. 66 => '-'));
      New_Line;
   end Display_Currencies;

end Currency_Table;