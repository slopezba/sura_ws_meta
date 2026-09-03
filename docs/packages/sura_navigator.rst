sura_navigator
==============

``sura_navigator`` converts the robot odometry into the SURA navigation message
used by controllers, diagnostics and higher-level behaviors.

This package does not estimate the robot localization by itself. It expects an
odometry source, produced by :doc:`sura_localization <sura_localization>`
in a real robot or by the simulator in simulation, and republishes that state as
:doc:`sura_msgs/msg/Navigator <sura_msgs>`.

Role in SURA
------------

The mission of ``sura_navigator`` is to provide one common navigation interface
for the rest of the stack. Instead of every controller reading localization,
altitude and velocity information in a different format, they subscribe to:

.. code-block:: text

   /<robot_namespace>/navigator/navigation

This topic contains a ``sura_msgs/msg/Navigator`` message with pose, altitude,
roll-pitch-yaw, velocity and acceleration fields.

``sura_navigator`` is normally launched from :doc:`sura_bringup <sura_bringup>`.
Manual launch is mainly useful for testing or debugging the navigation adapter
alone.

.. raw:: html

   <svg class="bringup-flow" viewBox="0 0 980 210" role="img" aria-label="sura navigator data flow">
     <defs>
       <marker id="navigator-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
         <path d="M 0 0 L 10 5 L 0 10 z" fill="#5f7280"></path>
       </marker>
     </defs>

     <rect class="box" x="35" y="45" width="220" height="58" rx="6"></rect>
     <text x="145" y="70" text-anchor="middle">odometry</text>
     <text class="small-label" x="145" y="89" text-anchor="middle">localization or simulation</text>

     <rect class="box" x="35" y="127" width="220" height="50" rx="6"></rect>
     <text x="145" y="157" text-anchor="middle">optional altitude</text>

     <rect class="box primary" x="345" y="72" width="250" height="78" rx="8"></rect>
     <text class="primary-label" x="470" y="105" text-anchor="middle">sura_navigator</text>
     <text class="small-label" x="470" y="126" text-anchor="middle">navigation-state adapter</text>

     <rect class="box source" x="685" y="72" width="250" height="78" rx="8"></rect>
     <text x="810" y="102" text-anchor="middle">Navigator message</text>
     <text class="small-label" x="810" y="124" text-anchor="middle">pose, rpy, velocity, acceleration</text>

     <path class="line" d="M255 74 H345" marker-end="url(#navigator-arrow)"></path>
     <path class="line" d="M255 152 H300 V122 H345" marker-end="url(#navigator-arrow)"></path>
     <path class="line" d="M595 111 H685" marker-end="url(#navigator-arrow)"></path>
   </svg>

Inputs and Output
-----------------

The main input is a ``nav_msgs/msg/Odometry`` topic:

``real`` environment
   Uses ``/<robot_namespace>/odometry/filtered``. This is expected to come from
   the real localization pipeline.

``sim`` environment
   Uses ``/<robot_namespace>/stonefish/odometry``. This is the ground-truth
   odometry provided by the simulation environment.

The optional altitude input is:

.. code-block:: text

   /<robot_namespace>/sensors/dvl/altitude

This topic is a ``sensor_msgs/msg/Range`` message. Its latest value is copied
into the ``altitude`` field of the Navigator message. It is not used to compute
pose, velocity or acceleration.

The output is:

.. code-block:: text

   /<robot_namespace>/navigator/navigation

What It Publishes
-----------------

``sura_navigator`` fills the ``Navigator`` message from the input odometry:

``position``
   Robot pose from ``odom.pose.pose``.

``altitude``
   Latest range value from the optional altitude topic. If no altitude has been
   received yet, the value starts at ``0.0``.

``rpy``
   Roll, pitch and yaw extracted from the odometry orientation, in radians.

``body_velocity``
   Linear velocity expressed in the robot body frame, plus angular velocity.

``ned_velocity``
   Linear velocity expressed in the NED world frame, plus angular velocity.

``body_acceleration``
   Acceleration estimated from consecutive body-frame velocities.

``ned_acceleration``
   Acceleration estimated from consecutive NED-frame velocities.

Velocity Filtering
------------------

The launch exposes ``velocity_filter_alpha`` to smooth the velocity values used
in the Navigator message:

.. code-block:: text

   filtered = alpha * raw + (1 - alpha) * previous

The vector order is:

.. code-block:: text

   [x, y, z, roll, pitch, yaw]

``1.0`` disables filtering for that axis. Lower values make the signal smoother
but add more delay. The default launch value is:

.. code-block:: text

   [1.0, 1.0, 0.05, 1.0, 1.0, 1.0]

Launch
------

Normal usage is through ``sura_bringup``. For manual testing:

.. code-block:: bash

   ros2 launch sura_navigator navigator.launch.py \
     robot_namespace:=<robot_namespace> \
     environment:=real

For simulation:

.. code-block:: bash

   ros2 launch sura_navigator navigator.launch.py \
     robot_namespace:=<robot_namespace> \
     environment:=sim

Main launch arguments:

``robot_namespace``
   Robot namespace used to build the input and output topic names.

``environment``
   Selects the odometry source. Use ``real`` for the real localization output
   and ``sim`` for Stonefish simulation odometry.

``velocity_filter_alpha``
   Six-value filter vector for linear and angular velocity.

Node Parameters
---------------

The launch file fills the node parameters automatically:

``odom_topic``
   Selected from ``environment``.

``altitude_topic``
   Defaults to ``/<robot_namespace>/sensors/dvl/altitude``.

``navigator_topic``
   Defaults to ``/<robot_namespace>/navigator/navigation``.

``parent_frame`` and ``child_frame``
   Frames used if TF publication is enabled. The default parent is
   ``world_ned`` and the child is ``<robot_namespace>/base_link``.

``publish_tf``
   Enabled in simulation and disabled in real mode by the launch file.

Useful Checks
-------------

Check the Navigator output:

.. code-block:: bash

   ros2 topic echo /<robot_namespace>/navigator/navigation --once

Check the real odometry input:

.. code-block:: bash

   ros2 topic echo /<robot_namespace>/odometry/filtered --once

Check the simulation odometry input:

.. code-block:: bash

   ros2 topic echo /<robot_namespace>/stonefish/odometry --once

Check the optional altitude input:

.. code-block:: bash

   ros2 topic echo /<robot_namespace>/sensors/dvl/altitude --once
