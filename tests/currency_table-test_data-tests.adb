--  This package has been generated automatically by GNATtest.
--  You are allowed to add your code to the bodies of test routines.
--  Such changes will be kept during further regeneration of this file.
--  All code placed outside of test routine bodies will be lost. The
--  code intended to set up and tear down the test environment should be
--  placed into Currency_Table.Test_Data.

with AUnit.Assertions; use AUnit.Assertions;
with System.Assertions;

--  begin read only
--  id:2.2/00/
--
--  This section can be used to add with clauses if necessary.
--
--  end read only

with Ada.Text_IO;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;

--  begin read only
--  end read only
package body Currency_Table.Test_Data.Tests is

--  begin read only
--  id:2.2/01/
--
--  This section can be used to add global variables and other elements.
--
--  end read only

--  begin read only
--  end read only

--  begin read only
   procedure Test_Is_Valid_Currency (Gnattest_T : in out Test);
   procedure Test_Is_Valid_Currency_d32d55 (Gnattest_T : in out Test) renames Test_Is_Valid_Currency;
--  id:2.2/d32d55e775d0a96a/Is_Valid_Currency/1/0/
   procedure Test_Is_Valid_Currency (Gnattest_T : in out Test) is
   --  currency_table.ads:42:4:Is_Valid_Currency
--  end read only

      pragma Unreferenced (Gnattest_T);

   begin

      Assert (Is_Valid_Currency ("USD"),
              "USD should be a valid currency code");
      Assert (Is_Valid_Currency ("EUR"),
              "EUR should be a valid currency code");
      Assert (not Is_Valid_Currency ("XXX"),
              "XXX is not in the currency table and should be invalid");
      Assert (not Is_Valid_Currency ("US"),
              "a 2-character code should be invalid");
      Assert (not Is_Valid_Currency ("USDD"),
              "a 4-character code should be invalid");
      Assert (not Is_Valid_Currency ("usd"),
              "currency codes are matched case-sensitively");

--  begin read only
   end Test_Is_Valid_Currency;
--  end read only


--  begin read only
   procedure Test_Display_Currencies (Gnattest_T : in out Test);
   procedure Test_Display_Currencies_c1c662 (Gnattest_T : in out Test) renames Test_Display_Currencies;
--  id:2.2/c1c662c329a642cf/Display_Currencies/1/0/
   procedure Test_Display_Currencies (Gnattest_T : in out Test) is
   --  currency_table.ads:43:4:Display_Currencies
--  end read only

      pragma Unreferenced (Gnattest_T);

      Temp_Name    : constant String := "test_display_currencies_output.tmp";
      Output       : Ada.Text_IO.File_Type;
      Found_Header : Boolean := False;
      Found_USD    : Boolean := False;

   begin

      Ada.Text_IO.Create (Output, Ada.Text_IO.Out_File, Temp_Name);
      Ada.Text_IO.Set_Output (Output);

      begin
         Display_Currencies;
      exception
         when others =>
            Ada.Text_IO.Set_Output (Ada.Text_IO.Standard_Output);
            Ada.Text_IO.Close (Output);
            raise;
      end;

      Ada.Text_IO.Set_Output (Ada.Text_IO.Standard_Output);
      Ada.Text_IO.Close (Output);

      Ada.Text_IO.Open (Output, Ada.Text_IO.In_File, Temp_Name);
      while not Ada.Text_IO.End_Of_File (Output) loop
         declare
            Line : constant String := Ada.Text_IO.Get_Line (Output);
         begin
            if Line = "Supported currencies:" then
               Found_Header := True;
            end if;
            if Index (Line, "USD") > 0 then
               Found_USD := True;
            end if;
         end;
      end loop;
      Ada.Text_IO.Delete (Output);

      Assert (Found_Header, "Display_Currencies should print the header line");
      Assert (Found_USD, "Display_Currencies should list the USD entry");

--  begin read only
   end Test_Display_Currencies;
--  end read only

--  begin read only
--  id:2.2/02/
--
--  This section can be used to add elaboration code for the global state.
--
begin
--  end read only
   null;
--  begin read only
--  end read only
end Currency_Table.Test_Data.Tests;
