Your Own Robot Setup
====================

This guide explains how to prepare your own marine robot to run SURA. The
process is similar to the BlueROV Heavy and BlueBoat setups: flash the onboard
Raspberry Pi, install the SURA runtime, clone or create a robot description
package, and then adapt sensors, thrusters and actuators to the real vehicle.

Use this page for custom ROVs, AUVs, USVs, UVMs, UVDMs or any robot that does
not already have a ready-to-use SURA description package.

Before You Start
----------------

Prepare the following material:

* The onboard Raspberry Pi or compatible computer.
* A microSD card, preferably 128 GB.
* A computer to flash the card and connect through SSH.
* A local network where the onboard computer can be reached.
* The robot assembled with its sensors, thrusters, actuators and payload
  hardware connected.
* A name for the robot namespace, for example ``my_robot``.

The robot namespace is important. SURA expects the description package to follow
the namespace convention:

.. code-block:: text

   <robot_namespace>_description

For example, if the robot namespace is ``my_robot``, the description package
should normally be named ``my_robot_description``.

1. Flash Raspberry Pi OS 64-bit
-------------------------------

First, prepare the microSD card with Raspberry Pi OS 64-bit. From your computer:

#. Insert the microSD card.
#. Open Raspberry Pi Imager, or the flashing tool you normally use.
#. Select a 64-bit Raspberry Pi OS image.
#. Enable SSH before flashing the image if the tool provides that option.
#. Configure the user, password, hostname and network if needed.
#. Flash the microSD card.
#. Eject the card safely.

If SSH is not enabled during flashing, enable it later from the Raspberry Pi.
For robot setup work, enabling SSH from the beginning is recommended because the
rest of the installation is done through a remote terminal.

2. Boot the Robot Computer
--------------------------

Once the card has been flashed:

#. Insert the microSD card into the robot Raspberry Pi.
#. Connect the Raspberry Pi to the robot electronics.
#. Power the robot.
#. Wait until the Raspberry Pi has fully booted.
#. Find its IP address on the network, or use the configured hostname.

From your computer, connect through SSH:

.. code-block:: bash

   ssh user@ROBOT_IP

For example:

.. code-block:: bash

   ssh pi@192.168.1.50

The username, password and IP address depend on how the image was configured.

3. Prepare the Base System
--------------------------

Once you are connected through SSH, update the system:

.. code-block:: bash

   sudo apt update
   sudo apt upgrade

Install Docker, which is the intended runtime for running SURA onboard the
robot:

.. code-block:: bash

   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker "$USER"

After adding the user to the ``docker`` group, close the SSH session and connect
again so the permission change is applied:

.. code-block:: bash

   exit
   ssh user@ROBOT_IP

Check that Docker responds:

.. code-block:: bash

   docker ps

4. Clone the SURA Repository
----------------------------

From the robot Raspberry Pi, clone the main SURA repository:

.. code-block:: bash

   git clone https://github.com/slopezba/sura_ws_meta.git
   cd sura_ws_meta

The URL ``https://github.com/slopezba/sura_ws_meta/tree/main`` is useful for
viewing the repository in a browser, but the terminal clone command uses the URL
ending in ``.git``.

5. Clone or Create the Robot Description Package
------------------------------------------------

Before running the robot, SURA needs a description package for your robot inside
``src/``. If you already have one in Git, clone it into the workspace:

.. code-block:: bash

   git clone <robot_description_repository_url> src/<robot_namespace>_description

For example:

.. code-block:: bash

   git clone https://github.com/example/my_robot_description.git src/my_robot_description

If you do not have a description package yet, create one following this
structure:

.. code-block:: text

   src/<robot_namespace>_description/
   ├── CMakeLists.txt
   ├── package.xml
   ├── config/bringup_description.yaml
   ├── config/ros2_control_params.yaml
   ├── launch/robot_description.launch.py
   ├── meshes/
   └── urdf/<robot_namespace>.urdf.xacro

This package is where the real robot is described. It should contain the xacro
model, meshes if needed, launch file, bringup profile and controller
configuration.

6. Configure ``bringup_description.yaml``
-----------------------------------------

The file ``config/bringup_description.yaml`` tells ``sura_bringup`` which robot
model and runtime configuration should be used for your namespace.

For a real robot, start with this structure:

.. code-block:: yaml

   robot:
     name: <robot_namespace>
     environment: real
     localization: real

   description:
     package: <robot_namespace>_description
     xacro: urdf/<robot_namespace>.urdf.xacro

   ros2_control:
     params_package: <robot_namespace>_description
     params: config/ros2_control_params.yaml

   diagnostics:
     params_package: sura_diagnostics
     params: config/diagnostics.yaml

   imu:
     raw_imu_topic: controller/imu_broadcaster/imu
     filtered_imu_topic: sensors/imu
     mag_topic: controller/magnetometer_broadcaster/mag

   localization:
     enabled: true
     launch_package: sura_localization
     launch_file: auv_localization.launch.py
     publish_tf: true

Change the values to match your robot. The ``robot.name`` value must match the
namespace used when launching SURA. The ``description.package`` value must match
the package cloned or created inside ``src/``.

For the full structure and all available fields, see
:doc:`bringup_description.yaml <packages/robot_description_bringup_description>`.

7. Create the Robot Xacro
-------------------------

The xacro is the main hardware description of the robot. It defines:

* The robot name and family.
* The ``base_link`` frame.
* Sensor frames and their real positions.
* Thruster frames and their real positions.
* Actuator frames or joints.
* ``ros2_control`` blocks for sensors, thrusters and actuators.

The robot header should look like this:

.. code-block:: xml

   <?xml version="1.0"?>
   <robot xmlns:xacro="http://www.ros.org/wiki/xacro"
          name="$(arg robot_name)"
          family="<surface|underwater>">

     <xacro:arg name="robot_name" default="<robot_namespace>"/>
     <xacro:arg name="environment" default="real"/>

Use ``family="surface"`` for USV-style robots and ``family="underwater"`` for
ROV/AUV-style robots. SURA uses this value to select the controller groups that
apply to the vehicle.

For the complete expected xacro structure, see
:doc:`URDF/Xacro Model <packages/robot_description_urdf_xacro>`.

8. Adjust Sensors First
-----------------------

Start by describing the sensors installed on the robot. Some common sensors may
already be supported by SURA, such as IMU, magnetometer, pressure, GPS, DVL,
battery, leak sensor or altimeter, but you must still place them correctly in
your robot xacro.

For each sensor, check that:

* The sensor exists in the xacro.
* The sensor frame is located in the correct physical position.
* The sensor orientation is correct.
* The ``ros2_control`` sensor interface matches the real hardware.
* The sensor parameters match the real connection, address, IP or port.
* The sensor broadcaster is configured in
  ``src/<robot_namespace>_description/config/ros2_control_params.yaml``.

Each physical sensor should have a ``link`` and a fixed ``joint`` relative to
``base_link``:

.. code-block:: xml

   <link name="$(arg robot_name)/sensor_link" tf_type="sensor"/>
   <joint name="$(arg robot_name)/sensor_joint" type="fixed">
     <parent link="$(arg robot_name)/base_link"/>
     <child link="$(arg robot_name)/sensor_link"/>
     <origin xyz="<x> <y> <z>" rpy="<roll> <pitch> <yaw>"/>
   </joint>

Then add the matching ``sensor`` block inside the ``SensorsSystem``
``ros2_control`` section. If your sensor is already supported, use the
corresponding existing interface. If your sensor is not in the available sensor
list, follow the instructions for adding your own sensor interface in
:doc:`Sensors <packages/sura_hardware_interface_sensors>`.

9. Adjust Thrusters
-------------------

After the sensors, describe the thrusters installed on the robot. The xacro must
match the real thruster layout and the real Navigator wiring.

For each thruster, check that:

* The thruster exists in the xacro.
* The thruster frame matches the real physical position.
* The thruster orientation matches the real mounting angle.
* The fixed joint ``origin`` gives the real position and orientation of the
  thruster with respect to ``base_link``.
* The ``lookup_csv`` matches the thruster model and supply voltage.
* The ``channel`` matches the physical Navigator output.
* The ``inverted`` value matches the real thrust direction.

The thruster position with respect to ``base_link`` is critical. SURA uses the
thruster frame positions and orientations to understand where each force is
applied on the robot. If a thruster is placed incorrectly in the xacro, the
controller can compute the wrong force distribution even when the channel and
``inverted`` values are correct.

Each thruster should first have a fixed joint like this:

.. code-block:: xml

   <link name="$(arg robot_name)/thruster_0" tf_type="thruster"/>
   <joint name="$(arg robot_name)/thruster_0_joint" type="fixed">
     <parent link="$(arg robot_name)/base_link"/>
     <child link="$(arg robot_name)/thruster_0"/>
     <origin xyz="<x> <y> <z>" rpy="<roll> <pitch> <yaw>"/>
   </joint>

The ``xyz`` field must be the real thruster position relative to ``base_link``.
The ``rpy`` field must be the real thrust orientation.

Then declare the thruster as a joint in the ``ThrustersSystem``
``ros2_control`` block:

.. code-block:: xml

   <joint name="$(arg robot_name)/thruster_0">
     <command_interface name="effort"/>
     <state_interface name="effort"/>
     <param name="lookup_csv">config/t200_lookup.csv</param>
     <param name="stonefish_topic">/$(arg robot_name)/controller/thruster_setpoints_sim</param>
     <param name="inverted">false</param>
     <param name="pwm_offset">0.0</param>
     <param name="channel">0</param>
   </joint>

Identify each motor physically, check which Navigator channel it is connected
to, and test whether positive thrust goes in the expected direction. Adjust
``channel`` if the wiring does not match the xacro, and adjust ``inverted`` if
the thrust direction is opposite to the expected one.

See :doc:`Thrusters <packages/sura_hardware_interface_thrusters>` for the
available thruster lookup files and the parameters used by
``ThrustersSystem``. If your thruster model is not in the available lookup list,
use that page to understand the required lookup CSV format and add a table for
your own thruster model and supply voltage.

10. Adjust Actuators
--------------------

Finally, describe the actuators installed on the robot. Actuators are
controllable devices that are not propulsion thrusters, such as lights, servos,
payload mechanisms, fins, arms or grippers.

For each actuator, check that:

* The actuator exists in the xacro.
* The actuator frame or joint matches the real hardware location.
* The selected actuator interface matches the real device.
* The ``channel`` matches the physical Navigator output, when the actuator uses
  Navigator PWM.
* The matching controller exists in
  ``src/<robot_namespace>_description/config/ros2_control_params.yaml``.

An actuator joint normally looks like this:

.. code-block:: xml

   <joint name="$(arg robot_name)/new_actuator_joint">
     <param name="interface">sura_hardware_interface/NewActuatorInterface</param>
     <command_interface name="command"/>
     <state_interface name="command"/>
     <param name="controller">new_actuator_controller</param>
   </joint>

If your actuator is already supported, add its joint, interface parameters and
controller configuration. If the actuator you need is not in the available
actuator list, follow the instructions for adding your own actuator interface in
:doc:`Actuators <packages/sura_hardware_interface_actuators>`.

11. Review ``ros2_control_params.yaml``
---------------------------------------

The robot controller configuration should be in:

.. code-block:: text

   src/<robot_namespace>_description/config/ros2_control_params.yaml

This file defines the controller manager update rate, the controllers to load,
the sensor broadcasters and the actuator controllers.

Check that:

* Controller names match the names used by the xacro.
* Thruster joint names match the xacro exactly.
* Sensor broadcaster ``sensor_name`` values match the xacro sensor names.
* Actuator controller joint names match the xacro actuator joints.
* Topic names follow the namespace expected by the rest of SURA.

For the expected structure of this file, see
:doc:`ROS 2 Control Parameters <packages/robot_description_ros2_control_params>`.

12. Run the Installer and Build
-------------------------------

From the ``sura_ws_meta`` root, run the installer:

.. code-block:: bash

   ./install.sh

Start the runtime:

.. code-block:: bash

   sura start

On the first run, use your robot namespace when asked for the robot name. Then
enter the container:

.. code-block:: bash

   sura shell

Build the workspace:

.. code-block:: bash

   colcon build
   source install/setup.bash

13. Launch and Check the Robot
------------------------------

Launch the robot bringup using your namespace:

.. code-block:: bash

   ros2 launch sura_bringup sura_bringup.launch.py robot_namespace:=<robot_namespace>

In another terminal inside the container, inspect the system:

.. code-block:: bash

   ros2 topic list
   ros2 control list_controllers
   ros2 control list_hardware_components

Check that:

* The expected sensor topics are available.
* The broadcasters are active.
* The controllers load without errors.
* There are no I2C, network, serial, PWM or device access errors.
* ``robot_state_publisher`` publishes the robot description.
* The TF frames look correct when visualized in RViz.

14. Safety Checks Before Navigation
-----------------------------------

Before testing the robot in the water, perform a controlled validation:

#. Secure the robot before testing propulsion.
#. Test one thruster at a time.
#. Use small commands.
#. Visually verify that the correct thruster responds.
#. Verify that the thrust direction matches the expected direction.
#. Check sensors at rest before moving the robot.
#. Check battery and leak status if those sensors are installed.
#. Check that each actuator command produces the expected physical response.

Do not move to a pool, tank or open-water test until all sensors, thrusters and
actuators respond consistently.

Complete Setup Summary
----------------------

#. Flash Raspberry Pi OS 64-bit to the microSD card.
#. Insert the microSD card into the robot Raspberry Pi.
#. Boot the robot and connect through SSH.
#. Install Docker.
#. Clone ``https://github.com/slopezba/sura_ws_meta.git``.
#. Clone or create ``src/<robot_namespace>_description``.
#. Configure ``bringup_description.yaml``.
#. Create or adapt the robot xacro.
#. Add and position the robot sensors.
#. Add and configure the robot thrusters.
#. Add and configure the robot actuators.
#. Review ``ros2_control_params.yaml``.
#. Run ``./install.sh``.
#. Start the environment with ``sura start``.
#. Enter the container with ``sura shell``.
#. Build the workspace.
#. Launch the bringup and check topics, controllers, sensors and TF.
#. Perform controlled tests before navigation.
