Development
===========

SURA is designed to grow as new robots, sensors, actuators and missions are
added. Development should keep each change close to the package that owns that
part of the system, so the same architecture can be reused across BlueROV,
BlueBoat and custom vehicles.

Development Workflow
--------------------

Use this workflow for most changes:

#. Update or clone the required packages inside ``src/``.
#. Make the change in the package that owns the behavior.
#. Build the affected packages with ``colcon build``.
#. Source the workspace with ``source install/setup.bash``.
#. Launch the robot or simulation with the right ``robot_namespace``.
#. Check topics, TF, controllers and diagnostics before testing on hardware.

Robot Descriptions
------------------

Robot-specific geometry and hardware declarations belong in the robot
description package, for example ``bluerov_description`` or
``blueboat_description``.

The description package should define:

* The URDF/xacro model.
* Sensor frames and their real positions.
* Thruster frames, channels, lookup tables and inversion.
* Actuator joints, channels and interfaces.
* ``bringup_description.yaml``.
* ``ros2_control_params.yaml``.

For the expected xacro structure, see
:doc:`URDF/Xacro Model <packages/robot_description_urdf_xacro>`. For the robot
profile used by launch files, see
:doc:`bringup_description.yaml <packages/robot_description_bringup_description>`.

Adding Sensors
--------------

If the sensor is already supported, add it to the robot xacro and configure the
matching broadcaster in the robot ``ros2_control`` YAML.

If the sensor is not supported yet, add a new sensor interface plugin in
``sura_hardware_interface`` and, if needed, a broadcaster in ``sura_sensors``.
The available interfaces and the process for adding a new one are documented in
:doc:`Sensors <packages/sura_hardware_interface_sensors>`.

Adding Thrusters
----------------

Thrusters are declared in the robot xacro and handled by
``sura_hardware_interface/ThrustersSystem``. When adding or changing thrusters,
check the physical position, mounting angle, Navigator channel, ``inverted``
value and lookup CSV.

Available lookup files and thruster parameters are documented in
:doc:`Thrusters <packages/sura_hardware_interface_thrusters>`.

Adding Actuators
----------------

Actuators such as lights, servos or payload mechanisms are declared in the robot
xacro and connected to a controller through the robot ``ros2_control`` YAML.

If the actuator is not supported yet, add a new actuator interface plugin in
``sura_hardware_interface``. The available actuator interfaces and the process
for adding a new one are documented in
:doc:`Actuators <packages/sura_hardware_interface_actuators>`.

Adding Controllers Or Behavior
------------------------------

Controller logic belongs in ``sura_controllers``. Navigation-state adaptation
belongs in ``sura_navigator``. Localization configuration and conversion nodes
belong in ``sura_localization``. Camera pipelines belong in ``sura_cameras``.
Diagnostics belong in ``sura_diagnostics``.

Keep robot-specific values in the robot description package or in robot-specific
YAML files. Shared packages should stay reusable across platforms.

Updating the Manifest
---------------------

When the repositories reach a known good state, regenerate or edit
``workspace.repos`` and commit the change in this repository. The manifest
should point to a tested combination of package versions.
