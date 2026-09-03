Actuators
=========

Actuators are handled by ``sura_hardware_interface/ActuatorsSystem``. This is a
ROS 2 Control ``SystemInterface`` that loads one actuator plugin per actuator
joint declared in the robot xacro.

Actuators expose command interfaces and state interfaces. Controllers write to
the command interfaces, while ``ActuatorsSystem`` forwards those commands to the
selected actuator plugin and mirrors the latest applied value through the state
interfaces.

In practice, actuators are declared inside a ``ros2_control`` block:

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
       <param name="channel"><navigator_channel></param>
       <param name="controller"><controller_name></param>
     </joint>
   </ros2_control>

More ``joint`` entries can be added inside the same ``ros2_control`` block, one
for each actuator available on the robot.

What ActuatorsSystem Does
-------------------------

``ActuatorsSystem`` reads the actuator joints from the robot xacro and creates
the selected ``interface`` plugin using ``pluginlib``. Each plugin is
responsible for one actuator backend, while ``ActuatorsSystem`` manages the ROS
2 Control lifecycle and exposes the declared command and state interfaces.

In ``real`` mode, the available actuator plugins use the Blue Robotics Navigator
PWM outputs. In ``sim`` mode, the plugins accept the command and update the
state interface, but they do not drive physical hardware.

During controller launch, ``sura_controllers.launch.py`` parses the rendered
robot description and reads each ``<param name="controller">`` declared inside
the actuator ``joint`` blocks. If that controller is also configured in the
``ros2_control`` parameter YAML, it is spawned automatically.

Common Parameters
-----------------

``environment``
   Hardware-level parameter. It must be ``sim`` or ``real`` and is forwarded to
   every actuator plugin.

``interface``
   Required per actuator joint. It selects the actuator plugin to load, for
   example ``sura_hardware_interface/LightsBluerovInterface``.

``command_interface``
   Command exposed to ROS 2 Control. The name must match what the selected
   actuator plugin expects.

``state_interface``
   State exposed to ROS 2 Control. For the available light actuators, this
   mirrors the latest applied command.

``channel``
   Navigator PWM channel used by the actuator in ``real`` mode.

``controller``
   Name of the controller that should command the actuator. This name must also
   exist in the robot ``ros2_control`` parameter YAML.

Available Actuator Interfaces
-----------------------------

The following examples show the currently available actuator interfaces and how
they are expected to be declared in the robot xacro.

LightsBluerovInterface
^^^^^^^^^^^^^^^^^^^^^^

``sura_hardware_interface/LightsBluerovInterface`` controls BlueROV lights with
a PWM command in microseconds. The command is clamped between ``1100`` and
``1900`` microseconds.

In ``real`` mode, the plugin uses the Blue Robotics Navigator PWM output
selected by ``channel``. In ``sim`` mode, the command is accepted and reflected
in the state interface without writing to hardware.

.. code-block:: xml

   <joint name="$(arg robot_name)/lights_joint">
     <param name="interface">sura_hardware_interface/LightsBluerovInterface</param>
     <command_interface name="pwm_us"/>
     <state_interface name="pwm_us"/>
     <param name="channel">11</param>
     <param name="controller">lights_controller</param>
   </joint>

The matching controller configuration can use a forward command controller:

.. code-block:: yaml

   lights_controller:
     type: forward_command_controller/ForwardCommandController

   /<robot_namespace>/controller/lights_controller:
     ros__parameters:
       joints:
         - <robot_namespace>/lights_joint
       interface_name: pwm_us

LightBlueboatInterface
^^^^^^^^^^^^^^^^^^^^^^

``sura_hardware_interface/LightBlueboatInterface`` controls a binary BlueBoat
status light. It uses an ``enabled`` command interface instead of a PWM value:
values greater than or equal to ``0.5`` are treated as enabled.

In ``real`` mode, the plugin writes a high or low duty cycle to the configured
Navigator channel. In ``sim`` mode, the command is accepted and reflected in the
state interface.

.. code-block:: xml

   <joint name="$(arg robot_name)/status_light_joint">
     <param name="interface">sura_hardware_interface/LightBlueboatInterface</param>
     <command_interface name="enabled"/>
     <state_interface name="enabled"/>
     <param name="channel">1</param>
     <param name="controller">status_light_controller</param>
   </joint>

The matching controller configuration can also use a forward command
controller:

.. code-block:: yaml

   status_light_controller:
     type: forward_command_controller/ForwardCommandController

   /<robot_namespace>/controller/status_light_controller:
     ros__parameters:
       joints:
         - <robot_namespace>/status_light_joint
       interface_name: enabled

Adding a New Actuator
---------------------

To add support for a new actuator, create a new actuator interface plugin and
declare the actuator joint in the robot description.

1. Create the actuator interface class.

   Add a new class that inherits from ``ActuatorInterfaceBase``:

   .. code-block:: cpp

      class NewActuatorInterface : public ActuatorInterfaceBase
      {
      public:
        bool initialize(
          const hardware_interface::ComponentInfo & actuator_info,
          const hardware_interface::HardwareInfo & hardware_info,
          const std::string & environment) override;

        bool activate() override;
        bool deactivate() override;
        bool cleanup() override;

        bool read(
          const std::unordered_map<std::string, double> & commands,
          std::unordered_map<std::string, double> & states) override;

        bool write(
          const std::unordered_map<std::string, double> & commands,
          std::unordered_map<std::string, double> & states) override;
      };

   ``initialize`` should read the xacro parameters and prepare the real or
   simulated backend. ``write`` should read the command values and apply them to
   the actuator. ``read`` should update the state values exposed to ROS 2
   Control.

2. Register the plugin.

   Export the class with ``PLUGINLIB_EXPORT_CLASS`` and add it to
   ``sura_hardware_plugins.xml``:

   .. code-block:: xml

      <class
        name="sura_hardware_interface/NewActuatorInterface"
        type="sura_hardware_interface::NewActuatorInterface"
        base_class_type="sura_hardware_interface::ActuatorInterfaceBase">
        <description>
          Actuator interface for a new actuator
        </description>
      </class>

3. Add the source file to the build.

   Add the new ``.cpp`` file to ``sura_hardware_interface`` in
   ``CMakeLists.txt`` so the plugin is compiled into the package library.

4. Declare the actuator in the robot xacro.

   Add a ``joint`` block inside the ``ActuatorsSystem`` ``ros2_control``
   section:

   .. code-block:: xml

      <joint name="$(arg robot_name)/new_actuator_joint">
        <param name="interface">sura_hardware_interface/NewActuatorInterface</param>
        <command_interface name="command"/>
        <state_interface name="command"/>
        <param name="controller">new_actuator_controller</param>
      </joint>

   The command and state interface names must match the keys used by the plugin.

5. Add the controller configuration.

   Add the controller type and parameters to the robot ``ros2_control`` YAML.
   The controller name must match the ``controller`` parameter declared in the
   xacro.

6. Validate both runtimes.

   Test ``environment:=sim`` first, then ``environment:=real`` with the physical
   device. Check that ``ros2_control_node`` loads the new interface, that the
   controller is spawned, and that commands produce the expected actuator state.
