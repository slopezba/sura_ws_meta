ROS 2 Control Parameters
========================

The ROS 2 Control parameter file contains the controller manager configuration
for a specific robot. It defines which controllers and broadcasters are
available, their plugin types and the parameters each one needs at runtime.

For the official parameter format, see the
`ros2_control controller manager documentation <https://control.ros.org/humble/doc/ros2_control/controller_manager/doc/userdoc.html#parameters>`_.

The file is selected from ``bringup_description.yaml``:

.. code-block:: yaml

   ros2_control:
     params_package: <robot_namespace>_description
     params: config/<ros2_control_params>.yaml

At runtime, ``sura_controllers.launch.py`` loads this YAML together with the
rendered robot xacro. The YAML provides the controller definitions, while the
xacro is used to discover the robot-specific joints, sensors and broadcasters
that should be spawned.

A typical file starts with the controller manager namespace:

.. code-block:: yaml

   /<robot_namespace>/controller/controller_manager:
     ros__parameters:
       update_rate: 200

       common_controllers:
         - <controller_name>

       auv_controllers:
         - <controller_name>

       <controller_name>:
         type: <controller_plugin>

Controller Manager Section
--------------------------

The first entry configures the ``controller_manager`` node:

.. code-block:: yaml

   /<robot_namespace>/controller/controller_manager:
     ros__parameters:
       update_rate: 200

``update_rate`` defines the control loop frequency in hertz. The namespace must
match the robot namespace used by the launch files.

Controller Groups
-----------------

Controller groups define which regular controllers are selected for each robot
family. ``sura_controllers.launch.py`` chooses the groups from the ``family``
attribute declared in the xacro:

.. code-block:: yaml

   common_controllers:
     - thruster_test_controller

   usv_controllers:
     - body_force
     - body_velocity
     - body_position

   auv_controllers:
     - body_force
     - body_velocity
     - position_hold
     - stabilize
     - depth_hold

``common_controllers`` are used for every robot. ``usv_controllers`` are used
when ``family="surface"``, and ``auv_controllers`` are used when
``family="underwater"``.

Controller and Broadcaster Types
--------------------------------

Every controller or broadcaster that can be spawned must be declared in the
controller manager section with its plugin type:

.. code-block:: yaml

   body_force:
     type: sura_controllers/usv/BodyForceController

   body_velocity:
     type: sura_controllers/usv/BodyVelocityController

   body_position:
     type: sura_controllers/usv/BodyPositionController

   imu_broadcaster:
     type: sura_sensors/ImuBroadcaster

These names must match the names referenced by the controller groups or by the
robot xacro. Sensor broadcasters are discovered from ``<param
name="broadcaster">`` entries, and actuator controllers are discovered from
``<param name="controller">`` entries.

Controller Parameter Sections
-----------------------------

Each controller can have its own parameter section under the controller
namespace:

.. code-block:: yaml

   /<robot_namespace>/controller/<controller_name>:
     ros__parameters:
       <parameter_name>: <value>

For command controllers, this section usually defines the controlled joints and
the interface name:

.. code-block:: yaml

   /<robot_namespace>/controller/<controller_name>:
     ros__parameters:
       joints:
         - <robot_namespace>/<joint_name>
       interface_name: effort

For SURA motion controllers, this section defines topics, controller
dependencies and tuning values such as PID gains, thresholds and feedforward
settings.

Broadcaster Parameter Sections
------------------------------

Broadcasters also have their own parameter sections:

.. code-block:: yaml

   /<robot_namespace>/controller/<broadcaster_name>:
     ros__parameters:
       sensor_name: <sensor_name_from_xacro>
       frame_id: <robot_namespace>/<sensor_frame>
       topic_name: /<robot_namespace>/sensors/<topic>
       update_rate: 50

``sensor_name`` must match the ``<sensor name="...">`` entry in the xacro.
``frame_id`` selects the TF frame used in the published message, ``topic_name``
selects the output topic, and ``update_rate`` controls how often the broadcaster
publishes.

Relationship with the Xacro
---------------------------

This YAML does not describe the physical robot. The xacro describes the
available joints, sensors and hardware interfaces; this YAML provides the
controller manager configuration for them.

For a controller or broadcaster to be spawned, both sides must agree:

* the xacro must reference the controller or broadcaster name;
* this YAML must define that same name with a valid ``type``;
* if the component needs parameters, its namespaced parameter section must be
  present.
