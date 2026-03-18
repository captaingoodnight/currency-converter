--  Currency Converter
--  Fetches live exchange rates from api.frankfurter.dev via curl,
--  then converts a user-supplied amount between two currencies.
--
--  ==========================================================================
--  GNAT SAS Static Analysis Demo — Intentional Coding Issues
--  ==========================================================================
--
--  The history buffer in this file contains deliberate poor coding practices
--  to demonstrate findings produced by GNAT SAS (and partially by the GNAT
--  compiler's own warning flags).  They are NOT bugs that affect correctness
--  under normal use; they are style and data-flow issues that static analysis
--  is designed to surface.
--
--  All eight issues are confined to three areas of the source:
--    - The declarations of H, N, and Last_Rate (history buffer state)
--    - The procedure Add_To_History
--    - The procedure Print_History
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
--    uninitialised object.  This is the strongest demonstration of what SAS
--    can find that the compiler alone cannot.
--
--  Issue 6 — Redundant intermediate variable      (code quality observation)
--    'I := N + 1; N := I;' uses a superfluous local variable where the
--    single statement 'N := N + 1;' is both clearer and equivalent.  This
--    is a readability concern rather than a formal GNAT SAS check category.
--
--  Issue 7 — Magic numbers                   (GNAT SAS, requires config)
--    The literal values 10, 9, and 1 appear directly in array bounds, loop
--    ranges, and comparisons throughout the history code.  A named constant
--    (e.g. Max_History : constant := 10) would make the intent explicit and
--    prevent inconsistencies if the size ever changes.  Flagged by GNAT SAS
--    when coding-standard rules are enabled in the project configuration.
--
--  Issue 8 — Non-descriptive identifiers        (GNAT SAS, requires config)
--    H (array), N (counter), I (loop index), and the record fields F, T,
--    Amt, Res are all excessively abbreviated.  GNAT SAS naming-convention
--    checks flag identifiers that are too short to convey their purpose.
--    Requires naming rules to be enabled in the GNAT SAS configuration.
--  ==========================================================================

with Ada.Text_IO;             use Ada.Text_IO;
with Ada.Strings.Unbounded;   use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Ada.Characters.Handling;
with Ada.Exceptions;
with Interfaces.C;

procedure Currency_Converter is

   use type Interfaces.C.int;   --  makes =, /=, <, etc. visible for C.int

   package Float_IO is new Ada.Text_IO.Float_IO (Float);

   --  Binding to the C standard library system() call.
   --  Used to invoke curl without requiring any Ada HTTP library.
   function C_System (Command : Interfaces.C.char_array)
      return Interfaces.C.int;
   pragma Import (C, C_System, "system");

   Temp_File : constant String := "/tmp/ada_currency_rate.json";

   ---------------------------------------------------------------------------
   --  Currency table
   ---------------------------------------------------------------------------

   type Currency is record
      Code : String (1 .. 3);
      Name : Unbounded_String;
   end record;

   Currencies : constant array (Positive range <>) of Currency :=
     ((Code => "AUD", Name => To_Unbounded_String ("Australian Dollar")),
      (Code => "BRL", Name => To_Unbounded_String ("Brazilian Real")),
      (Code => "CAD", Name => To_Unbounded_String ("Canadian Dollar")),
      (Code => "CHF", Name => To_Unbounded_String ("Swiss Franc")),
      (Code => "CNY", Name => To_Unbounded_String ("Chinese Yuan")),
      (Code => "CZK", Name => To_Unbounded_String ("Czech Koruna")),
      (Code => "DKK", Name => To_Unbounded_String ("Danish Krone")),
      (Code => "EUR", Name => To_Unbounded_String ("Euro")),
      (Code => "GBP", Name => To_Unbounded_String ("British Pound Sterling")),
      (Code => "HKD", Name => To_Unbounded_String ("Hong Kong Dollar")),
      (Code => "HUF", Name => To_Unbounded_String ("Hungarian Forint")),
      (Code => "IDR", Name => To_Unbounded_String ("Indonesian Rupiah")),
      (Code => "ILS", Name => To_Unbounded_String ("Israeli New Shekel")),
      (Code => "INR", Name => To_Unbounded_String ("Indian Rupee")),
      (Code => "ISK", Name => To_Unbounded_String ("Icelandic Krona")),
      (Code => "JPY", Name => To_Unbounded_String ("Japanese Yen")),
      (Code => "KRW", Name => To_Unbounded_String ("South Korean Won")),
      (Code => "MXN", Name => To_Unbounded_String ("Mexican Peso")),
      (Code => "MYR", Name => To_Unbounded_String ("Malaysian Ringgit")),
      (Code => "NOK", Name => To_Unbounded_String ("Norwegian Krone")),
      (Code => "NZD", Name => To_Unbounded_String ("New Zealand Dollar")),
      (Code => "PHP", Name => To_Unbounded_String ("Philippine Peso")),
      (Code => "PLN", Name => To_Unbounded_String ("Polish Zloty")),
      (Code => "RON", Name => To_Unbounded_String ("Romanian Leu")),
      (Code => "SEK", Name => To_Unbounded_String ("Swedish Krona")),
      (Code => "SGD", Name => To_Unbounded_String ("Singapore Dollar")),
      (Code => "THB", Name => To_Unbounded_String ("Thai Baht")),
      (Code => "TRY", Name => To_Unbounded_String ("Turkish Lira")),
      (Code => "USD", Name => To_Unbounded_String ("US Dollar")),
      (Code => "ZAR", Name => To_Unbounded_String ("South African Rand")));

   ---------------------------------------------------------------------------
   --  History buffer  (intentionally poor coding for static-analysis demo)
   ---------------------------------------------------------------------------

   type H_Entry is record        --  POOR: abbreviated, cryptic type name
      F   : String (1 .. 3);    --  POOR: single-letter field names throughout
      T   : String (1 .. 3);
      Amt : Float;
      Res : Float;
   end record;

   H         : array (1 .. 10) of H_Entry;  --  POOR: magic number; name 'H'
   N         : Integer := 0;                 --  POOR: name 'N'
   Last_Rate : Float;                        --  POOR: assigned but never read

   procedure Add_To_History (From, To : String;
                              Amt, Res, R : Float) is
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
      Count : Integer := N;   --  POOR: unnecessary copy of N
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

   ---------------------------------------------------------------------------
   --  Display_Currencies
   ---------------------------------------------------------------------------

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

   ---------------------------------------------------------------------------
   --  Is_Valid_Currency
   ---------------------------------------------------------------------------

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

   ---------------------------------------------------------------------------
   --  Fetch_Rate
   --  Calls curl to retrieve the latest rate for From -> To from
   --  api.frankfurter.dev.  Returns the rate as a Float (amount of To
   --  currency per 1 unit of From currency).
   ---------------------------------------------------------------------------

   function Fetch_Rate (From : String; To : String) return Float is
      URL     : constant String :=
        "https://api.frankfurter.dev/v1/latest?from=" & From & "&to=" & To;
      Command : constant String :=
        "curl -s --max-time 15 """ & URL & """ > " & Temp_File & " 2>/dev/null";
      Ret     : Interfaces.C.int;
   begin
      Ret := C_System (Interfaces.C.To_C (Command));
      if Ret /= 0 then
         raise Program_Error with
           "curl failed — check your internet connection.";
      end if;

      --  Read the JSON response from the temp file
      declare
         File    : File_Type;
         Content : Unbounded_String := Null_Unbounded_String;
         Line    : String (1 .. 2048);
         Last    : Natural;
      begin
         Open (File, In_File, Temp_File);
         while not End_Of_File (File) loop
            Get_Line (File, Line, Last);
            Append (Content, Line (1 .. Last));
         end loop;
         Close (File);

         --  The response looks like:
         --    {"amount":1.0,"base":"USD","date":"2025-03-14","rates":{"EUR":0.9215}}
         --  We look for the key  "TO_CODE": and read the number that follows.
         declare
            S   : constant String := To_String (Content);
            Key : constant String := """" & To & """:";
            Pos : Natural;
         begin
            if S = "" then
               raise Program_Error with
                 "Empty response — the API may be unavailable.";
            end if;

            Pos := Ada.Strings.Fixed.Index (S, Key);
            if Pos = 0 then
               raise Program_Error with
                 "Rate for " & To & " not found.  API response: " & S;
            end if;

            declare
               Start : Natural := Pos + Key'Length;
               Stop  : Natural;
            begin
               --  Skip any whitespace
               while Start <= S'Last and then S (Start) = ' ' loop
                  Start := Start + 1;
               end loop;
               --  Consume digits and decimal point
               Stop := Start;
               while Stop <= S'Last and then
                     (S (Stop) in '0' .. '9' or else S (Stop) = '.') loop
                  Stop := Stop + 1;
               end loop;
               return Float'Value (S (Start .. Stop - 1));
            end;
         end;
      end;
   end Fetch_Rate;

   ---------------------------------------------------------------------------
   --  Prompt_Currency
   --  Repeatedly prompts until the user enters a recognised 3-letter code.
   --  Returns the code in uppercase.
   ---------------------------------------------------------------------------

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
            if Is_Valid_Currency (Upper) then
               return Upper;
            end if;
            Put ("  Unknown code """ & Input (1 .. Last) & """.");
            Put_Line ("  Enter one of the codes shown above.");
         end;
      end loop;
   end Prompt_Currency;

   ---------------------------------------------------------------------------
   --  Main
   ---------------------------------------------------------------------------

   From_Code : Unbounded_String;
   To_Code   : Unbounded_String;
   Amount    : Float;
   Rate      : Float;
   Converted : Float;
   Amt_Buf   : String (1 .. 30);
   Amt_Last  : Natural;
   Again_Buf : String (1 .. 10);
   Again_Last : Natural;

begin
   Put_Line ("╔══════════════════════════════════╗");
   Put_Line ("║      Ada Currency Converter       ║");
   Put_Line ("╚══════════════════════════════════╝");
   New_Line;

   Display_Currencies;

   loop
      --  Show history at the top of each conversion
      Print_History;

      --  1. Source currency
      From_Code :=
        To_Unbounded_String (Prompt_Currency ("Source currency code : "));

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
        To_Unbounded_String (Prompt_Currency ("Target currency code : "));

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
            Rate      := Fetch_Rate (To_String (From_Code),
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

            Add_To_History (To_String (From_Code), To_String (To_Code),
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
