.. _robot-description-bringup-description:

bringup_description.yaml
========================

``bringup_description.yaml`` is the robot profile used by SURA launch files.
It lives in the robot description package and tells SURA which robot model,
controller configuration and runtime modules should be used for a specific
robot namespace.

The file must be located at:

.. code-block:: text

   <robot_namespace>_description/config/bringup_description.yaml

``sura_bringup.launch.py`` reads this file on the robot, while
``sura_perception.launch.py`` also uses it to start the camera pipelines from
the user's computer.

General Structure
-----------------

A typical file contains these sections:

.. code-block:: yaml

   robot:
     name: <robot_namespace>
     environment: sim        # sim or real
     localization: sim       # sim or real

   description:
     package: <robot_namespace>_description
     xacro: urdf/<robot>.urdf.xacro
     arms: single              # optional, only for robots with arms: dual or single

   ros2_control:
     params_package: <robot_namespace>_description
     params: config/<ros2_control_params>.yaml

   diagnostics:
     params_package: sura_diagnostics
     params: config/<diagnostics_params>.yaml

   cameras:
     <camera_name>:
       enabled: true
       driver: usb_cam          # optional: usb_cam, gstramer
       aruco: false
     <camera_name>:
        ...

   imu:
     raw_imu_topic: controller/<imu_broadcaster>/imu
     filtered_imu_topic: sensors/imu
     mag_topic: controller/<magnetometer_broadcaster>/mag
     orientation_yaw_stddev_deg: 40.0

   localization:
     enabled: true
     launch_package: sura_localization
     launch_file: <localization_launch>.launch.py
     config_package: sura_localization
     config_file: config/<localization_params>.yaml
     publish_tf: true
     datum:
       latitude: <latitude>
       longitude: <longitude>
       heading: <heading>

Robot
-----

``name``
   Robot name. It must match the ``robot_namespace`` used when launching SURA.

``environment``
   Target runtime. Use ``sim`` when SURA is launched against a simulator, and
   ``real`` when it is launched on the physical robot.

``localization``
   Navigator source. On the real robot, this should be ``real``. In simulation,
   ``real`` runs the localization stack as it would run on the robot, using
   simulated sensor data; ``sim`` uses the ground-truth simulator state
   directly, without estimating navigation data from sensors.

Description
-----------

The ``description`` section selects the robot model:

.. code-block:: yaml

   description:
     package: <robot_namespace>_description
     xacro: urdf/<robot>.urdf.xacro

``description.package`` is the package that contains the model and
``description.xacro`` is the relative path to the xacro file. 

``description.arms`` is optional and is only needed for robot descriptions with
arms. It selects the arm configuration to render, such as ``dual`` or
``single``.

ROS 2 Control
-------------

The ``ros2_control`` section selects the controller manager parameter file:

.. code-block:: yaml

   ros2_control:
     params_package: <robot_namespace>_description
     params: config/<ros2_control_params>.yaml

``params_package`` is the package that contains the controller manager parameters, which is usually the same as
``description.package``. ``params`` is also optional and defaults to
``config/ros2_control_params.yaml``.

See :doc:`ROS 2 Control Parameters <robot_description_ros2_control_params>` for
the expected structure of this file.

Diagnostics
-----------

The ``diagnostics`` section selects the diagnostics parameter file:

.. code-block:: yaml

   diagnostics:
     params_package: sura_diagnostics
     params: config/<diagnostics_params>.yaml

If this section is omitted, SURA uses ``sura_diagnostics`` and
``config/diagnostics.yaml`` by default.

Cameras
-------

The ``cameras`` section defines the camera pipelines available for the robot:

.. code-block:: yaml

   cameras:
     front_camera:
       enabled: true
       driver: usb_cam
       aruco: false

Each camera entry defines one camera pipeline:

``enabled``
   Enables or disables that camera.

``driver``
   Selects the camera backend. The supported values are ``usb_cam`` and
   ``gstreamer``.

``aruco``
   Enables the OpenCV ArUco marker detection pipeline for that camera.

The same section is forwarded to :doc:`sura_cameras <sura_cameras>`
IMU
---

The ``imu`` section tells ``sura_imu`` which raw topics should be fused and
where to publish the filtered IMU output:

.. code-block:: yaml

   imu:
     raw_imu_topic: controller/<imu_broadcaster>/imu
     filtered_imu_topic: sensors/imu
     mag_topic: controller/<magnetometer_broadcaster>/mag

``raw_imu_topic`` and ``mag_topic`` are required. ``filtered_imu_topic`` is
optional and defaults to ``sensors/imu``.

Localization
------------

The ``localization`` section selects the localization launch file and the datum
used when real localization is active:

.. code-block:: yaml

   localization:
     launch_package: sura_localization
     launch_file: <localization_launch>.launch.py
     publish_tf: true
     datum:
       latitude: <latitude>
       longitude: <longitude>
       heading: <heading>

``launch_package``, ``launch_file`` and ``publish_tf`` are required.
``datum`` is optional; if it is not provided, the latitude, longitude and
heading are set to ``0.0``.
