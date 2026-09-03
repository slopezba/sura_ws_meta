BlueBoat Setup
==============

This guide explains, step by step, how to prepare a BlueBoat to run SURA from
the robot's onboard Raspberry Pi. The setup starts from a freshly flashed
microSD card and ends with the boat configured according to its real hardware:
sensors, sensor positions, thruster channels and actuators.

Before You Start
----------------

Prepare the following material:

* The Raspberry Pi used onboard the BlueBoat.
* A microSD card, preferably 128 GB.
* A computer to flash the card and connect to the Raspberry Pi through SSH.
* A local network where the Raspberry Pi can be reached.
* The assembled BlueBoat, with the Navigator, thrusters and payload hardware
  connected.

The final configuration depends on the physical boat. Two BlueBoats can run the
same software but still have different sensors, different sensor positions,
different thruster wiring or different payload actuators.

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

2. Boot the Boat Raspberry Pi
-----------------------------

Once the card has been flashed:

#. Insert the microSD card into the BlueBoat Raspberry Pi.
#. Connect the Raspberry Pi to the boat electronics.
#. Power the boat.
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

Then clone the BlueBoat description package inside the repository ``src``
directory:

.. code-block:: bash

   git clone https://github.com/Mariolopez31/blueboat_description.git src/blueboat_description

This package contains the robot xacro, meshes, bringup description and
``ros2_control`` parameters used to describe the physical BlueBoat.

5. Run the Repository Installer
-------------------------------

From the repository root, run the installer:

.. code-block:: bash

   ./install.sh

This script installs the ``sura`` command on the system. This command is used to
start, stop, inspect and enter the Docker environment for the boat.

Start the runtime:

.. code-block:: bash

   sura start

On the first run, the command asks for some configuration values:

* Robot name. For this setup, it will normally be ``blueboat``.
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

6. Prepare the BlueBoat Description
-----------------------------------

Before launching the real boat, SURA needs a robot description package for the
``blueboat`` namespace. That package normally contains:

.. code-block:: text

   src/blueboat_description/
   ├── config/bringup_description.yaml
   ├── config/ros2_control_params.yaml
   ├── launch/robot_description.launch.py
   └── urdf/blueboat.urdf.xacro

If your workspace already includes a ``blueboat_description`` package, use it as
the starting point. If it does not, create one following the structure described
in :doc:`URDF/Xacro Model <packages/robot_description_urdf_xacro>` and
:doc:`bringup_description.yaml <packages/robot_description_bringup_description>`.

The xacro is the file that describes the real boat: base frame, sensor frames,
thrusters, actuators and ``ros2_control`` hardware blocks. The
``bringup_description.yaml`` file tells ``sura_bringup`` which xacro,
controller parameters, diagnostics profile, cameras and localization launch
files belong to the BlueBoat.

For a real BlueBoat, the robot profile should normally use:

.. code-block:: yaml

   robot:
     name: blueboat
     environment: real
     localization: real

   description:
     package: blueboat_description
     xacro: urdf/blueboat.urdf.xacro

   ros2_control:
     params_package: blueboat_description
     params: config/ros2_control_params.yaml

   diagnostics:
     params_package: sura_diagnostics
     params: config/blueboat_diagnostics.yaml

7. Adjust Sensors First
-----------------------

Start by checking the sensors. The BlueBoat setup may already include several
sensor entries, such as IMU, magnetometer, GPS, battery, leak sensor or the
BlueBoat altimeter. These entries are a starting point, not a guarantee that the
description matches your boat.

For each sensor installed on your BlueBoat, check that:

* The sensor exists in the xacro.
* The sensor frame is located in the correct physical position.
* The sensor orientation is correct.
* The ``ros2_control`` sensor interface matches the real hardware.
* The sensor parameters match the real connection, address, IP, serial port or
  GPIO/PWM channel.
* The sensor broadcaster is configured in
  ``src/blueboat_description/config/ros2_control_params.yaml``.

Each physical sensor should have a ``link`` and a fixed ``joint`` relative to
``base_link``. For example:

.. code-block:: xml

   <link name="$(arg robot_name)/gps_link" tf_type="sensor"/>
   <joint name="$(arg robot_name)/gps_joint" type="fixed">
     <parent link="$(arg robot_name)/base_link"/>
     <child link="$(arg robot_name)/gps_link"/>
     <origin xyz="0.0 0.0 0.2" rpy="0 0 0"/>
   </joint>

The ``xyz`` field defines the sensor position with respect to the boat
``base_link``. The ``rpy`` field defines its roll, pitch and yaw orientation.
Both must match the real sensor placement on your BlueBoat.

Then check the sensor block inside the ``SensorsSystem`` ``ros2_control``
section. For example, a GPS sensor must expose the expected GPS state
interfaces and use the correct frame. The BlueBoat altimeter must use the
BlueBoat altimeter interface and the correct connection parameters for your
hardware.

If your sensor is already supported but is not present in the xacro, add its
``link``, fixed ``joint`` and ``sensor`` block. If your sensor does not appear
in the available sensor list, follow the instructions for adding your own sensor
interface in :doc:`Sensors <packages/sura_hardware_interface_sensors>`.

If your boat does not have one of the sensors already declared in the xacro,
remove or disable its description and its associated configuration. It is not
enough for a sensor to exist in the xacro: it must also be connected, powered,
reachable from the Raspberry Pi and published by the correct broadcaster.

8. Adjust Thrusters
-------------------

After the sensors, review the BlueBoat thrusters. A standard BlueBoat normally
uses two horizontal thrusters, but the xacro must match the real boat and the
real Navigator wiring.

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
applied on the boat. If a thruster is placed incorrectly in the xacro, the
controller can compute the wrong force distribution even when the channel and
``inverted`` values are correct.

Each thruster should have a fixed joint like this:

.. code-block:: xml

   <link name="$(arg robot_name)/left_thruster" tf_type="thruster"/>
   <joint name="$(arg robot_name)/left_thruster_joint" type="fixed">
     <parent link="$(arg robot_name)/base_link"/>
     <child link="$(arg robot_name)/left_thruster"/>
     <origin xyz="0.0 0.25 0.0" rpy="0 0 0"/>
   </joint>

The ``xyz`` field must be the real thruster position relative to ``base_link``.
The ``rpy`` field must be the real thrust orientation.

Each thruster also has a ``ros2_control`` block like this:

.. code-block:: xml

   <joint name="$(arg robot_name)/left_thruster">
     <command_interface name="effort"/>
     <state_interface name="effort"/>
     <param name="lookup_csv">config/t200_lookup.csv</param>
     <param name="inverted">false</param>
     <param name="pwm_offset">0.0</param>
     <param name="channel">0</param>
   </joint>

For a typical BlueBoat, check the port and starboard thrusters, or the left and
right thrusters if that is the naming used in your xacro. The important point is
that the joint name, physical location, Navigator channel and thrust direction
all describe the same real motor.

Identify each motor, check which Navigator channel it is connected to, and test
whether positive thrust goes in the expected direction. Adjust ``channel`` if
the wiring does not match the xacro, and adjust ``inverted`` if the thrust
direction is opposite to the expected one.

Do not assume the mapping is correct just because the boat builds. A wrong
channel or an incorrect ``inverted`` value can make the controller send a valid
command while the boat turns or pushes in the wrong direction. See
:doc:`Thrusters <packages/sura_hardware_interface_thrusters>` for the available
thruster lookup files and the parameters used by ``ThrustersSystem``. If your
thruster model is not in the available lookup list, use that page to understand
the required lookup CSV format and add a table for your own thruster model and
supply voltage.

9. Adjust Actuators
-------------------

Finally, review the actuators. A BlueBoat may include a status light, payload
power switching, servos or other mechanisms connected to the Navigator or to
external electronics.

For each actuator, check that:

* The actuator exists in the xacro.
* The actuator frame or joint matches the real hardware location.
* The selected actuator interface matches the real device.
* The ``channel`` matches the physical Navigator output, when the actuator uses
  Navigator PWM.
* The matching controller exists in
  ``src/blueboat_description/config/ros2_control_params.yaml``.

A BlueBoat status light actuator can use the BlueBoat light interface:

.. code-block:: xml

   <joint name="$(arg robot_name)/status_light_joint">
     <param name="interface">sura_hardware_interface/LightBlueboatInterface</param>
     <command_interface name="enabled"/>
     <state_interface name="enabled"/>
     <param name="channel">1</param>
     <param name="controller">status_light_controller</param>
   </joint>

If your actuator is already supported but is not present in the xacro, add its
joint, interface parameters and controller configuration. If the actuator you
need is not in the available actuator list, follow the instructions for adding
your own actuator interface in
:doc:`Actuators <packages/sura_hardware_interface_actuators>`.

10. Review Controllers and Topics
---------------------------------

The BlueBoat control configuration should be in:

.. code-block:: text

   src/blueboat_description/config/ros2_control_params.yaml

Check that the joint names used by the controllers match the names defined in
the xacro. In particular, review the thruster controller joint list, the sensor
broadcasters and any actuator controller declared by the boat.

It is also useful to review:

* IMU and magnetometer topics.
* GPS topic.
* Altimeter topic, if installed.
* Battery topic.
* Leak sensor topic.
* Status light or payload actuator controllers.

11. Launch and Check the Boat
-----------------------------

With the workspace built and the BlueBoat description reviewed, launch the boat
bringup from inside the container:

.. code-block:: bash

   ros2 launch sura_bringup sura_bringup.launch.py robot_namespace:=blueboat

In another terminal inside the container, inspect the system:

.. code-block:: bash

   ros2 topic list
   ros2 control list_controllers
   ros2 control list_hardware_components

Check that:

* The expected sensor topics are available.
* The broadcasters are active.
* The controllers load without errors.
* There are no I2C, network, port, PWM or device access errors.
* ``robot_state_publisher`` publishes the boat description.
* The TF frames look correct when visualized in RViz.

12. Safety Checks Before Navigation
-----------------------------------

Before testing the boat in the water, perform a controlled validation:

#. Keep the boat secured while testing propulsion.
#. Test one thruster at a time.
#. Use small commands.
#. Visually verify that the correct thruster responds.
#. Verify that the thrust direction matches the expected direction.
#. Check sensors at rest before moving the boat.
#. Check battery and leak status.
#. Check that any actuator command produces the expected physical response.

Do not move to an open-water test until all sensors, thrusters and actuators
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
#. Insert the microSD card into the BlueBoat Raspberry Pi.
#. Boot the boat and connect through SSH.
#. Install Docker.
#. Clone ``https://github.com/slopezba/sura_ws_meta.git``.
#. Run ``./install.sh``.
#. Start the environment with ``sura start``.
#. Enter the container with ``sura shell``.
#. Build the workspace.
#. Create or adapt the ``blueboat_description`` package.
#. Adapt the BlueBoat xacro to the real sensors and sensor positions.
#. Review thruster positions, ``channel`` and ``inverted``.
#. Review actuators and their controller configuration.
#. Review ``ros2_control_params.yaml``.
#. Launch the bringup and check topics, controllers, sensors and TF.
#. Perform controlled tests before navigation.
