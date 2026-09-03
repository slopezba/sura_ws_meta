sura_imu
========

``sura_imu`` converts raw inertial measurements into the robot orientation.

Its main mission is to take raw IMU data, such as gyroscope and accelerometer
measurements, and estimate the robot orientation. Magnetometer data can also be
used when available, but it is optional. The resulting filtered IMU topic
provides the orientation needed by localization, navigation, controllers and
diagnostics.

Role in SURA
------------

In a real robot, raw IMU data usually comes from
:doc:`sura_sensors <sura_sensors>` broadcasters, optionally together with a
magnetometer topic. ``sura_imu`` first corrects those raw measurements with the
configured calibration and then runs the attitude filter that estimates the
robot orientation.

.. raw:: html

   <svg class="bringup-flow" viewBox="0 0 980 260" role="img" aria-label="sura imu inputs, internal processing and outputs">
     <defs>
       <marker id="imu-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
         <path d="M 0 0 L 10 5 L 0 10 z" fill="#5f7280"></path>
       </marker>
     </defs>

     <text class="small-label" x="135" y="35" text-anchor="middle">INPUT</text>
     <rect class="box" x="30" y="58" width="210" height="64" rx="6"></rect>
     <text x="135" y="82" text-anchor="middle">raw IMU topic</text>
     <text class="small-label" x="135" y="102" text-anchor="middle">angular velocity + accel</text>

     <rect class="box" x="30" y="145" width="210" height="64" rx="6"></rect>
     <text x="135" y="169" text-anchor="middle">magnetometer topic</text>
     <text class="small-label" x="135" y="189" text-anchor="middle">magnetic field vector</text>

     <text class="small-label" x="505" y="35" text-anchor="middle">sura_imu package</text>
     <rect class="box" x="315" y="50" width="380" height="170" rx="8" style="stroke-dasharray: 8 6;"></rect>

     <rect class="box primary" x="350" y="78" width="150" height="64" rx="8"></rect>
     <text class="primary-label" x="425" y="104" text-anchor="middle">calibration</text>
     <text class="small-label" x="425" y="124" text-anchor="middle">bias + mag correction</text>

     <rect class="box primary" x="545" y="78" width="115" height="64" rx="8"></rect>
     <text class="primary-label" x="602" y="104" text-anchor="middle">filter</text>
     <text class="small-label" x="602" y="124" text-anchor="middle">orientation</text>

     <text class="small-label" x="505" y="181" text-anchor="middle">real mode: calibration_filter + imu_filter_madgwick</text>
     <text class="small-label" x="505" y="200" text-anchor="middle">sim mode: relay raw IMU to output</text>

     <text class="small-label" x="845" y="35" text-anchor="middle">OUTPUT</text>
     <rect class="box" x="750" y="92" width="190" height="70" rx="6"></rect>
     <text x="845" y="118" text-anchor="middle">filtered IMU topic</text>
     <text class="small-label" x="845" y="138" text-anchor="middle">accel + gyro + orientation</text>

     <path class="line" d="M240 90 H350" marker-end="url(#imu-arrow)"></path>
     <path class="line" d="M240 177 H295 V122 H350" marker-end="url(#imu-arrow)"></path>
     <path class="line" d="M500 110 H545" marker-end="url(#imu-arrow)"></path>
     <path class="line" d="M660 110 H750" marker-end="url(#imu-arrow)"></path>
   </svg>

In simulation, ``sura_imu`` skips the Madgwick filter and uses
``calibration_filter`` as a relay. This avoids estimating an attitude that is
already provided by the simulator.

In other words, the package receives angular velocity, linear acceleration and,
when available, magnetic field measurements. It publishes a filtered IMU
message that keeps the IMU measurements and adds the estimated orientation,
which represents roll, pitch and yaw.

.. warning::

   This package is still under development. In some setups the estimated
   orientation can behave incorrectly or become unstable. If that happens, one
   of the first parameters to test is ``constant_dt`` in
   ``sura_imu/config/imu_filter.yaml``, adjusting it.

Launch
------

``imu.launch.py`` starts the IMU processing pipeline. In normal robot operation
it is included by :doc:`sura_bringup <sura_bringup>`. For isolated tests, it can
also be launched manually.

There are therefore two places where the launch can be configured:

* For the full robot bringup, edit the robot ``bringup_description.yaml``.
* For a manual test, pass launch arguments directly in the terminal command.

Launch from ``sura_bringup``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

When the full robot is started with ``sura_bringup.launch.py``, the IMU topics
are read from:

.. code-block:: text

   <robot_namespace>_description/config/bringup_description.yaml

The relevant section is:

.. code-block:: yaml

   imu:
     raw_imu_topic: controller/imu_broadcaster/imu
     mag_topic: controller/magnetometer_broadcaster/mag
     filtered_imu_topic: sensors/imu

These fields mean:

``raw_imu_topic``
   Topic published by the IMU broadcaster before ``sura_imu`` processes it.
   This is the input IMU data.

``mag_topic``
   Topic published by the magnetometer broadcaster. In real mode it can be used
   by the attitude filter to help estimate yaw.

``filtered_imu_topic``
   Final topic published by ``sura_imu``. This is the topic consumed by the rest
   of SURA, such as localization, controllers and diagnostics.

``sura_bringup.launch.py`` forwards these values to ``sura_imu/imu.launch.py``
as launch arguments. The ``environment`` value is also forwarded, but it comes
from ``robot.environment`` in the same ``bringup_description.yaml`` file.

Manual launch
^^^^^^^^^^^^^

Manual launch example:

.. code-block:: bash

   ros2 launch sura_imu imu.launch.py \
     environment:=real \
     raw_imu_topic:=controller/imu_broadcaster/imu \
     mag_topic:=controller/magnetometer_broadcaster/mag \
     filtered_imu_topic:=sensors/imu

Use this form when testing ``sura_imu`` without launching the complete robot.
The command above uses relative topic names; if it is launched inside a robot
namespace, ROS 2 resolves them under that namespace.

Manual launch arguments:

``environment``
   Selects how the pipeline behaves. ``real`` starts the calibration step and
   ``imu_filter_madgwick``. ``sim`` skips the attitude filter and relays the raw
   simulator IMU to the filtered output topic.

``raw_imu_topic``
   Input ``sensor_msgs/msg/Imu`` topic. This normally matches the IMU
   broadcaster output.

``mag_topic``
   Input ``sensor_msgs/msg/MagneticField`` topic. This normally matches the
   magnetometer broadcaster output.

``calibrated_imu_topic`` and ``calibrated_mag_topic``
   Internal topics between ``calibration_filter`` and ``imu_filter_madgwick``.
   These usually do not need to be changed.

``filtered_imu_topic``
   Output ``sensor_msgs/msg/Imu`` topic used by the rest of SURA.

``use_calibration``
   Enables or disables the correction loaded from the calibration YAML. Keep it
   enabled for real hardware unless intentionally debugging raw measurements.

``calibration_yaml``
   Calibration file loaded by ``calibration_filter``. Change it only when using
   a different calibration file for the same IMU pipeline.

Package Configuration File
--------------------------

The main configuration file of this package is:

.. code-block:: text

   sura_imu/config/imu_filter.yaml

This YAML configures the ``imu_filter_madgwick_node`` used in real robots to
estimate the robot orientation from the calibrated IMU data. In normal SURA
usage, this is the file to review when the orientation estimate needs to be
tuned.

Current structure:

.. code-block:: yaml

   /**:
     ros__parameters:
       stateless: false
       use_mag: false
       publish_tf: false
       reverse_tf: false
       fixed_frame: world_ned
       constant_dt: 0.0035
       publish_debug_topics: false
       world_frame: ned
       gain: 0.1
       zeta: 0.0
       orientation_stddev: 0.02

``stateless``
   Keeps the filter state between updates. SURA normally uses ``false`` so the
   attitude estimate evolves continuously over time.

``use_mag``
   Selects whether the optional magnetometer topic is used by the attitude
   filter. When ``false``, orientation is estimated from gyroscope and
   accelerometer data only. When ``true``, magnetometer data can help correct
   yaw drift, assuming the magnetometer is available and properly calibrated.

``publish_tf`` and ``reverse_tf``
   Control whether the filter publishes a TF transform. SURA normally keeps
   ``publish_tf`` disabled because the robot TF tree is handled by the robot
   description and localization pipeline.

``fixed_frame`` and ``world_frame``
   Define the frame convention used by the filter. SURA uses ``world_frame:
   ned`` to match the marine robotics convention used in the rest of the
   stack.

``constant_dt``
   Fixed time step used by the filter. It should match the expected IMU update
   period when a constant period is preferred. If the orientation estimate is
   unstable, try tuning this value according to the measured IMU frequency.

``publish_debug_topics``
   Enables extra debug topics from the Madgwick filter. It is normally disabled
   for regular operation.

``gain``
   Main Madgwick filter gain. Higher values make the estimate react more
   strongly to accelerometer and magnetometer corrections; lower values make it
   rely more on gyroscope integration.

``zeta``
   Gyroscope drift bias gain used by the filter. The default value disables this
   correction.

``orientation_stddev``
   Orientation covariance value published in the filtered IMU message. This
   value is consumed downstream as a confidence estimate for the orientation.

Calibration File
----------------

The calibration values used before the attitude filter are stored in:

.. code-block:: text

   sura_imu/config/sura_imu_calibration.yaml

This file is generated by the calibration tools and read by
``calibration_filter``. It is not the filter tuning file: it stores measured
corrections for the specific IMU and magnetometer installation.

Main sections:

``metadata``
   Stores information about how the file was generated, including the source
   topics and calibration mode.

``gyro``
   Stores gyroscope calibration. The relevant values for runtime are
   ``bias_x``, ``bias_y`` and ``bias_z``; they are subtracted from the raw
   angular velocity.

``magnetometer``
   Stores optional magnetometer calibration. ``offset_x``, ``offset_y`` and
   ``offset_z`` correct hard-iron offset. ``scale_x``, ``scale_y`` and
   ``scale_z`` correct axis scaling.

``compass``
   Stores the optional ``yaw_offset_deg`` correction used to align the measured
   magnetic heading with the robot yaw convention.

Quality fields such as ``quality_score`` and ``quality_label`` are generated by
the calibration tools to help evaluate the result. They are useful for the user,
but the runtime correction uses the bias, offset, scale and yaw offset values.

Calibration Filter
------------------

``calibration_filter`` corrects raw IMU and magnetometer messages before the
attitude filter receives them.

It can apply:

- gyroscope bias removal;
- magnetometer offset correction;
- magnetometer scale correction;
- compass yaw offset correction.

The calibration values come from ``sura_imu/config/sura_imu_calibration.yaml``.

Attitude Filter
---------------

In real mode, the launch starts ``imu_filter_madgwick_node`` from
`imu_filter_madgwick <https://docs.ros.org/en/humble/p/imu_filter_madgwick/>`_.
This node estimates the robot orientation from the calibrated gyroscope,
accelerometer and magnetometer data.

Its parameters are stored in ``sura_imu/config/imu_filter.yaml``.

Calibration Tools
-----------------

``sura_imu`` provides calibration tools for preparing the calibration YAML:

``calibration_wizard``
   Interactive calibration flow for gyro, magnetometer and compass offset.

``calibrate_gyro``
   Gyroscope-only calibration.

``calibrate_magnetometer``
   Magnetometer-only calibration.

``calibrate_compass``
   Compass/yaw-offset calibration.

Typical wizard command:

.. code-block:: bash

   ros2 run sura_imu calibration_wizard \
     --robot-namespace <robot_namespace> \
     --output src/sura_imu/config/sura_imu_calibration.yaml

When ``--robot-namespace`` is provided, the wizard can look for the robot
bringup description at:

.. code-block:: text

   <robot_namespace>_description/config/bringup_description.yaml

Use calibration again when the IMU mounting changes, the magnetometer is moved,
or the vehicle magnetic environment changes significantly.

Useful Checks
-------------

After launching the IMU pipeline:

.. code-block:: bash

   ros2 topic echo sensors/imu
   ros2 topic hz sensors/imu
   ros2 topic echo imu/mag

If the filtered IMU topic is missing, first check that the raw broadcaster
topics exist and that ``environment`` is set correctly.
