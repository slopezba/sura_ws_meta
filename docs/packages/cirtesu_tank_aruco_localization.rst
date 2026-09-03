cirtesu_tank_aruco_localization
===============================

``cirtesu_tank_aruco_localization`` estimates the robot position inside the
CIRTESU tank using ArUco markers placed on the floor.

The package receives the ArUco detections from the downward camera. Each marker
has a known position in the tank map, so when the camera detects one or more
markers, the node computes where the robot must be with respect to the tank.
The result is published as a pose that can be used by the localization stack.

.. raw:: html

   <svg class="bringup-flow" viewBox="0 0 920 170" role="img" aria-label="cirtesu tank aruco localization flow">
     <defs>
       <marker id="tank-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
         <path d="M 0 0 L 10 5 L 0 10 z" fill="#5f7280"></path>
       </marker>
     </defs>

     <rect class="box" x="25" y="54" width="180" height="62" rx="6"></rect>
     <text x="115" y="79" text-anchor="middle">floor ArUcos</text>
     <text class="small-label" x="115" y="99" text-anchor="middle">known tank map</text>

     <rect class="box source" x="260" y="54" width="190" height="62" rx="6"></rect>
     <text x="355" y="79" text-anchor="middle">down camera</text>
     <text class="small-label" x="355" y="99" text-anchor="middle">ArUco detections</text>

     <rect class="box primary" x="505" y="38" width="190" height="94" rx="8"></rect>
     <text class="primary-label" x="600" y="70" text-anchor="middle">tank localization</text>
     <text class="small-label" x="600" y="94" text-anchor="middle">matches marker IDs</text>
     <text class="small-label" x="600" y="114" text-anchor="middle">filters pose</text>

     <rect class="box" x="750" y="54" width="145" height="62" rx="6"></rect>
     <text x="822" y="79" text-anchor="middle">robot pose</text>
     <text class="small-label" x="822" y="99" text-anchor="middle">x, y, z, yaw</text>

     <path class="line" d="M205 85 H260" marker-end="url(#tank-arrow)"></path>
     <path class="line" d="M450 85 H505" marker-end="url(#tank-arrow)"></path>
     <path class="line" d="M695 85 H750" marker-end="url(#tank-arrow)"></path>
   </svg>

What It Uses
------------

The node needs:

``down_camera/aruco_detections``
   ArUco detections from the downward camera.

``aruco_map``
   Position of each marker in the tank reference frame. The current map is
   adjusted for the CIRTESU tank.

TF between ``base_link`` and ``camera_down/optical_frame``
   Used to know where the camera is mounted on the robot.

TF between ``world_ned`` and ``cirtesu_tank``
   Used to express the final pose in the world frame.

What It Publishes
-----------------

``sensors/aruco/pose_enu``
   Estimated robot pose from the tank ArUcos, as
   ``geometry_msgs/msg/PoseWithCovarianceStamped``. The pose contains position
   and orientation around yaw.

``aruco/markers``
   Visualization markers for RViz. They show the tank mesh and the ArUco map,
   highlighting the markers currently detected by the camera.

Tank Adjustment
---------------

The default configuration is made for the CIRTESU tank. To use the same package
in another tank or with a different marker layout, modify
``config/aruco_map.yaml``.

``aruco_map``
   Main parameter to change. Each marker ID contains ``[x, y, z, yaw]`` in the
   tank frame. These values must match the real position and orientation of the
   ArUcos on the floor.

``marker_frame`` and ``world_frame``
   Frames used for the tank map and the output pose.

``base_frame`` and ``camera_frame``
   Frames used to transform detections from the camera to the robot body. Change
   them if the robot or camera frame names are different.

``aruco_topic``, ``pose_topic`` and ``marker_topic``
   Input and output topics. Change them if the camera pipeline or localization
   stack uses different topic names.

``mesh_path``, ``mesh_scale``, ``mesh_pos`` and ``mesh_yaw``
   RViz visualization of the tank. These only affect the displayed mesh, not the
   localization calculation.

``alpha_pos`` and ``alpha_yaw``
   Smoothing applied to the estimated position and yaw. Higher values react
   faster; lower values make the pose smoother.

``pose_covariance_xy``, ``pose_covariance_z`` and ``pose_covariance_yaw``
   Covariance values published with the pose. Increase them if the ArUco pose is
   noisy or should be trusted less by the localization filter.
