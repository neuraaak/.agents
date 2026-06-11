# JS/TS Style & Layout Standards (UIA)

Visual structure, import organization, and documentation standards for JS/TS source files.

<rules>
- **SECTIONING:** Use `// ///////////////////////////////////////////////////////////////` for main sections.
- **DOCSTRINGS:** Use JSDoc (Google-style) for all public functions, classes, and types.
- **IMPORTS:** Group by: 1. standard (node:), 2. 3rd-party, 3. local. Sort alphabetically.
- **TYPES:** Use `import type` for TypeScript types to aid tree-shaking.
- **COMMENTS:** Explain "why", not "what". Always use English.
</rules>

## Main Section Separators

Use the forward slash separator for major code boundaries.

```javascript
// ///////////////////////////////////////////////////////////////
// IMPORTS
// ///////////////////////////////////////////////////////////////
```

## Subsection Markers

Use dashes for internal organization within classes, functions, or modules.

```javascript
// ------------------------------------------------
// PRIVATE METHODS
// ------------------------------------------------
```

## Import Organization Pattern

```javascript
// ///////////////////////////////////////////////////////////////
// IMPORTS
// ///////////////////////////////////////////////////////////////
// Standard library (node:)
import { readFile } from "node:fs/promises";
import { join } from "node:path";

// Third-party
import express from "express";
import { z } from "zod";

// Local
import { CustomError } from "./exceptions.js";
```

<examples>
/**
 * Calculates metrics for a dataset.
 *
 * @param {Array<number>} data - A list of numeric measurements.
 * @returns {Record<string, number>} A mapping of metric names to values.
 */
function calculateMetrics(data: Array<number>): Record<string, number> {
  // Implementation
}
</examples>

<success_criteria>

- Section markers used for navigation.
- Imports correctly grouped and sorted.
- JSDoc present for all public symbols.

</success_criteria>
