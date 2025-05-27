
# Changelog

## 0.4.0

- Do not add a default log handler.

## 0.3.0

- Add support for python 3.7 and 3.8.

## 0.2.0

- Fix redirection in test where a file `nul` was created in working directory.
- Improve test by using functions instead of copying the code.
- Add option to configure message format via environment variables
  `LOGGING_PIPELINE_WARNING_MESSAGE_FORMAT` and `LOGGING_PIPELINE_ERROR_MESSAGE_FORMAT`.
  The value is used to configure the python logger with `{}`-format, see
  [LogRecord attributes](https://docs.python.org/3/library/logging.html#logrecord-attributes).

## 0.1.3

- Fix release notes.

## 0.1.2

- Fix description and add release notes.

## 0.1.1

- Fix installation instruction and development state.

## 0.1.0

- First implementation.
