with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Interfaces.C;

package body Currency_Fetch is

   use type Interfaces.C.int;

   function C_System (Command : Interfaces.C.char_array)
      return Interfaces.C.int;
   pragma Import (C, C_System, "system");

   Temp_File : constant String := "/tmp/ada_currency_rate.json";

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

end Currency_Fetch;