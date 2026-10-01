sura_controllers
================

``sura_controllers`` contains reusable ROS 2 Control controller plugins for SURA
vehicles.

These controllers convert motion commands into references that the robot
hardware can execute. Depending on the selected configuration, SURA can work
with position targets, velocity targets, attitude/depth targets or direct body
force commands.

Configuration
-------------

Controllers are configured in the robot ROS 2 Control parameter file:

.. code-block:: text

   <robot_namespace>_description/config/<ros2_control_params>.yaml

This file is explained in
:doc:`ROS 2 Control Params YAML <robot_description_ros2_control_params>`.

This file declares the controller names, plugin types and parameters. The robot
xacro defines the physical joints, thrusters, sensors and actuators that those
controllers connect to.

In a normal robot startup, this package is loaded by
``sura_controllers.launch.py`` from :doc:`sura_bringup <sura_bringup>`.

Controller Arbitrator
---------------------

``ControllerArbitrator`` is the common entry point for movement requests from
teleoperation and mission behaviors. It decides which request takes control,
preventing competing sources from sending conflicting commands to the
controllers. The controllers then turn the selected command into robot motion.

Messages You Can Send
^^^^^^^^^^^^^^^^^^^^^

The three message types come from :doc:`sura_msgs <sura_msgs>`. All identify
the sender (``requester``), destination (``controller``) and ``priority`` from
1 to 100, plus standard ROS metadata (``header``). Each adds a different command
field, shown below with example values. Topic names share the prefix
``/<robot_namespace>/controller/arbitrator/``.

.. raw:: html

   <svg class="bringup-flow" viewBox="0 0 800 345" role="img" aria-labelledby="arbitrator-messages-title arbitrator-messages-desc">
     <title id="arbitrator-messages-title">Three message types accepted by the arbitrator</title>
     <desc id="arbitrator-messages-desc">Every message includes header, requester, controller and priority. A velocity request adds a Twist, a pose request adds a PoseStamped, and a force and torque request adds a Wrench. The cards show illustrative values for each.</desc>

     <rect class="box source" x="20" y="10" width="244" height="320" rx="8"></rect>
     <text class="primary-label" x="142" y="37" text-anchor="middle">SuraVelocityCommand</text>
     <text class="small-label" x="142" y="58" text-anchor="middle">topic: …/velocity</text>
     <path class="line" d="M32 72 H252"></path>
     <text x="35" y="96">header: ROS metadata</text>
     <text x="35" y="120">requester: teleop</text>
     <text x="35" y="144">controller: body_velocity</text>
     <text x="35" y="168">priority: 80</text>
     <rect class="box primary" x="32" y="188" width="220" height="127" rx="6"></rect>
     <text class="primary-label" x="45" y="214">velocity · Twist</text>
     <text x="45" y="245">linear.x: 0.2 m/s</text>
     <text x="45" y="271">angular.z: 0.0 rad/s</text>
     <text class="small-label" x="45" y="299">Move forward without turning</text>

     <rect class="box source" x="278" y="10" width="244" height="320" rx="8"></rect>
     <text class="primary-label" x="400" y="37" text-anchor="middle">SuraPoseCommand</text>
     <text class="small-label" x="400" y="58" text-anchor="middle">topic: …/pose</text>
     <path class="line" d="M290 72 H510"></path>
     <text x="293" y="96">header: ROS metadata</text>
     <text x="293" y="120">requester: mission</text>
     <text x="293" y="144">controller: position_hold</text>
     <text x="293" y="168">priority: 40</text>
     <rect class="box primary" x="290" y="188" width="220" height="127" rx="6"></rect>
     <text class="primary-label" x="303" y="214">pose · PoseStamped</text>
     <text class="small-label" x="303" y="240">header.frame_id: world_ned</text>
     <text x="303" y="265">position: (2, 1, -3) m</text>
     <text x="303" y="291">orientation: (0, 0, 0, 1)</text>

     <rect class="box source" x="536" y="10" width="244" height="320" rx="8"></rect>
     <text class="primary-label" x="658" y="37" text-anchor="middle">SuraWrenchCommand</text>
     <text class="small-label" x="658" y="58" text-anchor="middle">topic: …/wrench</text>
     <path class="line" d="M548 72 H768"></path>
     <text x="551" y="96">header: ROS metadata</text>
     <text x="551" y="120">requester: helper</text>
     <text x="551" y="144">controller: body_force</text>
     <text x="551" y="168">priority: 20</text>
     <rect class="box primary" x="548" y="188" width="220" height="127" rx="6"></rect>
     <text class="primary-label" x="561" y="214">wrench · Wrench</text>
     <text x="561" y="245">force.x: 5 N</text>
     <text x="561" y="271">torque.z: 0 N*m</text>
     <text class="small-label" x="561" y="299">Apply a forward body force</text>
   </svg>

The cards show representative command values; the remaining velocity and force
components are zero in these examples. Pose orientation uses a quaternion in
``(x, y, z, w)`` order; ``(0, 0, 0, 1)`` means no rotation in the chosen frame.

The arbitrator's parameters map each controller to an accepted message type and
output topic. Requests for an unknown controller or with an incompatible type
are rejected. It forwards the selected command field as a standard ROS message
(``geometry_msgs/Twist``, ``geometry_msgs/PoseStamped`` or
``geometry_msgs/Wrench``) to that topic.

The pose route is available, but the current teleoperation node sends velocity
and wrench requests only. ``PositionHoldController`` can also take its pose
target from the robot's current navigation state.

How Requests Are Kept and Selected
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The request queue keeps one entry per ``requester`` + ``controller`` pair.
A new message from that pair replaces its entry and refreshes its reception
time. At each cycle, the highest-priority valid entry is sent again and remains
in the queue; the others stay available. The diagram shows an example, arranged
by priority to make the selection visible.

.. raw:: html

   <svg class="bringup-flow" viewBox="0 0 800 565" role="img" aria-labelledby="arbitrator-title arbitrator-desc">
     <title id="arbitrator-title">Arbitrator requests and priority selection</title>
     <desc id="arbitrator-desc">A new teleop message changes forward velocity from 0.2 to 0.3 meters per second in the existing teleop and body_velocity entry. Teleop at priority 80 is selected, while mission at 40 and helper at 20 remain available. When teleop expires, the mission velocity request is selected because the mission continues refreshing its entry.</desc>
     <defs>
       <marker id="arbitrator-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
         <path d="M 0 0 L 10 5 L 0 10 z" fill="#5f7280"></path>
       </marker>
     </defs>

     <rect class="box source" x="20" y="15" width="250" height="76" rx="6"></rect>
     <text class="primary-label" x="145" y="38" text-anchor="middle">New teleop message</text>
     <text class="small-label" x="145" y="59" text-anchor="middle">body_velocity · priority 80</text>
     <text x="145" y="80" text-anchor="middle">linear.x: 0.2 → 0.3 m/s</text>
     <path class="line" d="M270 53 H320" marker-end="url(#arbitrator-arrow)"></path>
     <rect class="box config" x="320" y="15" width="460" height="76" rx="6"></rect>
     <text class="primary-label" x="550" y="40" text-anchor="middle">Same sender + controller → update its entry</text>
     <text x="550" y="68" text-anchor="middle">Replace the value and refresh the timeout</text>
     <path class="line" d="M400 91 V120" marker-end="url(#arbitrator-arrow)"></path>

     <rect class="namespace" x="20" y="120" width="530" height="280" rx="8"></rect>
     <text class="primary-label" x="40" y="146">ControllerArbitrator: stored requests</text>
     <text class="small-label" x="40" y="170">One entry per requester + controller; new messages update that entry</text>
     <text class="small-label" x="73" y="196" text-anchor="middle">Priority</text>
     <text class="small-label" x="145" y="196">Requester → controller</text>
     <text class="small-label" x="480" y="196" text-anchor="middle">Command</text>

     <rect class="box primary" x="35" y="207" width="500" height="46" rx="6"></rect>
     <text class="primary-label" x="73" y="236" text-anchor="middle">80</text>
     <text x="145" y="236">teleop → body_velocity</text>
     <text x="480" y="236" text-anchor="middle">0.3 m/s</text>
     <rect class="box" x="35" y="263" width="500" height="46" rx="6"></rect>
     <text x="73" y="292" text-anchor="middle">40</text>
     <text x="145" y="292">mission → body_velocity</text>
     <text x="480" y="292" text-anchor="middle">0.1 m/s</text>
     <rect class="box" x="35" y="319" width="500" height="46" rx="6"></rect>
     <text x="73" y="348" text-anchor="middle">20</text>
     <text x="145" y="348">helper → body_force</text>
     <text x="480" y="348" text-anchor="middle">5 N</text>
     <text class="small-label" x="40" y="387">Lower-priority requests remain available while valid</text>

     <path class="line" d="M535 230 H595" marker-end="url(#arbitrator-arrow)"></path>
     <text class="small-label" x="687" y="194" text-anchor="middle">Selected this cycle</text>
     <rect class="box primary" x="595" y="207" width="185" height="62" rx="6"></rect>
     <text x="687" y="232" text-anchor="middle">body_velocity</text>
     <text class="small-label" x="687" y="254" text-anchor="middle">Twist · linear.x = 0.3</text>
     <path class="line" d="M687 269 V319" marker-end="url(#arbitrator-arrow)"></path>
     <rect class="box" x="595" y="319" width="185" height="56" rx="6"></rect>
     <text x="687" y="343" text-anchor="middle">Control chain</text>
     <text x="687" y="363" text-anchor="middle">and thrusters</text>

     <rect class="namespace" x="20" y="420" width="760" height="125" rx="8"></rect>
     <text class="primary-label" x="40" y="446">Next: teleop stops sending and its request expires</text>
     <rect class="box variable" x="35" y="463" width="200" height="44" rx="6"></rect>
     <text x="135" y="490" text-anchor="middle">80 · teleop removed</text>
     <path class="line" d="M235 485 H285" marker-end="url(#arbitrator-arrow)"></path>
     <rect class="box primary" x="285" y="463" width="250" height="44" rx="6"></rect>
     <text x="410" y="490" text-anchor="middle">40 · mission → body_velocity</text>
     <path class="line" d="M535 485 H595" marker-end="url(#arbitrator-arrow)"></path>
     <rect class="box" x="595" y="463" width="170" height="44" rx="6"></rect>
     <text x="680" y="490" text-anchor="middle">Twist · linear.x = 0.1</text>
     <text class="small-label" x="40" y="531">The mission keeps sending updates, so its request is still valid.</text>
   </svg>

Three rules govern this selection:

- **Priority:** one request wins across all controllers. If priorities are
  equal, the most recently received request wins.
- **Lifetime:** velocity and force requests expire after the configured timeout
  (0.15 seconds by default) without an update. Pose targets remain available
  until replaced or cleared.
- **Handover:** when a selected velocity or force request loses control or
  expires, the arbitrator sends zero to its previous destination. The next
  valid winner then takes over, as shown above.

With a position-hold request present, selected body velocity commands pass
through ``PositionHoldController``'s velocity input, allowing movement while
preserving the stored pose target.

Services allow requests to be cleared and controllers to be blocked by a safety
interlock. Blocked requests are removed and new ones rejected. Controller
activation is a separate request: the arbitrator forwards it to
``controller_manager`` only if the requested controllers are not blocked.

Available Controllers
---------------------

Body Force Controller
^^^^^^^^^^^^^^^^^^^^^

``BodyForceController`` is the controller that converts a desired force and
torque on the robot body into individual thruster commands.

It reads the robot description, finds the thruster joints with an ``effort``
command interface and computes the Thruster Allocation Matrix from the TFs of
the thrusters defined in the
:doc:`robot xacro <robot_description_urdf_xacro>`. In practice, this matrix
tells SURA how each thruster contributes to surge, sway, heave, roll, pitch and
yaw.

Input body forces are expressed in Newtons, ``N``, and body torques in Newton
meters, ``N*m``. The output effort command for each thruster is also expressed
as force in Newtons, ``N``.

.. raw:: html

   <svg class="bringup-flow" viewBox="0 0 800 145" role="img" aria-label="body force controller allocation flow">
     <defs>
       <marker id="body-force-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
         <path d="M 0 0 L 10 5 L 0 10 z" fill="#5f7280"></path>
       </marker>
     </defs>

     <rect class="box" x="35" y="52" width="185" height="46" rx="6"></rect>
     <text x="127" y="80" text-anchor="middle">desired body wrench</text>

     <rect class="box primary" x="280" y="24" width="285" height="98" rx="8"></rect>
     <text class="primary-label" x="422" y="55" text-anchor="middle">BodyForceController</text>
     <rect class="box source" x="325" y="74" width="195" height="34" rx="6"></rect>
     <text class="small-label" x="422" y="96" text-anchor="middle">Thruster Allocation Matrix</text>

     <rect class="box" x="625" y="52" width="150" height="46" rx="6"></rect>
     <text x="700" y="72" text-anchor="middle">individual</text>
     <text x="700" y="90" text-anchor="middle">thruster efforts</text>

     <path class="line" d="M220 75 H280" marker-end="url(#body-force-arrow)"></path>
     <path class="line" d="M565 75 H625" marker-end="url(#body-force-arrow)"></path>
   </svg>

This is usually the last controller before
:doc:`sura_hardware_interface <sura_hardware_interface>` sends commands to the
real thrusters or to the simulator.

Stabilize Controller
^^^^^^^^^^^^^^^^^^^^

``sura_controllers/auv/StabilizeController`` is an AUV PID controller used to
stabilize attitude. It uses the navigation estimate, applies roll, pitch and yaw
PID control and outputs a body force reference for the body force controller.
``Navigator references`` provide the current roll, pitch and yaw used as
feedback. ``desired wrench`` provides the force/torque command to correct.
``StabilizeController`` adds the PID attitude correction and outputs a
``corrected wrench``. That corrected wrench is passed to ``BodyForceController``,
which converts it into thruster efforts.

.. raw:: html

   <svg class="bringup-flow" viewBox="0 0 900 190" role="img" aria-label="stabilize controller flow">
     <defs>
       <marker id="stabilize-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
         <path d="M 0 0 L 10 5 L 0 10 z" fill="#5f7280"></path>
       </marker>
     </defs>

     <rect class="box" x="30" y="28" width="175" height="54" rx="6"></rect>
     <text x="117" y="50" text-anchor="middle">Navigator references</text>
     <text class="small-label" x="117" y="68" text-anchor="middle">roll, pitch, yaw</text>
     <rect class="box" x="30" y="108" width="175" height="54" rx="6"></rect>
     <text x="117" y="130" text-anchor="middle">desired wrench</text>
     <text class="small-label" x="117" y="148" text-anchor="middle">force and torque</text>

     <rect class="box primary" x="285" y="58" width="245" height="78" rx="8"></rect>
     <text class="primary-label" x="407" y="103" text-anchor="middle">StabilizeController</text>

     <rect class="box primary" x="615" y="58" width="245" height="78" rx="8"></rect>
     <text class="primary-label" x="737" y="103" text-anchor="middle">BodyForceController</text>

     <rect class="box" x="655" y="150" width="165" height="34" rx="6"></rect>
     <text x="737" y="172" text-anchor="middle">thruster efforts</text>

     <path class="line" d="M205 55 H245 V86 H285" marker-end="url(#stabilize-arrow)"></path>
     <path class="line" d="M205 135 H245 V110 H285" marker-end="url(#stabilize-arrow)"></path>
     <path class="line" d="M530 97 H615" marker-end="url(#stabilize-arrow)"></path>
     <path class="line" d="M737 136 V150" marker-end="url(#stabilize-arrow)"></path>
   </svg>

The PID gains are configured in the
:doc:`robot ros2_control YAML <robot_description_ros2_control_params>` with
parameters such as ``kp_roll``, ``ki_roll``, ``kd_roll``, ``kp_pitch``,
``ki_pitch``, ``kd_pitch``, ``kp_yaw``, ``ki_yaw`` and ``kd_yaw``. The same
section also contains desired-wrench gains, named ``feedforward_gain_*`` in the
controller parameters, and command thresholds.

Roll, pitch and yaw errors are in radians, ``rad``. The desired wrench and the
controller output use Newtons, ``N``, and Newton meters, ``N*m``.

Depth Hold Controller
^^^^^^^^^^^^^^^^^^^^^

``sura_controllers/auv/DepthHoldController`` is an AUV PID controller for
holding depth and yaw. It can also keep roll and pitch stabilized when enabled.
``Navigator references`` provide the current depth, roll, pitch and yaw used as
feedback. ``desired wrench`` provides the force/torque command to correct.
``DepthHoldController`` adds the PID correction and sends the resulting wrench
directly to ``BodyForceController``.

.. raw:: html

   <svg class="bringup-flow" viewBox="0 0 900 190" role="img" aria-label="depth hold controller flow">
     <defs>
       <marker id="depth-hold-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
         <path d="M 0 0 L 10 5 L 0 10 z" fill="#5f7280"></path>
       </marker>
     </defs>

     <rect class="box" x="30" y="28" width="175" height="54" rx="6"></rect>
     <text x="117" y="50" text-anchor="middle">Navigator references</text>
     <text class="small-label" x="117" y="68" text-anchor="middle">depth, roll, pitch, yaw</text>
     <rect class="box" x="30" y="108" width="175" height="42" rx="6"></rect>
     <text x="117" y="134" text-anchor="middle">desired wrench</text>

     <rect class="box primary" x="285" y="58" width="245" height="78" rx="8"></rect>
     <text class="primary-label" x="407" y="103" text-anchor="middle">DepthHoldController</text>

     <rect class="box primary" x="615" y="58" width="245" height="78" rx="8"></rect>
     <text class="primary-label" x="737" y="103" text-anchor="middle">BodyForceController</text>

     <rect class="box" x="655" y="150" width="165" height="34" rx="6"></rect>
     <text x="737" y="172" text-anchor="middle">thruster efforts</text>

     <path class="line" d="M205 55 H245 V86 H285" marker-end="url(#depth-hold-arrow)"></path>
     <path class="line" d="M205 129 H245 V110 H285" marker-end="url(#depth-hold-arrow)"></path>
     <path class="line" d="M530 97 H615" marker-end="url(#depth-hold-arrow)"></path>
     <path class="line" d="M737 136 V150" marker-end="url(#depth-hold-arrow)"></path>
   </svg>

Its PID gains are configured in the robot ``ros2_control`` YAML with parameters
such as ``kp_depth``, ``ki_depth``, ``kd_depth``, ``kp_yaw``, ``ki_yaw`` and
``kd_yaw``. The same controller section also includes ``depth_bias_force``,
feedforward gains and command thresholds.

Depth is expressed in meters, ``m``, and yaw in radians, ``rad``. The output of
this controller is a body force reference in Newtons, ``N``, and Newton meters,
``N*m``.

Body Velocity Controllers
^^^^^^^^^^^^^^^^^^^^^^^^^

Body velocity controllers track a desired robot velocity and generate the body
force reference needed to achieve it. The next controller is selected by the
``feedforward_topic`` configured in the robot YAML. In the BlueROV
configuration, the velocity output is passed to ``DepthHoldController`` before
reaching ``BodyForceController``:

.. raw:: html

   <svg class="bringup-flow" viewBox="0 0 1060 190" role="img" aria-label="body velocity controller cascade">
     <defs>
       <marker id="body-velocity-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
         <path d="M 0 0 L 10 5 L 0 10 z" fill="#5f7280"></path>
       </marker>
     </defs>

     <rect class="box" x="25" y="34" width="170" height="46" rx="6"></rect>
     <text x="110" y="62" text-anchor="middle">velocity command</text>
     <rect class="box" x="25" y="110" width="170" height="46" rx="6"></rect>
     <text x="110" y="138" text-anchor="middle">Navigator references</text>

     <rect class="box primary" x="250" y="48" width="230" height="78" rx="8"></rect>
     <text class="primary-label" x="365" y="93" text-anchor="middle">BodyVelocityController</text>

     <rect class="box primary" x="545" y="48" width="220" height="78" rx="8"></rect>
     <text class="primary-label" x="655" y="93" text-anchor="middle">DepthHoldController</text>

     <rect class="box primary" x="830" y="48" width="220" height="78" rx="8"></rect>
     <text class="primary-label" x="940" y="93" text-anchor="middle">BodyForceController</text>

     <rect class="box" x="857" y="144" width="165" height="34" rx="6"></rect>
     <text x="940" y="166" text-anchor="middle">thruster efforts</text>

     <path class="line" d="M195 57 H222 V76 H250" marker-end="url(#body-velocity-arrow)"></path>
     <path class="line" d="M195 133 H222 V101 H250" marker-end="url(#body-velocity-arrow)"></path>
     <path class="line" d="M480 87 H545" marker-end="url(#body-velocity-arrow)"></path>
     <path class="line" d="M765 87 H830" marker-end="url(#body-velocity-arrow)"></path>
     <path class="line" d="M940 126 V144" marker-end="url(#body-velocity-arrow)"></path>
   </svg>

For AUVs, ``sura_controllers/auv/BodyVelocityController`` controls the six body
axes using PID gains such as ``kp_x``, ``ki_x``, ``kd_x``, ``kp_yaw``,
``ki_yaw`` and ``kd_yaw``.

For USVs, ``sura_controllers/usv/BodyVelocityController`` focuses on surge
velocity and yaw rate, with parameters such as ``kp_u``, ``ki_u``, ``kd_u``,
``kp_r``, ``ki_r`` and ``kd_r``.

Linear velocity references are in meters per second, ``m/s``. Angular velocity
references are in radians per second, ``rad/s``. The output of this controller
is a body force reference in Newtons, ``N``, and Newton meters, ``N*m``.

These values are configured in the controller parameter section of the robot
``ros2_control`` YAML.

Position Hold Controllers
^^^^^^^^^^^^^^^^^^^^^^^^^

Position hold controllers track a target pose or target position and generate
velocity references. They are one level above the velocity controller, so the
typical AUV chain starts with ``PositionHoldController`` and then continues
through the same velocity and wrench controllers:

.. raw:: html

   <svg class="bringup-flow" viewBox="0 0 1120 390" role="img" aria-label="position hold controller cascade">
     <defs>
       <marker id="position-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
         <path d="M 0 0 L 10 5 L 0 10 z" fill="#5f7280"></path>
       </marker>
     </defs>

     <rect class="box" x="25" y="42" width="170" height="46" rx="6"></rect>
     <text x="110" y="70" text-anchor="middle">position target</text>
     <rect class="box" x="25" y="112" width="170" height="46" rx="6"></rect>
     <text x="110" y="140" text-anchor="middle">Navigator references</text>

     <rect class="box primary" x="230" y="40" width="200" height="68" rx="8"></rect>
     <text class="primary-label" x="330" y="80" text-anchor="middle">PositionHoldController</text>

     <rect class="box primary" x="450" y="110" width="200" height="68" rx="8"></rect>
     <text class="primary-label" x="550" y="150" text-anchor="middle">BodyVelocityController</text>

     <rect class="box primary" x="670" y="180" width="200" height="68" rx="8"></rect>
     <text class="primary-label" x="770" y="220" text-anchor="middle">DepthHoldController</text>

     <rect class="box primary" x="890" y="250" width="200" height="68" rx="8"></rect>
     <text class="primary-label" x="990" y="290" text-anchor="middle">BodyForceController</text>

     <rect class="box" x="907" y="340" width="165" height="34" rx="6"></rect>
     <text x="990" y="362" text-anchor="middle">thruster efforts</text>

     <path class="line" d="M195 65 H212 V66 H230" marker-end="url(#position-arrow)"></path>
     <path class="line" d="M195 135 H212 V88 H230" marker-end="url(#position-arrow)"></path>
     <path class="line" d="M430 74 H440 V144 H450" marker-end="url(#position-arrow)"></path>
     <path class="line" d="M650 144 H660 V214 H670" marker-end="url(#position-arrow)"></path>
     <path class="line" d="M870 214 H880 V284 H890" marker-end="url(#position-arrow)"></path>
     <path class="line" d="M990 318 V340" marker-end="url(#position-arrow)"></path>
   </svg>

For AUVs, ``sura_controllers/auv/PositionHoldController`` generates body
velocity references from a pose target and the current navigation estimate. It
uses PID gains for position and attitude axes, configured with parameters such
as ``kp_x``, ``ki_x``, ``kd_x``, ``kp_z``, ``kp_yaw`` and ``antiwindup_*`` in
the robot ``ros2_control`` YAML.

For USVs, ``sura_controllers/usv/BodyPositionController`` generates surge and
yaw-rate references from a position target. Its user-facing tuning includes
``kp_position``, ``kp_yaw``, speed limits, position thresholds and yaw
tolerance.

Position targets and thresholds are expressed in meters, ``m``. Roll, pitch and
yaw are expressed in radians, ``rad``. The output of this controller is a
velocity reference: linear velocity in meters per second, ``m/s``, and angular
velocity in radians per second, ``rad/s``.

Alpha Cartesian Velocity Controller
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

``sura_controllers/uvms/AlphaCartesianVelocityController`` controls Cartesian
velocity references for the Alpha manipulator and writes joint velocity
commands. It uses the robot description, base/tip frames, joint list, velocity
limits and IK parameters from the robot ``ros2_control`` YAML.

Cartesian linear velocity commands are in meters per second, ``m/s``. Cartesian
angular velocity commands and joint velocity outputs are in radians per second,
``rad/s``.

.. raw:: html

   <svg class="bringup-flow" viewBox="0 0 860 145" role="img" aria-label="alpha cartesian velocity controller flow">
     <defs>
       <marker id="alpha-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
         <path d="M 0 0 L 10 5 L 0 10 z" fill="#5f7280"></path>
       </marker>
     </defs>

     <rect class="box" x="30" y="28" width="165" height="42" rx="6"></rect>
     <text x="112" y="54" text-anchor="middle">cartesian twist</text>
     <rect class="box" x="30" y="86" width="165" height="42" rx="6"></rect>
     <text x="112" y="112" text-anchor="middle">robot description</text>

     <rect class="box primary" x="280" y="26" width="285" height="104" rx="8"></rect>
     <text class="primary-label" x="422" y="57" text-anchor="middle">AlphaCartesianVelocity</text>
     <text class="primary-label" x="422" y="77" text-anchor="middle">Controller</text>
     <rect class="box source" x="345" y="92" width="155" height="28" rx="6"></rect>
     <text class="small-label" x="422" y="111" text-anchor="middle">IK and limits</text>

     <rect class="box" x="650" y="54" width="170" height="46" rx="6"></rect>
     <text x="735" y="74" text-anchor="middle">joint velocity</text>
     <text x="735" y="92" text-anchor="middle">commands</text>

     <path class="line" d="M195 49 H240 V67 H280" marker-end="url(#alpha-arrow)"></path>
     <path class="line" d="M195 107 H240 V91 H280" marker-end="url(#alpha-arrow)"></path>
     <path class="line" d="M565 78 H650" marker-end="url(#alpha-arrow)"></path>
   </svg>

Controller Families
-------------------

Controllers are grouped by robot family. The launch selects the groups from the
``family`` declared in the robot xacro and from the lists defined in the
``ros2_control`` YAML.

``common``
   ``BodyForceController``.

``auv``
   ``BodyForceController``, ``BodyVelocityController``,
   ``PositionHoldController``, ``StabilizeController``,
   ``DepthHoldController`` and ``Mpc4dofController``.

``usv``
   ``BodyForceController``, ``BodyVelocityController`` and
   ``BodyPositionController``.

``uvms``
   ``AlphaCartesianVelocityController``.

Debug Information
-----------------

Several controllers can publish ``sura_msgs/msg/ControllerDebug``. This is used
to monitor whether a controller is active and whether its update loop is meeting
the expected period.

When enabled in the controller parameters, this debug information can be used by
diagnostics or inspected directly from ROS 2 topics.

Useful Checks
-------------

After launching the robot, these commands are useful to check the controller
state:

.. code-block:: bash

   ros2 control list_controllers
   ros2 control list_hardware_interfaces
   ros2 control list_controller_types

``list_controllers`` shows which controllers were loaded and whether each one is
``active`` or ``inactive``. ``list_hardware_interfaces`` helps confirm that the
expected thruster, sensor or actuator interfaces are available.
