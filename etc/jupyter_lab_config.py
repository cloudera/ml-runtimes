# JupyterLab Configuration for CML Runtime
# This file configures JupyterLab behavior and nbconvert exporters

c = get_config()

# Disable Qt-based exporters that require OpenGL and cause crashes in containerized runtimes
c.QtPDFExporter.enabled = False
c.QtPNGExporter.enabled = False

# Disable WebPDF exporter (requires Chromium browser)
c.WebPDFExporter.enabled = False

"""
Configure nbconvert to use a hardened, offline-first LaTeX engine.
- Use a small wrapper around Tectonic to ensure offline-only operation
  and consistent flags across runs.
- Keep a single LaTeX pass for speed; templates should minimize the
  need for multiple reruns.
"""

# Run LaTeX only once to reduce runtime. Complex docs with heavy cross-references
# can increase this later if needed.
c.PDFExporter.latex_count = 1

# Use the offline-first wrapper created in the image at /usr/local/bin/tectonic-nbconvert
c.PDFExporter.latex_command = [
    '/usr/local/bin/tectonic-nbconvert', '{filename}'
]

