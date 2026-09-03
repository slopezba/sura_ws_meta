Installation
============

The intended onboard setup starts with a Raspberry Pi connected to the
`Blue Robotics Navigator <https://bluerobotics.com/store/comm-control-power/control/navigator/>`_
flight controller and a microSD card, preferably **128 GB**. The card should
contain a Raspberry Pi OS/Raspbian-based system prepared for the robot. Once the
board boots, the complete SURA runtime runs inside Docker on the robot.

Install Docker
--------------

Install Docker on the Raspberry Pi:

.. code-block:: bash

   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker "$USER"

Clone SURA
----------

Clone the workspace and enter it:

.. code-block:: bash

   git clone https://github.com/slopezba/sura_ws_meta.git
   cd sura_ws_meta

Install the Command
-------------------

Run the installer from the repository root:

.. code-block:: bash

   ./install.sh

This installs the ``sura`` command globally by linking ``bin/sura`` into
``/usr/local/bin/sura``.

Start the Runtime
-----------------

Start the Docker runtime:

.. code-block:: bash

   sura start

On the first run, the command asks for:

* Robot name.
* ``ROS_DOMAIN_ID``.
* DDS middleware: ``CycloneDDS`` is recommended, although ``FastDDS`` is also
  supported.

Open a Shell
------------

To open an interactive terminal inside the container:

.. code-block:: bash

   sura shell

Stop the Runtime
----------------

To stop and remove the Docker runtime:

.. code-block:: bash

   sura stop
