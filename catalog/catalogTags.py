aircraftTypeTags = [
    "ga", "fighter", "helicopter", "glider", "spaceship", "bomber", "groundvehicle",
    "tanker", "cargo", "transport", "bizjet", "trainer", "airship", "balloon"
]

manufacturerTags = [
    "boeing", "cessna", "diamond", "douglas", "bell", "piper",
    "airbus", "vickers", "lockheed", "fokker",
    "embraer", "bombardier", "pilatus", "robin",
    "eurocopter"
]

eraTags = [
    "early-pioneers",
    "ww1",
    "1920s",
    "1930s",
    "golden-age",
    "ww2",
    "coldwar", "vietnam",
    "1950s",
    "1960s",
    "1970s",
    "1980s",
    "1990s",
    "2000s",
    "gulfwar1",
    "gulfwar2"
]

featureTags = [
    "ifr",
    "retractable-gear",
    "fixed-gear",
    "tail-dragger",
    "seaplane",
    "vtol",
    "stol",
    "experimental",
    "prototype",
    "fictional",
    "biplane",
    "triplane",
    "supersonic",
    "t-tail",
    "v-tail",
    "high-wing",
    "cannard",
    "tail-hook",
    "refuel",
    "delta",
    "variable-geometry",
    "glass-cockpit",
    "hud",
    "etops",
    "floats",
    "amphibious",
    "airship",
    "aerobatic"
]

propulsionTags = [
    "piston", "radial",
    "diesel",
    "variable-pitch",
    "supercharged",
    "turboprop",
    "jet", "afterburner", "rocket",
    "electric",
    "twin-engine",
    "single-engine"
]

simFeatureTags = [
    "tow",
    "dual-controls",
    "rembrandt"
]

tags = aircraftTypeTags + manufacturerTags + eraTags + simFeatureTags + propulsionTags + featureTags

def isValidTag(maybeTag):
    return maybeTag in tags
