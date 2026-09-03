sura_hardware_interface
=======================

``sura_hardware_interface`` contains SURA's implementations of the
`ros2_control hardware_interface <https://docs.ros.org/en/ros2_packages/humble/api/hardware_interface/doc/hardware_interface_types_userdoc.html>`_.
These hardware plugins connect the control stack with the robot hardware or
with a simulator. It is the layer that translates generic controller commands
and state interfaces into the backend required by each runtime environment.

The hardware interfaces are declared in the robot xacro and loaded by
``ros2_control_node`` through the controller manager. The same robot
description can therefore be used in two modes:

* ``sim``, where SURA publishes or reads simulated signals.
* ``real``, where SURA communicates with the physical hardware, such as the
  Blue Robotics Navigator.

The package is organized around three hardware groups:

* thrusters, used to convert force commands into thruster outputs.
* sensors, used to expose robot measurements through ROS 2 Control state
  interfaces and broadcasters.
* actuators, used for auxiliary devices such as lights.

.. toctree::
   :maxdepth: 1

   sura_hardware_interface_thrusters
   sura_hardware_interface_sensors
   sura_hardware_interface_actuators
