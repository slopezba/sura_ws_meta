sura_sensors
============

``sura_sensors`` provides ROS 2 Control broadcaster plugins for SURA sensor
data. These broadcasters do not read the physical sensors directly. Instead,
they read the state interfaces exported by
:doc:`sura_hardware_interface <sura_hardware_interface>` and publish them as
standard ROS 2 messages.

The typical flow is:

.. code-block:: text

   sura_hardware_interface/SensorsSystem
     -> ros2_control state interfaces
     -> sura_sensors broadcaster
     -> ROS 2 topic

Broadcaster Configuration
-------------------------

Broadcasters are configured in the robot ``ros2_control`` parameter YAML. The
controller manager loads them like regular ROS 2 Control controllers, but they
only read state interfaces and publish messages.

Most broadcasters use the same parameters:

``sensor_name``
   Name of the sensor declared in the robot xacro. This is the prefix used to
   request state interfaces, for example ``imu_sensor/orientation.x``.

``frame_id``
   Frame used in the published message header.

``topic_name``
   ROS 2 topic where the broadcaster publishes the message.

``update_rate``
   Controller manager update rate for that broadcaster.

Example:

.. code-block:: yaml

   imu_broadcaster:
     type: sura_sensors/ImuBroadcaster

   /<robot_namespace>/controller/imu_broadcaster:
     ros__parameters:
       sensor_name: imu_sensor
       frame_id: <robot_namespace>/imu_link
       topic_name: /<robot_namespace>/controller/imu_broadcaster/imu
       update_rate: 100

The ``sensor_name`` must match the ``<sensor name="...">`` declared in the
robot xacro.

Available Broadcasters
----------------------

ImuBroadcaster
^^^^^^^^^^^^^^

``sura_sensors/ImuBroadcaster`` publishes ``sensor_msgs/msg/Imu``.

Required state interfaces:

.. code-block:: text

   <sensor_name>/orientation.x
   <sensor_name>/orientation.y
   <sensor_name>/orientation.z
   <sensor_name>/orientation.w
   <sensor_name>/angular_velocity.x
   <sensor_name>/angular_velocity.y
   <sensor_name>/angular_velocity.z
   <sensor_name>/linear_acceleration.x
   <sensor_name>/linear_acceleration.y
   <sensor_name>/linear_acceleration.z
   <sensor_name>/sample_time.sec
   <sensor_name>/sample_time.nanosec

MagnetometerBroadcaster
^^^^^^^^^^^^^^^^^^^^^^^

``sura_sensors/MagnetometerBroadcaster`` publishes
``sensor_msgs/msg/MagneticField``.

Required state interfaces:

.. code-block:: text

   <sensor_name>/magnetic_field.x
   <sensor_name>/magnetic_field.y
   <sensor_name>/magnetic_field.z
   <sensor_name>/sample_time.sec
   <sensor_name>/sample_time.nanosec

PressureBroadcaster
^^^^^^^^^^^^^^^^^^^

``sura_sensors/PressureBroadcaster`` publishes
``sensor_msgs/msg/FluidPressure``.

Additional parameter:

``pressure_variance``
   Variance assigned to the published pressure message.

Required state interface:

.. code-block:: text

   <sensor_name>/fluid_pressure

BatteryBroadcaster
^^^^^^^^^^^^^^^^^^

``sura_sensors/BatteryBroadcaster`` publishes ``sensor_msgs/msg/BatteryState``.

Additional parameter:

``cell_count``
   Battery cell count used to estimate percentage. Supported values are ``4``
   and ``6``.

Required state interfaces:

.. code-block:: text

   <sensor_name>/voltage
   <sensor_name>/current
   <sensor_name>/present

LeakBroadcaster
^^^^^^^^^^^^^^^

``sura_sensors/LeakBroadcaster`` publishes ``std_msgs/msg/Bool``.

Required state interface:

.. code-block:: text

   <sensor_name>/leak

AltimeterBlueboatBroadcaster
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

``sura_sensors/AltimeterBlueboatBroadcaster`` publishes
``sensor_msgs/msg/Range``.

Additional parameters:

``field_of_view``
   Field of view used in the published range message.

``min_range`` and ``max_range``
   Range limits used when sensor-provided limits are not enabled or not valid.

``use_sensor_limits``
   When ``true``, uses ``scan_start`` and ``scan_length`` from the sensor state
   interfaces to set the message range limits.

Required state interfaces:

.. code-block:: text

   <sensor_name>/altitude
   <sensor_name>/confidence
   <sensor_name>/scan_start
   <sensor_name>/scan_length
   <sensor_name>/gain_setting

GpsBroadcaster
^^^^^^^^^^^^^^

``sura_sensors/GpsBroadcaster`` publishes ``sensor_msgs/msg/NavSatFix``.

Additional parameter:

``position_covariance``
   Diagonal covariance value used in the published GPS fix.

Required state interfaces:

.. code-block:: text

   <sensor_name>/gps.latitude
   <sensor_name>/gps.longitude
   <sensor_name>/gps.altitude
   <sensor_name>/gps.valid

DvlVelBroadcaster
^^^^^^^^^^^^^^^^^

``sura_sensors/DvlVelBroadcaster`` publishes DVL velocity as a twist message
with covariance.

Additional parameters:

``min_linear_velocity_covariance`` and ``max_linear_velocity_covariance``
   Bounds for the linear velocity covariance computed from DVL confidence.

``angular_velocity_covariance``
   Covariance assigned to angular velocity fields.

Required state interfaces:

.. code-block:: text

   <sensor_name>/linear_velocity.x
   <sensor_name>/linear_velocity.y
   <sensor_name>/linear_velocity.z
   <sensor_name>/angular_velocity.x
   <sensor_name>/angular_velocity.y
   <sensor_name>/angular_velocity.z
   <sensor_name>/confidence

Dvl75AltitudeBroadcaster
^^^^^^^^^^^^^^^^^^^^^^^^

``sura_sensors/Dvl75AltitudeBroadcaster`` publishes DVL altitude as
``sensor_msgs/msg/Range``.

Additional parameters:

``field_of_view``
   Field of view used in the range message.

``min_range`` and ``max_range``
   Range limits used in the message.

Required state interface:

.. code-block:: text

   <sensor_name>/distance_z

Dvl75GpsBroadcaster
^^^^^^^^^^^^^^^^^^^

``sura_sensors/Dvl75GpsBroadcaster`` publishes GPS data relayed by a DVL-75 as
``sensor_msgs/msg/NavSatFix``.

Additional parameter:

``position_covariance``
   Diagonal covariance value used in the published GPS fix.

Required state interfaces:

.. code-block:: text

   <sensor_name>/gps.latitude
   <sensor_name>/gps.longitude
   <sensor_name>/gps.altitude
   <sensor_name>/gps.valid

DvlA50Broadcaster
^^^^^^^^^^^^^^^^^

``sura_sensors/DvlA50Broadcaster`` publishes the full Water Linked DVL-A50
report as a SURA message.

Required state interfaces include the DVL velocity, figure of merit, altitude,
status fields and beam data:

.. code-block:: text

   <sensor_name>/linear_velocity.x
   <sensor_name>/linear_velocity.y
   <sensor_name>/linear_velocity.z
   <sensor_name>/fom
   <sensor_name>/altitude
   <sensor_name>/velocity_valid
   <sensor_name>/status
   <sensor_name>/time
   <sensor_name>/format_code
   <sensor_name>/beam0.*
   <sensor_name>/beam1.*
   <sensor_name>/beam2.*
   <sensor_name>/beam3.*

DvlA50TwistStampedBroadcaster
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

``sura_sensors/DvlA50TwistStampedBroadcaster`` publishes DVL-A50 velocity as a
twist message with covariance.

Additional parameters:

``min_linear_velocity_covariance`` and ``max_linear_velocity_covariance``
   Bounds for the linear velocity covariance computed from the DVL figure of
   merit.

``angular_velocity_covariance``
   Covariance assigned to angular velocity fields.

Required state interfaces:

.. code-block:: text

   <sensor_name>/linear_velocity.x
   <sensor_name>/linear_velocity.y
   <sensor_name>/linear_velocity.z
   <sensor_name>/fom

AlphaJointStateBroadcaster
^^^^^^^^^^^^^^^^^^^^^^^^^^

``sura_sensors/AlphaJointStateBroadcaster`` is a helper broadcaster that filters
selected joints from a ``sensor_msgs/msg/JointState`` topic and republishes
them.

Parameters:

``input_topic``
   Input joint state topic.

``output_topic``
   Output topic with the filtered joint states.

``joint_names``
   Explicit list of joints to keep.

``joint_name_substrings``
   Substrings used to keep matching joints when ``joint_names`` is empty.

Adding a New Broadcaster
------------------------

To add a new broadcaster, create a new ROS 2 Control controller plugin that
reads the required state interfaces and publishes the desired ROS 2 message.

1. Create the broadcaster class.

   Add a class that inherits from ``controller_interface::ControllerInterface``:

   .. code-block:: cpp

      class NewSensorBroadcaster : public controller_interface::ControllerInterface
      {
      public:
        controller_interface::CallbackReturn on_init() override;

        controller_interface::InterfaceConfiguration
        command_interface_configuration() const override;

        controller_interface::InterfaceConfiguration
        state_interface_configuration() const override;

        controller_interface::CallbackReturn on_configure(
          const rclcpp_lifecycle::State & previous_state) override;

        controller_interface::CallbackReturn on_activate(
          const rclcpp_lifecycle::State & previous_state) override;

        controller_interface::CallbackReturn on_deactivate(
          const rclcpp_lifecycle::State & previous_state) override;

        controller_interface::return_type update(
          const rclcpp::Time & time,
          const rclcpp::Duration & period) override;
      };

2. Declare the parameters.

   In ``on_init``, declare the parameters the broadcaster needs. Most sensor
   broadcasters use ``sensor_name``, ``frame_id`` and ``topic_name``.

3. Select the state interfaces.

   In ``state_interface_configuration``, request the state interfaces exported
   by ``sura_hardware_interface``:

   .. code-block:: cpp

      return {
        controller_interface::interface_configuration_type::INDIVIDUAL,
        {
          sensor_name + "/value",
        },
      };

   The state names must match the ``state_interface`` entries declared in the
   robot xacro.

4. Create the publisher.

   In ``on_configure``, read the parameters and create the ROS 2 publisher for
   the output message.

5. Publish in ``update``.

   In ``update``, read the values from ``state_interfaces_``, fill the ROS
   message and publish it.

6. Register the plugin.

   Export the class with ``PLUGINLIB_EXPORT_CLASS`` and add it to
   ``sura_sensors_plugins.xml``:

   .. code-block:: xml

      <class
        name="sura_sensors/NewSensorBroadcaster"
        type="sura_sensors::NewSensorBroadcaster"
        base_class_type="controller_interface::ControllerInterface">
        <description>
          Broadcasts new sensor data from ros2_control state interfaces.
        </description>
      </class>

7. Add the source file to the build.

   Add the new broadcaster ``.cpp`` file to ``CMakeLists.txt`` so it is compiled
   into the ``sura_sensors`` plugin library.

8. Configure it in the robot YAML.

   Add the broadcaster type and its parameters to the robot ``ros2_control``
   parameter YAML:

   .. code-block:: yaml

      new_sensor_broadcaster:
        type: sura_sensors/NewSensorBroadcaster

      /<robot_namespace>/controller/new_sensor_broadcaster:
        ros__parameters:
          sensor_name: new_sensor
          frame_id: <robot_namespace>/new_sensor_link
          topic_name: /<robot_namespace>/sensors/new_sensor
          update_rate: 10

   The broadcaster name should match the ``broadcaster`` parameter declared in
   the robot xacro when automatic spawning from ``sura_controllers.launch.py``
   is desired.
