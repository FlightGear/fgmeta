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
    "dassault",
    "diamond",
    "douglas",
    "embraer",
    "eurocopter",
    "fairchild",
    "fairey",
    "fokker",
    "grumman",
    "lockheed",
    "pilatus",
    "piper",
    "robin",
    "vickers",
    "vought"
]

eraTags = [
    "1910s",
    "1920s",
    "1930s",
    "1940s",
    "1950s",
    "1960s",
    "1970s",
    "1980s",
    "1990s",
    "2000s",
    "2010s",
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
    "canard",
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
    "vtol",
    "wing-fold"
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
