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

      AUnit.Assertions.Assert
        (Gnattest_Generated.Default_Assert_Value,
         "Test not implemented.");

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

   begin

      AUnit.Assertions.Assert
        (Gnattest_Generated.Default_Assert_Value,
         "Test not implemented.");

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
