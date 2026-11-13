// Code-first Agent HTTP DTOs. Reviewed baseline: protocol 0.1.0-draft.1.
import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { ArrayMaxSize, ArrayMinSize, IsArray, IsBase64, IsBoolean, IsDefined, IsIn, IsInt, IsNumber, IsString, IsUUID, Matches, Max, MaxLength, Min, MinLength, ValidateIf, ValidateNested } from 'class-validator';

export class AgentCapabilitySetDto {
  @ApiProperty({"type":"array","items":{"type":"string","enum":["web","android","ios"]},"maxItems":3,"default":[],"required":true})
  @IsDefined()
  @IsArray()
  @ArrayMaxSize(3)
  @IsIn(["web","android","ios"], { each: true })
  @IsString({ each: true })
  platforms!: Array<string>;
  @ApiProperty({"type":"array","items":{"type":"string","minLength":1,"maxLength":128,"description":"Canonical public Engine action name for the pinned release; server and local capability allowlists intersect. Aliases are forbidden."},"maxItems":100,"default":[],"required":true})
  @IsDefined()
  @IsArray()
  @ArrayMaxSize(100)
  @IsString({ each: true })
  @MinLength(1, { each: true })
  @MaxLength(128, { each: true })
  actions!: Array<string>;
}

export class AgentClaimRequestDto {
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  agentId!: string;
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  instanceId!: string;
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  claimRequestId!: string;
  @ApiProperty({"type":"string","enum":["0.1.0-draft.1"],"required":true})
  @IsDefined()
  @IsIn(["0.1.0-draft.1"])
  @IsString()
  protocolVersion!: string;
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  engineVersion!: string;
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  engineContractVersion!: string;
  @ApiProperty({ ...{"required":true}, type: () => AgentCapabilitySetDto })
  @IsDefined()
  @ValidateNested()
  @Type(() => AgentCapabilitySetDto)
  capabilities!: AgentCapabilitySetDto;
  @ApiProperty({"type":"array","items":{"type":"string","minLength":1,"maxLength":256},"minItems":0,"maxItems":100,"required":true})
  @IsDefined()
  @IsArray()
  @ArrayMinSize(0)
  @ArrayMaxSize(100)
  @IsString({ each: true })
  @MinLength(1, { each: true })
  @MaxLength(256, { each: true })
  resourceKeys!: Array<string>;
  @ApiProperty({"type":"array","items":{"type":"string","minLength":1,"maxLength":128},"minItems":0,"maxItems":100,"required":true})
  @IsDefined()
  @IsArray()
  @ArrayMinSize(0)
  @ArrayMaxSize(100)
  @IsString({ each: true })
  @MinLength(1, { each: true })
  @MaxLength(128, { each: true })
  projectIds!: Array<string>;
  @ApiProperty({"type":"string","pattern":"^[a-f0-9]{64}$","description":"SHA-256 of exact public Engine contracts/releases/qa-contract-<engineVersion>.json bytes; not the runtime file manifest or npm tarball hash.","required":true})
  @IsDefined()
  @IsString()
  @Matches(new RegExp("^[a-f0-9]{64}$"))
  engineContractSha256!: string;
}

export class AgentResourceManifestDto {
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  resourceId!: string;
  @ApiProperty({"type":"string","maxLength":512,"pattern":"^(?!.*\\.\\.)(?:[A-Za-z0-9_-][A-Za-z0-9_.-]{0,63}/)*[A-Za-z0-9_-][A-Za-z0-9_.-]{0,127}\\.(png|json|woff|woff2|ttf|otf)$","description":"Safe ASCII slash-separated path relative to isolated document root; reject absolute/UNC/backslash/traversal/symlink/case-fold collisions.","required":true})
  @IsDefined()
  @IsString()
  @MaxLength(512)
  @Matches(new RegExp("^(?!.*\\.\\.)(?:[A-Za-z0-9_-][A-Za-z0-9_.-]{0,63}/)*[A-Za-z0-9_-][A-Za-z0-9_.-]{0,127}\\.(png|json|woff|woff2|ttf|otf)$"))
  name!: string;
  @ApiProperty({"type":"string","pattern":"^[a-f0-9]{64}$","required":true})
  @IsDefined()
  @IsString()
  @Matches(new RegExp("^[a-f0-9]{64}$"))
  sha256!: string;
  @ApiProperty({"type":"integer","minimum":0,"maximum":10485760,"required":true})
  @IsDefined()
  @IsInt()
  @Min(0)
  @Max(10485760)
  size!: number;
  @ApiProperty({"type":"string","enum":["image/png","application/json","font/woff","font/woff2","font/ttf","font/otf"],"required":true})
  @IsDefined()
  @IsIn(["image/png","application/json","font/woff","font/woff2","font/ttf","font/otf"])
  @IsString()
  mimeType!: string;
}

export class AgentCaseSnapshotPublishedVersionDto {
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  versionId!: string;
  @ApiProperty({"type":"string","pattern":"^[a-f0-9]{64}$","required":true})
  @IsDefined()
  @IsString()
  @Matches(new RegExp("^[a-f0-9]{64}$"))
  sha256!: string;
}

export class AgentCaseSnapshotDto {
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  caseId!: string;
  @ApiProperty({"type":"string","minLength":2,"maxLength":1048576,"description":"Opaque Engine JSON; exact public Engine schema, UTF-8 byte/depth limits and immutable snapshot validation apply.","required":true})
  @IsDefined()
  @IsString()
  @MinLength(2)
  @MaxLength(1048576)
  blueprintJson!: string;
  @ApiProperty({"type":"string","pattern":"^sha256:[a-f0-9]{64}$","required":true})
  @IsDefined()
  @IsString()
  @Matches(new RegExp("^sha256:[a-f0-9]{64}$"))
  blueprintSnapshotHash!: string;
  @ApiProperty({ ...{"minItems":0,"maxItems":128,"required":true}, type: () => [AgentResourceManifestDto] })
  @IsDefined()
  @IsArray()
  @ArrayMinSize(0)
  @ArrayMaxSize(128)
  @ValidateNested({ each: true })
  @Type(() => AgentResourceManifestDto)
  resources!: Array<AgentResourceManifestDto>;
  @ApiProperty({ ...{"nullable":true,"required":true}, type: () => AgentCaseSnapshotPublishedVersionDto })
  @ValidateIf((_object, value) => value !== null)
  @IsDefined()
  @ValidateNested()
  @Type(() => AgentCaseSnapshotPublishedVersionDto)
  publishedVersion!: AgentCaseSnapshotPublishedVersionDto | null;
}

export class AgentExecutionPolicyNativeAppsItemDto {
  @ApiProperty({"type":"string","enum":["android","ios"],"required":true})
  @IsDefined()
  @IsIn(["android","ios"])
  @IsString()
  platform!: string;
  @ApiProperty({"type":"string","minLength":1,"maxLength":256,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(256)
  appId!: string;
  @ApiProperty({"type":"array","items":{"type":"string","minLength":1,"maxLength":256},"maxItems":100,"default":[],"required":true})
  @IsDefined()
  @IsArray()
  @ArrayMaxSize(100)
  @IsString({ each: true })
  @MinLength(1, { each: true })
  @MaxLength(256, { each: true })
  activities!: Array<string>;
}

export class AgentExecutionPolicyDto {
  @ApiProperty({"type":"string","minLength":1,"maxLength":256,"description":"Must equal Lease.resourceKey; resolves only through registered local physical device/browser slot mapping.","required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(256)
  resourceKey!: string;
  @ApiProperty({"type":"string","enum":["web","android","ios"],"required":true})
  @IsDefined()
  @IsIn(["web","android","ios"])
  @IsString()
  platform!: string;
  @ApiProperty({"type":"array","items":{"type":"string","minLength":1,"maxLength":2048,"description":"Exact normalized http(s) origin. Empty denies all web navigation."},"maxItems":100,"default":[],"required":true})
  @IsDefined()
  @IsArray()
  @ArrayMaxSize(100)
  @IsString({ each: true })
  @MinLength(1, { each: true })
  @MaxLength(2048, { each: true })
  allowedOrigins!: Array<string>;
  @ApiProperty({ ...{"maxItems":100,"default":[],"required":true}, type: () => [AgentExecutionPolicyNativeAppsItemDto] })
  @IsDefined()
  @IsArray()
  @ArrayMaxSize(100)
  @ValidateNested({ each: true })
  @Type(() => AgentExecutionPolicyNativeAppsItemDto)
  nativeApps!: Array<AgentExecutionPolicyNativeAppsItemDto>;
  @ApiProperty({"type":"array","items":{"type":"string","minLength":1,"maxLength":128,"pattern":"^[A-Za-z][A-Za-z0-9_.-]{0,127}$"},"maxItems":100,"default":[],"required":true})
  @IsDefined()
  @IsArray()
  @ArrayMaxSize(100)
  @IsString({ each: true })
  @MinLength(1, { each: true })
  @MaxLength(128, { each: true })
  @Matches(new RegExp("^[A-Za-z][A-Za-z0-9_.-]{0,127}$"), { each: true })
  secretRefs!: Array<string>;
  @ApiProperty({"type":"boolean","default":false,"description":"Production execution requires BOTH this server policy and explicit local opt-in. Missing means deny.","required":true})
  @IsDefined()
  @IsBoolean()
  allowProduction!: boolean;
}

export class AgentSuitePolicyDto {
  @ApiProperty({"type":"boolean","required":true})
  @IsDefined()
  @IsBoolean()
  stopOnFailure!: boolean;
  @ApiProperty({"type":"string","nullable":true,"maxLength":128,"required":true})
  @ValidateIf((_object, value) => value !== null)
  @IsDefined()
  @IsString()
  @MaxLength(128)
  publishedVersionId!: string | null;
  @ApiProperty({"type":"string","pattern":"^[a-f0-9]{64}$","nullable":true,"required":true})
  @ValidateIf((_object, value) => value !== null)
  @IsDefined()
  @IsString()
  @Matches(new RegExp("^[a-f0-9]{64}$"))
  publishedSha256!: string | null;
}

export class AgentLeaseDto {
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  agentId!: string;
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  instanceId!: string;
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  leaseId!: string;
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  executionId!: string;
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  projectId!: string;
  @ApiProperty({"type":"integer","minimum":1,"maximum":9007199254740991,"required":true})
  @IsDefined()
  @IsInt()
  @Min(1)
  @Max(9007199254740991)
  jobAttempt!: number;
  @ApiProperty({"type":"integer","minimum":1,"maximum":9007199254740991,"required":true})
  @IsDefined()
  @IsInt()
  @Min(1)
  @Max(9007199254740991)
  fence!: number;
  @ApiProperty({"type":"string","minLength":1,"maxLength":256,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(256)
  resourceKey!: string;
  @ApiProperty({ ...{"minItems":1,"maxItems":32,"required":true}, type: () => [AgentCaseSnapshotDto] })
  @IsDefined()
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(32)
  @ValidateNested({ each: true })
  @Type(() => AgentCaseSnapshotDto)
  cases!: Array<AgentCaseSnapshotDto>;
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  engineVersion!: string;
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  engineContractVersion!: string;
  @ApiProperty({"type":"string","enum":["0.1.0-draft.1"],"required":true})
  @IsDefined()
  @IsIn(["0.1.0-draft.1"])
  @IsString()
  protocolVersion!: string;
  @ApiProperty({"type":"string","enum":["active","reporting","closed","expired","quarantined","recovered"],"required":true})
  @IsDefined()
  @IsIn(["active","reporting","closed","expired","quarantined","recovered"])
  @IsString()
  state!: string;
  @ApiProperty({"type":"integer","minimum":0,"maximum":30000,"required":true})
  @IsDefined()
  @IsInt()
  @Min(0)
  @Max(30000)
  validForMs!: number;
  @ApiProperty({"type":"integer","enum":[5000],"required":true})
  @IsDefined()
  @IsIn([5000])
  @IsInt()
  heartbeatIntervalMs!: number;
  @ApiProperty({"type":"integer","enum":[5000],"required":true})
  @IsDefined()
  @IsIn([5000])
  @IsInt()
  requestTimeoutMs!: number;
  @ApiProperty({"type":"integer","enum":[5000],"required":true})
  @IsDefined()
  @IsIn([5000])
  @IsInt()
  safetyMarginMs!: number;
  @ApiProperty({"type":"boolean","required":true})
  @IsDefined()
  @IsBoolean()
  cancelRequested!: boolean;
  @ApiProperty({"type":"integer","minimum":0,"maximum":9007199254740991,"required":true})
  @IsDefined()
  @IsInt()
  @Min(0)
  @Max(9007199254740991)
  acceptedThrough!: number;
  @ApiProperty({"type":"string","pattern":"^[a-f0-9]{64}$","description":"SHA-256 of exact public Engine contracts/releases/qa-contract-<engineVersion>.json bytes; not the runtime file manifest or npm tarball hash.","required":true})
  @IsDefined()
  @IsString()
  @Matches(new RegExp("^[a-f0-9]{64}$"))
  engineContractSha256!: string;
  @ApiProperty({ ...{"required":true}, type: () => AgentExecutionPolicyDto })
  @IsDefined()
  @ValidateNested()
  @Type(() => AgentExecutionPolicyDto)
  executionPolicy!: AgentExecutionPolicyDto;
  @ApiProperty({ ...{"required":true}, type: () => AgentSuitePolicyDto })
  @IsDefined()
  @ValidateNested()
  @Type(() => AgentSuitePolicyDto)
  suitePolicy!: AgentSuitePolicyDto;
}

export class AgentClaimResponseDto {
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  claimRequestId!: string;
  @ApiProperty({ ...{"required":true}, type: () => AgentLeaseDto })
  @IsDefined()
  @ValidateNested()
  @Type(() => AgentLeaseDto)
  lease!: AgentLeaseDto;
}

export class AgentHeartbeatRequestDto {
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  agentId!: string;
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  instanceId!: string;
  @ApiProperty({"type":"integer","minimum":1,"maximum":9007199254740991,"required":true})
  @IsDefined()
  @IsInt()
  @Min(1)
  @Max(9007199254740991)
  fence!: number;
  @ApiProperty({"type":"integer","minimum":0,"maximum":9007199254740991,"required":true})
  @IsDefined()
  @IsInt()
  @Min(0)
  @Max(9007199254740991)
  lastAcknowledgedSequence!: number;
  @ApiProperty({"type":"string","enum":["confirmed","unknown","failed"],"required":true})
  @IsDefined()
  @IsIn(["confirmed","unknown","failed"])
  @IsString()
  cleanupState!: string;
}

export class AgentHeartbeatResponseDto {
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  leaseId!: string;
  @ApiProperty({"type":"integer","minimum":1,"maximum":9007199254740991,"required":true})
  @IsDefined()
  @IsInt()
  @Min(1)
  @Max(9007199254740991)
  fence!: number;
  @ApiProperty({"type":"integer","minimum":0,"maximum":30000,"required":true})
  @IsDefined()
  @IsInt()
  @Min(0)
  @Max(30000)
  validForMs!: number;
  @ApiProperty({"type":"boolean","required":true})
  @IsDefined()
  @IsBoolean()
  cancelRequested!: boolean;
  @ApiProperty({"type":"string","enum":["active","reporting","expired","quarantined"],"required":true})
  @IsDefined()
  @IsIn(["active","reporting","expired","quarantined"])
  @IsString()
  state!: string;
  @ApiProperty({"type":"integer","minimum":0,"maximum":9007199254740991,"required":true})
  @IsDefined()
  @IsInt()
  @Min(0)
  @Max(9007199254740991)
  acceptedThrough!: number;
}

export class AgentDeliveryDto {
  @ApiProperty({"type":"integer","minimum":1,"maximum":9007199254740991,"required":true})
  @IsDefined()
  @IsInt()
  @Min(1)
  @Max(9007199254740991)
  deliverySequence!: number;
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  caseId!: string;
  @ApiProperty({"type":"string","minLength":2,"maxLength":1048576,"description":"Opaque Engine JSON; exact public Engine schema, UTF-8 byte/depth limits and immutable snapshot validation apply.","required":true})
  @IsDefined()
  @IsString()
  @MinLength(2)
  @MaxLength(1048576)
  engineEventJson!: string;
}

export class AgentEventsRequestDto {
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  agentId!: string;
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  instanceId!: string;
  @ApiProperty({"type":"integer","minimum":1,"maximum":9007199254740991,"required":true})
  @IsDefined()
  @IsInt()
  @Min(1)
  @Max(9007199254740991)
  fence!: number;
  @ApiProperty({ ...{"minItems":1,"maxItems":100,"required":true}, type: () => [AgentDeliveryDto] })
  @IsDefined()
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(100)
  @ValidateNested({ each: true })
  @Type(() => AgentDeliveryDto)
  events!: Array<AgentDeliveryDto>;
}

export class AgentEventsResponseDto {
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  leaseId!: string;
  @ApiProperty({"type":"integer","minimum":1,"maximum":9007199254740991,"required":true})
  @IsDefined()
  @IsInt()
  @Min(1)
  @Max(9007199254740991)
  fence!: number;
  @ApiProperty({"type":"integer","minimum":0,"maximum":9007199254740991,"required":true})
  @IsDefined()
  @IsInt()
  @Min(0)
  @Max(9007199254740991)
  acceptedThrough!: number;
}

export class AgentCaseResultDto {
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  caseId!: string;
  @ApiProperty({"type":"string","minLength":2,"maxLength":1048576,"description":"Opaque Engine JSON; exact public Engine schema, UTF-8 byte/depth limits and immutable snapshot validation apply.","required":true})
  @IsDefined()
  @IsString()
  @MinLength(2)
  @MaxLength(1048576)
  resultJson!: string;
}

export class AgentArtifactManifestDto {
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  caseId!: string;
  @ApiProperty({"type":"string","pattern":"^[A-Za-z0-9_-][A-Za-z0-9_.-]{0,250}\\.(png|json)$","required":true})
  @IsDefined()
  @IsString()
  @Matches(new RegExp("^[A-Za-z0-9_-][A-Za-z0-9_.-]{0,250}\\.(png|json)$"))
  path!: string;
  @ApiProperty({"type":"string","pattern":"^[a-f0-9]{64}$","required":true})
  @IsDefined()
  @IsString()
  @Matches(new RegExp("^[a-f0-9]{64}$"))
  sha256!: string;
  @ApiProperty({"type":"integer","minimum":0,"maximum":10485760,"required":true})
  @IsDefined()
  @IsInt()
  @Min(0)
  @Max(10485760)
  size!: number;
  @ApiProperty({"type":"string","enum":["image/png","application/json"],"required":true})
  @IsDefined()
  @IsIn(["image/png","application/json"])
  @IsString()
  mimeType!: string;
}

export class AgentArtifactReceiptDto {
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  caseId!: string;
  @ApiProperty({"type":"string","pattern":"^[A-Za-z0-9_-][A-Za-z0-9_.-]{0,250}\\.(png|json)$","required":true})
  @IsDefined()
  @IsString()
  @Matches(new RegExp("^[A-Za-z0-9_-][A-Za-z0-9_.-]{0,250}\\.(png|json)$"))
  path!: string;
  @ApiProperty({"type":"string","pattern":"^[a-f0-9]{64}$","required":true})
  @IsDefined()
  @IsString()
  @Matches(new RegExp("^[a-f0-9]{64}$"))
  sha256!: string;
  @ApiProperty({"type":"integer","minimum":0,"maximum":10485760,"required":true})
  @IsDefined()
  @IsInt()
  @Min(0)
  @Max(10485760)
  size!: number;
  @ApiProperty({"type":"string","enum":["image/png","application/json"],"required":true})
  @IsDefined()
  @IsIn(["image/png","application/json"])
  @IsString()
  mimeType!: string;
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  artifactId!: string;
  @ApiProperty({"type":"boolean","required":true})
  @IsDefined()
  @IsBoolean()
  uploaded!: boolean;
}

export class AgentCompleteRequestDto {
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  agentId!: string;
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  instanceId!: string;
  @ApiProperty({"type":"integer","minimum":1,"maximum":9007199254740991,"required":true})
  @IsDefined()
  @IsInt()
  @Min(1)
  @Max(9007199254740991)
  fence!: number;
  @ApiProperty({ ...{"minItems":0,"maxItems":32,"required":true}, type: () => [AgentCaseResultDto] })
  @IsDefined()
  @IsArray()
  @ArrayMinSize(0)
  @ArrayMaxSize(32)
  @ValidateNested({ each: true })
  @Type(() => AgentCaseResultDto)
  caseResults!: Array<AgentCaseResultDto>;
  @ApiProperty({"type":"string","enum":["finished","blocked","infra_error","cancelled"],"required":true})
  @IsDefined()
  @IsIn(["finished","blocked","infra_error","cancelled"])
  @IsString()
  executionStatus!: string;
  @ApiProperty({"type":"string","nullable":true,"maxLength":4096,"required":true})
  @ValidateIf((_object, value) => value !== null)
  @IsDefined()
  @IsString()
  @MaxLength(4096)
  reason!: string | null;
  @ApiProperty({"type":"string","enum":["confirmed","unknown","failed"],"required":true})
  @IsDefined()
  @IsIn(["confirmed","unknown","failed"])
  @IsString()
  cleanupState!: string;
  @ApiProperty({ ...{"minItems":0,"maxItems":256,"required":true}, type: () => [AgentArtifactManifestDto] })
  @IsDefined()
  @IsArray()
  @ArrayMinSize(0)
  @ArrayMaxSize(256)
  @ValidateNested({ each: true })
  @Type(() => AgentArtifactManifestDto)
  artifactManifest!: Array<AgentArtifactManifestDto>;
}

export class AgentCompleteResponseDto {
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  leaseId!: string;
  @ApiProperty({"type":"integer","minimum":1,"maximum":9007199254740991,"required":true})
  @IsDefined()
  @IsInt()
  @Min(1)
  @Max(9007199254740991)
  fence!: number;
  @ApiProperty({"type":"boolean","required":true})
  @IsDefined()
  @IsBoolean()
  accepted!: boolean;
  @ApiProperty({"type":"integer","minimum":0,"maximum":9007199254740991,"required":true})
  @IsDefined()
  @IsInt()
  @Min(0)
  @Max(9007199254740991)
  acceptedThrough!: number;
  @ApiProperty({"type":"string","format":"uuid","nullable":true,"required":true})
  @ValidateIf((_object, value) => value !== null)
  @IsDefined()
  @IsString()
  @IsUUID('all')
  completionReceipt!: string | null;
  @ApiProperty({"type":"boolean","required":true})
  @IsDefined()
  @IsBoolean()
  deliveryClosed!: boolean;
  @ApiProperty({"type":"string","enum":["pending","missing","verified"],"required":true})
  @IsDefined()
  @IsIn(["pending","missing","verified"])
  @IsString()
  evidenceStatus!: string;
  @ApiProperty({"type":"string","enum":["confirmed","unknown","failed"],"required":true})
  @IsDefined()
  @IsIn(["confirmed","unknown","failed"])
  @IsString()
  cleanupState!: string;
  @ApiProperty({"type":"boolean","required":true})
  @IsDefined()
  @IsBoolean()
  quarantined!: boolean;
  @ApiProperty({ ...{"minItems":0,"maxItems":256,"required":true}, type: () => [AgentArtifactReceiptDto] })
  @IsDefined()
  @IsArray()
  @ArrayMinSize(0)
  @ArrayMaxSize(256)
  @ValidateNested({ each: true })
  @Type(() => AgentArtifactReceiptDto)
  artifacts!: Array<AgentArtifactReceiptDto>;
}

export class AgentKnownLeaseTerminalResultHashesItemDto {
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  caseId!: string;
  @ApiProperty({"type":"string","pattern":"^[a-f0-9]{64}$","required":true})
  @IsDefined()
  @IsString()
  @Matches(new RegExp("^[a-f0-9]{64}$"))
  sha256!: string;
}

export class AgentKnownLeaseDto {
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  leaseId!: string;
  @ApiProperty({"type":"integer","minimum":1,"maximum":9007199254740991,"required":true})
  @IsDefined()
  @IsInt()
  @Min(1)
  @Max(9007199254740991)
  fence!: number;
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  ownerInstanceId!: string;
  @ApiProperty({"type":"integer","minimum":0,"maximum":9007199254740991,"required":true})
  @IsDefined()
  @IsInt()
  @Min(0)
  @Max(9007199254740991)
  lastAcknowledgedSequence!: number;
  @ApiProperty({"type":"string","enum":["confirmed","unknown","failed"],"required":true})
  @IsDefined()
  @IsIn(["confirmed","unknown","failed"])
  @IsString()
  cleanupState!: string;
  @ApiProperty({ ...{"minItems":0,"maxItems":32,"required":true}, type: () => [AgentKnownLeaseTerminalResultHashesItemDto] })
  @IsDefined()
  @IsArray()
  @ArrayMinSize(0)
  @ArrayMaxSize(32)
  @ValidateNested({ each: true })
  @Type(() => AgentKnownLeaseTerminalResultHashesItemDto)
  terminalResultHashes!: Array<AgentKnownLeaseTerminalResultHashesItemDto>;
}

export class AgentReconcileRequestDto {
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  agentId!: string;
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  instanceId!: string;
  @ApiProperty({ ...{"minItems":0,"maxItems":100,"required":true}, type: () => [AgentKnownLeaseDto] })
  @IsDefined()
  @IsArray()
  @ArrayMinSize(0)
  @ArrayMaxSize(100)
  @ValidateNested({ each: true })
  @Type(() => AgentKnownLeaseDto)
  knownLeases!: Array<AgentKnownLeaseDto>;
}

export class AgentOperatorRecoveryDto {
  @ApiProperty({ format: 'uuid' }) @IsDefined() @IsUUID('all') id!: string;
  @ApiProperty({ format: 'date-time' }) @IsDefined() @IsString() confirmedAt!: string;
  @ApiProperty({ type: 'integer', minimum: 1, maximum: 9007199254740991 }) @IsInt() @Min(1) @Max(9007199254740991) priorFence!: number;
  @ApiProperty({ type: 'integer', minimum: 2, maximum: 9007199254740991 }) @IsInt() @Min(2) @Max(9007199254740991) newFence!: number;
}
export class AgentReconcileDecisionDto {
  @ApiProperty({ type: () => AgentOperatorRecoveryDto, nullable: true }) @ValidateIf((_o,v) => v !== null) @IsDefined() @ValidateNested() @Type(() => AgentOperatorRecoveryDto) operatorRecovery!: AgentOperatorRecoveryDto | null;
  @ApiProperty({ type: String, format: 'uuid', nullable: true }) @ValidateIf((_object, value) => value !== null) @IsDefined() @IsUUID('all') completionReceipt!: string | null;
  @ApiProperty() @IsDefined() @IsBoolean() deliveryClosed!: boolean;
  @ApiProperty({ enum: ['pending', 'missing', 'verified'] }) @IsDefined() @IsIn(['pending', 'missing', 'verified']) evidenceStatus!: string;
  @ApiProperty({ ...{"required":true}, type: () => AgentLeaseDto })
  @IsDefined()
  @ValidateNested()
  @Type(() => AgentLeaseDto)
  lease!: AgentLeaseDto;
  @ApiProperty({"type":"string","enum":["resume","cancel","quarantine","observe"],"required":true})
  @IsDefined()
  @IsIn(["resume","cancel","quarantine","observe"])
  @IsString()
  directive!: string;
  @ApiProperty({"type":"string","minLength":1,"maxLength":4096,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(4096)
  reason!: string;
  @ApiProperty({"type":"string","enum":["confirmed","unknown","failed"],"required":true})
  @IsDefined()
  @IsIn(["confirmed","unknown","failed"])
  @IsString()
  cleanupState!: string;
}

export class AgentReconcileResponseDto {
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  agentId!: string;
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  instanceId!: string;
  @ApiProperty({"type":"string","enum":["active","observer","quarantined","released"],"required":true})
  @IsDefined()
  @IsIn(["active","observer","quarantined","released"])
  @IsString()
  instanceState!: string;
  @ApiProperty({ ...{"minItems":0,"maxItems":100,"required":true}, type: () => [AgentReconcileDecisionDto] })
  @IsDefined()
  @IsArray()
  @ArrayMinSize(0)
  @ArrayMaxSize(100)
  @ValidateNested({ each: true })
  @Type(() => AgentReconcileDecisionDto)
  decisions!: Array<AgentReconcileDecisionDto>;
  @ApiProperty({"type":"boolean","required":true})
  @IsDefined()
  @IsBoolean()
  hasMore!: boolean;
  @ApiProperty({"type":"string","nullable":true,"maxLength":512,"required":true})
  @ValidateIf((_object, value) => value !== null)
  @IsDefined()
  @IsString()
  @MaxLength(512)
  nextCursor!: string | null;
}

export class AgentArtifactUploadRequestDto {
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  agentId!: string;
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  instanceId!: string;
  @ApiProperty({"type":"integer","minimum":1,"maximum":9007199254740991,"required":true})
  @IsDefined()
  @IsInt()
  @Min(1)
  @Max(9007199254740991)
  fence!: number;
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  caseId!: string;
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  artifactId!: string;
  @ApiProperty({"type":"string","pattern":"^[a-f0-9]{64}$","required":true})
  @IsDefined()
  @IsString()
  @Matches(new RegExp("^[a-f0-9]{64}$"))
  sha256!: string;
  @ApiProperty({"type":"string","enum":["image/png","application/json"],"required":true})
  @IsDefined()
  @IsIn(["image/png","application/json"])
  @IsString()
  mimeType!: string;
  @ApiProperty({"type":"string","format":"byte","maxLength":13981016,"required":true})
  @IsDefined()
  @IsString()
  @MaxLength(13981016)
  @IsBase64()
  base64!: string;
}

export class AgentResourceBytesDto {
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  resourceId!: string;
  @ApiProperty({"type":"string","maxLength":512,"pattern":"^(?!.*\\.\\.)(?:[A-Za-z0-9_-][A-Za-z0-9_.-]{0,63}/)*[A-Za-z0-9_-][A-Za-z0-9_.-]{0,127}\\.(png|json|woff|woff2|ttf|otf)$","description":"Safe ASCII slash-separated path relative to isolated document root; reject absolute/UNC/backslash/traversal/symlink/case-fold collisions.","required":true})
  @IsDefined()
  @IsString()
  @MaxLength(512)
  @Matches(new RegExp("^(?!.*\\.\\.)(?:[A-Za-z0-9_-][A-Za-z0-9_.-]{0,63}/)*[A-Za-z0-9_-][A-Za-z0-9_.-]{0,127}\\.(png|json|woff|woff2|ttf|otf)$"))
  name!: string;
  @ApiProperty({"type":"string","pattern":"^[a-f0-9]{64}$","required":true})
  @IsDefined()
  @IsString()
  @Matches(new RegExp("^[a-f0-9]{64}$"))
  sha256!: string;
  @ApiProperty({"type":"integer","minimum":0,"maximum":10485760,"required":true})
  @IsDefined()
  @IsInt()
  @Min(0)
  @Max(10485760)
  size!: number;
  @ApiProperty({"type":"string","enum":["image/png","application/json","font/woff","font/woff2","font/ttf","font/otf"],"required":true})
  @IsDefined()
  @IsIn(["image/png","application/json","font/woff","font/woff2","font/ttf","font/otf"])
  @IsString()
  mimeType!: string;
  @ApiProperty({"type":"string","format":"byte","maxLength":13981016,"required":true})
  @IsDefined()
  @IsString()
  @MaxLength(13981016)
  @IsBase64()
  base64!: string;
}

export class AgentHistoricalArtifactDto {
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  caseId!: string;
  @ApiProperty({"type":"string","pattern":"^[A-Za-z0-9_-][A-Za-z0-9_.-]{0,250}\\.(png|json)$","required":true})
  @IsDefined()
  @IsString()
  @Matches(new RegExp("^[A-Za-z0-9_-][A-Za-z0-9_.-]{0,250}\\.(png|json)$"))
  path!: string;
  @ApiProperty({"type":"string","pattern":"^[a-f0-9]{64}$","required":true})
  @IsDefined()
  @IsString()
  @Matches(new RegExp("^[a-f0-9]{64}$"))
  sha256!: string;
  @ApiProperty({"type":"integer","minimum":0,"maximum":10485760,"required":true})
  @IsDefined()
  @IsInt()
  @Min(0)
  @Max(10485760)
  size!: number;
  @ApiProperty({"type":"string","enum":["image/png","application/json"],"required":true})
  @IsDefined()
  @IsIn(["image/png","application/json"])
  @IsString()
  mimeType!: string;
  @ApiProperty({"type":"string","format":"byte","maxLength":13981016,"required":true})
  @IsDefined()
  @IsString()
  @MaxLength(13981016)
  @IsBase64()
  base64!: string;
}

export class AgentHistoricalEvidenceRequestDto {
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  agentId!: string;
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  reportingInstanceId!: string;
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  ownerInstanceId!: string;
  @ApiProperty({"type":"integer","minimum":1,"maximum":9007199254740991,"required":true})
  @IsDefined()
  @IsInt()
  @Min(1)
  @Max(9007199254740991)
  fence!: number;
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  evidenceRequestId!: string;
  @ApiProperty({ ...{"minItems":0,"maxItems":100,"required":true}, type: () => [AgentDeliveryDto] })
  @IsDefined()
  @IsArray()
  @ArrayMinSize(0)
  @ArrayMaxSize(100)
  @ValidateNested({ each: true })
  @Type(() => AgentDeliveryDto)
  events!: Array<AgentDeliveryDto>;
  @ApiProperty({ ...{"minItems":0,"maxItems":32,"required":true}, type: () => [AgentCaseResultDto] })
  @IsDefined()
  @IsArray()
  @ArrayMinSize(0)
  @ArrayMaxSize(32)
  @ValidateNested({ each: true })
  @Type(() => AgentCaseResultDto)
  caseResults!: Array<AgentCaseResultDto>;
  @ApiProperty({"type":"string","enum":["confirmed","unknown","failed"],"required":true})
  @IsDefined()
  @IsIn(["confirmed","unknown","failed"])
  @IsString()
  cleanupState!: string;
  @ApiProperty({ ...{"required":false}, type: () => AgentHistoricalArtifactDto })
  @ValidateIf((_object, value) => value !== undefined)
  @IsDefined()
  @ValidateNested()
  @Type(() => AgentHistoricalArtifactDto)
  artifact?: AgentHistoricalArtifactDto;
}

export class AgentHistoricalEvidenceResponseDto {
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  receiptId!: string;
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  leaseId!: string;
  @ApiProperty({"type":"boolean","required":true})
  @IsDefined()
  @IsBoolean()
  recorded!: boolean;
  @ApiProperty({"type":"boolean","enum":[false],"required":true})
  @IsDefined()
  @IsIn([false])
  @IsBoolean()
  executionPermission!: boolean;
  @ApiProperty({"type":"boolean","enum":[false],"required":true})
  @IsDefined()
  @IsIn([false])
  @IsBoolean()
  resourceReleased!: boolean;
  @ApiProperty({"type":"string","enum":["historical_quarantine"],"required":true})
  @IsDefined()
  @IsIn(["historical_quarantine"])
  @IsString()
  disposition!: string;
}

export class AgentInstanceReleaseRequestReceiptsItemDto {
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  leaseId!: string;
  @ApiProperty({"type":"string","format":"uuid","required":true})
  @IsDefined()
  @IsString()
  @IsUUID('all')
  completionReceipt!: string;
  @ApiProperty({"type":"integer","minimum":0,"maximum":9007199254740991,"required":true})
  @IsDefined()
  @IsInt()
  @Min(0)
  @Max(9007199254740991)
  acceptedThrough!: number;
}

export class AgentInstanceReleaseRequestDto {
  @ApiProperty({ format: 'uuid' }) @IsDefined() @IsUUID('all') reportingInstanceId!: string;
  @ApiProperty({ format: 'uuid' }) @IsDefined() @IsUUID('all') ownerInstanceId!: string;
  @ApiProperty({ enum: [true], type: Boolean }) @IsDefined() @IsIn([true]) ownerStopped!: boolean;
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  agentId!: string;
  @ApiProperty({ type: () => [AgentInstanceReleaseRequestReceiptsItemDto], minItems: 0, maxItems: 100 })
  @IsDefined()
  @IsArray()
  @ArrayMinSize(0)
  @ArrayMaxSize(100)
  @ValidateNested({ each: true })
  @Type(() => AgentInstanceReleaseRequestReceiptsItemDto)
  receipts!: Array<AgentInstanceReleaseRequestReceiptsItemDto>;
}

export class AgentInstanceReleaseResponseDto {
  @ApiProperty({ format: 'uuid' }) @IsDefined() @IsUUID('all') reportingInstanceId!: string;
  @ApiProperty({ format: 'uuid' }) @IsDefined() @IsUUID('all') ownerInstanceId!: string;
  @ApiProperty({"type":"string","minLength":1,"maxLength":128,"required":true})
  @IsDefined()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  agentId!: string;
  @ApiProperty({"type":"boolean","description":"False acknowledges this bounded receipt batch but keeps the owner; true only when all owned leases are independently releasable.","required":true})
  @IsDefined()
  @IsBoolean()
  released!: boolean;
  @ApiProperty({"type":"integer","minimum":0,"maximum":9007199254740991,"required":true})
  @IsDefined()
  @IsInt()
  @Min(0)
  @Max(9007199254740991)
  remainingReceipts!: number;
}

