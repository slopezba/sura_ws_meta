Changelog
=========

This page tracks relevant changes in SURA releases and workspace compositions.

First Version
-------------

Initial public documentation and workspace composition for SURA.

This version includes:

* A modular ROS 2 Humble architecture for surface and underwater robots,
  including USVs, ROVs, AUVs, UVMs, UVDMs and custom marine platforms.
* Vehicle bringup and launch orchestration through ``sura_bringup``, allowing a
  complete robot runtime to be composed from reusable launch files and
  configuration profiles.
* ``ros2_control``-based vehicle control, including velocity, position, heading,
  attitude and depth-control pipelines, body-force generation, thruster
  allocation and actuator command interfaces.
* Localization and state-estimation support for fusing vehicle state from IMUs,
  GPS/GNSS, pressure sensors, DVLs, odometry and vision-based localization
  sources such as ArUco markers.
* Sensor integration packages for marine robotics sensors, with broadcasters
  and hardware interfaces for IMU, GPS, pressure, DVL, battery, leak,
  magnetometer and altimeter data.
* Camera and perception support for USB cameras, simulated cameras, ArUco
  detection and image-processing pipelines.
* Hardware abstraction for thrusters, sensors and actuators, including
  Navigator-based robot hardware and lookup-table based thruster models.
* Navigation state adaptation through ``sura_navigator``, connecting estimated
  robot state with controller inputs and safety-related navigation messages.
* Teleoperation support for manually driving and testing supported robots while
  using the same control and hardware layers as the autonomous stack.
* Diagnostics and observability tools for monitoring sensors, controllers,
  hardware components, navigation limits, batteries, leaks and robot watchdog
  status.
* Robot description documentation for URDF/xacro models, ``ros2_control``
  parameters, sensor frames, actuator frames and vehicle-specific configuration.
* Robot setup guides for BlueROV Heavy, BlueBoat and custom robots.
* Simulation-oriented documentation for validating robot models, sensor
  configuration, localization, control and launch flows before running on
  physical hardware.
* Development guidance for extending SURA with new robots, sensors, actuators,
  payloads, controllers and package-level functionality.
* Initial ``workspace.repos`` manifest for recreating the workspace composition.
