-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Network Ambulance - TUI Display Interface

pragma Ada_2022;

with Network_State; use Network_State;

package TUI_Display with
   SPARK_Mode => Off  -- Terminal I/O not provable
is

   -- Display modes
   type Display_Mode is (
      Dashboard,    -- Main status overview
      Diagnostics,  -- Detailed diagnostic results
      Repairs,      -- Repair actions and results
      Help         -- Help and usage information
   );

   -- Initialize terminal for TUI
   procedure Initialize_Terminal;

   -- Cleanup and restore terminal
   procedure Cleanup_Terminal;

   -- Clear screen
   procedure Clear_Screen;

   -- Display header with title
   procedure Display_Header (Title : String);

   -- Display network state status
   procedure Display_State (Ctx : Context_Type);

   -- Display dashboard view
   procedure Display_Dashboard (Ctx : Context_Type);

   -- Display diagnostics view
   procedure Display_Diagnostics (Ctx : Context_Type);

   -- Display repairs view
   procedure Display_Repairs (Ctx : Context_Type);

   -- Display help view
   procedure Display_Help;

   -- Display status line at bottom
   procedure Display_Status_Line (Message : String);

   -- Display menu options
   procedure Display_Menu;

   -- Get user input (single character)
   function Get_Key return Character;

   -- Display error message
   procedure Display_Error (Message : String);

   -- Display success message
   procedure Display_Success (Message : String);

   -- Display a box with title and content
   procedure Display_Box (
      X      : Positive;
      Y      : Positive;
      Width  : Positive;
      Height : Positive;
      Title  : String;
      Content : String
   );

end TUI_Display;
