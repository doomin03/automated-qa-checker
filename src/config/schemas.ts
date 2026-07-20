import { z } from "zod";

export const PlatformSchema = z.enum(["web", "android", "ios", "webos"]);
export const ExecutionModeSchema = z.enum(["local"]);
export const RiskLevelSchema = z.enum(["READ_ONLY", "SAFE_WRITE", "DESTRUCTIVE"]);

export type Platform = z.infer<typeof PlatformSchema>;
export type RiskLevel = z.infer<typeof RiskLevelSchema>;

export const EvidenceConfigSchema = z
  .object({
    screenshotOnFailure: z.boolean().default(true),
    traceOnFailure: z.boolean().default(false),
    saveConsoleLogs: z.boolean().default(false),
    saveNetworkErrors: z.boolean().default(false),
  })
  .default({});

const TargetBaseSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1),
  enabled: z.boolean().default(true),
  executionMode: ExecutionModeSchema.default("local"),
  targetEnvironment: z.literal("production"),
  deviceProfile: z.string().min(1),
  scenarioPaths: z.array(z.string().min(1)).default([]),
  group: z.array(z.string().min(1)).default([]),
  evidence: EvidenceConfigSchema,
});

export const WebTargetSchema = TargetBaseSchema.extend({
  platform: z.literal("web"),
  baseUrl: z.string().url(),
  crawlerConfig: z.string().min(1).optional(),
});

const AppArtifactSchema = z.object({
  type: z.enum(["apk", "app", "ipa", "ipk"]),
  path: z.string().min(1),
});

export const AndroidTargetSchema = TargetBaseSchema.extend({
  platform: z.literal("android"),
  artifact: AppArtifactSchema.extend({
    type: z.literal("apk"),
  }),
  app: z.object({
    packageName: z.string().min(1),
    resetBeforeRun: z.boolean().default(false),
    reinstallBeforeRun: z.boolean().default(false),
  }),
});

export const IosTargetSchema = TargetBaseSchema.extend({
  platform: z.literal("ios"),
  artifact: AppArtifactSchema.extend({
    type: z.enum(["app", "ipa"]),
  }),
  app: z.object({
    bundleId: z.string().min(1),
    resetBeforeRun: z.boolean().default(false),
    reinstallBeforeRun: z.boolean().default(false),
  }),
});

export const WebOsTargetSchema = TargetBaseSchema.extend({
  platform: z.literal("webos"),
  artifact: AppArtifactSchema.extend({
    type: z.literal("ipk"),
  }),
  app: z.object({
    appId: z.string().min(1),
    reinstallBeforeRun: z.boolean().default(false),
  }),
});

export const TargetConfigSchema = z.discriminatedUnion("platform", [
  WebTargetSchema,
  AndroidTargetSchema,
  IosTargetSchema,
  WebOsTargetSchema,
]);

export type TargetConfig = z.infer<typeof TargetConfigSchema>;

export const TargetIndexSchema = z.object({
  targets: z.array(z.string().min(1)).default([]),
});

export type TargetIndex = z.infer<typeof TargetIndexSchema>;

export const DeviceProfileSchema = z.object({
  id: z.string().min(1),
  platform: PlatformSchema,
  locale: z.string().min(1).optional(),
  timezone: z.string().min(1).optional(),
  viewport: z
    .object({
      width: z.number().int().positive(),
      height: z.number().int().positive(),
    })
    .optional(),
  deviceScaleFactor: z.number().positive().optional(),
  colorScheme: z.enum(["light", "dark"]).optional(),
  osVersion: z.string().min(1).optional(),
  udid: z.string().min(1).optional(),
  avdName: z.string().min(1).optional(),
  webosDeviceName: z.string().min(1).optional(),
});

export type DeviceProfile = z.infer<typeof DeviceProfileSchema>;

export const CrawlerConfigSchema = z.object({
  startUrls: z.array(z.string().url()).min(1),
  scope: z
    .object({
      sameOriginOnly: z.boolean().default(true),
      maxDepth: z.number().int().nonnegative().default(3),
      maxPages: z.number().int().positive().default(100),
    })
    .default({}),
  include: z.array(z.string()).default(["/**"]),
  exclude: z.array(z.string()).default([]),
});

export type CrawlerConfig = z.infer<typeof CrawlerConfigSchema>;

export const IntegrationsConfigSchema = z.object({
  integrations: z.object({
    gitlab: z.object({ enabled: z.literal(false) }),
    n8n: z.object({ enabled: z.literal(false) }),
    postgres: z.object({ enabled: z.literal(false) }),
    slack: z.object({ enabled: z.literal(false) }),
  }),
});

export type IntegrationsConfig = z.infer<typeof IntegrationsConfigSchema>;
