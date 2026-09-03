Thrusters
=========

Thrusters are handled by ``sura_hardware_interface/ThrustersSystem``. This is a
ROS 2 Control ``SystemInterface`` that receives one ``effort`` command per
thruster and sends the corresponding output to the selected backend.

In practice, each thruster is declared as a joint in the robot xacro:

.. code-block:: xml

   <ros2_control name="$(arg robot_name)_thrusters" type="system">
     <hardware>
       <plugin>sura_hardware_interface/ThrustersSystem</plugin>
       <param name="environment">$(arg environment)</param>
     </hardware>

     <joint name="$(arg robot_name)/<thruster_frame>">
       <command_interface name="effort"/>
       <state_interface name="effort"/>
       <param name="lookup_csv">config/<thruster_lookup>.csv</param>
       <param name="stonefish_topic">/$(arg robot_name)/controller/thruster_setpoints_sim</param>
       <param name="inverted">false</param>
       <param name="pwm_offset">0.0</param>
       <param name="channel">0</param>
     </joint>
   </ros2_control>

More ``joint`` entries can be added inside the same ``ros2_control`` block, one
for each thruster mounted on the robot.

What ThrustersSystem Does
-------------------------

``ThrustersSystem`` exposes the same ROS 2 Control interface for simulation and
real hardware:

* command interface: ``<thruster_joint>/effort``
* state interface: ``<thruster_joint>/effort``

Controllers write force commands in newtons to the ``effort`` command
interfaces. ``ThrustersSystem`` filters the commands if configured, stores the
filtered force as the state, and maps the force through a lookup table.

In ``sim`` mode, the lookup table converts the force command into the value
expected by Stonefish and publishes all thruster outputs to
``stonefish_topic``.

.. note::

   In simulation, the thruster joints in the robot description must follow the
   same order as the thrusters defined in the Stonefish ``.scn`` file. The
   command array is published in that order, so a mismatch can send each command
   to the wrong simulated thruster.

In ``real`` mode, the lookup table converts the force command into PWM pulse
widths. The interface then uses the `Blue Robotics Navigator library
<https://github.com/bluerobotics/navigator-lib>`_ to initialize the PWM backend
and write those PWM commands to the configured Navigator channels. When the
interface is deactivated, cleaned up, shut down or enters an error state, it
sends neutral commands and disables the PWM output.

Lookup CSV
----------

The lookup CSV describes the response of a thruster model. SURA controllers
command thrusters in newtons, but the backend needs a different value depending
on the environment:

* in ``real`` mode, the output is a PWM pulse width for the Navigator.
* in ``sim`` mode, the output is the command value expected by Stonefish.

Each row of the CSV relates these values:

.. code-block:: text

   pwm_us,force_n,stonefish
   1500,0.0,0.0
   ...

``ThrustersSystem`` loads this CSV once during configuration and stores the
samples in memory. During control, it does not read the file again; it only
interpolates between the loaded samples to convert each force command into PWM
or Stonefish output.

The lookup is usually linked to the thruster model and supply voltage. For
example, a T200 at 16 V and a T500 at 22 V use different lookup files.

Available lookup models
^^^^^^^^^^^^^^^^^^^^^^^

The currently available thruster lookup models are:

* `A50 <https://rov-expert.com>`_ at 24 V: ``config/a50_lookup.csv``
* `M200 <https://bluerobotics.com/store/thrusters/t100-t200-thrusters/m200-motor/>`_
  at 16 V: ``config/m200_lookup.csv``
* `T200 <https://bluerobotics.com/store/thrusters/t100-t200-thrusters/t200-thruster-r2-rp/>`_
  at 16 V: ``config/t200_lookup.csv``
* `T500 <https://bluerobotics.com/store/thrusters/t100-t200-thrusters/t500-thruster/>`_
  at 22 V: ``config/t500_lookup.csv``

Required Parameters
-------------------

``environment``
   Hardware-level parameter. It must be ``sim`` or ``real`` and selects whether
   the output goes to Stonefish or to the Navigator.

``lookup_csv``
   Per-thruster parameter. It selects the lookup table used to convert force
   commands into PWM values for real hardware and Stonefish values for
   simulation. All thrusters in the same ``ThrustersSystem`` must use the same
   lookup table.

``stonefish_topic``
   Required in ``sim`` mode. It is the topic where the simulated thruster
   command array is published.

``inverted``
   Required in ``real`` mode and optional in ``sim`` mode. It reverses the
   thruster output direction. In real mode this is applied by mirroring the PWM
   command around the neutral value.

``channel``
   Required in ``real`` mode. It selects the PWM channel in the Blue Robotics
   Navigator for that thruster. This value must match the physical output where
   the ESC signal is connected.

``pwm_offset``
   Optional per-thruster PWM correction in microseconds. It is normally ``0.0``
   unless a specific thruster needs calibration.

Optional Hardware Parameters
----------------------------

``thruster_lpf_alpha``
   Low-pass filter coefficient for force commands. It must be between ``0.0``
   and ``1.0``. ``1.0`` disables filtering and sends each command directly to
   the output mapper. Lower values make command changes smoother.

``thruster_pwm_ramp_rate_us_per_s``
   Maximum PWM change rate in microseconds per second, used in ``real`` mode.
   ``0.0`` disables the ramp limiter.

``thruster_pwm_min_us`` and ``thruster_pwm_max_us``
   PWM output limits used in ``real`` mode after applying inversion, offset and
   ramp limiting. The defaults are ``1100.0`` and ``1900.0`` microseconds.
