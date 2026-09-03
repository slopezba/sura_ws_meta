sura_bringup
============

``sura_bringup`` is the main entry point for starting a SURA robot. Its role is
to read the robot-specific bringup configuration and launch the components that
make up the system under the correct ROS 2 namespace.

This package does not define the robot model, sensors or controllers by itself.
Those details live in the robot description package and in the configuration
files selected by that package.

sura_bringup.launch.py
----------------------

``sura_bringup.launch.py`` starts the main onboard runtime for a robot. It reads
the robot bringup configuration, prepares the namespace and launches the core
SURA components required by the vehicle.

.. code-block:: bash

   ros2 launch sura_bringup sura_bringup.launch.py \
     robot_namespace:=<robot_namespace>

.. raw:: html

   <svg class="bringup-flow" viewBox="0 0 920 765" role="img" aria-label="sura_bringup launch structure">
     <defs>
       <marker id="bringup-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
         <path d="M 0 0 L 10 5 L 0 10 z" fill="#5f7280"></path>
       </marker>
     </defs>

     <rect class="box variable" x="42" y="56" width="175" height="42" rx="6"></rect>
     <text class="variable-label" x="130" y="82" text-anchor="middle">robot_namespace</text>

     <rect class="box primary" x="35" y="152" width="245" height="62" rx="7"></rect>
     <text class="primary-label" x="157" y="189" text-anchor="middle">sura_bringup.launch.py</text>
     <path class="line" d="M130 98 V152" marker-end="url(#bringup-arrow)"></path>

     <a href="robot_description.html">
       <rect class="box source" x="345" y="34" width="245" height="56" rx="6"></rect>
       <text x="468" y="58" text-anchor="middle">&lt;robot_namespace&gt;_description</text>
       <text x="468" y="76" text-anchor="middle">package</text>
     </a>
     <path class="line" d="M217 77 H300 V62 H345" marker-end="url(#bringup-arrow)"></path>

     <rect class="box config" x="650" y="40" width="220" height="42" rx="6"></rect>
     <text x="760" y="66" text-anchor="middle">bringup_description.yaml</text>
     <path class="line" d="M590 62 H650" marker-end="url(#bringup-arrow)"></path>

     <rect class="box variable" x="635" y="116" width="250" height="82" rx="6"></rect>
     <text class="variable-label" x="760" y="138" text-anchor="middle">runtime values</text>
     <text class="small-label" x="760" y="158" text-anchor="middle">xacro, ros2_control, imu,</text>
     <text class="small-label" x="760" y="176" text-anchor="middle">cameras, localization_file,</text>
     <text class="small-label" x="760" y="194" text-anchor="middle">diagnostics_file</text>
     <path class="line" d="M760 82 V116" marker-end="url(#bringup-arrow)"></path>
     <path class="line" d="M635 151 H310 V183 H280" marker-end="url(#bringup-arrow)"></path>

     <rect class="namespace" x="160" y="250" width="680" height="465" rx="18"></rect>
     <text class="small-label" x="500" y="278" text-anchor="middle">PushRosNamespace(robot_namespace)</text>

     <path class="line" d="M157 214 V286 H245"></path>
     <path class="line" d="M245 286 V691"></path>
     <path class="line" d="M245 327 H285" marker-end="url(#bringup-arrow)"></path>
     <path class="line" d="M245 379 H285" marker-end="url(#bringup-arrow)"></path>
     <path class="line" d="M245 431 H285" marker-end="url(#bringup-arrow)"></path>
     <path class="line" d="M245 483 H285" marker-end="url(#bringup-arrow)"></path>
     <path class="line" d="M245 535 H285" marker-end="url(#bringup-arrow)"></path>
     <path class="line" d="M245 587 H285" marker-end="url(#bringup-arrow)"></path>
     <path class="line" d="M245 639 H285" marker-end="url(#bringup-arrow)"></path>
     <path class="line" d="M245 691 H285" marker-end="url(#bringup-arrow)"></path>

     <a href="robot_description.html">
       <rect class="box" x="285" y="306" width="350" height="42" rx="6"></rect>
       <text x="460" y="332" text-anchor="middle">robot_description.launch.py</text>
     </a>

     <a href="sura_controllers.html">
       <rect class="box" x="285" y="358" width="350" height="42" rx="6"></rect>
       <text x="460" y="384" text-anchor="middle">sura_controllers.launch.py</text>
     </a>

     <a href="sura_imu.html">
       <rect class="box" x="285" y="410" width="350" height="42" rx="6"></rect>
       <text x="460" y="436" text-anchor="middle">sura_imu/imu.launch.py</text>
     </a>

     <a href="sura_cameras.html">
       <rect class="box" x="285" y="462" width="350" height="42" rx="6"></rect>
       <text x="460" y="488" text-anchor="middle">sura_cameras/cameras.launch.py</text>
     </a>

     <a href="sura_localization.html">
       <rect class="box" x="285" y="514" width="350" height="42" rx="6"></rect>
       <text x="460" y="540" text-anchor="middle">sura_localization/&lt;localization_file&gt;</text>
     </a>

     <a href="sura_hardware_interface.html">
       <rect class="box" x="285" y="566" width="350" height="42" rx="6"></rect>
       <text x="460" y="592" text-anchor="middle">sura_hardware_interface/thruster_force_publisher</text>
     </a>

     <a href="sura_navigator.html">
       <rect class="box" x="285" y="618" width="350" height="42" rx="6"></rect>
       <text x="460" y="644" text-anchor="middle">sura_navigator/navigator.launch.py</text>
     </a>

     <a href="sura_diagnostics.html">
       <rect class="box" x="285" y="670" width="350" height="42" rx="6"></rect>
       <text x="460" y="696" text-anchor="middle">sura_diagnostics/&lt;diagnostics_file&gt;</text>
     </a>
   </svg>

The ``robot_namespace`` identifies the robot and is used to find the matching
description package:

.. code-block:: text

   <robot_namespace>_description/config/bringup_description.yaml

For example, if the namespace is ``bluerov``, SURA expects a package named
``bluerov_description`` with a ``config/bringup_description.yaml`` file.
This file is part of the :ref:`robot-description-package`.

The same namespace must match the robot name declared in the bringup
configuration and in the generated robot description.

The robot description launch receives the selected xacro file together with the
arguments needed to render the robot model for the chosen namespace and
environment.

``sura_bringup.launch.py`` prepares the ROS 2 Control configuration but does not
start ``ros2_control_node`` directly. The controller manager and controller
spawners are started by ``sura_controllers.launch.py``.

sura_controllers.launch.py
--------------------------

``sura_controllers.launch.py`` connects the robot description with
`ros2_control <https://control.ros.org/humble/index.html>`_. For a user,
this is the launch file that makes the robot controllers available: it starts
the controller manager and spawns the broadcasters and controllers required by
the selected robot.

This launch is normally started from ``sura_bringup.launch.py`` and does not
need to be executed manually. The main bringup passes the robot namespace, the
robot xacro file, the selected ``ros2_control`` parameter file, the robot family
and the arm configuration.

The robot configuration is resolved from the description package associated with
the namespace:

* ``<robot_namespace>_description/config/bringup_description.yaml`` defines the
  robot profile used by the main bringup, including where to find the xacro file ``<xacro_file>``
  and the ``ros2_control`` parameter file ``<ros2_control_params>``.
* ``<robot_namespace>_description/<description.xacro>`` is the xacro file used
  to render the robot model. The exact relative path is defined by
  ``description.xacro``.
* ``<robot_namespace>_description/<ros2_control_params>`` is the YAML file with
  the controller manager configuration. 

The launch selects the controller groups from the robot family declared in the
description and also discovers the broadcasters and joint controllers declared
in the xacro. Broadcasters start active; regular controllers are loaded inactive
until an operation mode activates them.

At runtime, it launches:

* ``ros2_control_node``, the controller manager loaded with the robot
  description and the selected control parameters.
* ``broadcaster spawners``, used for state and sensor broadcasters selected from
  the sensors and actuators declared in the robot description.
* ``controller spawners``, used for regular controllers selected from the robot
  family. These controllers are loaded inactive until an operation mode
  activates them.

It also applies the joint-state remaps needed to expose the controller joint
states under the robot namespace.

.. raw:: html

   <svg class="bringup-flow" viewBox="0 0 920 340" role="img" aria-label="sura_controllers launch structure">
     <defs>
       <marker id="controllers-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
         <path d="M 0 0 L 10 5 L 0 10 z" fill="#5f7280"></path>
       </marker>
     </defs>

     <rect class="box variable" x="55" y="36" width="230" height="38" rx="6"></rect>
     <text class="variable-label" x="170" y="60" text-anchor="middle">robot_namespace</text>

     <rect class="box variable" x="55" y="86" width="230" height="38" rx="6"></rect>
     <text class="variable-label" x="170" y="110" text-anchor="middle">robot_family</text>

     <rect class="box variable" x="55" y="136" width="230" height="38" rx="6"></rect>
     <text class="variable-label" x="170" y="160" text-anchor="middle">arms</text>

     <a href="robot_description.html">
       <rect class="box source" x="55" y="186" width="230" height="48" rx="6"></rect>
       <text x="170" y="206" text-anchor="middle">robot description</text>
       <text class="small-label" x="170" y="224" text-anchor="middle">package, xacro file, xacro args</text>
     </a>

     <a href="sura_controllers.html">
       <rect class="box source" x="55" y="250" width="230" height="48" rx="6"></rect>
       <text x="170" y="270" text-anchor="middle">ros2_control params</text>
       <text class="small-label" x="170" y="288" text-anchor="middle">package and file</text>
     </a>

     <rect class="box primary" x="355" y="127" width="230" height="70" rx="8"></rect>
     <text class="primary-label" x="470" y="167" text-anchor="middle">sura_controllers</text>

     <a href="sura_controllers.html">
       <rect class="box" x="655" y="54" width="250" height="42" rx="6"></rect>
       <text x="780" y="80" text-anchor="middle">ros2_control_node</text>
     </a>

     <a href="sura_controllers.html">
       <rect class="box" x="655" y="140" width="250" height="42" rx="6"></rect>
       <text x="780" y="166" text-anchor="middle">broadcaster spawners</text>
     </a>

     <a href="sura_controllers.html">
       <rect class="box" x="655" y="226" width="250" height="42" rx="6"></rect>
       <text x="780" y="252" text-anchor="middle">controller spawners</text>
     </a>

     <path class="line" d="M285 55 H320 L355 140" marker-end="url(#controllers-arrow)"></path>
     <path class="line" d="M285 105 H325 L355 151" marker-end="url(#controllers-arrow)"></path>
     <path class="line" d="M285 155 H355" marker-end="url(#controllers-arrow)"></path>
     <path class="line" d="M285 210 H325 L355 173" marker-end="url(#controllers-arrow)"></path>
     <path class="line" d="M285 274 H320 L355 184" marker-end="url(#controllers-arrow)"></path>
     <path class="line" d="M585 162 H620 V75 H655" marker-end="url(#controllers-arrow)"></path>
     <path class="line" d="M585 162 H655" marker-end="url(#controllers-arrow)"></path>
     <path class="line" d="M585 162 H620 V247 H655" marker-end="url(#controllers-arrow)"></path>
   </svg>

sura_perception.launch.py
-------------------------

``sura_perception.launch.py`` starts the robot camera pipelines from a different
computer, which is useful when perception processing should run outside the
onboard computer while still using the same robot namespace and camera
configuration.

Unlike the full robot bringup, this launch does not require a Navigator board.
It only needs the robot description package to be available in the workspace.
The cameras to launch are read from:

.. code-block:: text

   <robot_namespace>_description/config/bringup_description.yaml

Inside that file, the ``cameras`` section defines which cameras are enabled and
which optional features, such as ArUco detection, should be started for each
one. The launch then forwards that configuration to :doc:`sura_cameras <sura_cameras>`.

.. code-block:: bash

   ros2 launch sura_bringup sura_perception.launch.py robot_namespace:=<robot_namespace>


sura_gcs.launch.py
------------------

``sura_gcs.launch.py`` starts an RViz-based ground-control view and can also
launch teleoperation:

.. code-block:: bash

   ros2 launch sura_bringup sura_gcs.launch.py \
     robot_namespace:=<robot_namespace> \
     teleop_enabled:=true


.. note::

   This launch should be run on the user's computer, not on the robot onboard
   computer.
