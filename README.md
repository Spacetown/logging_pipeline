# logging_pipeline

Python module to inject logging handler for printing message in the format captured by pipeline.

Install with:

```bash
pip install logging_pipeline
```

If logging is imported a handler is added to the root logger to print the error and warning messages
in addition with a format recognized by the pipeline environment executing the script. If the script
is executed outside a pipeline nothing is printed. Supported pipelines are:

- Azure pipelines
- GitHub actions

## Compatibility

`logging_pipeline` uses a live-patching system to target the `logging` library and add a handler.

## PyInstaller

The method used to automatically adding a logging handler relies on a .pth file script that python
loads at startup. This method does not work when a python application is bundled into an executable
with PyInstaller (or similar).
If you want to use this tool in an application built with PyInstaller it will need to be manually
enabled in your application.
This can be done by adding the following line to the top of your main application script:

```python
import logging_pipeline.wrapt_logging
```

This must be run before logging is imported.

## Acknowledgements

The method of patching at runtime is built from the [pip_system_certs](https://pypi.org/project/pip-system-certs/)
module.
