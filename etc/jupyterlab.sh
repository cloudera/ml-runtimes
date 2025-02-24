#!/bin/bash -ex
#
# Launch JupyterLab with options appropriate for runnning as a custom CDSW/CML editor.

# Kernel inactivity timeout
DEFAULT_TIMEOUT=$[${IDLE_MAXIMUM_MINUTES:-60}*60]
export JUPYTER_KERNEL_TIMEOUT_SECONDS=${JUPYTER_KERNEL_TIMEOUT_SECONDS:-$DEFAULT_TIMEOUT}

# jupyter-server is considered inactive if it has no running kernels (notebooks or
# jupyter terminals) *and* the UI is not open in a live browser window.
export JUPYTER_SERVER_TIMEOUT_SECONDS=${JUPYTER_SERVER_TIMEOUT_SECONDS:-300}

export JUPYTER_LOG_LEVEL=${JUPYTER_LOG_LEVEL:-ERROR}
CML_JUPYTER_ENSURE_NATIVE_KERNEL=${CML_JUPYTER_ENSURE_NATIVE_KERNEL:-True}
JUPYTERLAB_DIR=${JUPYTERLAB_DIR_OVERRIDE:-/usr/local}

DEFAULT_COPILOT_MODEL=`python /usr/local/bin/read_default_copilot_model.py`
DEFAULT_COPILOT_EMBEDDING_MODEL=`python /usr/local/bin/read_default_copilot_embedding_model.py`

# cull_interval below means how often to check for inactivity (to apply timeout rules)
# nonzero return code indicates jupyterlab internal failure.
# `bash -e` relays this return code to the parent process.
"${JUPYTERLAB_DIR}"/bin/jupyter lab \
    --no-browser \
    --ip=127.0.0.1 \
    --port="${CDSW_APP_PORT}" \
    --ServerApp.token= \
    --ServerApp.allow_remote_access=True \
    --log-level=${JUPYTER_LOG_LEVEL} \
    --ServerApp.shutdown_no_activity_timeout="${JUPYTER_SERVER_TIMEOUT_SECONDS}" \
    --MappingKernelManager.cull_idle_timeout="${JUPYTER_KERNEL_TIMEOUT_SECONDS}" \
    --TerminalManager.cull_inactive_timeout="${JUPYTER_KERNEL_TIMEOUT_SECONDS}" \
    --MappingKernelManager.cull_interval=60 \
    --MappingKernelManager.cull_connected=True \
    --TerminalManager.cull_interval=60 \
    --KernelSpecManager.ensure_native_kernel="${CML_JUPYTER_ENSURE_NATIVE_KERNEL}" \
    --ContentsManager.allow_hidden=True \
    --AiExtension.default_language_model="${DEFAULT_COPILOT_MODEL}" \
    --AiExtension.default_embeddings_model="${DEFAULT_COPILOT_EMBEDDING_MODEL}" \
    "$@"

# If control reaches here, jupyterlab exited with return code 0.
# In our use case, that only happens on timeout.
# CML treats exit code 129 here as 'Timeout'.
exit 129
