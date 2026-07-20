import { z } from "zod";

import { RiskLevelSchema } from "./schemas.js";

const StepBaseSchema = z.object({
  id: z.string().min(1),
  optional: z.boolean().default(false),
});

const TimeoutSchema = z.object({
  timeoutMs: z.number().int().positive().optional(),
});

const CommonStepSchema = StepBaseSchema.extend({
  type: z.enum([
    "launchApp",
    "terminateApp",
    "installApp",
    "uninstallApp",
    "resetApp",
    "wait",
    "screenshot",
    "assertNoCrash",
    "runShell",
    "setVariable",
    "log",
  ]),
  name: z.string().min(1).optional(),
  durationMs: z.number().int().positive().optional(),
  message: z.string().optional(),
});

const CoordinateStepSchema = StepBaseSchema.extend({
  type: z.enum([
    "tap",
    "tapPercent",
    "doubleTap",
    "longPress",
    "swipe",
    "swipePercent",
    "drag",
    "tapRelativeToImage",
  ]),
  x: z.number().optional(),
  y: z.number().optional(),
  fromX: z.number().optional(),
  fromY: z.number().optional(),
  toX: z.number().optional(),
  toY: z.number().optional(),
  image: z.string().min(1).optional(),
});

const InputStepSchema = StepBaseSchema.extend({
  type: z.enum(["inputText", "clearText", "pressKey", "hideKeyboard"]),
  value: z.string().optional(),
  valueFromVariable: z.string().min(1).optional(),
  key: z.string().min(1).optional(),
});

const ImageStepSchema = StepBaseSchema.merge(TimeoutSchema).extend({
  type: z.enum([
    "waitForImage",
    "assertImage",
    "assertImageNotVisible",
    "findImageAndTap",
    "compareScreenshot",
    "cropScreenshot",
  ]),
  image: z.string().min(1).optional(),
  threshold: z.number().min(0).max(1).optional(),
  name: z.string().min(1).optional(),
});

const WebStepSchema = StepBaseSchema.merge(TimeoutSchema).extend({
  type: z.enum([
    "navigate",
    "reload",
    "goBack",
    "clickText",
    "clickRole",
    "clickCss",
    "clickCoordinate",
    "assertUrl",
    "assertText",
    "assertHttpStatus",
    "assertNoConsoleError",
    "assertNoPageError",
  ]),
  url: z.string().optional(),
  text: z.string().optional(),
  role: z.string().optional(),
  css: z.string().optional(),
  expected: z.string().optional(),
  status: z.number().int().optional(),
  x: z.number().optional(),
  y: z.number().optional(),
});

const AccessibilityStepSchema = StepBaseSchema.merge(TimeoutSchema).extend({
  type: z.enum(["tapText", "tapAccessibilityLabel", "assertTextVisible"]),
  text: z.string().optional(),
  label: z.string().optional(),
});

export const ScenarioStepSchema = z.union([
  CommonStepSchema,
  CoordinateStepSchema,
  InputStepSchema,
  ImageStepSchema,
  WebStepSchema,
  AccessibilityStepSchema,
]);

export const ScenarioVariableSchema = z.union([
  z.object({ value: z.string() }),
  z.object({ fromEnv: z.string().min(1) }),
]);

export const ScenarioSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1),
  tags: z.array(z.string().min(1)).default([]),
  riskLevel: RiskLevelSchema.default("READ_ONLY"),
  variables: z.record(ScenarioVariableSchema).default({}),
  steps: z.array(ScenarioStepSchema).min(1),
});

export type ScenarioConfig = z.infer<typeof ScenarioSchema>;
export type ScenarioStepConfig = z.infer<typeof ScenarioStepSchema>;

export function validateScenarioHasStepsAfterActions(scenario: ScenarioConfig): void {
  const actionTypes = new Set([
    "tap",
    "tapPercent",
    "doubleTap",
    "longPress",
    "swipe",
    "swipePercent",
    "drag",
    "tapRelativeToImage",
    "inputText",
    "clearText",
    "pressKey",
    "clickText",
    "clickRole",
    "clickCss",
    "clickCoordinate",
  ]);

  const assertionPrefixes = ["assert", "waitFor", "compare"];

  for (let index = 0; index < scenario.steps.length; index += 1) {
    const step = scenario.steps[index];
    if (!actionTypes.has(step.type)) {
      continue;
    }

    const nextStep = scenario.steps[index + 1];
    if (nextStep === undefined) {
      throw new Error(`Action step '${step.id}' must be followed by a validation step.`);
    }

    const hasValidation = assertionPrefixes.some((prefix) => nextStep.type.startsWith(prefix));
    if (!hasValidation && nextStep.type !== "screenshot") {
      throw new Error(`Action step '${step.id}' must be followed by a validation step.`);
    }
  }
}
