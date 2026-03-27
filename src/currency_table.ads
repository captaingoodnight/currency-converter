with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Currency_Table is

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

   function Is_Valid_Currency (Code : String) return Boolean;
   procedure Display_Currencies;

end Currency_Table;