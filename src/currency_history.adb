--  Currency_History — package body
--
--  ==========================================================================
--  GNAT SAS Static Analysis Demo — Intentional Coding Issues
--  ==========================================================================
--
--  The declarations and subprogram bodies below contain deliberate poor
--  coding practices to demonstrate findings produced by GNAT SAS (and
--  partially by the GNAT compiler's own warning flags).  They are NOT bugs
--  that affect correctness under normal use; they are style and data-flow
--  issues that static analysis is designed to surface.
--
--  Issues 1-4 are reported by the GNAT compiler with -gnatwa.
--  Issue 5 is the key finding: it requires GNAT SAS's full path-sensitive
--  data-flow analysis and is NOT caught by the compiler alone.
--  Issues 6-8 are code quality observations; 7 and 8 require GNAT SAS
--  coding-standard rules to be enabled in the project configuration.
--
--  Issue 1 — Variable assigned but never read          (GNAT -gnatwm / SAS)
--    'Last_Rate : Float' is written inside Add_To_History with the value of
--    the rate parameter R, but that value is never subsequently read.
--    The assignment is therefore useless.
--
--  Issue 2 — Self-assignment / useless statement       (GNAT -gnatwr / SAS)
--    In the else-branch of Add_To_History, 'H (10) := H (10)' assigns an
--    array element to itself.  It has no effect and is almost certainly a
--    copy-paste error (the intent was to write the new entry into slot 10,
--    not to copy slot 10 over itself).
--
--  Issue 3 — No-op if statement / condition always true (GNAT -gnatwr / SAS)
--    After the if/else block in Add_To_History, N is provably >= 1, so the
--    guard 'if N > 0 then null; end if;' is always True and the entire
--    statement has no effect.  There is no else-branch; the whole construct
--    is dead weight and GNAT flags it as an if statement with no effect.
--
--  Issue 4 — Variable that could be constant           (GNAT -gnatwk / SAS)
--    In Print_History, 'Count : Integer := N' is initialised once and never
--    modified.  It should be declared 'constant'.  GNAT warns that a
--    non-constant declaration is used where a constant would suffice.
--
--  Issue 5 — Potentially uninitialised variable  *** GNAT SAS only ***
--    'Prev_N : Integer' inside Add_To_History is assigned only on the
--    if-branch (N < 10).  On the else-branch (buffer full, shift occurs)
--    Prev_N is never assigned, yet it is read unconditionally in the
--    Put_Line call that follows.  GNAT's -gnatwa does not catch this because
--    the variable is assigned on at least one path; GNAT SAS's full
--    path-sensitive data-flow analysis flags it as a potential read of an
--    uninitialised object.
--
--    Cross-unit dimension: because Add_To_History is a separate compilation
--    unit, GNAT SAS propagates the finding to every call site in other
--    units (e.g. Currency_Converter).  This is the strongest demonstration
--    of what SAS can find that the compiler alone cannot.
--
--  Issue 6 — Redundant intermediate variable      (code quality observation)
--    'I := N + 1; N := I;' uses a superfluous local variable where the
--    single statement 'N := N + 1;' is both clearer and equivalent.
--
--  Issue 7 — Magic numbers                   (GNAT SAS, requires config)
--    The literal values 10, 9, and 1 appear directly in array bounds, loop
--    ranges, and comparisons.  A named constant (e.g. Max_History : constant
--    := 10) would make the intent explicit.  Flagged by GNAT SAS when
--    coding-standard rules are enabled in the project configuration.
--
--  Issue 8 — Non-descriptive identifiers        (GNAT SAS, requires config)
--    H (array), N (counter), I (loop index), and the record fields F, T,
--    Amt, Res are all excessively abbreviated.  GNAT SAS naming-convention
--    checks flag identifiers that are too short to convey their purpose.
--    Requires naming rules to be enabled in the GNAT SAS configuration.
--  ==========================================================================

with Ada.Text_IO; use Ada.Text_IO;

package body Currency_History is

   package Float_IO is new Ada.Text_IO.Float_IO (Float);

   type H_Entry is record        --  POOR: abbreviated, cryptic type name
      F   : String (1 .. 3);    --  POOR: single-letter field names throughout
      T   : String (1 .. 3);
      Amt : Float;
      Res : Float;
   end record;

   H         : array (1 .. 10) of H_Entry;  --  POOR: magic number; name 'H'
   N         : Integer := 0;                 --  POOR: name 'N'
   Last_Rate : Float;                        --  POOR: assigned but never read

   procedure Add_To_History (From, To : String; Amt, Res, R : Float) is
      I      : Integer;   --  POOR: redundant intermediate variable, name 'I'
      Prev_N : Integer;   --  POOR: uninitialised; only assigned in one branch
   begin
      Last_Rate := R;     --  POOR: value assigned to Last_Rate is never used

      if N < 10 then      --  POOR: magic number
         Prev_N := N;     --  assigned only on this path
         I      := N + 1; --  POOR: I exists solely to hold N+1 temporarily
         N      := I;     --  could simply be: N := N + 1
      else
         --  Prev_N is NOT assigned here; reading it below is undefined
         for J in 1 .. 9 loop   --  POOR: magic numbers
            H (J) := H (J + 1);
         end loop;
         H (10) := H (10);      --  POOR: self-assignment; no effect
      end if;

      H (N) := (F   => From (From'First .. From'First + 2),
                T   => To   (To'First   .. To'First   + 2),
                Amt => Amt,
                Res => Res);

      --  POOR: dead code — N is provably > 0 at this point
      if N > 0 then
         null;
      end if;

      --  POOR: Prev_N may be uninitialised when the else branch was taken
      Put_Line ("  [history] saved to slot" & Integer'Image (N) &
                "  (previous count:" & Integer'Image (Prev_N) & ")");
   end Add_To_History;

   procedure Print_History is
      Count : Integer := N;   --  POOR: Count could be declared constant
   begin
      if Count = 0 then
         return;
      end if;
      New_Line;
      Put_Line ("  --- Last" & Integer'Image (Count) &
                " conversion(s) ---");
      for I in 1 .. Count loop   --  POOR: magic lower bound 1 (use H'First)
         Put ("  " & Integer'Image (I) & ".  ");
         Float_IO.Put (Item => H (I).Amt, Fore => 1, Aft => 2, Exp => 0);
         Put (" " & H (I).F & " -> ");
         Float_IO.Put (Item => H (I).Res, Fore => 1, Aft => 2, Exp => 0);
         Put_Line (" " & H (I).T);
      end loop;
      New_Line;
   end Print_History;

end Currency_History;