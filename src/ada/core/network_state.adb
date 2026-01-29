-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Network Ambulance - Network State Machine (SPARK implementation)

pragma SPARK_Mode (On);

package body Network_State with
   SPARK_Mode => On
is

   procedure Initialize (Ctx : out Context_Type) is
   begin
      Ctx := (
         Current_State   => Unknown,
         Previous_State  => Unknown,
         DNS_Servers     => 0,
         Has_Route       => False,
         Has_Carrier     => False,
         Has_Internet    => False,
         Repair_Attempts => 0
      );
   end Initialize;

   procedure Transition (
      Ctx   : in out Context_Type;
      Event : in Event_Type
   ) is
   begin
      Ctx.Previous_State := Ctx.Current_State;

      case Event is
         when Start_Diagnosis =>
            Ctx.Current_State := Diagnosing;

         when Diagnosis_Complete =>
            -- Determine final state based on diagnostics
            if Ctx.Has_Internet and Ctx.Has_Route and Ctx.Has_Carrier
               and Ctx.DNS_Servers > 0
            then
               Ctx.Current_State := Healthy;
            elsif Ctx.DNS_Servers = 0 or not Ctx.Has_Internet then
               Ctx.Current_State := DNS_Failed;
            elsif not Ctx.Has_Route then
               Ctx.Current_State := No_Route;
            elsif not Ctx.Has_Carrier then
               Ctx.Current_State := No_Carrier;
            else
               Ctx.Current_State := No_Internet;
            end if;

         when DNS_OK =>
            if Ctx.Current_State = Diagnosing then
               Ctx.DNS_Servers := 1;  -- At least one server
            end if;

         when DNS_Fail =>
            if Ctx.Current_State = Diagnosing then
               Ctx.DNS_Servers := 0;
               Ctx.Current_State := DNS_Failed;
            end if;

         when Route_OK =>
            if Ctx.Current_State = Diagnosing then
               Ctx.Has_Route := True;
            end if;

         when Route_Fail =>
            if Ctx.Current_State = Diagnosing then
               Ctx.Has_Route := False;
               Ctx.Current_State := No_Route;
            end if;

         when Carrier_OK =>
            if Ctx.Current_State = Diagnosing then
               Ctx.Has_Carrier := True;
            end if;

         when Carrier_Fail =>
            if Ctx.Current_State = Diagnosing then
               Ctx.Has_Carrier := False;
               Ctx.Current_State := No_Carrier;
            end if;

         when Internet_OK =>
            if Ctx.Current_State = Diagnosing then
               Ctx.Has_Internet := True;
            end if;

         when Internet_Fail =>
            if Ctx.Current_State = Diagnosing then
               Ctx.Has_Internet := False;
               Ctx.Current_State := No_Internet;
            end if;

         when Start_Repair =>
            if Has_Problem (Ctx.Current_State)
               and Ctx.Repair_Attempts < Max_Repair_Attempts
            then
               Ctx.Current_State := Repairing;
               Ctx.Repair_Attempts := Ctx.Repair_Attempts + 1;
            end if;

         when Repair_Success =>
            if Ctx.Current_State = Repairing then
               Ctx.Current_State := Diagnosing;  -- Re-diagnose after repair
            end if;

         when Repair_Fail =>
            if Ctx.Current_State = Repairing then
               if Ctx.Repair_Attempts >= Max_Repair_Attempts then
                  Ctx.Current_State := Repair_Failed;
               else
                  Ctx.Current_State := Ctx.Previous_State;
               end if;
            end if;

         when Reset =>
            Initialize (Ctx);
      end case;
   end Transition;

   function Is_Terminal (State : State_Type) return Boolean is
   begin
      return State = Repair_Failed;
   end Is_Terminal;

   function Has_Problem (State : State_Type) return Boolean is
   begin
      return State in DNS_Failed | No_Route | No_Carrier | No_Internet | Repair_Failed;
   end Has_Problem;

   function Can_Repair (Ctx : Context_Type) return Boolean is
   begin
      return Has_Problem (Ctx.Current_State)
         and Ctx.Current_State /= Repairing
         and Ctx.Current_State /= Repair_Failed
         and Ctx.Repair_Attempts < Max_Repair_Attempts;
   end Can_Repair;

   function State_Name (State : State_Type) return String is
   begin
      case State is
         when Unknown       => return "Unknown";
         when Diagnosing    => return "Diagnosing";
         when Healthy       => return "Healthy";
         when DNS_Failed    => return "DNS Failed";
         when No_Route      => return "No Route";
         when No_Carrier    => return "No Carrier";
         when No_Internet   => return "No Internet";
         when Repairing     => return "Repairing";
         when Repair_Failed => return "Repair Failed";
      end case;
   end State_Name;

end Network_State;
