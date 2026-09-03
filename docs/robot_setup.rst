Robot Setup
===========

The intended robot setup runs SURA inside Docker on the onboard computer.
Vehicle-specific setup pages describe the configuration expected for supported
platforms and for custom integrations.

.. toctree::
   :maxdepth: 1

   bluerov_setup
   blueboat_setup
   custom_robot

The container mounts the workspace, uses host networking and host IPC, and has
access to the robot devices. It does not launch any ROS 2 package automatically.

Useful runtime commands include:

.. code-block:: bash

   sura status
   sura logs
   sura config
   sura reconfigure
   sura doctor
