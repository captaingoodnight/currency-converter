--  Currency_History — rolling session history of the last 10 conversions.
--
--  GNAT SAS Static Analysis Demo
--  -----------------------------------------------------------------------
--  All eight intentional coding issues in this project live in the body of
--  this package (see currency_history.adb for the full commentary).
--
--  The headline cross-unit finding (Issue 5): Add_To_History contains an
--  uninitialized read of Prev_N on the else-path.  Because the subprogram
--  is a separate compilation unit, GNAT SAS traces the defect back to
--  every call site — including Currency_Converter — demonstrating
--  inter-unit, path-sensitive data-flow analysis.

package Currency_History is

   procedure Add_To_History (From, To : String; Amt, Res, R : Float);
   procedure Print_History;

end Currency_History;