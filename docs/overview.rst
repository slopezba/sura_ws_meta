Overview
========

SURA stands for **Surface and Underwater Robotic Architecture**. It is a
modular robotics architecture built on **ROS 2 Humble** for surface and
underwater robotic vehicles.

SURA provides a common software foundation for:

* Uncrewed Surface Vehicles (USVs).
* Autonomous Underwater Vehicles (AUVs).
* Remotely Operated Vehicles (ROVs).
* Underwater Vehicles with Manipulators (UVMs).
* Underwater Vehicle-Dual Manipulator Systems (UVDMs).
* Custom marine robotic platforms.

The architecture is designed to simplify the integration of hardware, sensors,
control systems, localization, navigation and operator interfaces while keeping
vehicle-specific components separated from reusable functionality.

A Common Architecture for Marine Robots
---------------------------------------

Surface and underwater robots often require different sensors, actuators and
control strategies. However, they also share fundamental capabilities such as
state estimation, navigation, communication, diagnostics and mission execution.

SURA provides a common architecture that allows these capabilities to be shared
across different vehicle types. This reduces duplicated development effort and
makes it easier to create new robotic platforms from existing components.

Key Capabilities
----------------

Modular Architecture
~~~~~~~~~~~~~~~~~~~~

SURA is organized as a collection of independent ROS 2 components with clearly
defined responsibilities.

Each component can be developed, tested, replaced or extended without requiring
major changes to the rest of the system. This modular design makes SURA suitable
for both small experimental platforms and more complex robotic systems.

Hardware Abstraction
~~~~~~~~~~~~~~~~~~~~

SURA separates high-level robotic functionality from the physical hardware of
the vehicle.

Sensors and actuators are exposed through standardized ROS 2 interfaces,
allowing the same control, localization and navigation components to work with
different vehicle configurations.

This separation also simplifies the transition between simulated and physical
robots.

Vehicle Control
~~~~~~~~~~~~~~~

The control architecture is based on ``ros2_control``, providing a structured
and extensible framework for managing vehicle controllers and hardware
interfaces.

Depending on the platform, control pipelines can include:

* Velocity control.
* Position control.
* Heading and attitude control.
* Depth control.
* Body-force and body-wrench generation.
* Thruster allocation.
* Individual actuator command generation.

Controllers can be combined to create layered control strategies, from
high-level motion references down to individual thruster commands.

Localization and State Estimation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SURA provides a common framework for estimating the state of the vehicle from
multiple sensor sources.

The architecture can integrate information from devices such as:

* Inertial Measurement Units.
* GNSS and GPS receivers.
* Pressure and depth sensors.
* Doppler Velocity Logs.
* Odometry sources.
* Vision-based localization systems.

Sensor measurements can be combined to estimate the position, orientation,
velocity and motion of the vehicle. The architecture also manages the
coordinate-frame transformations required to connect sensors, actuators, vehicle
frames and world references.

Sensor Integration
~~~~~~~~~~~~~~~~~~

SURA is designed to support a wide range of marine robotics sensors and
payloads.

Sensor drivers and processing components can be integrated independently and
expose their data through standard ROS 2 interfaces. This allows new sensors to
be added without modifying the complete robotic system.

Navigation
~~~~~~~~~~

The navigation layer connects vehicle-state estimation with the control system.
It provides the information required to guide the vehicle and execute motion
commands consistently across different platforms.

The modular structure allows navigation algorithms to evolve independently from
the low-level hardware and control interfaces.

Teleoperation
~~~~~~~~~~~~~

SURA supports manual and supervised operation through ROS 2-based teleoperation
interfaces.

Operator commands can be converted into references for the vehicle control
system while preserving the same safety, control and hardware abstraction layers
used during autonomous operation.

Diagnostics and Observability
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SURA includes mechanisms for monitoring the state and performance of the robotic
system.

Diagnostic information can be used to detect:

* Missing sensor data.
* Communication problems.
* Controller failures.
* Invalid state estimates.
* Hardware-interface errors.
* Performance degradation.

This observability is essential for operating complex robotic systems in real
environments.

Simulation-Ready Design
~~~~~~~~~~~~~~~~~~~~~~~

The architecture is designed so that the same software components can be used
with physical hardware and compatible simulation environments.

Simulation can be used to validate:

* Robot models.
* Sensor configurations.
* Coordinate frames.
* Localization pipelines.
* Control strategies.
* Navigation behaviors.
* Complete operational workflows.

This reduces the risk and cost associated with testing new functionality
directly on physical vehicles.

Reusable Across Vehicles
------------------------

SURA is not tied to a single robot.

The architecture is intended to support different surface and underwater
platforms while preserving a common set of software interfaces and development
practices.

A new vehicle can reuse existing components for:

* Control.
* Localization.
* Navigation.
* Sensor processing.
* Teleoperation.
* Diagnostics.
* Shared ROS 2 interfaces.

Only the components that depend directly on the vehicle hardware need to be
adapted.

Designed for Extensibility
--------------------------

SURA is designed to evolve as new requirements appear.

The architecture can be extended with:

* New vehicles.
* New sensors and payloads.
* New actuator configurations.
* New control strategies.
* New localization algorithms.
* New navigation systems.
* New operator interfaces.
* New autonomous capabilities.

This extensibility makes SURA suitable as a long-term foundation for marine
robotics research and development.

Architecture Goals
------------------

The main goals of SURA are:

* Provide a shared architecture for surface and underwater robots.
* Reduce duplicated development between robotic platforms.
* Promote reusable and interchangeable ROS 2 components.
* Separate vehicle hardware from high-level robotic functionality.
* Simplify integration, testing and maintenance.
* Support both physical and simulated environments.
* Provide a scalable foundation for future autonomous capabilities.

SURA aims to make the development of marine robots more modular, reusable and
maintainable while preserving the flexibility required by different vehicles and
missions.
