# SURA Architecture

Estructura base de documentacion con Sphinx y el tema Read the Docs.

La navegacion usa secciones comunes para documentacion tecnica: overview,
installation, architecture, packages, robot setup, simulation, workspace, build,
development, changelog y license. De momento el contenido es una primera version
breve basada en el README del proyecto.

## Construccion local sin venv

Este modo instala dependencias dentro de `docs/`, en una carpeta ignorada por
Git:

```bash
python3 -m pip install --target docs/.deps/python -r docs/requirements.txt
PYTHONPATH=docs/.deps/python python3 -m sphinx -b html docs docs/_build/html
python3 -m http.server 8000 --directory docs/_build/html
```

Despues abre `http://localhost:8000`.

## Publicacion en Read the Docs

El archivo `.readthedocs.yaml` queda en la raiz del repositorio porque Read the
Docs lo detecta ahi. Todo el contenido, configuracion de Sphinx, dependencias y
HTML generado viven dentro de `docs/`.
