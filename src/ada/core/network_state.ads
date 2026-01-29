-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Network Ambulance - Network State Machine (SPARK specification)

pragma SPARK_Mode (On);

package Network_State with
   SPARK_Mode => On
is

   -- Network diagnostic states
   type State_Type is (
      Unknown,           -- Initial state, no data
      Diagnosing,        -- Running diagnostics
      Healthy,           -- All systems operational
      DNS_Failed,        -- DNS resolution failing
      No_Route,          -- No default route
      No_Carrier,        -- Physical link down
      No_Internet,       -- Cannot reach internet
      Repairing,         -- Repair in progress
      Repair_Failed      -- Repair unsuccessful
   );

   -- Transition events
   type Event_Type is (
      Start_Diagnosis,
      Diagnosis_Complete,
      DNS_OK,
      DNS_Fail,
      Route_OK,
      Route_Fail,
      Carrier_OK,
      Carrier_Fail,
      Internet_OK,
      Internet_Fail,
      Start_Repair,
      Repair_Success,
      Repair_Fail,
      Reset
   );

   -- State machine context
   type Context_Type is record
      Current_State   : State_Type := Unknown;
      Previous_State  : State_Type := Unknown;
      DNS_Servers     : Natural := 0;
      Has_Route       : Boolean := False;
      Has_Carrier     : Boolean := False;
      Has_Internet    : Boolean := False;
      Repair_Attempts : Natural := 0;
   end record;

   -- Constants
   Max_Repair_Attempts : constant Natural := 3;

   -- Initialize state machine
   procedure Initialize (Ctx : out Context_Type)
   with
      Post => Ctx.Current_State = Unknown
         and Ctx.Previous_State = Unknown
         and Ctx.DNS_Servers = 0
         and Ctx.Has_Route = False
         and Ctx.Has_Carrier = False
         and Ctx.Has_Internet = False
         and Ctx.Repair_Attempts = 0;

   -- State transition function
   procedure Transition (
      Ctx   : in out Context_Type;
      Event : in Event_Type
   )
   with
      Pre  => Ctx.Repair_Attempts <= Max_Repair_Attempts,
      Post => Ctx.Previous_State = Ctx.Current_State'Old
         and (if Event = Reset then Ctx.Repair_Attempts = 0
              else Ctx.Repair_Attempts <= Max_Repair_Attempts);

   -- Check if state is terminal (requires user action)
   function Is_Terminal (State : State_Type) return Boolean
   with
      Post => Is_Terminal'Result = (State in Repair_Failed);

   -- Check if state indicates a problem
   function Has_Problem (State : State_Type) return Boolean
   with
      Post => Has_Problem'Result =
         (State in DNS_Failed | No_Route | No_Carrier | No_Internet | Repair_Failed);

   -- Check if repair is possible from current state
   function Can_Repair (Ctx : Context_Type) return Boolean
   with
      Post => Can_Repair'Result =
         (Has_Problem (Ctx.Current_State)
          and Ctx.Current_State /= Repairing
          and Ctx.Current_State /= Repair_Failed
          and Ctx.Repair_Attempts < Max_Repair_Attempts);

   -- Get state name as string
   function State_Name (State : State_Type) return String;

end Network_State;
