-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Network Ambulance - TUI Display Implementation

pragma Ada_2022;

with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Characters.Latin_1; use Ada.Characters.Latin_1;

package body TUI_Display is

   -- ANSI escape codes
   Clear_Code    : constant String := ESC & "[2J" & ESC & "[H";
   Bold_On       : constant String := ESC & "[1m";
   Bold_Off      : constant String := ESC & "[0m";
   Green         : constant String := ESC & "[32m";
   Red           : constant String := ESC & "[31m";
   Yellow        : constant String := ESC & "[33m";
   Blue          : constant String := ESC & "[34m";
   Reset_Color   : constant String := ESC & "[0m";

   procedure Initialize_Terminal is
   begin
      -- Terminal initialization (raw mode would require ncurses)
      Clear_Screen;
   end Initialize_Terminal;

   procedure Cleanup_Terminal is
   begin
      Clear_Screen;
      Put_Line ("Terminal restored.");
   end Cleanup_Terminal;

   procedure Clear_Screen is
   begin
      Put (Clear_Code);
   end Clear_Screen;

   procedure Display_Header (Title : String) is
      Separator : String (1 .. Title'Length);
   begin
      for I in Separator'Range loop
         Separator (I) := '=';
      end loop;

      Put_Line (Bold_On & Blue & Title & Reset_Color & Bold_Off);
      Put_Line (Separator);
      New_Line;
   end Display_Header;

   procedure Display_State (Ctx : Context_Type) is
      Color : String (1 .. 5);
      Status_Icon : Character;
   begin
      -- Choose color and icon based on state
      case Ctx.Current_State is
         when Healthy =>
            Color := Green;
            Status_Icon := '+';
         when DNS_Failed | No_Route | No_Carrier | No_Internet | Repair_Failed =>
            Color := Red;
            Status_Icon := 'X';
         when Diagnosing | Repairing =>
            Color := Yellow;
            Status_Icon := '*';
         when Unknown =>
            Color := Reset_Color (1 .. 5);
            Status_Icon := '?';
      end case;

      Put_Line ("Status: " & Color & Status_Icon & " " &
                State_Name (Ctx.Current_State) & Reset_Color);
   end Display_State;

   procedure Display_Dashboard (Ctx : Context_Type) is
   begin
      Clear_Screen;
      Display_Header ("Network Ambulance - Dashboard");

      Display_State (Ctx);
      New_Line;

      Put_Line ("Network Diagnostics:");
      Put_Line ("  DNS Servers:     " &
                (if Ctx.DNS_Servers > 0 then Green & "[OK] Configured" else Red & "[NO] None") &
                Reset_Color);

      Put_Line ("  Default Route:   " &
                (if Ctx.Has_Route then Green & "[OK] Present" else Red & "[NO] Missing") &
                Reset_Color);

      Put_Line ("  Physical Link:   " &
                (if Ctx.Has_Carrier then Green & "[OK] UP" else Red & "[NO] DOWN") &
                Reset_Color);

      Put_Line ("  Internet:        " &
                (if Ctx.Has_Internet then Green & "[OK] Connected" else Red & "[NO] Disconnected") &
                Reset_Color);

      New_Line;
      Put_Line ("Repair Attempts: " & Ctx.Repair_Attempts'Image & " / " &
                Max_Repair_Attempts'Image);

      New_Line;
      Display_Menu;
   end Display_Dashboard;

   procedure Display_Diagnostics (Ctx : Context_Type) is
   begin
      Clear_Screen;
      Display_Header ("Network Ambulance - Diagnostics");

      Display_State (Ctx);
      New_Line;

      Put_Line (Bold_On & "Detailed Diagnostics:" & Bold_Off);
      Put_Line ("  [DNS]      " & (if Ctx.DNS_Servers > 0
                then "Servers configured: " & Ctx.DNS_Servers'Image
                else "No DNS servers configured"));

      Put_Line ("  [Routing]  " & (if Ctx.Has_Route
                then "Default route present"
                else "No default route"));

      Put_Line ("  [Interface] " & (if Ctx.Has_Carrier
                then "Physical link UP"
                else "Physical link DOWN"));

      Put_Line ("  [Internet] " & (if Ctx.Has_Internet
                then "Connectivity OK"
                else "Cannot reach internet"));

      New_Line;
      Display_Menu;
   end Display_Diagnostics;

   procedure Display_Repairs (Ctx : Context_Type) is
   begin
      Clear_Screen;
      Display_Header ("Network Ambulance - Repairs");

      Display_State (Ctx);
      New_Line;

      if Can_Repair (Ctx) then
         Put_Line (Green & "Repairs available for current issues." & Reset_Color);
         New_Line;
         Put_Line ("Available repair actions:");

         if Ctx.DNS_Servers = 0 then
            Put_Line ("  • Configure DNS servers (8.8.8.8, 1.1.1.1)");
         end if;

         if not Ctx.Has_Route then
            Put_Line ("  • Add default route");
         end if;

         if not Ctx.Has_Carrier then
            Put_Line ("  • Reset network interface");
         end if;

         if not Ctx.Has_Internet then
            Put_Line ("  • Diagnose connectivity issues");
         end if;

      elsif Ctx.Current_State = Repair_Failed then
         Put_Line (Red & "Automatic repair failed." & Reset_Color);
         Put_Line ("Manual intervention required.");

      elsif Ctx.Current_State = Healthy then
         Put_Line (Green & "No repairs needed - system healthy." & Reset_Color);

      else
         Put_Line (Yellow & "Run diagnostics first." & Reset_Color);
      end if;

      New_Line;
      Display_Menu;
   end Display_Repairs;

   procedure Display_Help is
   begin
      Clear_Screen;
      Display_Header ("Network Ambulance - Help");

      Put_Line ("Keyboard Commands:");
      Put_Line ("  d - Run diagnostics");
      Put_Line ("  r - Attempt repair");
      Put_Line ("  1 - Dashboard view");
      Put_Line ("  2 - Diagnostics view");
      Put_Line ("  3 - Repairs view");
      Put_Line ("  h - Help (this screen)");
      Put_Line ("  q - Quit");
      New_Line;

      Put_Line ("About:");
      Put_Line ("  Network Ambulance TUI v1.1.0-alpha");
      Put_Line ("  Ada 2022 + SPARK formally verified");
      Put_Line ("  Safety-critical network diagnostics and repair");
      New_Line;

      Put_Line ("Press any key to continue...");
   end Display_Help;

   procedure Display_Status_Line (Message : String) is
   begin
      Put_Line (Bold_On & "─────────────────────────────────────────" & Bold_Off);
      Put_Line (Message);
   end Display_Status_Line;

   procedure Display_Menu is
   begin
      Display_Status_Line ("d=Diagnose | r=Repair | 1=Dashboard | 2=Details | 3=Repairs | h=Help | q=Quit");
   end Display_Menu;

   function Get_Key return Character is
      C : Character;
   begin
      Get_Immediate (C);
      return C;
   end Get_Key;

   procedure Display_Error (Message : String) is
   begin
      Put_Line (Red & "[ERROR] " & Message & Reset_Color);
   end Display_Error;

   procedure Display_Success (Message : String) is
   begin
      Put_Line (Green & "[OK] " & Message & Reset_Color);
   end Display_Success;

   procedure Display_Box (
      X      : Positive;
      Y      : Positive;
      Width  : Positive;
      Height : Positive;
      Title  : String;
      Content : String
   ) is
      pragma Unreferenced (X, Y, Height);
      Top_Border : String (1 .. Width);
   begin
      for I in Top_Border'Range loop
         Top_Border (I) := '-';
      end loop;

      Put_Line ("+" & Top_Border & "+");
      Put_Line ("| " & Title & " |");
      Put_Line ("+" & Top_Border & "+");
      Put_Line ("| " & Content & " |");
      Put_Line ("+" & Top_Border & "+");
   end Display_Box;

end TUI_Display;
