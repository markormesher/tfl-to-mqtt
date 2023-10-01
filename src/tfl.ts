type AllModesResponse = { modeName: string }[];

type AllSeveritiesResponse = { modeName: string; severityLevel: number; description: string }[];

type AllDisruptionCategoriesResponse = string[];

type LinesForModeResponse = { id: string; name: string; modeName: string }[];

type LineStatusResponse = {
  id: string;
  modeName: string;
  lineStatuses: {
    statusSeverity: number;
    statusSeverityDescription: string;
    reason: string;
    disruption?: {
      category: string;
      categoryDescription: string;
      description: string;
    };
  }[];
}[];

async function getModes(appKey: string): Promise<string[]> {
  const result = await fetch(`https://api.tfl.gov.uk/Line/Meta/Modes?app_key=${appKey}`);
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const body: AllModesResponse = await result.json();
  return body.map((mode) => mode.modeName);
}

async function getSeveritiesByMode(appKey: string): Promise<Record<string, string[]>> {
  const result = await fetch(`https://api.tfl.gov.uk/Line/Meta/Severity?app_key=${appKey}`);
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const body: AllSeveritiesResponse = await result.json();
  const output: Record<string, string[]> = {};
  body.forEach((sev) => {
    if (!output[sev.modeName]) {
      output[sev.modeName] = [];
    }
    output[sev.modeName].push(sev.description);
  });
  return output;
}

async function getDisruptionCategories(appKey: string): Promise<string[]> {
  const result = await fetch(`https://api.tfl.gov.uk/Line/Meta/DisruptionCategories?app_key=${appKey}`);
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const body: AllDisruptionCategoriesResponse = await result.json();
  return body;
}

async function getLinesForMode(appKey: string, mode: string): Promise<string[]> {
  const result = await fetch(`https://api.tfl.gov.uk/Line/Mode/${mode}?app_key=${appKey}`);
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const body: LinesForModeResponse = await result.json();
  return body.map((line) => line.id);
}

async function getLineStatus(appKey: string, line: string): Promise<LineStatusResponse[number] | null> {
  const result = await fetch(`https://api.tfl.gov.uk/Line/${line}/Status?app_key=${appKey}`);
  if (!result.ok) {
    return null;
  }

  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const body: LineStatusResponse = await result.json();
  if (body.length == 0) {
    return null;
  }

  return body[0];
}

export { getModes, getSeveritiesByMode, getDisruptionCategories, getLinesForMode, getLineStatus };
