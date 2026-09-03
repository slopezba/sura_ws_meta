BlueROV Heavy Setup
===================

This guide explains, step by step, how to prepare a BlueROV Heavy to run SURA
from the robot's Raspberry Pi. The setup starts from a freshly flashed microSD
card and ends with the robot configured according to its real hardware: sensors,
sensor positions, thruster channels and thruster direction.

Before You Start
----------------

Prepare the following material:

* The Raspberry Pi used onboard the robot.
* A microSD card, preferably 128 GB.
* A computer to flash the card and connect to the Raspberry Pi through SSH.
* A local network where the Raspberry Pi can be reached.
* The assembled BlueROV Heavy, with the Navigator and thrusters connected.

The final configuration depends on the physical assembly of the robot. Two
BlueROV Heavy vehicles can run the same software but still have different
sensors, different sensor positions or different thruster wiring.

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

If SSH is not enabled during flashing, it must be enabled later from the
Raspberry Pi. For this setup, enabling SSH from the beginning is recommended
because the rest of the installation is done through a remote terminal.

2. Boot the Robot Raspberry Pi
------------------------------

Once the card has been flashed:

#. Insert the microSD card into the BlueROV Heavy Raspberry Pi.
#. Connect the Raspberry Pi to the robot system.
#. Power the robot.
#. Wait until the Raspberry Pi has fully booted.
#. Find its IP address on the network, or use the configured hostname.

From your computer, connect through SSH:

.. code-block:: bash

   ssh user@RASPBERRY_PI_IP

For example:

.. code-block:: bash

   ssh pi@192.168.1.50

The username, password and IP address depend on how the image was configured.

3. Prepare the Base System
--------------------------

Once you are connected to the Raspberry Pi through SSH, update the system:

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
   ssh user@RASPBERRY_PI_IP

Check that Docker responds:

.. code-block:: bash

   docker ps

4. Clone the SURA Repository
----------------------------

From the Raspberry Pi, clone the main repository:

.. code-block:: bash

   git clone https://github.com/slopezba/sura_ws_meta.git
   cd sura_ws_meta

The URL ``https://github.com/slopezba/sura_ws_meta/tree/main`` is useful for
viewing the repository in a browser, but the terminal clone command uses the URL
ending in ``.git``.

Then clone the BlueROV Heavy description package inside the repository ``src``
directory:

.. code-block:: bash

   git clone https://github.com/inesperez03/bluerov_description.git src/bluerov_description

This package contains the robot xacro, meshes, bringup description and
``ros2_control`` parameters used to describe the physical BlueROV Heavy.


5. Run the Repository Installer
-------------------------------

From the repository root, run the installer:

.. code-block:: bash

   ./install.sh

This script installs the ``sura`` command on the system. This command is used to
start, stop, inspect and enter the Docker environment for the robot.

Start the runtime:

.. code-block:: bash

   sura start

On the first run, the command asks for some configuration values:

* Robot name. For this setup, it will normally be ``bluerov``.
* ``ROS_DOMAIN_ID`` used by the robot.
* DDS middleware. ``CycloneDDS`` is recommended unless you have a reason to use
  ``FastDDS``.

Open a terminal inside the container:

.. code-block:: bash

   sura shell

Inside the container, work from the SURA-mounted workspace. After installing or
modifying packages, build from the workspace root:

.. code-block:: bash

   colcon build
   source install/setup.bash

6. Adjust Sensors
-----------------------

Once the environment is installed, adapt the robot description to your real
BlueROV Heavy. The main file is:

.. code-block:: text

   src/bluerov_description/urdf/bluerov.urdf.xacro

This xacro defines the robot structure, sensor frames, thrusters, actuators and
``ros2_control`` blocks. Treat it as a hardware configuration file: it must
match the physical robot.

Start with the sensors. The BlueROV Heavy xacro already includes several sensor
frames and sensor interfaces, such as IMU, magnetometer, pressure sensor, DVL,
battery and leak sensor. These entries are a starting point, not a guarantee
that the description matches your vehicle.

For each sensor installed on your BlueROV Heavy, check that:

* The sensor exists in the xacro.
* The sensor frame is located in the correct physical position.
* The sensor orientation is correct.
* The sensor parameters match the real connection, address, IP or port.
* The sensor broadcaster is configured in
  ``src/bluerov_description/config/ros2_control_params.yaml``.

Each physical sensor should have a ``link`` and a fixed ``joint`` relative to
``base_link``. For example:

.. code-block:: xml

   <link name="$(arg robot_name)/dvl_link" tf_type="sensor"/>
   <joint name="$(arg robot_name)/dvl_joint" type="fixed">
     <parent link="$(arg robot_name)/base_link"/>
     <child link="$(arg robot_name)/dvl_link"/>
     <origin xyz="0.0 -0.23 -0.05" rpy="0 0 0"/>
   </joint>

The ``xyz`` field defines the sensor position with respect to the robot
``base_link``. The ``rpy`` field defines its roll, pitch and yaw orientation.
Both must match the real sensor placement on your BlueROV Heavy.

Then check the sensor block inside the ``SensorsSystem`` ``ros2_control``
section. For example, the pressure sensor has parameters such as ``i2c_bus``,
``i2c_address`` and ``pressure_offset_pa``. A DVL has parameters such as
``dvl_ip``, ``dvl_listen_port``, ``dvl_command_port``,
``dvl_min_confidence`` and ``dvl_timeout_s``.

If your sensor is already supported but is not present in the xacro, add its
``link``, fixed ``joint`` and ``sensor`` block. If your sensor does not appear
in the available sensor list, follow the instructions for adding your own sensor
interface in :doc:`Sensors <packages/sura_hardware_interface_sensors>`.

If your robot does not have one of the sensors already declared in the xacro,
remove or disable its description and its associated configuration. It is not
enough for a sensor to exist in the xacro: it must also be connected, powered,
reachable from the Raspberry Pi and published by the correct broadcaster.

7. Adjust Thrusters
-------------------

After the sensors, review the BlueROV Heavy thrusters. The xacro already
contains the standard 8-thruster Heavy configuration, but you must verify that
it matches how your robot has actually been assembled and wired.

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

Each thruster should have a fixed joint like this:

.. code-block:: xml

   <link name="$(arg robot_name)/Thruster_R_FORWARD_FRONT" tf_type="thruster"/>
   <joint name="$(arg robot_name)/Thruster_R_FORWARD_FRONT" type="fixed">
     <parent link="$(arg robot_name)/base_link"/>
     <child link="$(arg robot_name)/Thruster_R_FORWARD_FRONT"/>
     <origin xyz="0.145737 0.091717 0.04783" rpy="0.0 0.0 -0.7853"/>
   </joint>

The ``xyz`` field must be the real thruster position relative to ``base_link``.
The ``rpy`` field must be the real thrust orientation.

Each thruster also has a ``ros2_control`` block like this:

.. code-block:: xml

   <joint name="$(arg robot_name)/Thruster_R_FORWARD_FRONT">
     <command_interface name="effort"/>
     <state_interface name="effort"/>
     <param name="lookup_csv">config/t200_lookup.csv</param>
     <param name="inverted">false</param>
     <param name="pwm_offset">0.0</param>
     <param name="channel">0</param>
   </joint>

For a BlueROV Heavy with 8 thrusters, normally check these joints:

* ``Thruster_R_FORWARD_FRONT``
* ``Thruster_L_FORWARD_FRONT``
* ``Thruster_R_FORWARD_REAR``
* ``Thruster_L_FORWARD_REAR``
* ``Thruster_R_UP_FRONT``
* ``Thruster_L_UP_FRONT``
* ``Thruster_R_UP_REAR``
* ``Thruster_L_UP_REAR``

The order and direction depend on the physical build. Identify each motor,
check which Navigator channel it is connected to, and test whether positive
thrust goes in the expected direction. Adjust ``channel`` if the wiring does
not match the xacro, and adjust ``inverted`` if the thrust direction is
opposite to the expected one.

Do not assume the mapping is correct just because the robot builds. A wrong
channel or an incorrect ``inverted`` value can make the controller send a valid
command while the robot pushes in the wrong direction. See
:doc:`Thrusters <packages/sura_hardware_interface_thrusters>` for the available
thruster lookup files and the parameters used by ``ThrustersSystem``. If your
thruster model is not in the available lookup list, use that page to understand
the required lookup CSV format and add a table for your own thruster model and
supply voltage.

8. Adjust Actuators
-------------------

Finally, review the actuators. The BlueROV Heavy xacro already includes a
lights actuator, but your robot may have different lights, a gripper, a payload
servo or another actuator connected to the Navigator.

For each actuator, check that:

* The actuator exists in the xacro.
* The actuator frame or joint matches the real hardware location.
* The selected actuator interface matches the real device.
* The ``channel`` matches the physical Navigator output.
* The matching controller exists in
  ``src/bluerov_description/config/ros2_control_params.yaml``.

The default BlueROV lights actuator looks like this:

.. code-block:: xml

   <joint name="$(arg robot_name)/lights_joint">
     <param name="interface">sura_hardware_interface/LightsBluerovInterface</param>
     <command_interface name="pwm_us"/>
     <state_interface name="pwm_us"/>
     <param name="channel">11</param>
     <param name="controller">lights_controller</param>
   </joint>

If your actuator is already supported but is not present in the xacro, add its
joint, interface parameters and controller configuration. If the actuator you
need is not in the available actuator list, follow the instructions for adding
your own actuator interface in
:doc:`Actuators <packages/sura_hardware_interface_actuators>`.


10. Launch and Check the Robot
------------------------------

With the workspace built and the xacro reviewed, launch the robot bringup from
inside the container:

.. code-block:: bash

   ros2 launch sura_bringup sura_bringup.launch.py robot_namespace:=bluerov

In another terminal inside the container, inspect the system:

.. code-block:: bash

   ros2 topic list
   ros2 control list_controllers
   ros2 control list_hardware_components

Check that:

* The expected sensor topics are available.
* The broadcasters are active.
* The controllers load without errors.
* There are no I2C, network, port or device access errors.
* ``robot_state_publisher`` publishes the robot description.
* The TF frames look correct when visualized in RViz.

11. Safety Checks Before Navigation
-----------------------------------

Before testing the robot in the water, perform a controlled validation:

#. Remove propellers if you are going to test motors outside the water.
#. Test one thruster at a time.
#. Use small commands.
#. Visually verify that the correct thruster responds.
#. Verify that the thrust direction matches the expected direction.
#. Check sensors at rest before moving the robot.
#. Check battery and leak status.

Do not move to a pool or tank test until all sensors, thrusters and actuators
respond consistently.

Useful Commands
---------------

From the Raspberry Pi:

.. code-block:: bash

   sura status
   sura logs
   sura config
   sura reconfigure
   sura doctor
   sura shell
   sura stop

Complete Setup Summary
----------------------

#. Flash Raspberry Pi OS 64-bit to the microSD card.
#. Insert the microSD card into the BlueROV Heavy Raspberry Pi.
#. Boot the robot and connect through SSH.
#. Install Docker.
#. Clone ``https://github.com/slopezba/sura_ws_meta.git``.
#. Run ``./install.sh``.
#. Start the environment with ``sura start``.
#. Enter the container with ``sura shell``.
#. Build the workspace.
#. Adapt ``bluerov.urdf.xacro`` to the real sensors and sensor positions.
#. Review ``channel`` and ``inverted`` for every thruster.
#. Review ``ros2_control_params.yaml``.
#. Launch the bringup and check topics, controllers, sensors and TF.
#. Perform controlled tests before navigation.
