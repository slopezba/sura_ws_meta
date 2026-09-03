Overview
========

SURA is organized as a collection of ROS 2 packages with clear responsibilities.
The workspace separates launch orchestration, hardware access, sensors,
localization, control, navigation, teleoperation, diagnostics and shared
messages so that each part can be developed and tested independently.

The package structure is intended to keep reusable functionality separate from
vehicle-specific configuration. This makes it easier to support different marine
robots while preserving a common architecture.
