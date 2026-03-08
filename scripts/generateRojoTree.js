#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const BASE_PATH = path.join(__dirname, "../src");

const BLACKLISTED_DIRS = [
  toPosix(path.join(BASE_PATH, "startup")),
  toPosix(path.join(BASE_PATH, "shared")),
  toPosix(path.join(BASE_PATH, "ui")),
  toPosix(path.join(BASE_PATH, "assets"))
];

function toPosix(p) {
  return p.split(path.sep).join("/");
}

function toPascalCase(str) {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

/**
 * Determines routing for a file based on the new structure
 * @param {string} filepath - Full path to the file
 * @returns {Object} Routing information
 */
function getVirtualPath(filepath) {
  const relativePath = path.relative(BASE_PATH, filepath);
  const parts = relativePath.split(path.sep);
  const filename = path.basename(filepath, ".luau");
  const lowerFilename = filename.toLowerCase();

  // Check if this is in features/ or services/
  const isFeature = parts[0] === "features";
  const isService = parts[0] === "services";

  if (isFeature || isService) {
    const moduleType = parts[0]; // "features" or "services"
    const moduleName = parts[1]; // e.g., "Example" or "ExampleService"
    const subFolder = parts[2]; // e.g., "server", "shared", "network", "ui", or undefined

    let target = "ReplicatedStorage";
    let destinationFolder = moduleType === "features" ? "Features" : "Services";
    let name = filename;

    // Handle network folder specially
    if (subFolder === "network") {
      const networkFile = parts[3]; // "Server.luau" or "Client.luau"
      const isServerNetwork = networkFile === "Server.luau";

      target = isServerNetwork ? "ServerScriptService" : "ReplicatedStorage";
      name = isServerNetwork ? "NetworkServer" : "NetworkClient";

      return {
        target,
        folder: [destinationFolder, moduleName],
        name,
        file: toPosix(filepath.replace(BASE_PATH + path.sep, "src" + path.sep)),
        moduleType,
        moduleName,
      };
    }

    // Handle ui folder - mark it for $path treatment
    if (subFolder === "ui") {
      target = "ReplicatedStorage";

      return {
        target,
        folder: [destinationFolder, moduleName],
        name: "UI",
        isUIFolder: true,
        uiPath: toPosix(path.dirname(filepath).replace(BASE_PATH + path.sep, "src" + path.sep)),
        file: toPosix(filepath.replace(BASE_PATH + path.sep, "src" + path.sep)),
        moduleType,
        moduleName,
      };
    }

    // Handle server folder - everything goes to ServerScriptService
    if (subFolder === "server") {
      target = "ServerScriptService";

      // Build folder path including any nested subdirectories
      // e.g., server/Utils/init.luau should have folder: ["Services", "ExampleService", "Utils"]
      const nestedFolders = parts.slice(3, -1); // Get folders between "server" and the file
      const folderPath = [destinationFolder, moduleName, ...nestedFolders];

      // If it's init.luau in a subdirectory, use folder name
      if (lowerFilename === "init") {
        const parentFolder = parts[parts.length - 2];
        name = toPascalCase(parentFolder);
      }

      return {
        target,
        folder: folderPath,
        name,
        file: toPosix(filepath.replace(BASE_PATH + path.sep, "src" + path.sep)),
        moduleType,
        moduleName,
      };
    }

    // Handle shared folder - everything goes to ReplicatedStorage
    if (subFolder === "shared") {
      target = "ReplicatedStorage";

      // Build folder path including any nested subdirectories
      // e.g., shared/Utils/init.luau should have folder: ["Services", "ExampleService", "Utils"]
      const nestedFolders = parts.slice(3, -1); // Get folders between "shared" and the file
      const folderPath = [destinationFolder, moduleName, ...nestedFolders];

      // If it's init.luau in a subdirectory, use folder name
      if (lowerFilename === "init") {
        const parentFolder = parts[parts.length - 2];
        name = toPascalCase(parentFolder);
      }

      return {
        target,
        folder: folderPath,
        name,
        file: toPosix(filepath.replace(BASE_PATH + path.sep, "src" + path.sep)),
        moduleType,
        moduleName,
      };
    }

    // Handle root-level files in the module (e.g., ExampleServer.luau, ExampleClient.luau)
    if (parts.length === 3) {
      const isServerFile = lowerFilename.includes("server");
      target = isServerFile ? "ServerScriptService" : "ReplicatedStorage";

      return {
        target,
        folder: [destinationFolder, moduleName],
        name,
        file: toPosix(filepath.replace(BASE_PATH + path.sep, "src" + path.sep)),
        moduleType,
        moduleName,
      };
    }
  }

  // Default fallback for other files
  return {
    target: "ReplicatedStorage",
    folder: parts.slice(0, -1).map(toPascalCase),
    name: filename,
    file: toPosix(filepath.replace(BASE_PATH + path.sep, "src" + path.sep)),
  };
}

const tree = {
  name: "Game-Framework",
  tree: {
    $className: "DataModel",

    ReplicatedStorage: {
      $className: "ReplicatedStorage",

      Features: {
        $className: "Folder",
      },

      Services: {
        $className: "Folder",
      },

      Shared: {
        $className: "Folder",
        $path: "src/shared",
      },

      Assets: {
        $className: "Folder",
        $path: "src/assets/Shared",
      },

      UI: {
        $className: "Folder",
        $path: "src/ui",
      },

      Packages: {
        $path: "Packages",
      },
    },

    ServerStroage: {
      $className: "ServerStorage",

      Assets: {
        $className: "Folder",
        $path: "src/assets/Server",
      }
    },

    ServerScriptService: {
      $className: "ServerScriptService",

      Features: {
        $className: "Folder",
      },

      Services: {
        $className: "Folder",
      },

      ServerStartup: {
        $path: "src/startup/Server.server.luau",
      },

      ServerPackages: {
        $path: "ServerPackages",
      },
    },

    StarterPlayer: {
      $className: "StarterPlayer",

      StarterPlayerScripts: {
        $className: "StarterPlayerScripts",

        ClientStartup: {
          $path: "src/startup/Client.client.luau",
        },

        UIStartup: {
          $path: "src/startup/UI.client.luau",
        }
      },
    }
  },
};

const replicatedFeatures = tree.tree.ReplicatedStorage.Features;
const replicatedServices = tree.tree.ReplicatedStorage.Services;
const serverFeatures = tree.tree.ServerScriptService.Features;
const serverServices = tree.tree.ServerScriptService.Services;

// Recursively walk all files
function walk(dir, callback) {
  if (BLACKLISTED_DIRS.includes(toPosix(dir))) return;

  fs.readdirSync(dir, { withFileTypes: true }).forEach((entry) => {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(full, callback);
    } else if (entry.isFile() && entry.name.endsWith(".luau")) {
      callback(full);
    }
  });
}

// Track init.luau claimed folders to avoid duplicates
const initClaimedFolders = new Set();
// Track UI folders that should be $path references
const uiFolderPaths = new Map(); // key: folder path, value: ui directory path

walk(BASE_PATH, (filepath) => {
  const pathInfo = getVirtualPath(filepath);
  const { target, folder, name, file, moduleName, isUIFolder, uiPath } = pathInfo;

  // If this is a UI folder file, track it and skip processing
  if (isUIFolder) {
    const folderKey = folder.join("/") + "/UI";
    if (!uiFolderPaths.has(folderKey)) {
      // Find the actual ui folder path (up to the 'ui' directory)
      const relativePath = path.relative(BASE_PATH, filepath);
      const parts = relativePath.split(path.sep);
      const uiIndex = parts.indexOf("ui");
      const uiFolderPath = parts.slice(0, uiIndex + 1).join("/");
      uiFolderPaths.set(folderKey, "src/" + uiFolderPath);
    }
    return; // Skip processing individual UI files
  }

  // Determine root based on target and folder type
  let root;
  if (target === "ServerScriptService") {
    root = folder[0] === "Features" ? serverFeatures : serverServices;
  } else {
    root = folder[0] === "Features" ? replicatedFeatures : replicatedServices;
  }

  // Navigate to the correct nested location
  let current = root;
  for (let i = 1; i < folder.length; i++) {
    const part = folder[i];
    if (!current[part]) {
      current[part] = { $className: "Folder" };
    }
    current = current[part];
  }

  // Handle init.luau files - they represent their parent folder
  const filename = path.basename(filepath, ".luau");
  if (filename.toLowerCase() === "init") {
    const folderKey = folder.join("/");

    // Mark this folder as claimed
    initClaimedFolders.add(folderKey);

    // Set the folder to point to the directory containing init.luau
    const dirPath = toPosix(path.dirname(filepath).replace(BASE_PATH + path.sep, "src" + path.sep));

    // Get parent and set the module folder to the path
    const parentFolder = folder[folder.length - 1];
    const parent = folder.slice(0, -1).reduce((acc, part) => {
      if (part === "Features" || part === "Services") return acc;
      if (!acc[part]) acc[part] = { $className: "Folder" };
      return acc[part];
    }, root);

    parent[parentFolder] = { $path: dirPath };
    return;
  }

  // Check if parent folder was claimed by init.luau
  const folderKey = folder.join("/");
  if (initClaimedFolders.has(folderKey)) return;

  // Add the file
  current[name] = { $path: file };
});

// After processing all files, add UI folder $path references
for (const [folderKey, uiPath] of uiFolderPaths.entries()) {
  const parts = folderKey.split("/");
  const destinationType = parts[0]; // "Features" or "Services"

  let root;
  if (destinationType === "Features") {
    root = replicatedFeatures;
  } else {
    root = replicatedServices;
  }

  // Navigate to the parent folder
  let current = root;
  for (let i = 1; i < parts.length - 1; i++) {
    const part = parts[i];
    if (!current[part]) {
      current[part] = { $className: "Folder" };
    }
    current = current[part];
  }

  // Set the UI folder to $path
  current.UI = { $path: uiPath };
}

fs.writeFileSync("default.project.json", JSON.stringify(tree, null, 2));
console.log("✅ default.project.json generated.");