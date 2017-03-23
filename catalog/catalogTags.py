aircraftTypeTags = [
    "aerobatic",
    "airship",
    "balloon",
    "bizjet",
    "bomber",
    "cargo",
    "fighter",
    "ga",
    "glider",
    "groundvehicle",
    "helicopter",
    "spaceship",
    "tanker",
    "trainer",
    "transport",
    "ultralight"
]

manufacturerTags = [
    "airbus",
    "avro",
    "bell",
    "boeing",
    "bombardier",
    "cessna",
    "diamond",
    "douglas",
    "embraer",
    "eurocopter",
    "fokker",
    "lockheed",
    "pilatus",
    "piper",
    "robin",
    "vickers"
]

eraTags = [
    "1920s",
    "1930s",
    "1950s",
    "1960s",
    "1970s",
    "1980s",
    "1990s",
    "2000s",
    "coldwar",
    "early-pioneers",
    "golden-age",
    "gulfwar1",
    "gulfwar2",
    "vietnam",
    "ww1",
    "ww2"
]

featureTags = [
    "aerobatic",
    "airship",
    "amphibious",
    "biplane",
    "cannard",
    "delta",
    "etops",
    "experimental",
    "fictional",
    "fixed-gear",
    "floats",
    "glass-cockpit",
    "high-wing",
    "hud",
    "ifr",
    "prototype",
    "refuel",
    "retractable-gear",
    "seaplane",
    "stol",
    "supersonic",
    "t-tail",
    "tail-dragger",
    "tail-hook",
    "triplane",
    "v-tail",
    "variable-geometry",
    "vtol"
]

propulsionTags = [
    "afterburner",
    "diesel",
    "electric",
    "jet",
    "piston",
    "radial",
    "rocket",
    "single-engine",
    "supercharged",
    "turboprop",
    "twin-engine",
    "variable-pitch"
]

simFeatureTags = [
    "dual-controls",
    "rembrandt",
    "tow"
]

tags = aircraftTypeTags + manufacturerTags + eraTags + simFeatureTags + propulsionTags + featureTags

def isValidTag(maybeTag):
    return maybeTag in tags
