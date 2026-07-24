--  This package has been generated automatically by GNATtest.
--  You are allowed to add your code to the bodies of test routines.
--  Such changes will be kept during further regeneration of this file.
--  All code placed outside of test routine bodies will be lost. The
--  code intended to set up and tear down the test environment should be
--  placed into Currency_History.Test_Data.

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
package body Currency_History.Test_Data.Tests is

--  begin read only
--  id:2.2/01/
--
--  This section can be used to add global variables and other elements.
--
--  end read only

--  begin read only
--  end read only

--  begin read only
   procedure Test_Add_To_History (Gnattest_T : in out Test);
   procedure Test_Add_To_History_645816 (Gnattest_T : in out Test) renames Test_Add_To_History;
--  id:2.2/64581603d832caef/Add_To_History/1/0/
   procedure Test_Add_To_History (Gnattest_T : in out Test) is
   --  currency_history.ads:16:4:Add_To_History
--  end read only

      pragma Unreferenced (Gnattest_T);

   begin

      AUnit.Assertions.Assert
        (Gnattest_Generated.Default_Assert_Value,
         "Test not implemented.");

--  begin read only
   end Test_Add_To_History;
--  end read only


--  begin read only
   procedure Test_Print_History (Gnattest_T : in out Test);
   procedure Test_Print_History_9b432a (Gnattest_T : in out Test) renames Test_Print_History;
--  id:2.2/9b432a28aca2c41d/Print_History/1/0/
   procedure Test_Print_History (Gnattest_T : in out Test) is
   --  currency_history.ads:17:4:Print_History
--  end read only

      pragma Unreferenced (Gnattest_T);

   begin

      AUnit.Assertions.Assert
        (Gnattest_Generated.Default_Assert_Value,
         "Test not implemented.");

--  begin read only
   end Test_Print_History;
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
end Currency_History.Test_Data.Tests;
