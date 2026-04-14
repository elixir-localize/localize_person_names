import Config

config :ex_unit,
  case_load_timeout: 220_000,
  timeout: 120_000

config :localize,
  allow_runtime_locale_download: true
