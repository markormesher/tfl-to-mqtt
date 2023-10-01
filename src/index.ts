import { strict as assert } from "assert";
import { XToMqtt, getEnvConfig, logger, registerRepeatingUpdate } from "@markormesher/x-to-mqtt";
import { getDisruptionCategories, getLineStatus, getLinesForMode, getModes, getSeveritiesByMode } from "./tfl.js";

const appKey = getEnvConfig("TFL_APP_KEY") ?? "";
assert(!!appKey, "App key not set");

const linesToPublish = (getEnvConfig("LINE_IDS") ?? "").split(",").filter((line) => line != "");
if (linesToPublish.length == 0) {
  logger.warn("No lines are configured!");
}

const mqttWrapper = new XToMqtt();

const maxStatusesPublishedPerLine: Record<string, number> = {};

function clearLineTopics(mode: string, line: string, keepFirst = 0): void {
  const countPublished = maxStatusesPublishedPerLine[line];
  if (!countPublished) {
    return;
  }

  for (let i = keepFirst; i < countPublished; ++i) {
    mqttWrapper.publish(`state/modes/${mode}/lines/${line}/status_${i}/severity`, "");
    mqttWrapper.publish(`state/modes/${mode}/lines/${line}/status_${i}/reason`, "");
    mqttWrapper.publish(`state/modes/${mode}/lines/${line}/status_${i}/disruption_category`, "");
    mqttWrapper.publish(`state/modes/${mode}/lines/${line}/status_${i}/disruption_description`, "");
  }
}

async function publishApiInfo(): Promise<void> {
  const disruptionCategories = await getDisruptionCategories(appKey);
  mqttWrapper.publish("state/api_info/disruption_categories", disruptionCategories.join(", "));

  const modes = await getModes(appKey);
  const severitiesByMode = await getSeveritiesByMode(appKey);
  for (const mode of modes) {
    const severities = severitiesByMode[mode] ?? [];
    const lines = await getLinesForMode(appKey, mode);
    mqttWrapper.publish(`state/api_info/modes/${mode}/lines`, lines.length > 0 ? lines.join(", ") : "NONE");
    mqttWrapper.publish(
      `state/api_info/modes/${mode}/severities`,
      severities.length > 0 ? severities.join(", ") : "NONE",
    );
  }
}

async function doUpdate(): Promise<void> {
  logger.info("Starting update...");

  for (const line of linesToPublish) {
    const statusResponse = await getLineStatus(appKey, line);
    if (!statusResponse) {
      logger.warn(`Failed to fetch status for line '${line}'`);
      continue;
    }

    const mode = statusResponse.modeName;

    if (statusResponse.lineStatuses.length == 0) {
      logger.warn(`Line '${line}' has no reported status`);
      clearLineTopics(mode, line);
      continue;
    }

    const lineStatuses = statusResponse.lineStatuses.filter((status) => {
      if (!status.validityPeriods || status.validityPeriods.length == 0) {
        // no validity specified = currently valid
        return true;
      } else {
        return status.validityPeriods.some((period) => period.isNow);
      }
    });

    let count = 0;
    while (count < lineStatuses.length) {
      const status = lineStatuses[count];
      mqttWrapper.publish(`state/modes/${mode}/lines/${line}/status_${count}/reason`, status.reason);
      mqttWrapper.publish(
        `state/modes/${mode}/lines/${line}/status_${count}/severity`,
        status.statusSeverityDescription,
      );
      mqttWrapper.publish(
        `state/modes/${mode}/lines/${line}/status_${count}/disruption_category`,
        status.disruption?.categoryDescription ?? "",
      );
      mqttWrapper.publish(
        `state/modes/${mode}/lines/${line}/status_${count}/disruption_description`,
        status.disruption?.description ?? "",
      );
      ++count;
    }

    if (!maxStatusesPublishedPerLine[line] || maxStatusesPublishedPerLine[line] < count) {
      maxStatusesPublishedPerLine[line] = count;
    }

    clearLineTopics(mode, line, count);
  }
}

publishApiInfo().catch((error) => {
  logger.error("Publishing API info failed", { error: error as Error });
  mqttWrapper.updateUpstreamStatus("errored");
});

registerRepeatingUpdate({ runImmediately: true, defaultIntervalSeconds: 60, minIntervalSeconds: 60 }, () => {
  doUpdate().catch((error) => {
    logger.error("Update failed", { error: error as Error });
    mqttWrapper.updateUpstreamStatus("errored");
  });
});
