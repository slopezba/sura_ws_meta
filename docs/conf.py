project = "SURA Architecture"
author = "SURA"
copyright = "2026, SURA"

extensions = []

templates_path = ["_templates"]
exclude_patterns = ["_build", ".deps", ".venv", "Thumbs.db", ".DS_Store"]

html_theme = "sphinx_rtd_theme"
html_logo = "_static/sura_logo.png"
html_favicon = "_static/sura_logo.png"
html_static_path = ["_static"]
html_css_files = ["custom.css"]

html_theme_options = {
    "collapse_navigation": False,
    "navigation_depth": 3,
    "titles_only": True,
    "logo_only": True,
}

html_context = {
    "github_repo_url": "https://github.com/slopezba/sura_ws_meta",
}
