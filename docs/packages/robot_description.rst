.. _robot-description-package:

Robot Description Package
=========================

SURA also expects a robot description package for the vehicle being used. This
package is usually cloned separately because it depends on the specific robot
platform.

This package contains the information that describes the robot and the runtime
configuration that SURA should launch for it. In practice, it is where each
vehicle defines its model, frames, sensors, actuators, controller configuration
and bringup profile.

A typical description package is named after the robot namespace:

.. code-block:: text

   <robot_namespace>_description/
     config/
       bringup_description.yaml
       <ros2_control_params>.yaml
     launch/
       robot_description.launch.py
     urdf/
       <robot>.urdf.xacro
     meshes/ or resources/

.. toctree::
   :maxdepth: 1

   robot_description_bringup_description
   robot_description_urdf_xacro
   robot_description_ros2_control_params
