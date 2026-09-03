URDF/Xacro Model
================

The URDF xacro is the main robot model. It defines the physical and logical
structure of the vehicle so that SURA can publish the robot description, build
the TF tree and configure ``ros2_control``.

At a high level, the xacro should make this structure visible:

.. code-block:: xml

   <?xml version="1.0"?>
   <robot xmlns:xacro="http://www.ros.org/wiki/xacro"
          name="$(arg robot_name)"
          family="<surface|underwater>">

     <xacro:arg name="robot_name" default="<robot_namespace>" />
     <xacro:arg name="environment" default="real"/>


     <!-- TF tree -->
     <!-- links, joints and frames -->
     <!-- base_link -->
     <!-- sensor frames -->
     <!-- thruster frames -->
     <!-- actuator frames -->
     <!-- visualization frames -->

     <!-- Thruster hardware plugin -->
     <ros2_control name="$(arg robot_name)_thrusters" type="system">
       <!-- Thruster joints, command interfaces and state interfaces -->
     </ros2_control>

     <!-- Sensor hardware plugin -->
     <ros2_control name="$(arg robot_name)_sensors" type="system">
       <!-- Sensors, state interfaces and broadcaster names -->
     </ros2_control>

     <!-- Actuator hardware plugin -->
     <ros2_control name="$(arg robot_name)_actuators" type="system">
       <!-- Actuator joints, command interfaces, state interfaces and controller names -->
     </ros2_control>
   </robot>

Robot Header
------------

The first part of the xacro defines the robot identity. ``robot_name`` is passed
by the launch system and is used as the namespace prefix for frames, joints and
controllers. The ``family`` attribute declares the type of robot model. SURA uses
this value to select the controller groups that apply to the vehicle, for
example ``surface`` for USV-style robots or ``underwater`` for ROV/AUV-style
robots.

TF Tree
-------

The next part of the xacro normally describes the robot frames: links, joints
and transforms such as ``base_link``, sensor frames, actuator frames and any
extra frames required by localization or visualization.

``base_link`` is the main robot frame. It is recommended that this link includes
the mesh of the complete robot, so the vehicle can be visualized directly from
the main frame:

.. code-block:: xml

   <link name="$(arg robot_name)/base_link" tf_type="base">
     <visual>
       <geometry>
         <mesh
           filename="package://<robot_namespace>_description/meshes/<robot_mesh>.dae"
           scale="<sx> <sy> <sz>"/>
       </geometry>
       <origin xyz="<x> <y> <z>" rpy="<roll> <pitch> <yaw>"/>
     </visual>
   </link>

A fixed frame attached to ``base_link`` usually follows this pattern:

.. code-block:: xml

   <link name="$(arg robot_name)/<frame_name>" tf_type="<sensor|thruster|actuator>"/>
   <joint name="$(arg robot_name)/<frame_name>_joint" type="fixed">
     <parent link="$(arg robot_name)/base_link"/>
     <child link="$(arg robot_name)/<frame_name>"/>
     <origin xyz="<x> <y> <z>" rpy="<roll> <pitch> <yaw>"/>
   </joint>

Thruster, Sensor and Actuator Hardware Plugins
----------------------------------------------

After the TF structure, the xacro includes the ``ros2_control`` hardware
description. This is where the robot exposes the interfaces that SURA will use
at runtime. The description is usually split into:

* ``<robot_name>_thrusters``, for propulsion units, their hardware plugin,
  channels and command/state interfaces.
* ``<robot_name>_sensors``, for sensors, their hardware interface, frame ids,
  read rates, state interfaces and broadcaster names.
* ``<robot_name>_actuators``, for controllable mechanisms such as lights, arms,
  fins or other joints, including the controller names used to command them.

Thrusters
^^^^^^^^^

Thrusters are defined as joints inside the ``<robot_name>_thrusters``
``ros2_control`` block. Each thruster must expose the command and state
interfaces used by the controller, and the hardware plugin needs the information
required to map controller commands to the real or simulated vehicle.

.. code-block:: xml

   <ros2_control name="$(arg robot_name)_thrusters" type="system">
     <hardware>
       <plugin>sura_hardware_interface/ThrustersSystem</plugin>
       <param name="environment">$(arg environment)</param>
     </hardware>

     <joint name="$(arg robot_name)/<thruster_frame>">
       <command_interface name="effort"/>
       <state_interface name="effort"/>
       <param name="lookup_csv">config/<thruster_lookup>.csv</param>
       <param name="stonefish_topic">/$(arg robot_name)/controller/thruster_setpoints_sim</param>
       <param name="inverted">false</param>
       <param name="pwm_offset">0.0</param>
       <param name="channel">0</param>
     </joint>
   </ros2_control>

Add one ``<joint>`` entry for each thruster installed on the robot.

The main thruster parameters are:

* ``lookup_csv``: relative path to the lookup table used to convert the
  commanded force or effort into the thruster output model. This file is usually
  linked to the specific thruster model being used.
* ``stonefish_topic``: topic used to send thruster setpoints to the Stonefish
  simulation backend.
* ``inverted``: reverses the sign of the command when the physical thruster
  orientation or wiring requires it.
* ``pwm_offset``: calibration offset applied to the PWM command sent to the
  thruster. In normal setups this value is usually ``0.0``.
* ``channel``: hardware output channel connected to that thruster on the Blue
  Robotics Navigator flight controller.

For the currently available thruster models, see
:doc:`sura_hardware_interface Thrusters <sura_hardware_interface_thrusters>`.

Sensors
^^^^^^^

Sensors are defined inside the ``<robot_name>_sensors`` ``ros2_control`` block.
Each sensor declares the interface used to read it, the broadcaster that should
publish its data and the state interfaces exposed to ROS 2 Control.

.. code-block:: xml

   <ros2_control name="$(arg robot_name)_sensors" type="system">
     <hardware>
       <plugin>sura_hardware_interface/SensorsSystem</plugin>
       <param name="environment">$(arg environment)</param>
     </hardware>

     <sensor name="<sensor_name>">
       <param name="interface">sura_hardware_interface/<SensorInterface></param>
       <param name="broadcaster"><sensor_broadcaster></param>
       <param name="read_rate_hz">100.0</param>
       <param name="frame_id">$(arg robot_name)/<sensor_frame></param>
       <param name="stonefish_topic">/$(arg robot_name)/stonefish/sensors/<sensor_topic></param>
       <state_interface name="<state_interface>"/>
     </sensor>
   </ros2_control>

Add one ``<sensor>`` entry for each sensor that should be exposed through
``ros2_control``.

The main sensor parameters are:

* ``interface``: SURA hardware interface used to read the sensor.
* ``broadcaster``: controller broadcaster that publishes the sensor data.
* ``read_rate_hz``: desired sensor read rate.
* ``frame_id``: TF frame associated with the sensor measurement.
* ``stonefish_topic``: simulation topic used when the sensor is provided by
  Stonefish.
* ``state_interface``: state value exposed by the sensor to ``ros2_control``.

For more information about available sensor interfaces, see
:doc:`sura_hardware_interface Sensors <sura_hardware_interface_sensors>`.

Actuators
^^^^^^^^^

Actuators are defined as joints inside the ``<robot_name>_actuators``
``ros2_control`` block. This block is used for controllable hardware that is not
a propulsion thruster, such as lights, arms, fins or other mechanisms.

.. code-block:: xml

   <ros2_control name="$(arg robot_name)_actuators" type="system">
     <hardware>
       <plugin>sura_hardware_interface/ActuatorsSystem</plugin>
       <param name="environment">$(arg environment)</param>
     </hardware>

     <joint name="$(arg robot_name)/<actuator_joint>">
       <param name="interface">sura_hardware_interface/<ActuatorInterface></param>
       <command_interface name="<command_interface>"/>
       <state_interface name="<state_interface>"/>
       <param name="channel">0</param>
       <param name="controller"><actuator_controller></param>
     </joint>
   </ros2_control>

Add one ``<joint>`` entry for each actuator installed on the robot.

The main actuator parameters are:

* ``interface``: SURA hardware interface used to command the actuator.
* ``command_interface``: command value accepted by the actuator, such as PWM,
  position, velocity or effort.
* ``state_interface``: state value reported by the actuator.
* ``channel``: hardware output channel connected to that actuator when the
  device is controlled through the Navigator.
* ``controller``: controller name that ``sura_controllers.launch.py`` can spawn
  for this actuator.

For more information about available actuator interfaces, see
:doc:`sura_hardware_interface Actuators <sura_hardware_interface_actuators>`.

``sura_controllers.launch.py`` reads this rendered xacro to discover the
robot-specific joint controllers and sensor broadcasters that must be spawned.
