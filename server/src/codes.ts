// Room codes: a friendly word and two digits, e.g. FROG-42.

export const WORDS: readonly string[] = [
  "FROG", "MOSS", "FERN", "LEAF", "PINE", "OAK", "MAPLE", "ACORN", "SEED", "ROOT", "BUD", "BLOOM",
  "ROSE", "LILY", "IRIS", "DAISY", "TULIP", "MINT", "SAGE", "BASIL", "PLUM", "PEAR", "APPLE", "LEMON",
  "LIME", "MANGO", "PEACH", "BERRY", "GRAPE", "MELON", "KIWI", "FIG", "HONEY", "CANDY", "TAFFY", "GUMMY",
  "COCOA", "CAKE", "PIE", "BUN", "TOAST", "JAM", "TEA", "MOCHA", "BEAN", "CLOUD", "RAIN", "SNOW",
  "FROST", "ICE", "STORM", "MIST", "FOG", "DEW", "SUN", "MOON", "STAR", "COMET", "SKY", "DAWN",
  "DUSK", "GLOW", "SPARK", "EMBER", "FLAME", "LAVA", "OWL", "BAT", "CAT", "FOX", "BEAR", "WOLF",
  "DEER", "HARE", "MOLE", "NEWT", "TOAD", "CRAB", "CLAM", "SEAL", "ORCA", "SWAN", "DUCK", "GOOSE",
  "CROW", "WREN", "LARK", "ROBIN", "FINCH", "MOTH", "BEE", "SNAIL", "YAK", "LLAMA", "PANDA", "KOALA",
  "OTTER", "LYNX", "PUMA", "TIGER", "LION", "ZEBRA", "CAMEL", "PONY", "LAMB", "GOAT", "HEN", "CHICK",
  "NEST", "HIVE", "CAVE", "HILL", "PEAK", "LAKE", "POND", "RIVER", "BROOK", "REEF", "ISLE", "BAY",
  "COVE", "DUNE", "VALE", "GLEN", "WOOD", "GROVE", "FIELD", "BELL", "DRUM", "HARP", "FLUTE", "LUTE",
  "KITE", "BOAT", "RAFT", "MAP", "KEY", "GEM", "OPAL", "JADE", "RUBY", "PEARL", "AMBER", "GOLD",
  "SILK", "WOOL", "YARN", "SOCK", "HAT", "CAP", "BOOT", "MUG", "CUP", "BOWL", "SPOON", "LAMP",
  "WAND", "ORB", "RUNE", "TALE", "SONG", "POEM", "DREAM", "NAP", "BLOB", "BOOP", "ZIP", "ZAP",
  "POP", "FIZZ", "BUZZ", "HUSH",
];

const CODE = /^[A-Z]{3,5}-[0-9]{2}$/;

export function makeCode(rand: () => number): string {
  const word = WORDS[Math.min(WORDS.length - 1, Math.floor(rand() * WORDS.length))];
  const num = Math.min(99, Math.floor(rand() * 100));
  return `${word}-${String(num).padStart(2, "0")}`;
}

export function isCode(s: string): boolean {
  return CODE.test(s);
}
