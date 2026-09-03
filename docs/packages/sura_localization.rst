sura_localization
=================

``sura_localization`` is the localization layer used by SURA when the full robot
is launched. It takes the available sensor measurements, prepares them for
``robot_localization`` and publishes the robot odometry used by navigation,
controllers and diagnostics.

For a normal user, this package is configured from the robot bringup profile. It
is not usually launched by hand.

What It Does
------------

The package converts SURA sensor data into the conventions expected by the EKF,
fuses the selected measurements with ``robot_localization`` and publishes the
final odometry back in the convention used by the rest of SURA.

Marine robots commonly use NED/FRD conventions, while ROS localization tools
usually work with ENU/FLU. Because of that, the EKF runs in ENU and the result is
converted back to NED before it is consumed by the rest of the underwater stack.

.. raw:: html

   <svg class="bringup-flow" viewBox="0 0 1040 310" role="img" aria-label="sura localization inputs, processing and outputs">
     <defs>
       <marker id="loc-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
         <path d="M 0 0 L 10 5 L 0 10 z" fill="#5f7280"></path>
       </marker>
     </defs>

     <text class="small-label" x="150" y="35" text-anchor="middle">INPUT</text>
     <rect class="box" x="35" y="55" width="230" height="52" rx="6"></rect>
     <text x="150" y="77" text-anchor="middle">IMU NED/FRD</text>
     <text class="small-label" x="150" y="94" text-anchor="middle">orientation + gyro + accel</text>

     <rect class="box" x="35" y="122" width="230" height="52" rx="6"></rect>
     <text x="150" y="144" text-anchor="middle">pressure</text>
     <text class="small-label" x="150" y="161" text-anchor="middle">depth / z position</text>

     <rect class="box" x="35" y="189" width="230" height="52" rx="6"></rect>
     <text x="150" y="211" text-anchor="middle">GPS, DVL, ArUco</text>
     <text class="small-label" x="150" y="228" text-anchor="middle">position and velocity aids</text>

     <text class="small-label" x="535" y="35" text-anchor="middle">sura_localization package</text>
     <rect class="box" x="315" y="50" width="440" height="210" rx="8" style="stroke-dasharray: 8 6;"></rect>

     <rect class="box primary" x="350" y="74" width="165" height="58" rx="8"></rect>
     <text class="primary-label" x="432" y="99" text-anchor="middle">converters</text>
     <text class="small-label" x="432" y="117" text-anchor="middle">frames and message types</text>

     <rect class="box primary" x="350" y="158" width="165" height="58" rx="8"></rect>
     <text class="primary-label" x="432" y="183" text-anchor="middle">sensor adapters</text>
     <text class="small-label" x="432" y="201" text-anchor="middle">pressure to pose</text>

     <rect class="box primary" x="560" y="112" width="155" height="68" rx="8"></rect>
     <text class="primary-label" x="637" y="139" text-anchor="middle">EKF</text>
     <text class="small-label" x="637" y="158" text-anchor="middle">robot_localization</text>

     <text class="small-label" x="890" y="35" text-anchor="middle">OUTPUT</text>
     <rect class="box" x="805" y="92" width="180" height="60" rx="6"></rect>
     <text x="895" y="117" text-anchor="middle">filtered odometry</text>
     <text class="small-label" x="895" y="136" text-anchor="middle">ENU estimate</text>

     <rect class="box" x="805" y="174" width="180" height="60" rx="6"></rect>
     <text x="895" y="199" text-anchor="middle">NED odometry</text>
     <text class="small-label" x="895" y="218" text-anchor="middle">for SURA navigation</text>

     <path class="line" d="M265 81 H350" marker-end="url(#loc-arrow)"></path>
     <path class="line" d="M265 148 H350" marker-end="url(#loc-arrow)"></path>
     <path class="line" d="M265 215 H312 V146 H560" marker-end="url(#loc-arrow)"></path>
     <path class="line" d="M515 103 H560" marker-end="url(#loc-arrow)"></path>
     <path class="line" d="M515 187 H538 V154 H560" marker-end="url(#loc-arrow)"></path>
     <path class="line" d="M715 146 H805" marker-end="url(#loc-arrow)"></path>
     <path class="line" d="M895 152 V174" marker-end="url(#loc-arrow)"></path>
   </svg>

Full SURA Launch
----------------

Start localization through the complete SURA bringup:

.. code-block:: bash

   ros2 launch sura_bringup sura_bringup.launch.py \
     robot_namespace:=<robot_namespace>

The ``robot_namespace`` selects this file:

.. code-block:: text

   <robot_namespace>_description/config/bringup_description.yaml

That file is the user-facing place to decide whether real localization is used
and which localization pipeline is started.

Bringup Profile
^^^^^^^^^^^^^^^

In the ``robot`` section, ``localization: real`` enables the real localization
pipeline:

.. code-block:: yaml

   robot:
     name: <robot_namespace>
     environment: real
     localization: real

When ``localization`` is ``real``, ``sura_bringup`` includes the localization
launch selected below. When ``localization`` is ``sim``, the real localization
pipeline is not used.

The ``localization`` section selects the launch file that is included by the
full bringup:

.. code-block:: yaml

   localization:
     launch_package: sura_localization
     launch_file: cirtesu_auv_localization.launch.py
     publish_tf: true
     datum:
       latitude: <latitude>
       longitude: <longitude>
       heading: <heading>

``launch_package``
   Package that contains the localization launch file.

``launch_file``
   Localization pipeline to start. This is the main choice a user makes.

``publish_tf``
   Whether the EKF publishes the localization TF.

``datum``
   Geographic reference used by GPS localization. ``sura_bringup`` forwards it
   as ``datum_latitude``, ``datum_longitude`` and ``datum_heading``.

Available Pipelines
-------------------

``auv_localization.launch.py``
   Generic underwater pipeline. It can use IMU, pressure, GPS and DVL. It starts
   the frame converters, pressure-to-pose conversion, optional GPS conversion,
   the EKF and the final ENU-to-NED odometry conversion.

``cirtesu_auv_localization.launch.py``
   CIRTESU tank pipeline. It wraps the generic AUV pipeline, adds the ArUco tank
   localization node, adds the static transform to the tank frame and uses
   CIRTESU-specific pressure calibration defaults.

``surface_fastlio.launch.py``
   Pipeline used by the surface robot with FAST-LIO. It uses
   ``ekf_surface_fastlio.yaml`` and also starts ``sura_sensors/gps_anchor_node``.

What To Check
-------------

After launching the full bringup, the main localization output should be:

.. code-block:: text

   /<robot_namespace>/odometry/filtered

Useful checks:

.. code-block:: bash

   ros2 topic echo /<robot_namespace>/odometry/filtered --once
   ros2 topic hz /<robot_namespace>/odometry/filtered

Useful intermediate topics:

``/<robot_namespace>/sensors/imu_enu``
   IMU converted to ENU/FLU for ``robot_localization``.

``/<robot_namespace>/sensors/pressure/pose``
   Pressure converted into a Z pose measurement.

``/<robot_namespace>/sensors/gps/odometry``
   GPS odometry produced by ``navsat_transform_node`` when GPS is enabled.

``/<robot_namespace>/odometry/filtered_enu``
   EKF output before conversion back to NED.

Configuration YAML Files
------------------------

There are two different YAML layers:

``bringup_description.yaml``
   Selects which localization launch file the complete SURA bringup starts.

``sura_localization/config/*.yaml``
   Configures what the EKF fuses once that localization launch is running.

The localization config YAML does not start nodes by itself. It is passed to
``robot_localization`` by the selected launch file.

Localization Config YAML Structure
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Most localization config files contain an EKF section and, when GPS is used, a
``navsat_transform_node`` section:

.. code-block:: yaml

   ekf_filter_node:
     ros__parameters:
       frequency: 50.0
       sensor_timeout: 0.2
       two_d_mode: false
       publish_tf: true
       map_frame: <robot_namespace>/map
       odom_frame: <robot_namespace>/odom
       base_link_frame: <robot_namespace>/base_link
       world_frame: <robot_namespace>/map

       pose0: sensors/pressure/pose
       pose0_config: [...]

       odom0: sensors/gps/odometry
       odom0_config: [...]

       twist0: sensors/dvl/twist
       twist0_config: [...]

       imu0: sensors/imu_enu
       imu0_config: [...]

   navsat_transform_node:
     ros__parameters:
       frequency: 10.0
       use_odometry_yaw: true
       wait_for_datum: false

``ekf_filter_node``
   Main Extended Kalman Filter. It publishes the fused odometry.

``navsat_transform_node``
   Converts GPS fixes into odometry that can be fused by the EKF.

Global EKF Parameters
^^^^^^^^^^^^^^^^^^^^^

``frequency``
   EKF update frequency in Hz.

``sensor_timeout``
   Maximum age of a measurement before that sensor is considered stale.

``two_d_mode``
   Forces planar localization. This is useful for some surface setups, but not
   for normal underwater 3D motion.

``publish_tf``
   Whether the EKF publishes TF. The full bringup can override this with the
   ``publish_tf`` value from ``bringup_description.yaml``.

``map_frame``, ``odom_frame``, ``base_link_frame`` and ``world_frame``
   Frames used by ``robot_localization``. The launch files may override these
   with namespaced values.

Sensor Inputs In The EKF
^^^^^^^^^^^^^^^^^^^^^^^^

The EKF reads sensors through numbered entries:

``poseN``
   Pose input. In the current configs this is used for pressure-derived Z and
   CIRTESU ArUco pose.

``odomN``
   Odometry input. This is used for GPS odometry or FAST-LIO odometry.

``twistN``
   Velocity input. In the underwater configs this is used for DVL velocity.

``imuN``
   IMU input. In SURA this should normally be ``sensors/imu_enu`` because the
   EKF expects ENU/FLU data.

The ``N`` is only an index. For example, ``pose0`` and ``pose1`` are two
different pose sources.

How ``*_config`` Works
^^^^^^^^^^^^^^^^^^^^^^

Every sensor entry has a matching ``*_config`` list. This list tells the EKF
which variables from that sensor should be trusted:

.. code-block:: text

   [x, y, z,
    roll, pitch, yaw,
    vx, vy, vz,
    vroll, vpitch, vyaw,
    ax, ay, az]

``true`` means that variable is fused. ``false`` means it is ignored.

Pressure example: fuse only Z.

.. code-block:: yaml

   pose0: sensors/pressure/pose
   pose0_config: [false, false, true,
                  false, false, false,
                  false, false, false,
                  false, false, false,
                  false, false, false]

DVL example: fuse X and Y velocity.

.. code-block:: yaml

   twist0: sensors/dvl/twist
   twist0_config: [false, false, false,
                   false, false, false,
                   true,  true,  false,
                   false, false, false,
                   false, false, false]

IMU example: fuse roll, pitch and yaw.

.. code-block:: yaml

   imu0: sensors/imu_enu
   imu0_config: [false, false, false,
                 true,  true,  true,
                 false, false, false,
                 false, false, false,
                 false, false, false]

Other Sensor Parameters
^^^^^^^^^^^^^^^^^^^^^^^

``*_differential``
   Uses the difference between consecutive measurements instead of the absolute
   measurement.

``*_relative``
   Treats the first measurement as the local reference.

``*_queue_size``
   Subscription queue size for that sensor.

``*_rejection_threshold``
   Rejects measurements that are too far from the current estimate. This is
   useful for noisy or intermittent sources such as vision pose.

``imuN_remove_gravitational_acceleration``
   Controls whether gravity is removed from IMU acceleration before fusion.

Existing Config Profiles
^^^^^^^^^^^^^^^^^^^^^^^^

``config/auv_localization.yaml``
   Generic AUV profile. It fuses pressure Z, GPS odometry XY, DVL velocity XY
   and converted IMU orientation from ``sensors/imu_enu``.

``config/cirtesu_auv_localization.yaml``
   CIRTESU tank profile. It fuses pressure Z, ArUco X/Y and yaw, GPS odometry
   XY, DVL velocity XY and IMU orientation.

``config/ekf_surface_fastlio.yaml``
   Surface FAST-LIO profile. It runs in ``two_d_mode`` and fuses
   ``fastlio/odometry``.

``config/ekf_with_depth.yaml`` and ``config/ekf_imu_only.yaml``
   Simpler profiles that use depth and IMU, or only IMU. They are installed with
   the package but are not selected by the main launch defaults.

Custom Localization
-------------------

Custom localization should still follow the same SURA contract:

* ``sura_bringup`` starts one localization launch file.
* The EKF YAML selects which sensor variables are fused.
* The final odometry for the rest of SURA is
  ``/<robot_namespace>/odometry/filtered``.

Custom YAML With The Standard Pipeline
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

When the generic AUV pipeline is enough but the robot needs a different EKF
configuration, the custom part is usually the YAML file. A typical custom YAML
starts from the closest existing file in ``sura_localization/config`` and
changes the sensor topics and ``*_config`` lists for the robot.

Because ``sura_bringup`` selects a localization launch file, the custom YAML is
usually connected through a small wrapper launch. The wrapper includes
``auv_localization.launch.py`` and passes the custom ``config_file``.

Wrapper example:

.. code-block:: python

   import os

   from ament_index_python.packages import get_package_share_directory
   from launch import LaunchDescription
   from launch.actions import IncludeLaunchDescription
   from launch.launch_description_sources import PythonLaunchDescriptionSource
   from launch.substitutions import LaunchConfiguration


   def generate_launch_description():
       auv_launch = os.path.join(
           get_package_share_directory("sura_localization"),
           "launch",
           "auv_localization.launch.py",
       )

       return LaunchDescription([
           IncludeLaunchDescription(
               PythonLaunchDescriptionSource(auv_launch),
               launch_arguments=[
                   ("robot_namespace", LaunchConfiguration("robot_namespace")),
                   ("publish_tf", LaunchConfiguration("publish_tf")),
                   ("datum_latitude", LaunchConfiguration("datum_latitude")),
                   ("datum_longitude", LaunchConfiguration("datum_longitude")),
                   ("datum_heading", LaunchConfiguration("datum_heading")),
                   ("config_package", "sura_localization"),
                   ("config_file", "config/my_robot_localization.yaml"),
               ],
           ),
       ])

The robot profile then selects the wrapper:

.. code-block:: yaml

   robot:
     name: <robot_namespace>
     environment: real
     localization: real

   localization:
     launch_package: sura_localization
     launch_file: my_robot_localization.launch.py
     publish_tf: true
     datum:
       latitude: <latitude>
       longitude: <longitude>
       heading: <heading>

Custom Nodes Or New Sensors
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Create a new localization launch file when the robot needs different converters,
different sensor preparation nodes or extra localization sources. The new launch
file can still include ``auv_localization.launch.py`` for the common EKF path,
or it can start its own EKF and converters directly.

Keep these outputs compatible with the rest of SURA:

``/<robot_namespace>/odometry/filtered_enu``
   EKF odometry in ENU, before conversion.

``/<robot_namespace>/odometry/filtered``
   Final odometry in NED, consumed by SURA navigation.

Runtime Nodes
-------------

``imu_ned_to_enu``
   Converts ``sensor_msgs/msg/Imu`` from NED/FRD to ENU/FLU. It converts
   orientation, angular velocity, linear acceleration and covariance.

``pressure_to_pose``
   Converts ``sensor_msgs/msg/FluidPressure`` into
   ``geometry_msgs/msg/PoseWithCovarianceStamped``. The output pose only carries
   depth as Z position.

``enu_to_ned_odometry``
   Converts ``nav_msgs/msg/Odometry`` from ENU to NED. It swaps X/Y, flips Z,
   rotates orientation and transforms covariance.

Topic Summary
-------------

Common inputs:

* ``sensors/imu``: NED/FRD IMU input.
* ``sensors/pressure``: pressure sensor input.
* ``sensors/gps``: GPS fix input used by ``navsat_transform_node``.
* ``sensors/gps/odometry``: GPS odometry used by the EKF.
* ``sensors/dvl/twist``: DVL velocity input.
* ``sensors/aruco/pose_enu``: CIRTESU tank ArUco pose input.

Common outputs:

* ``sensors/imu_enu``: converted IMU for ``robot_localization``.
* ``sensors/pressure/pose``: pressure-derived Z pose.
* ``sensors/gps/odometry``: GPS odometry from ``navsat_transform_node``.
* ``odometry/filtered_enu``: EKF output in ENU.
* ``odometry/filtered``: final odometry converted back to NED.

Build
-----

Build this package from the workspace root:

.. code-block:: bash

   colcon build --packages-select sura_localization

Then source the workspace:

.. code-block:: bash

   source install/setup.bash
