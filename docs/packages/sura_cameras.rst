sura_cameras
============

``sura_cameras`` provides the camera launch pipelines used by SURA. For real
cameras, it supports a ROS image pipeline with ``usb_cam`` and a low-latency
GStreamer streaming pipeline. It can also republish simulated camera images and
optionally launch image processing stages such as decimation and ArUco marker
detection.

This package is normally launched through ``sura_perception.launch.py`` from
the user's computer. The list of cameras to launch is read from the robot
description package, in:

.. code-block:: text

   <robot_namespace>_description/config/bringup_description.yaml

under the ``cameras`` section.

Camera Selection
----------------

The ``cameras`` section decides which camera pipelines are started:

.. code-block:: yaml

   cameras:
     down_camera:
       enabled: true
       driver: usb_cam
       aruco: true

     front_camera:
       enabled: false
       driver: usb_cam
       aruco: false

``enabled``
   Starts or skips that camera.

``driver``
   Selects the real-camera backend. Supported values are ``usb_cam`` and
   ``gstreamer``.

``aruco``
   Starts OpenCV ArUco marker detection for that camera when an
   ``aruco_tracker.yaml`` file exists in the camera configuration folder.

The camera names, such as ``down_camera`` or ``front_camera``, must match a
folder under ``sura_cameras/config/``.

Launch Files
------------

``cameras.launch.py``
   Launches all enabled cameras from the ``cameras`` dictionary. For each
   enabled camera, it loads ``single_camera.launch.py`` with the matching
   configuration folder.

``single_camera.launch.py``
   Launches one camera pipeline. It selects the source from ``environment`` and
   ``driver``:

   * ``real`` with ``usb_cam`` starts ``usb_cam_node_exe`` and publishes ROS
     camera topics.
   * ``real`` with ``gstreamer`` starts a low-latency H.264 UDP stream using
     ``gst-launch-1.0``.
   * ``sim`` starts ``sim_camera_republisher`` and republishes simulator images
     using the same ROS topic structure as a real camera.

In real mode, ArUco and decimation are only available through the ``usb_cam``
ROS pipeline. The GStreamer path is intended for video streaming.

Pipeline Outputs
----------------

For each camera, the ROS pipeline uses the camera namespace:

.. code-block:: text

   <camera_name>/camera/

The main outputs are:

.. code-block:: text

   image_raw
   image_raw/compressed
   camera_info

If decimation is enabled, ``image_decimator`` also publishes:

.. code-block:: text

   decimated/image_raw
   decimated/camera_info

Camera Configuration
--------------------

Each camera has a configuration folder:

.. code-block:: text

   sura_cameras/config/<camera_name>/
     camera.yaml
     calibration.yaml
     aruco_tracker.yaml

``camera.yaml`` defines the camera source and optional processing stages:

.. code-block:: yaml

   name: <camera_name>
   driver: usb_cam
   port: /dev/video0
   frame_id: <robot_namespace>/<camera_frame>/optical_frame

   width: 640
   height: 360
   framerate: 10.0
   pixel_format: mjpeg2rgb
   io_method: mmap

   stonefish_topic: /<robot_namespace>/stonefish/<camera_name>/image_color

   gstreamer:
     width: 1280
     height: 720
     framerate: 15
     host: <receiver_ip>
     port: 5600
     bitrate: 3500
     key_int_max: 15
     threads: 2

   decimated:
     enabled: false
     width: 320
     height: 180
     decimation_x: 2
     decimation_y: 2
     offset_x: 0
     offset_y: 0

Important fields:

``port``
   Video device used in ``real`` mode, for example ``/dev/video0``.

``frame_id``
   Optical frame used in image headers.

``width``, ``height`` and ``framerate``
   Camera resolution and frame rate. These values must be supported by the
   selected camera and driver.

``stonefish_topic``
   Simulator image topic used in ``sim`` mode.

``gstreamer``
   UDP streaming configuration used when ``driver`` is ``gstreamer``.

``decimated``
   Optional reduced-resolution image stream.

Calibration
-----------

``calibration.yaml`` is prepared to work with the ROS 2
`camera_calibration <https://docs.ros.org/en/kilted/p/camera_calibration/doc/tutorial_mono.html>`_
workflow and the standard ``camera_info_url`` mechanism used by ROS camera
drivers.

If ``calibration.yaml`` exists and contains an entry matching the active camera
resolution, ``single_camera.launch.py`` writes that entry to a temporary camera
info YAML and passes it to the camera pipeline as ``camera_info_url``. This is
used both by the ``usb_cam`` real-camera path and by the simulated camera
republisher.

The key must follow this format:

.. code-block:: yaml

   calibrated: true

   calibration_640x360:
     image_width: 640
     image_height: 360
     camera_name: down_camera
     camera_matrix:
       rows: 3
       cols: 3
       data: [...]

For a ``640x360`` camera, the expected key is ``calibration_640x360``.

ArUco Detection
---------------

When ``aruco: true`` is set for a camera, ``single_camera.launch.py`` checks for
``aruco_tracker.yaml`` and launches ``aruco_opencv/aruco_tracker_autostart``.

The ArUco configuration lives next to ``camera.yaml``:

.. code-block:: text

   sura_cameras/config/<camera_name>/aruco_tracker.yaml

It defines the marker dictionary, marker size, input topic behavior and output
settings used by ``aruco_opencv``.

Usage
-----

In the full SURA system, cameras are normally launched with:

.. code-block:: bash

   ros2 launch sura_bringup sura_perception.launch.py \
     robot_namespace:=<robot_namespace>

For direct testing, ``sura_cameras`` can be launched manually:

.. code-block:: bash

   ros2 launch sura_cameras cameras.launch.py \
     environment:=real \
     cameras:="{down_camera: {enabled: true, driver: usb_cam, aruco: true}}"

Adding a New Camera
-------------------

1. Create a new configuration folder:

   .. code-block:: text

      sura_cameras/config/<camera_name>/

2. Add ``camera.yaml`` with the device, frame, resolution and simulator topic.

3. Add ``calibration.yaml`` if calibration is available.

4. Add ``aruco_tracker.yaml`` if ArUco detection is needed.

5. Enable the camera from
   ``<robot_namespace>_description/config/bringup_description.yaml``:

   .. code-block:: yaml

      cameras:
        <camera_name>:
          enabled: true
          driver: usb_cam
          aruco: false

6. Test the camera with ``sura_perception.launch.py`` or directly with
   ``cameras.launch.py``.
