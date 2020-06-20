The tests can be run this way:

  cd python3-flightgear
  python3 -m unittest

If you want to be more specific:

  cd python3-flightgear
  python3 -m unittest flightgear.meta.tests.test_catalog
  python3 -m unittest flightgear.meta.tests.test_sgprops
  python3 -m unittest flightgear.meta.tests.test_catalog.UpdateCatalogTests
  python3 -m unittest flightgear.meta.tests.test_catalog.UpdateCatalogTests.test_scan_set
  etc.
