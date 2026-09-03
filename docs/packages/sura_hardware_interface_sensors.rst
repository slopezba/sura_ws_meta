Sensors
=======

Sensors are handled by ``sura_hardware_interface/SensorsSystem``. This is a
ROS 2 Control ``SystemInterface`` that loads one sensor plugin per sensor
declared in the robot xacro and exposes its measurements as ROS 2 Control state
interfaces.

Unlike thrusters, sensors do not expose command interfaces. Their role is to
read data from the selected backend and make that data available to the
controller manager, where sensor broadcasters can publish it as ROS 2 topics.

In practice, sensors are declared inside a ``ros2_control`` block:

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
       <param name="stonefish_topic">/$(arg robot_name)/stonefish/sensors/<sensor></param>
       <state_interface name="<state_name>"/>
     </sensor>
   </ros2_control>

More ``sensor`` entries can be added inside the same ``ros2_control`` block,
one for each sensor available on the robot.

What SensorsSystem Does
-----------------------

``SensorsSystem`` reads the sensor definitions from the robot xacro and creates
the selected ``interface`` plugin using ``pluginlib``. Each plugin is
responsible for reading one type of sensor, while ``SensorsSystem`` manages the
ROS 2 Control lifecycle and exposes the declared state interfaces.

In ``sim`` mode, sensor plugins usually subscribe to Stonefish topics using a
simulation node created by ``SensorsSystem``.

In ``real`` mode, each plugin reads from the real device backend it supports,
such as the Navigator, I2C, UDP or serial devices, depending on the sensor.

During controller launch, ``sura_controllers.launch.py`` parses the rendered
robot description and reads each ``<param name="broadcaster">`` declared inside
the ``sensor`` blocks. If the broadcaster is also configured in the
``ros2_control`` parameter YAML, it is spawned automatically so the sensor
states can be published as regular ROS 2 topics. The broadcaster
implementations are provided by :doc:`sura_sensors <sura_sensors>`.

Common Parameters
-----------------

``environment``
   Hardware-level parameter. It must be ``sim`` or ``real`` and is forwarded to
   every sensor plugin.

``interface``
   Required per sensor. It selects the sensor plugin to load, for example
   ``sura_hardware_interface/ImuInterface``.

``broadcaster``
   Name of the broadcaster that should publish the sensor data. A sensor can
   define more than one ``broadcaster`` entry when it exposes several outputs,
   such as velocity, altitude and GPS data from a DVL.

``read_rate_hz``
   Optional read rate for that sensor. When it is greater than ``0.0``,
   ``SensorsSystem`` reads the sensor in its own thread at that frequency. When
   it is ``0.0`` or omitted, the sensor is read during the normal ROS 2 Control
   read cycle.

``frame_id``
   Frame associated with the sensor measurement. It should match a frame
   defined in the robot TF tree.

``stonefish_topic``
   Simulation topic used by sensor plugins in ``sim`` mode. Some sensors use
   additional Stonefish topics for extra outputs.

``state_interface``
   Declares each numeric state exported by the sensor to ROS 2 Control. The
   names must match what the selected sensor plugin and broadcaster expect.

Available Sensor Interfaces
---------------------------

The following examples show the currently available sensor interfaces and the
state interfaces they are expected to expose in the robot xacro.

Imu Sensor
^^^^^^^^^^^^

``sura_hardware_interface/ImuInterface`` reads IMU orientation, angular velocity
and linear acceleration. In ``real`` mode it reads the IMU integrated in the
`Blue Robotics Navigator flight controller <https://bluerobotics.com/store/comm-control-power/control/navigator/>`_.
In ``sim`` mode it subscribes to ``stonefish_topic``.

.. code-block:: xml

   <sensor name="imu_sensor">
     <param name="interface">sura_hardware_interface/ImuInterface</param>
     <param name="broadcaster">imu_broadcaster</param>
     <param name="read_rate_hz">100.0</param>
     <param name="frame_id">$(arg robot_name)/imu_link</param>
     <param name="stonefish_topic">/$(arg robot_name)/stonefish/sensors/imu</param>
     <param name="msg_type">sensor_msgs/msg/Imu</param>
     <state_interface name="orientation.x"/>
     <state_interface name="orientation.y"/>
     <state_interface name="orientation.z"/>
     <state_interface name="orientation.w"/>
     <state_interface name="angular_velocity.x"/>
     <state_interface name="angular_velocity.y"/>
     <state_interface name="angular_velocity.z"/>
     <state_interface name="linear_acceleration.x"/>
     <state_interface name="linear_acceleration.y"/>
     <state_interface name="linear_acceleration.z"/>
     <state_interface name="sample_time.sec"/>
     <state_interface name="sample_time.nanosec"/>
   </sensor>

Magnetometer Sensor
^^^^^^^^^^^^^^^^^^^^^

``sura_hardware_interface/MagnetometerInterface`` reads magnetic field data. In
``real`` mode it reads the magnetometer integrated in the `Blue Robotics
Navigator flight controller <https://bluerobotics.com/store/comm-control-power/control/navigator/>`_.
In ``sim`` mode it subscribes to ``stonefish_topic``.

.. code-block:: xml

   <sensor name="magnetometer_sensor">
     <param name="interface">sura_hardware_interface/MagnetometerInterface</param>
     <param name="broadcaster">magnetometer_broadcaster</param>
     <param name="read_rate_hz">100.0</param>
     <param name="frame_id">$(arg robot_name)/imu_link</param>
     <param name="stonefish_topic">/$(arg robot_name)/stonefish/sensors/magnetometer</param>
     <param name="msg_type">sensor_msgs/msg/MagneticField</param>
     <state_interface name="magnetic_field.x"/>
     <state_interface name="magnetic_field.y"/>
     <state_interface name="magnetic_field.z"/>
     <state_interface name="sample_time.sec"/>
     <state_interface name="sample_time.nanosec"/>
   </sensor>

Pressure Sensor
^^^^^^^^^^^^^^^^^

``sura_hardware_interface/PressureInterface`` reads a pressure sensor based on
the MS5837 family. It is intended for the `Blue Robotics Bar30 depth/pressure
sensor <https://bluerobotics.com/store/sensors-cameras/sensors/bar-depth-pressure-sensor/>`_,
which uses the MS5837-30BA sensor and communicates over I2C. In ``real`` mode
it uses the configured I2C bus and address. In ``sim`` mode it subscribes to
``stonefish_topic``.

.. code-block:: xml

   <sensor name="pressure_sensor">
     <param name="interface">sura_hardware_interface/PressureInterface</param>
     <param name="broadcaster">pressure_broadcaster</param>
     <param name="read_rate_hz">50.0</param>
     <param name="frame_id">$(arg robot_name)/pressure_link</param>
     <param name="i2c_bus">6</param>
     <param name="i2c_address">118</param>
     <param name="pressure_offset_pa">0.0</param>
     <param name="stonefish_topic">/$(arg robot_name)/stonefish/sensors/pressure</param>
     <param name="msg_type">sensor_msgs/msg/FluidPressure</param>
     <state_interface name="fluid_pressure"/>
   </sensor>

Dvl75 Sensor
^^^^^^^^^^^^

``sura_hardware_interface/DvlInterface`` reads DVL velocity, altitude and GPS
related outputs from a `Cerulean Sonar DVL-75 <https://docs.ceruleansonar.com/c/dvl-75>`_.
In ``real`` mode it uses the configured UDP connection. In ``sim`` mode it
subscribes to the Stonefish DVL, altitude and GPS topics.

.. code-block:: xml

   <sensor name="dvl_sensor">
     <param name="interface">sura_hardware_interface/DvlInterface</param>
     <param name="broadcaster">dvl75_velocity_broadcaster</param>
     <param name="broadcaster">dvl75_altitude_broadcaster</param>
     <param name="broadcaster">dvl75_gps_broadcaster</param>
     <param name="read_rate_hz">20.0</param>
     <param name="frame_id">$(arg robot_name)/dvl_link</param>
     <param name="dvl_ip"><dvl_ip></param>
     <param name="dvl_listen_port">27000</param>
     <param name="dvl_command_port">50000</param>
     <param name="dvl_min_confidence">50.0</param>
     <param name="dvl_timeout_s">1.0</param>
     <param name="sim_dvl_confidence">100.0</param>
     <param name="stonefish_topic">/$(arg robot_name)/stonefish/sensors/dvl</param>
     <param name="stonefish_altitude_topic">/$(arg robot_name)/stonefish/sensors/dvl_altitude</param>
     <param name="stonefish_gps_topic">/$(arg robot_name)/stonefish/sensors/gps</param>
     <state_interface name="linear_velocity.x"/>
     <state_interface name="linear_velocity.y"/>
     <state_interface name="linear_velocity.z"/>
     <state_interface name="angular_velocity.x"/>
     <state_interface name="angular_velocity.y"/>
     <state_interface name="angular_velocity.z"/>
     <state_interface name="distance_z"/>
     <state_interface name="confidence"/>
     <state_interface name="gps.latitude"/>
     <state_interface name="gps.longitude"/>
     <state_interface name="gps.altitude"/>
     <state_interface name="gps.valid"/>
   </sensor>

DvlA50 Sensor
^^^^^^^^^^^^^^^

``sura_hardware_interface/DvlA50Interface`` reads `Water Linked DVL-A50
<https://www.waterlinked.com/shop/dvl-a50-1248#attribute_values=47,52,126>`_
velocity reports. In ``real`` mode it uses the configured UDP endpoint. In
``sim`` mode it can subscribe to Stonefish velocity and altitude topics.

.. code-block:: xml

   <sensor name="dvla50_sensor">
     <param name="interface">sura_hardware_interface/DvlA50Interface</param>
     <param name="broadcaster">dvla50_broadcaster</param>
     <param name="read_rate_hz">20.0</param>
     <param name="frame_id">$(arg robot_name)/dvl_link</param>
     <param name="dvl_ip"><dvl_ip></param>
     <param name="dvl_port">16171</param>
     <param name="dvl_timeout_s">1.0</param>
     <param name="sim_fom">0.0</param>
     <param name="stonefish_topic">/$(arg robot_name)/stonefish/sensors/dvl</param>
     <param name="stonefish_altitude_topic">/$(arg robot_name)/stonefish/sensors/dvl_altitude</param>
     <state_interface name="linear_velocity.x"/>
     <state_interface name="linear_velocity.y"/>
     <state_interface name="linear_velocity.z"/>
     <state_interface name="fom"/>
     <state_interface name="altitude"/>
     <state_interface name="velocity_valid"/>
     <state_interface name="status"/>
     <state_interface name="time"/>
     <state_interface name="format_code"/>
     <state_interface name="beam0.id"/>
     <state_interface name="beam0.velocity"/>
     <state_interface name="beam0.distance"/>
     <state_interface name="beam0.rssi"/>
     <state_interface name="beam0.nsd"/>
     <state_interface name="beam0.valid"/>
   </sensor>

The DVL-A50 interface can also expose ``beam1.*``, ``beam2.*`` and ``beam3.*``
with the same fields as ``beam0.*``.

Battery Sensor
^^^^^^^^^^^^^^^^

``sura_hardware_interface/BatteryInterface`` reads battery voltage and current.
In ``real`` mode it reads the Navigator ADC channels.

.. code-block:: xml

   <sensor name="battery_sensor">
     <param name="interface">sura_hardware_interface/BatteryInterface</param>
     <param name="broadcaster">battery_broadcaster</param>
     <param name="read_rate_hz">2.0</param>
     <param name="frame_id">$(arg robot_name)/base_link</param>
     <state_interface name="voltage"/>
     <state_interface name="current"/>
     <state_interface name="present"/>
   </sensor>

Leak Sensor
^^^^^^^^^^^^^

``sura_hardware_interface/LeakInterface`` reads the leak detector. In ``real``
mode it reads the Navigator leak input.

.. code-block:: xml

   <sensor name="leak_sensor">
     <param name="interface">sura_hardware_interface/LeakInterface</param>
     <param name="broadcaster">leak_broadcaster</param>
     <param name="read_rate_hz">1.0</param>
     <param name="frame_id">$(arg robot_name)/base_link</param>
     <state_interface name="leak"/>
   </sensor>

AltimeterBlueboat Sensor
^^^^^^^^^^^^^^^^^^^^^^^^^^

``sura_hardware_interface/AltimeterBlueboatInterface`` reads the BlueBoat
serial altimeter based on the `Blue Robotics Ping Sonar
<https://bluerobotics.com/store/sonars/echosounders/ping-sonar-r2-rp/>`_.

.. code-block:: xml

   <sensor name="altimeter_sensor">
     <param name="interface">sura_hardware_interface/AltimeterBlueboatInterface</param>
     <param name="broadcaster">altimeter_broadcaster</param>
     <param name="read_rate_hz">10.0</param>
     <param name="frame_id">$(arg robot_name)/altimeter_link</param>
     <param name="serial_port">/dev/serial3</param>
     <param name="baudrate">115200</param>
     <param name="timeout_ms">500</param>
     <param name="speed_of_sound">1450000</param>
     <param name="ping_interval">100</param>
     <param name="gain_setting">1</param>
     <param name="scan_start">100</param>
     <param name="scan_length">3000</param>
     <param name="mode_auto">0</param>
     <state_interface name="altitude"/>
     <state_interface name="confidence"/>
     <state_interface name="scan_start"/>
     <state_interface name="scan_length"/>
     <state_interface name="gain_setting"/>
   </sensor>

Gps Sensor
^^^^^^^^^^^^

``sura_hardware_interface/GpsInterface`` reads GPS data from a serial receiver.
The supported protocols are ``ubx`` and ``nmea``.

.. code-block:: xml

   <sensor name="gps_sensor">
     <param name="interface">sura_hardware_interface/GpsInterface</param>
     <param name="broadcaster">gps_broadcaster</param>
     <param name="read_rate_hz">10.0</param>
     <param name="frame_id">$(arg robot_name)/gps_link</param>
     <param name="protocol">ubx</param>
     <param name="serial_port">/dev/ttyAMA5</param>
     <param name="baudrate">230400</param>
     <state_interface name="gps.latitude"/>
   <state_interface name="gps.longitude"/>
   <state_interface name="gps.altitude"/>
   <state_interface name="gps.valid"/>
 </sensor>

Adding a New Sensor
-------------------

To add support for a new sensor, the goal is to create a new sensor interface
plugin and then declare that sensor in the robot description.

1. Create the sensor interface class.

   Add a new class that inherits from ``SensorInterfaceBase``:

   .. code-block:: cpp

      class NewSensorInterface : public SensorInterfaceBase
      {
      public:
        bool initialize(
          const hardware_interface::ComponentInfo & sensor_info,
          const hardware_interface::HardwareInfo & hardware_info,
          const std::string & environment,
          const rclcpp::Node::SharedPtr & sim_node) override;

        bool activate() override;
        bool deactivate() override;
        bool cleanup() override;
        bool read(std::unordered_map<std::string, double> & states) override;
      };

   The interface class defines how the sensor is connected and how its data is
   read:

   * ``initialize`` reads the xacro parameters, stores the selected
     ``environment`` and prepares the real or simulated backend.
   * ``activate`` opens or starts the required resource, such as a serial port,
     UDP socket, I2C device, Navigator access or simulation subscription.
   * ``deactivate`` and ``cleanup`` stop and release those resources.
   * ``read`` performs the actual sensor read and fills the ``states`` map with
     the state names declared in the xacro.

   For example, if the xacro declares ``<state_interface name="value"/>``, then
   ``read`` should write ``states["value"]`` with the latest measurement.

2. Register the plugin.

   Export the class with ``PLUGINLIB_EXPORT_CLASS`` in the implementation file
   and add it to ``sura_hardware_plugins.xml``:

   .. code-block:: xml

      <class
        name="sura_hardware_interface/NewSensorInterface"
        type="sura_hardware_interface::NewSensorInterface"
        base_class_type="sura_hardware_interface::SensorInterfaceBase">
        <description>
          Sensor interface for new sensor readings
        </description>
      </class>

3. Add the source file to the build.

   Add the new ``.cpp`` file to ``sura_hardware_interface`` in
   ``CMakeLists.txt`` so the plugin is compiled into the package library.

4. Declare the sensor in the robot xacro.

   Add a ``sensor`` block inside the ``SensorsSystem`` ``ros2_control`` section:

   .. code-block:: xml

      <sensor name="new_sensor">
        <param name="interface">sura_hardware_interface/NewSensorInterface</param>
        <param name="broadcaster">new_sensor_broadcaster</param>
        <param name="read_rate_hz">10.0</param>
        <param name="frame_id">$(arg robot_name)/new_sensor_link</param>
        <param name="stonefish_topic">/$(arg robot_name)/stonefish/sensors/new_sensor</param>
        <state_interface name="value"/>
      </sensor>

   The ``state_interface`` names must match the keys written by ``read``.

5. Add the broadcaster configuration.

   Add the broadcaster type and its parameters to the robot
   ``ros2_control`` parameter YAML. The broadcaster name must match the
   ``broadcaster`` parameter declared in the xacro.

6. Validate both runtimes.

   Test ``environment:=sim`` with the simulated topic and ``environment:=real``
   with the physical device. Check that ``ros2_control_node`` loads the new
   interface, that the broadcaster is spawned, and that the expected ROS 2 topic
   publishes valid data.
