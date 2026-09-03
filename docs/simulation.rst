Simulation
==========

SURA is designed to run onboard real robots, but the same architecture can also
be used with different simulation environments. To make this easier, SURA
provides a Docker-based setup that packages the simulator dependencies and keeps
the host system clean.

The first supported example uses `Stonefish <https://stonefish.readthedocs.io/en/latest/>`_,
an advanced simulation tool developed for marine robotics. Stonefish was chosen
because it combines physics simulation with realistic marine and underwater
rendering, includes hydrodynamics based on body geometry, and can be integrated
with ROS through ``stonefish_ros``.

This simulation setup requires a GPU. The Docker Compose configuration below is
prepared for NVIDIA GPUs and expects the host to have the NVIDIA container
runtime available.

Create the Docker Compose File
------------------------------

Create a ``docker-compose.yml`` file with the following content:

.. code-block:: yaml

   services:
     sura_stonefish:
       image: inesperez03/sura-stonefish-ros2-humble:latest
       container_name: sura_stonefish

       network_mode: host
       ipc: host

       stdin_open: true
       tty: true

       environment:
         NVIDIA_DRIVER_CAPABILITIES: all
         DISPLAY: ${DISPLAY}
         XDG_RUNTIME_DIR: /tmp/runtime-root
         SDL_VIDEODRIVER: x11
         ROS_DOMAIN_ID: <SURA_ROS_DOMAIN_ID>
         RMW_IMPLEMENTATION: <SURA_RMW_IMPLEMENTATION>

       volumes:
         - /tmp/.X11-unix:/tmp/.X11-unix:rw
         - /dev/input:/dev/input

       device_cgroup_rules:
         - "c 13:* rmw"

       deploy:
         resources:
           reservations:
             devices:
               - driver: nvidia
                 count: all
                 capabilities: [gpu]

       command: sleep infinity

.. note::

   Replace ``<SURA_ROS_DOMAIN_ID>`` with the ``ROS_DOMAIN_ID`` selected when
   configuring SURA. Replace ``<SURA_RMW_IMPLEMENTATION>`` with the DDS
   middleware selected for SURA, for example ``rmw_cyclonedds_cpp`` when using
   CycloneDDS or ``rmw_fastrtps_cpp`` when using FastDDS.

Start the Container
-------------------

Allow the container to access the graphical display:

.. code-block:: bash

   xhost +si:localuser:root

Start the simulation container:

.. code-block:: bash

   docker compose up -d

Open a terminal inside the container:

.. code-block:: bash

   docker exec -it sura_stonefish bash

Launch an Example Simulation
----------------------------

Inside the container, launch the BlueROV Stonefish example:

.. code-block:: bash

   cd stonefish_environments
   ros2 launch bluerov_stonefish bluerov_cirtesu.launch.py
