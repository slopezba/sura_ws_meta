sura_teleop
===========

``sura_teleop`` provides joystick teleoperation for SURA vehicles. It reads the
gamepad, switches ROS 2 Control controllers when needed and publishes commands
to the active controller.

It is normally used from the operator side through the ground-control launch:

.. code-block:: bash

   ros2 launch sura_bringup sura_gcs.launch.py \
     robot_namespace:=<robot_namespace> \
     teleop_enabled:=true

When ``teleop_enabled`` is true, ``sura_gcs.launch.py`` includes
``sura_teleop/teleop.launch.py``. That launch starts ``joy_node`` and the
``sura_teleop`` node.

.. raw:: html

   <svg class="bringup-flow" viewBox="0 0 1040 270" role="img" aria-label="sura teleop data flow">
     <defs>
       <marker id="teleop-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
         <path d="M 0 0 L 10 5 L 0 10 z" fill="#5f7280"></path>
       </marker>
     </defs>

     <text class="small-label" x="135" y="35" text-anchor="middle">INPUT</text>
     <rect class="box" x="35" y="62" width="200" height="58" rx="6"></rect>
     <text x="135" y="86" text-anchor="middle">gamepad</text>
     <text class="small-label" x="135" y="105" text-anchor="middle">buttons + axes</text>

     <rect class="box source" x="300" y="62" width="180" height="58" rx="8"></rect>
     <text x="390" y="86" text-anchor="middle">joy_node</text>
     <text class="small-label" x="390" y="105" text-anchor="middle">publishes /joy</text>

     <text class="small-label" x="590" y="35" text-anchor="middle">sura_teleop package</text>
     <rect class="box primary" x="525" y="58" width="190" height="128" rx="8"></rect>
     <text class="primary-label" x="620" y="93" text-anchor="middle">sura_teleop</text>
     <text class="small-label" x="620" y="116" text-anchor="middle">reads joystick</text>
     <text class="small-label" x="620" y="136" text-anchor="middle">selects mode</text>
     <text class="small-label" x="620" y="156" text-anchor="middle">publishes commands</text>

     <text class="small-label" x="885" y="35" text-anchor="middle">OUTPUT</text>
     <rect class="box" x="790" y="42" width="210" height="58" rx="6"></rect>
     <text x="895" y="66" text-anchor="middle">controller services</text>
     <text class="small-label" x="895" y="85" text-anchor="middle">list + switch controllers</text>

     <rect class="box" x="790" y="126" width="210" height="58" rx="6"></rect>
     <text x="895" y="150" text-anchor="middle">robot commands</text>
     <text class="small-label" x="895" y="169" text-anchor="middle">Twist or Wrench</text>

     <rect class="box" x="790" y="210" width="210" height="44" rx="6"></rect>
     <text x="895" y="237" text-anchor="middle">Alpha arm commands</text>

     <path class="line" d="M235 91 H300" marker-end="url(#teleop-arrow)"></path>
     <path class="line" d="M480 91 H525" marker-end="url(#teleop-arrow)"></path>
     <path class="line" d="M715 96 H752 V71 H790" marker-end="url(#teleop-arrow)"></path>
     <path class="line" d="M715 126 H790" marker-end="url(#teleop-arrow)"></path>
     <path class="line" d="M715 156 H752 V232 H790" marker-end="url(#teleop-arrow)"></path>
   </svg>

AUV Controls
------------

These are the controls for underwater vehicle operation. They are intended to be
read together with the gamepad drawing.

.. list-table::
   :header-rows: 1

   * - What to press
     - Action
   * - Press the right stick button, ``R3``
     - Select AUV mode.
   * - Hold ``RB`` and press ``X``
     - Toggle ``body_velocity``.
   * - Hold ``RB`` and press ``B``
     - Toggle ``position_hold``.
   * - Hold ``RB`` and press ``Y``
     - Toggle ``stabilize``.
   * - Hold ``RB`` and press ``A``
     - Toggle ``depth_hold``.
   * - Hold ``RB`` and press ``LB``
     - Toggle direct ``body_force``.
   * - Move the right stick up/down
     - Forward/back motion.
   * - Move the right stick left/right
     - Lateral motion.
   * - Move the left stick up/down
     - Vertical motion.
   * - Move the left stick left/right
     - Yaw motion.
   * - Press D-pad up
     - Enable roll/pitch control in ``stabilize`` or ``depth_hold``.
   * - Press D-pad down
     - Disable roll/pitch control in ``stabilize`` or ``depth_hold``.
   * - Hold ``LB`` and move the right stick left/right
     - Roll command.
   * - Hold ``LB`` and move the right stick up/down
     - Pitch command.

Controller toggles use the controller manager services. The controller names in
the teleop YAML must match the controllers loaded by the robot.

Arm Controls
------------

Arm mode is used only on robots with Alpha manipulators.

.. list-table::
   :header-rows: 1

   * - What to press
     - Action
   * - Press the left stick button, ``L3``
     - Select arm mode.
   * - Hold ``RB`` and press ``X``
     - Select Cartesian arm mode.
   * - Hold ``RB`` and press ``A``
     - Select trajectory arm mode.
   * - Hold ``RB`` and press ``B``
     - Select joint arm mode.
   * - Hold ``RB`` and press D-pad right
     - Activate the selected mode for the left Alpha arm.
   * - Hold ``RB`` and press D-pad left
     - Activate the selected mode for the right Alpha arm.

In joint mode, teleop publishes joint and gripper velocity commands. In
Cartesian mode, it publishes ``geometry_msgs/msg/TwistStamped`` commands.

USV Controls
------------

Surface vehicles use fewer motion axes than an AUV, but they can still use
several control modes.

There is currently no dedicated USV or BlueBoat teleop YAML in
``sura_teleop``. The launch only selects ``teleop_params_bluerov.yaml`` when the
namespace contains ``bluerov``; otherwise it selects one of the CIRTESUB YAML
profiles. For a USV, create a custom teleop YAML or wrapper launch that maps the
joystick actions to the controllers loaded by the surface robot.

.. list-table::
   :header-rows: 1

   * - What to press
     - Expected USV action
   * - Press the right stick button, ``R3``
     - Select vehicle teleop mode.
   * - Hold ``RB`` and press ``X``
     - Toggle ``body_velocity`` for surface velocity control, if the custom
       USV YAML maps it.
   * - Hold ``RB`` and press ``B``
     - Toggle position control, if the USV profile maps this action to
       ``body_position``.
   * - Hold ``RB`` and press ``LB``
     - Toggle direct ``body_force``, if the custom USV YAML maps it.
   * - Move the right stick up/down
     - Surge command: forward/back motion.
   * - Move the left stick left/right
     - Yaw command: turn left/right.
   * - Move the right stick left/right
     - Sway command, only if the surface controller uses a lateral axis.
   * - Move the left stick up/down
     - Extra linear axis, only if the USV profile assigns it.

In the USV controllers, ``body_velocity`` normally uses surge and yaw-rate
references, while ``body_position`` receives a
``geometry_msgs/msg/PoseStamped`` target and converts it into surge and yaw-rate
commands. Direct ``body_force`` bypasses the velocity loop and sends force and
torque commands directly to the low-level controller.

Configuration YAML
------------------

``teleop.launch.py`` selects a YAML profile automatically:

``teleop_params_bluerov.yaml``
   Used when ``robot_namespace`` contains ``bluerov``. This selection is done
   in ``teleop.launch.py`` by checking the namespace string; it is not defined
   inside the YAML itself. For example, ``robot_namespace:=bluerov`` or
   ``robot_namespace:=my_bluerov`` selects this file.

``teleop_params_cirtesub_sim.yaml``
   Used for non-BlueROV robots when ``teleop:=sim``.

``teleop_params_cirtesub_real.yaml``
   Used for non-BlueROV robots when ``teleop:=real``.

Before the node starts, topics written as ``/sura/...`` are rewritten to
``/<robot_namespace>/...``.

BlueBoat is not selected automatically by the current launch logic. If the
robot is a BlueBoat or another USV, provide a custom teleop YAML from a wrapper
launch instead of relying on the BlueROV namespace rule.

The most useful parameters to edit are:

``rate``
   Publication rate for vehicle commands.

``joy_topic``
   Joystick input topic. The default is ``/joy``.

``controller_switch_service`` and ``controller_list_service``
   Controller manager services used to inspect and switch active controllers.

``*_controller.name``
   ROS 2 Control controller name. These must match the controller names loaded
   by the robot.

``*_controller.command_topic``, ``setpoint_topic`` and ``feedforward_topic``
   Topics where teleop publishes commands for each controller mode.

``buttons``
   Gamepad button indices.

``axes``
   Gamepad axis indices.

``scales``
   Sign and magnitude applied to each axis. Change these values to invert an
   axis or make a command softer/stronger.

``deadzone``
   Joystick values below this threshold are treated as zero.

``feedforward_gain_*``
   Gains used when teleop publishes wrench feedforward commands.

Useful Checks
-------------

Check that the joystick is publishing:

.. code-block:: bash

   ros2 topic echo /joy --once

Check active controllers:

.. code-block:: bash

   ros2 control list_controllers \
     -c /<robot_namespace>/controller/controller_manager

Check a command topic, for example body velocity:

.. code-block:: bash

   ros2 topic echo /<robot_namespace>/controller/body_velocity/setpoint
