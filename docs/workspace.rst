:orphan:

Workspace
=========

The workspace composition is tracked with ``vcstool``.

Manifest
--------

``workspace.repos`` stores the exact repository manifest for recreating the SURA
workspace.

Recreate the Workspace
----------------------

From the workspace root:

.. code-block:: bash

   mkdir -p src
   vcs import src < workspace.repos
