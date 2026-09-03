Architecture
============

SURA is organized as a layered ROS 2 architecture. Each layer owns a focused
part of the robot stack and can evolve without forcing the whole system to be
redesigned.

Layers
------

* Bringup and launch orchestration.
* Hardware interfaces.
* Sensor integration.
* Camera and perception pipelines.
* Localization and state estimation.
* Navigation state adaptation.
* Controllers.
* Teleoperation.
* Diagnostics.
* Shared messages.

Repository Model
----------------

Each package lives in its own Git repository under ``src/``. This repository
stores the manifest needed to recreate a known workspace composition.
