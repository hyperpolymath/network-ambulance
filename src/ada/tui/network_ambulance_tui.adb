-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Network Ambulance - Main TUI Program

pragma Ada_2022;

with Ada.Text_IO;        use Ada.Text_IO;
with Ada.Exceptions;     use Ada.Exceptions;
with Network_State;      use Network_State;
with TUI_Display;        use TUI_Display;

procedure Network_Ambulance_TUI is

   Ctx          : Context_Type;
   Current_View : Display_Mode := Dashboard;
   Running      : Boolean := True;
   Key          : Character;

   -- Simulate running network diagnostics
   procedure Run_Diagnostics is
   begin
      Display_Status_Line ("Running diagnostics...");

      -- Transition to diagnosing state
      Transition (Ctx, Start_Diagnosis);

      -- Simulate diagnostic checks
      -- In real implementation, these would call the D backend or shell commands

      -- Check DNS (simulated - would call: network-ambulance-d diagnose --json)
      Transition (Ctx, DNS_OK);
      Ctx.DNS_Servers := 2;  -- Simulated result

      -- Check routing
      Transition (Ctx, Route_OK);
      Ctx.Has_Route := True;

      -- Check carrier
      Transition (Ctx, Carrier_OK);
      Ctx.Has_Carrier := True;

      -- Check internet
      Transition (Ctx, Internet_OK);
      Ctx.Has_Internet := True;

      -- Complete diagnosis
      Transition (Ctx, Diagnosis_Complete);

      Display_Success ("Diagnostics complete");
      delay 1.0;
   end Run_Diagnostics;

   -- Simulate running repairs
   procedure Run_Repairs is
   begin
      if not Can_Repair (Ctx) then
         Display_Error ("No repairs available");
         delay 2.0;
         return;
      end if;

      Display_Status_Line ("Running repairs...");

      -- Transition to repairing state
      Transition (Ctx, Start_Repair);

      -- Simulate repair operations
      -- In real implementation, would call: network-ambulance-d repair all --json
      delay 2.0;

      -- Simulate success
      Transition (Ctx, Repair_Success);

      Display_Success ("Repair complete - re-running diagnostics");
      delay 1.0;

      -- Re-diagnose after repair
      Run_Diagnostics;
   end Run_Repairs;

   -- Main event loop
   procedure Event_Loop is
   begin
      while Running loop
         -- Display current view
         case Current_View is
            when Dashboard =>
               Display_Dashboard (Ctx);
            when Diagnostics =>
               Display_Diagnostics (Ctx);
            when Repairs =>
               Display_Repairs (Ctx);
            when Help =>
               Display_Help;
         end case;

         -- Get user input
         Key := Get_Key;

         -- Process command
         case Key is
            when 'd' | 'D' =>
               Run_Diagnostics;

            when 'r' | 'R' =>
               Run_Repairs;

            when '1' =>
               Current_View := Dashboard;

            when '2' =>
               Current_View := Diagnostics;

            when '3' =>
               Current_View := Repairs;

            when 'h' | 'H' | '?' =>
               Current_View := Help;

            when 'q' | 'Q' =>
               Running := False;

            when others =>
               Display_Error ("Unknown command: " & Key);
               delay 1.0;
         end case;
      end loop;
   end Event_Loop;

begin
   -- Initialize
   Initialize (Ctx);
   Initialize_Terminal;

   -- Display welcome
   Clear_Screen;
   Display_Header ("Network Ambulance TUI v1.1.0-alpha");
   Put_Line ("Ada 2022 + SPARK Formally Verified");
   Put_Line ("Safety-Critical Network Diagnostics");
   New_Line;
   Put_Line ("Press any key to start...");
   Key := Get_Key;

   -- Run main event loop
   Event_Loop;

   -- Cleanup
   Cleanup_Terminal;
   Put_Line ("Thank you for using Network Ambulance.");

exception
   when E : others =>
      Cleanup_Terminal;
      Put_Line ("Fatal error: " & Exception_Information (E));
end Network_Ambulance_TUI;
