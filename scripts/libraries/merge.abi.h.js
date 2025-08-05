// mergeAbi.js  –  CommonJS version
const fs = require("fs");
const path = require("path");
const { Interface } = require("ethers");

/**
 * @typedef {Object} MergeAbiOptions
 * @property {string[]} artifactPaths   Absolute/relative paths to Hardhat artifact JSON files.
 * @property {string}  [outputPath]     Where to save combined ABI (default: combinedAbi.json).
 * @property {boolean} [throwOnNonFuncDuplicate] Throw error on duplicate non-function fragments.
 */

function mergeAbi({
  artifactPaths,
  outputPath = "combinedAbi.json",
  throwOnNonFuncDuplicate = false,
}) {
  /* 1. Flatten all fragments */
  const allFragments = artifactPaths.flatMap((p) => {
    const { abi } = JSON.parse(fs.readFileSync(p, "utf8"));
    return abi;
  });

  /* 2. Deduplicate with duplicate checks */
  const fragmentMap = new Map();
  const nonFuncDuplicates = [];

  for (const frag of allFragments) {
    const key = JSON.stringify({
      type: frag.type,
      name: frag.name,
      inputs: frag.inputs?.map((i) => i.type), // param types only
    });

    if (fragmentMap.has(key)) {
      // Duplicate detected
      if (frag.type === "function") {
        throw new Error(
          `Duplicate function detected: ${frag.name}(${frag.inputs
            ?.map((i) => i.type)
            .join(",")})`
        );
      } else {
        nonFuncDuplicates.push({ key, frag });
        if (throwOnNonFuncDuplicate) {
          throw new Error(
            `Duplicate non-function fragment detected: ${frag.type} ${frag.name}`
          );
        }
        continue; // skip storing duplicate
      }
    }
    fragmentMap.set(key, frag);
  }

  /* 3. Write merged ABI & build Interface */
  const deduped = Array.from(fragmentMap.values());
  fs.writeFileSync(outputPath, JSON.stringify(deduped, null, 2));

  console.log(`✅ ABI merged – total unique fragments: ${deduped.length}`);
  if (nonFuncDuplicates.length) {
    console.warn(
      `⚠️  Found ${nonFuncDuplicates.length} duplicate non-function fragment(s)`
    );
  }

  return { abi: deduped, iface: new Interface(deduped) };
}

/**
 * Convert an Interface (or raw ABI) to minimal, human-readable ABI.
 * @param {Interface|any[]} source   ethers Interface instance or fragments.
 * @param {string}           [outputPath] Optional path to save minimal ABI as JSON.
 * @returns {string[]}                  Array of minimal signatures (strings).
 */
function toMinimalAbi(source, outputPath) {
  const iface =
    source instanceof Interface ? source : new Interface(source);

  // 1. Get minimal ABI array (strings)
  const minimal = iface.format(false);

  // 2. Helper: extract 'type' token from each signature
  const getType = (sig) => {
    const firstSpace = sig.indexOf(" ");
    if (firstSpace !== -1) return sig.slice(0, firstSpace);  // function / event / error
    return sig.slice(0, sig.indexOf("("));                   // constructor / fallback / receive
  };

  // 3. Sort by type lexicographically, keeping original order for same type
  const sorted = [...minimal].sort((a, b) => {
    const ta = getType(a);
    const tb = getType(b);
    if (ta < tb) return -1;
    if (ta > tb) return 1;
    return 0;
  });

  // 4. Optionally write to file
  if (outputPath) {
    fs.writeFileSync(outputPath, JSON.stringify(sorted, null, 2));
    console.log(`📄 Minimal ABI saved → ${outputPath}`);
  }

  return sorted;
}


module.exports = { mergeAbi, toMinimalAbi };
