# SURA: Surface and Underwater Robotic Architecture 🌊🤖

`sura_ws_meta` describes the SURA ROS 2 workspace architecture and tracks its
repository composition through `vcstool`.

SURA stands for **Surface and Underwater Robotic Architecture**. There is also a
small Valencian wink in the name: _sura_ means "it floats". Quite convenient
for robots that are expected to float, dive, resurface, and generally avoid
doing their finest impression of a brick.

SURA is intended for commercial surface and underwater robots, such as the
[BlueROV2](https://bluerobotics.com/store/rov/bluerov2/) and the
[BlueBoat](https://bluerobotics.com/store/boat/blueboat/blueboat/), and also for
custom underwater vehicles and custom surface vehicles developed for research,
experimental validation, and field operations. The architecture is fully native
in [ROS 2 Humble](https://docs.ros.org/en/humble/) and is organized as a set of
independent packages that can be reused, replaced, or extended depending on the
vehicle.

At the moment, the hardware layer is designed around the
[`sura_hardware_interface`](https://github.com/inesperez03/sura_hardware_interface)
package, working with a [Raspberry Pi](https://www.raspberrypi.com/) and the
Blue Robotics
[Navigator Flight Controller](https://bluerobotics.com/store/comm-control-power/elec-packages/navigator/).
The architecture is meant to keep growing, so more sensors, more actuators, new
payloads, and vehicle-specific interfaces can be integrated without redesigning
the rest of the system. Sensible engineering, suspiciously rare in the wild.

This work has been developed at
[CIRTESU](https://blogs.uji.es/cirtesu/), the Research Centre for Robotics and
Underwater Technologies at Universitat Jaume I.

## Architecture 🧭

The workspace is organized into several layers:

- Vehicle bringup and system composition.
- Hardware access and actuator/sensor integration.
- Sensor processing and perception pipelines.
- Localization and vehicle state estimation.
- Navigation and state adaptation for control.
- Teleoperation, diagnostics, and operator tools.
- Shared message definitions.

Each package lives in its own Git repository under `src/`. This meta-repository
only stores the manifest required to recreate a known workspace composition.

## Packages 📦

- [`sura_bringup`](https://github.com/slopezba/sura_bringup): main launch and
  orchestration package. It brings together the hardware interface, sensors,
  localization, navigation, teleoperation, diagnostics, and vehicle-level
  configuration.
- [`sura_hardware_interface`](https://github.com/inesperez03/sura_hardware_interface):
  ROS 2 hardware interface for the vehicle. It is currently focused on Raspberry
  Pi plus Blue Robotics Navigator integration, exposing the hardware needed by
  the control stack and leaving room for additional actuators and sensors.
- [`sura_sensors`](https://github.com/inesperez03/sura_sensors): vehicle sensor
  integration layer. It groups sensor drivers and ROS 2 interfaces that feed the
  rest of the architecture.
- [`sura_cameras`](https://github.com/slopezba/sura_cameras): launch files and
  image-processing pipelines for cameras, visual perception, and related flows.
- [`sura_controllers`](https://github.com/slopezba/sura_controllers): ROS 2
  Control controller plugins shared by the SURA AUV and USV stacks, including
  common thruster allocation, AUV controllers, and USV controllers.
- [`sura_imu`](../sura_imu): IMU processing and attitude-estimation package. It
  is present in this workspace as a local package, but it is not currently a Git
  repository, so it cannot be pinned in `workspace.repos`.
- [`sura_localization`](https://github.com/slopezba/sura_localization):
  localization and sensor-fusion package for estimating the vehicle state from
  the available sensors.
- [`sura_navigator`](https://github.com/slopezba/sura_navigator): navigation
  state adapter between the vehicle state and the controller stack.
- [`sura_teleop`](https://github.com/slopezba/sura_teleop): teleoperation
  package for manual control and operator interaction.
- [`sura_diagnostics`](https://github.com/slopezba/sura_diagnostics):
  diagnostics and observability tools for monitoring the running system.
- [`sura_msgs`](https://github.com/inesperez03/sura_msgs): shared ROS 2 message
  definitions used by the SURA packages.

## Robot Setup 🛠️

The intended onboard setup starts with a Raspberry Pi and a microSD card,
preferably **128 GB**. The card should contain a Raspberry Pi OS/Raspbian-based
system prepared for the robot. Once the board boots, the complete SURA runtime
is expected to run inside Docker on the robot.

A typical setup flow is:

1. Prepare a 128 GB microSD card with Raspberry Pi OS or the required
   Raspbian-based image.
2. Assemble the Raspberry Pi with the Blue Robotics Navigator board.
3. Configure networking so the robot can be reached from the operator station.
4. Install or load the Docker image that contains the ROS 2 Humble SURA stack.
5. Start the container on the robot with access to the required hardware
   devices, network interfaces, and configuration files.
6. Launch the vehicle bringup through `sura_bringup`.
7. Check sensors, actuators, diagnostics, and teleoperation before going near
   water, because optimism is not a safety protocol.

## Simulation 🧪

Although SURA is designed to run onboard real robots, the same architecture can
also be used to simulate the robot with the
[Stonefish](https://stonefish.readthedocs.io/) simulator. This makes it possible
to validate launch files, sensor flows, navigation components, and operator
workflows before using physical hardware.

The project is under constant development. Upcoming work is expected to include
simulation support for both the BlueBoat and the BlueROV2.

## Workspace Manifest 🗂️

- [`workspace.repos`](workspace.repos): exact repository manifest for recreating
  the SURA workspace with `vcstool`.

## Recreate The Workspace 🔁

From the workspace root:

```bash
mkdir -p src
vcs import src < sura_ws_meta/workspace.repos
```

## Build 🔧

Always build from the workspace root:

```bash
colcon build
```

## Extending SURA 🚀

The architecture is prepared to grow with new hardware and mission needs.
Additional sensors, actuators, payload controllers, perception modules,
localization sources, or vehicle-specific launch files can be integrated as new
ROS 2 packages or as extensions of the existing packages.

## Update The Manifest 📝

When the repositories reach a known good state, regenerate or edit
`workspace.repos` and commit the change in this repository.
