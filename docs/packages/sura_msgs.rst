sura_msgs
=========

``sura_msgs`` is the ROS 2 interface package for SURA-specific messages. It
does not launch nodes or contain runtime logic; it only defines the custom data
types shared by the rest of the architecture.

Use this package when a SURA component needs information that is not represented
well by standard ROS 2 messages. Navigation, controllers, sensor broadcasters
and diagnostics can then depend on the same message definitions.

Package Role
------------

``sura_msgs`` keeps the SURA message API in one place:

- ``sura_navigator`` publishes the navigation state used by controllers and
  diagnostics.
- ``sura_controllers`` publishes controller telemetry and consumes SURA-specific
  setpoints.
- ``sura_sensors`` publishes custom sensor reports when standard ROS 2 messages
  are not enough.
- ``sura_diagnostics`` publishes safety and watchdog state.

Because these messages are shared interfaces, changing a ``.msg`` file usually
requires rebuilding every package that depends on ``sura_msgs``.

Available Messages
------------------

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - Message
     - Purpose
   * - ``AuvControllerSetPoint``
     - Compact AUV setpoint with target position and roll, pitch, yaw.
   * - ``Navigator``
     - Estimated robot navigation state with pose, altitude, attitude,
       velocity and acceleration.
   * - ``ControllerDebug``
     - Controller state and timing telemetry for diagnostics.
   * - ``AuvDynamicModel``
     - Dynamic model terms for AUV control, monitoring or identification.
   * - ``NavigationSafety``
     - Navigation safety state for depth, area and update frequency checks.
   * - ``RobotWatchdog``
     - Robot-level watchdog state, reset timing and timeout information.
   * - ``DVL``
     - Full DVL report with velocity, altitude, status and beam data.
   * - ``DVLBeam``
     - Per-beam DVL measurement used inside ``DVL``.
   * - ``LeakSensor``
     - Leak sensor state associated with a robot frame.

Control Messages
----------------

AuvControllerSetPoint
^^^^^^^^^^^^^^^^^^^^^

``AuvControllerSetPoint`` is a small setpoint message for AUV controllers.

.. code-block:: text

   geometry_msgs/Vector3 position
   geometry_msgs/Vector3 rpy

``position`` stores the desired Cartesian target. ``rpy`` stores roll, pitch and
yaw in radians.

ControllerDebug
^^^^^^^^^^^^^^^

``ControllerDebug`` reports the execution state of a controller:

.. code-block:: text

   std_msgs/Header header
   string controller_name
   bool active
   bool chained_mode
   float64 desired_period_us
   float64 last_update_us
   float64 avg_update_us
   float64 max_update_us
   float64 min_update_us
   uint64 deadline_miss_count
   uint64 cycle_count

It is useful for checking whether a controller is active, whether it is running
in chained mode and whether its update loop is meeting the expected timing.

AuvDynamicModel
^^^^^^^^^^^^^^^

``AuvDynamicModel`` stores identified or estimated model terms. The axis order
is:

.. code-block:: text

   surge, sway, heave, roll, pitch, yaw

The message contains inertia, added mass, damping, static wrench, variances and
residual values. It is intended for model reporting and controller debugging,
not for raw sensor data.

Navigation And Safety Messages
------------------------------

Navigator
^^^^^^^^^

``Navigator`` is the main estimated navigation state used inside SURA:

.. code-block:: text

   geometry_msgs/Pose position
   float32 altitude
   geometry_msgs/Vector3 rpy
   geometry_msgs/Twist body_velocity
   geometry_msgs/Accel body_acceleration
   geometry_msgs/Twist ned_velocity
   geometry_msgs/Accel ned_acceleration

It provides pose and attitude together with body-frame and NED-frame velocity
and acceleration, so different controllers can consume the representation they
need.

NavigationSafety
^^^^^^^^^^^^^^^^

``NavigationSafety`` summarizes navigation safety checks. It uses the state
values ``OK``, ``WARN``, ``ERROR`` and ``STALE`` for:

- depth limits;
- navigation area limits;
- navigation update frequency.

RobotWatchdog
^^^^^^^^^^^^^

``RobotWatchdog`` reports the global watchdog state of the robot. It includes
the architecture start time, uptime, last reset time, time remaining to warning
or error, reset count and timeout configuration.

Sensor Messages
---------------

DVL And DVLBeam
^^^^^^^^^^^^^^^

``DVL`` represents a complete DVL report when the data cannot be expressed with
a single standard ROS 2 message:

.. code-block:: text

   std_msgs/Header header
   float64 time
   geometry_msgs/Vector3 velocity
   float64 fom
   float64 altitude
   DVLBeam[] beams
   bool velocity_valid
   int64 status
   string form

``DVLBeam`` stores the measurement for each beam:

.. code-block:: text

   int64 id
   float64 velocity
   float64 distance
   float64 rssi
   float64 nsd
   bool valid

This is currently used for DVL reports that need to preserve velocity, altitude,
figure of merit, status and per-beam information.

LeakSensor
^^^^^^^^^^

``LeakSensor`` reports whether a leak has been detected and associates the
reading with a frame:

.. code-block:: text

   std_msgs/Header header
   string frame_id
   bool leak_detected

Adding a New Message
--------------------

Prefer standard ROS 2 messages whenever they are enough. Add a new message to
``sura_msgs`` only when the interface is specific to SURA or needs to be shared
by several SURA packages.

1. Create the message file in ``src/sura_msgs/msg/``.

   .. code-block:: text

      src/sura_msgs/msg/NewMessage.msg

2. Add the file to ``rosidl_generate_interfaces`` in
   ``src/sura_msgs/CMakeLists.txt``.

   .. code-block:: cmake

      rosidl_generate_interfaces(${PROJECT_NAME}
        "msg/NewMessage.msg"
        DEPENDENCIES builtin_interfaces geometry_msgs std_msgs
      )

3. Add any new message dependencies to ``src/sura_msgs/package.xml`` and to the
   ``DEPENDENCIES`` list in ``CMakeLists.txt``.

4. Build the interface package.

   .. code-block:: bash

      colcon build --packages-select sura_msgs
      source install/setup.bash

5. Rebuild the packages that publish or subscribe to the new message.
